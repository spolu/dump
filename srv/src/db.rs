use crate::models::{Entry, EntryCreation, Stream};
use anyhow::{anyhow, Result};
use bincode::{deserialize, serialize};
use lazy_static::lazy_static;
use nanoid::nanoid;
use regex::{Captures, Regex};
use std::time::SystemTime;

enum SyncUpdateKind {
    InsertEntry,
    DeleteEntry,
    InsertStream,
    DeleteStream,
}

pub struct SyncUpdate {
    kind: SyncUpdateKind,
    id: Option<String>,
    entry: Option<Entry>,
    stream: Option<Stream>,
}

#[derive(Debug, Clone)]
pub struct DB {
    entries: sled::Tree,
    streams: sled::Tree,
    sync: sled::Tree,
}

pub fn extract_stream_names(s: &String) -> Vec<String> {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"\{[^\{\}]+\}").unwrap();
    }
    RE.captures_iter(s)
        .map(|c| {
            let r = String::from(&c[0]);
            r[1..r.len() - 1].to_string()
        })
        .collect::<Vec<_>>()
}

pub fn clean_stream_names(query: &String) -> String {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"\{[^\{\}]+\}").unwrap();
    }
    let s = String::from(RE.replace_all(query, |_: &Captures| "").trim());
    lazy_static! {
        static ref RE2: Regex = Regex::new(r"\{[^\{\}]*$").unwrap();
    }
    let s = String::from(RE2.replace_all(s.as_str(), |_: &Captures| "").trim());
    s
}

pub fn match_title(query: &String, entry: &Entry) -> bool {
    entry
        .title
        .to_lowercase()
        .contains(clean_stream_names(query).to_lowercase().as_str())
}

pub fn match_body(query: &String, entry: &Entry) -> bool {
    entry
        .body
        .to_lowercase()
        .contains(clean_stream_names(query).to_lowercase().as_str())
}

impl DB {
    pub fn new<P: AsRef<std::path::Path>>(path: P) -> Result<Self> {
        let db = sled::open(path)?;
        let entries = db.open_tree("entries")?;
        let streams = db.open_tree("streams")?;

        let sync = db.open_tree("sync")?;

        let d = DB {
            entries,
            streams,
            sync,
        };
        d.init()?;

        Ok(d)
    }

    fn init(&self) -> Result<()> {
        // Insert `{Inbox}` with special ID `_stream_id_[0-inbox]__`.
        let s = Stream {
            id: String::from("0-inbox"),
            meta: String::from(""),
            name: String::from("Inbox"),
        };
        self.streams
            .insert(s.id.clone().as_bytes(), serialize(&s).unwrap())?;

        match self.sync.get(b"sync_id")? {
            Some(_) => {}
            None => {
                let sid: u64 = 0;
                self.sync.insert(b"sync_id", serialize(&sid).unwrap())?;
            }
        };

        // TODO(spolu) postprocess and update all existing entries.
        let entries = self
            .entries
            .iter()
            .filter_map(|x| {
                let id =
                    String::from(std::str::from_utf8(&x.clone().unwrap().0.to_owned()).unwrap());
                match deserialize(&x.clone().unwrap().1.to_owned()) {
                    Ok(e) => Some(e),
                    _ => {
                        // Deserialization failed, remove the id.
                        self.entries.remove(id.as_bytes()).unwrap();
                        None
                    }
                }
            })
            .collect::<Vec<Entry>>();
        entries.iter().for_each(|e| {
            self.insert_entry(e).unwrap();
        });

        Ok(())
    }

    pub fn get_sync_id(&self) -> Result<u64> {
        match self.sync.get(b"sync_id")? {
            Some(d) => {let sid: u64 = deserialize(&d).unwrap(); Ok(sid) }
            None => {
                Err(anyhow!("sync_id not present in sync tree"))
            }
        }
    }

    /// Finds a stream by name or create a new one with this name if it does not exist (if `create`
    /// is true) otherwise return `None`.
    fn stream_by_name(&self, name: &String, create: bool) -> Result<Option<Stream>> {
        match self.streams.iter().find_map(|x| {
            // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
            let s: Stream = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
            if s.name == name.clone() {
                Some(s)
            } else {
                None
            }
        }) {
            None => {
                if create {
                    let now = SystemTime::now()
                        .duration_since(SystemTime::UNIX_EPOCH)
                        .unwrap()
                        .as_secs();
                    let s = Stream {
                        id: format!("{}-{}", now, nanoid!()),
                        meta: String::from(""),
                        name: name.clone(),
                    };
                    self.streams
                        .insert(s.id.clone().as_bytes(), serialize(&s).unwrap())?;
                    Ok(Some(s))
                } else {
                    Ok(None)
                }
            }
            Some(s) => Ok(Some(s)),
        }
    }

    fn streams_from_query(&self, query: &String) -> Result<Vec<Stream>> {
        let stream_names = extract_stream_names(query);
        let streams = stream_names
            .iter()
            .map(|sn| self.stream_by_name(sn, false))
            .collect::<Result<Vec<_>>>()?;

        Ok(streams.into_iter().filter_map(|s| s).collect::<Vec<_>>())
    }

    /// `preprocess_meta` extracts the streams names from the `meta` string provided
    /// (`{StreamName}`), ensures that each stream exists and replace them with their id-based
    /// format (`_stream_id_[StreamID]__`).
    fn preprocess_meta(&self, meta: &String) -> Result<String> {
        let stream_names = extract_stream_names(meta);
        let streams = stream_names
            .iter()
            .map(|sn| self.stream_by_name(sn, true))
            .collect::<Result<Vec<_>>>()?;

        let mut m = meta.clone();
        streams.iter().for_each(|s| match s {
            Some(s) => {
                m = m.replace(
                    format!("{{{}}}", s.name.as_str()).as_str(),
                    format!("_stream_id_[{}]__", s.id.as_str()).as_str(),
                );
            }
            _ => {}
        });
        // tracing::debug!(meta = m.as_str(), "preprocess_meta");
        Ok(m)
    }

    pub fn extract_streams_from_meta(&self, s: &String, parent_streams: bool) -> Vec<Stream> {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"_stream_id_\[[^\{\[\]\}]+\]__").unwrap();
        }
        let stream_ids = RE
            .captures_iter(s)
            .map(|c| {
                let r = String::from(&c[0]);
                r[12..r.len() - 3].to_string()
            })
            .collect::<Vec<_>>();

        // First iterate on all sreams to match them by id from the ids extracted from `meta`.
        let streams = self
            .streams
            .iter()
            .filter_map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                let s: Stream = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                if stream_ids.iter().any(|id| s.id == *id) {
                    Some(s)
                } else {
                    None
                }
            })
            .collect::<Vec<_>>();

        if parent_streams {
            // If `parent_streams` is true, re-iterate on streams a second time and match streams
            // whose names are parents of the streams extracted previously.
            let mut parent_streams = self
                .streams
                .iter()
                .filter_map(|x| {
                    // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                    let sp: Stream = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                    if streams
                        .iter()
                        .any(|s| s.parent_names().iter().any(|n| sp.name == *n))
                    {
                        Some(sp)
                    } else {
                        None
                    }
                })
                .collect::<Vec<_>>();
            parent_streams.sort_unstable();
            parent_streams.dedup();
            parent_streams
        } else {
            // Otherwise return the `streams` directly.
            streams
        }
    }

    /// `postprocess_meta` extracts the streams ids from the `meta` string provided
    /// (`_stream_id_[StreamID]__`), and replace them with their name (`{StreamName}`).
    fn postprocess_meta(&self, meta: &String) -> Result<String> {
        let streams = self.extract_streams_from_meta(meta, false);

        let mut m = meta.clone();
        streams.iter().for_each(|s| {
            m = m.replace(
                format!("_stream_id_[{}]__", s.id.as_str()).as_str(),
                format!("{{{}}}", s.name.as_str()).as_str(),
            );
        });
        // tracing::debug!(meta = m.as_str(), "postprocess_meta");
        Ok(m)
    }

    pub fn match_meta(
        &self,
        query_streams: &Vec<Stream>,
        entry: &Entry,
        parent_streams: bool,
    ) -> bool {
        let streams = self.extract_streams_from_meta(&entry.meta, parent_streams);
        let mut m = true;
        for qs in query_streams {
            if !m {
                break;
            }
            m = streams.iter().any(|s| s.id == qs.id);
        }
        m
    }

    pub fn create_entry(&self, create: &EntryCreation) -> Result<Entry> {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let entry = Entry {
            id: format!("{}-{}", now, nanoid!()),
            created: now,
            title: create.title.clone(),
            meta: create.meta.clone(),
            body: create.body.clone(),
        };

        self.insert_entry(&entry).unwrap();

        Ok(entry)
    }

    pub fn sync_insert_entry(&self, update: &Entry) -> Result<()> {
        Ok(())
    }

    pub fn insert_entry(&self, update: &Entry) -> Result<()> {
        let meta = self.preprocess_meta(&update.meta)?;

        let entry = Entry {
            meta,
            ..update.clone()
        };

        self.entries
            .insert(entry.id.clone().as_bytes(), serialize(&entry).unwrap())?;
        Ok(())
    }

    pub fn get_entry(&self, id: &String) -> Result<Option<Entry>> {
        let e = &self.entries.get(id.as_bytes())?;
        match e {
            Some(d) => {
                let mut entry: Entry = deserialize(d)?;
                entry.meta = self.postprocess_meta(&entry.meta)?;
                Ok(Some(entry))
            }
            None => Ok(None),
        }
    }

    pub fn delete_entry(&self, id: &String) -> Result<()> {
        self.entries.remove(id.as_bytes())?;
        Ok(())
    }

    pub fn list_entries(
        &self,
        query: &String,
        offset: usize,
        limit: usize,
    ) -> Result<(usize, Vec<Entry>)> {
        let query_streams = self.streams_from_query(query)?;

        let all_entries: Vec<Entry> = self
            .entries
            .iter()
            .rev()
            .filter_map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                let mut e: Entry = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                if self.match_meta(&query_streams, &e, true)
                    && (match_title(&query, &e) || match_body(&query, &e))
                {
                    e.meta = self.postprocess_meta(&e.meta).unwrap();
                    Some(e)
                } else {
                    None
                }
            })
            .collect::<Vec<_>>();
        let total = all_entries.len();

        let entries = all_entries
            .into_iter()
            .skip(offset)
            .take(limit)
            .collect::<Vec<_>>();

        Ok((total, entries))
    }

    pub fn list_streams(&self) -> Result<Vec<Stream>> {
        let mut streams = self
            .streams
            .iter()
            .map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                deserialize(&x.clone().unwrap().1.to_owned()).unwrap()
            })
            .collect::<Vec<_>>();

        streams.sort_by(|a: &Stream, b: &Stream| a.partial_cmp(&b).unwrap());

        Ok(streams)
    }

    pub fn insert_stream(&self, update: &Stream) -> Result<()> {
        self.streams
            .insert(update.id.clone().as_bytes(), serialize(&update).unwrap())?;
        Ok(())
    }

    pub fn get_stream(&self, id: &String) -> Result<Option<Stream>> {
        let s = &self.streams.get(id)?;
        match s {
            Some(d) => {
                let stream: Stream = deserialize(d)?;
                Ok(Some(stream))
            }
            None => Ok(None),
        }
    }

    pub fn delete_stream(&self, id: &String) -> Result<()> {
        let s = &self.streams.get(id)?;
        let stream = match s {
            Some(d) => {
                let stream: Stream = deserialize(d)?;
                Some(stream)
            }
            None => None,
        };
        if !stream.is_some() {
            return Ok(());
        }

        // Remove the stream from its entries.
        let streams = vec![stream.unwrap()];
        let all_entries: Vec<Entry> = self
            .entries
            .iter()
            .rev()
            .filter_map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                let mut e: Entry = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                if self.match_meta(&streams, &e, false) {
                    e.meta = e
                        .meta
                        .replace(format!("_stream_id_[{}]__", id.as_str()).as_str(), "");
                    e.meta = String::from(e.meta.replacen("  ", " ", 2).trim());
                    e.meta = self.postprocess_meta(&e.meta).unwrap();
                    Some(e)
                } else {
                    None
                }
            })
            .collect::<Vec<_>>();

        // And reinsert them.
        all_entries.iter().for_each(|e| {
            self.insert_entry(e).unwrap();
        });

        self.streams.remove(id.as_bytes())?;

        Ok(())
    }
}

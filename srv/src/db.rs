use crate::models::{Entry, Stream};
use anyhow::{anyhow, Result};
use bincode::{deserialize, serialize};
use lazy_static::lazy_static;
use nanoid::nanoid;
use regex::{Captures, Regex};
use std::time::SystemTime;

#[derive(Debug, Clone)]
pub struct DB {
    entries: sled::Tree,
    streams: sled::Tree,
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

pub fn extract_stream_ids(s: &String) -> Vec<String> {
    lazy_static! {
        static ref RE: Regex = Regex::new(r"_stream_id_\[[^\{\[\]\}]+\]__").unwrap();
    }
    RE.captures_iter(s)
        .map(|c| {
            let r = String::from(&c[0]);
            r[12..r.len() - 3].to_string()
        })
        .collect::<Vec<_>>()
}

pub fn match_meta(query_streams: &Vec<Stream>, entry: &Entry) -> bool {
    let stream_ids = extract_stream_ids(&entry.meta);
    for id in stream_ids.clone() {
        tracing::debug!(id = id.as_str(), "stream_id_match_meta");
    }
    let mut m = true;
    for qs in query_streams {
        if !m {
            break;
        }
        m = stream_ids.iter().any(|id| *id == qs.id);
    }
    // tracing::debug!(is_match = m, "match");
    m
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
    tracing::debug!(s = s.as_str(), "clean_stream_names");
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
        Ok(DB { entries, streams })
    }

    pub fn init(&self) -> Result<()> {
        // Insert `{Inbox}` with special ID `_stream_id_[0-inbox]__`.
        let s = Stream {
            id: String::from("0-inbox"),
            name: String::from("Inbox"),
        };
        self.streams
            .insert(s.id.clone().as_bytes(), serialize(&s).unwrap())?;

        // TODO(spolu) postprocess and update all existing entries.
        let entries = self
            .entries
            .iter()
            .map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                deserialize(&x.clone().unwrap().1.to_owned()).unwrap()
            })
            .collect::<Vec<Entry>>();
        entries.iter().for_each(|e| {
            self.insert_entry(e).unwrap();
        });

        Ok(())
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

    fn stream_by_id(&self, id: &String) -> Result<Stream> {
        match self.streams.iter().find_map(|x| {
            // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
            let s: Stream = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
            if s.id == id.clone() {
                Some(s)
            } else {
                None
            }
        }) {
            None => Err(anyhow!("Unknown Stream: id={}", id))?,
            Some(s) => Ok(s),
        }
    }

    fn streams_from_query(&self, query: &String) -> Result<Vec<Stream>> {
        let stream_names = extract_stream_names(query);
        let streams = stream_names
            .iter()
            .map(|sn| self.stream_by_name(sn, false))
            .collect::<Result<Vec<_>>>()?;
        for s in streams.clone() {
            match s {
                Some(s) => tracing::debug!(
                    name = s.name.as_str(),
                    id = s.id.as_str(),
                    "streams_from_query"
                ),
                None => (),
            }
        }

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
        tracing::debug!(meta = m.as_str(), "preprocess_meta");
        Ok(m)
    }

    /// `postprocess_meta` extracts the streams ids from the `meta` string provided
    /// (`_stream_id_[StreamID]__`), and replace them with their name (`{StreamName}`).
    fn postprocess_meta(&self, meta: &String) -> Result<String> {
        let stream_ids = extract_stream_ids(meta);
        for id in stream_ids.clone() {
            tracing::debug!(id = id.as_str(), "postprocess_stream_ids");
        }
        let streams = stream_ids
            .iter()
            .map(|si| self.stream_by_id(si))
            .collect::<Result<Vec<_>>>()?;

        let mut m = meta.clone();
        streams.iter().for_each(|s| {
            m = m.replace(
                format!("_stream_id_[{}]__", s.id.as_str()).as_str(),
                format!("{{{}}}", s.name.as_str()).as_str(),
            );
        });
        tracing::debug!(meta = m.as_str(), "postprocess_meta");
        Ok(m)
    }

    pub fn create_entry(&self, create: &Entry) -> Result<Entry> {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let meta = self.preprocess_meta(&create.meta)?;

        let entry = Entry {
            id: Some(format!("{}-{}", now, nanoid!())),
            created: Some(now),
            title: create.title.clone(),
            meta,
            body: create.body.clone(),
        };

        self.insert_entry(&entry).unwrap();

        Ok(entry)
    }

    pub fn insert_entry(&self, update: &Entry) -> Result<()> {
        let meta = self.preprocess_meta(&update.meta)?;

        let entry = Entry {
            meta,
            ..update.clone()
        };

        self.entries.insert(
            entry.id.clone().unwrap().as_bytes(),
            serialize(&entry).unwrap(),
        )?;
        Ok(())
    }

    pub fn get_entry(&self, id: &String) -> Result<Option<Entry>> {
        let e = &self.entries.get(id)?;
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
                if match_meta(&query_streams, &e)
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
        Ok(self
            .streams
            .iter()
            .map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                deserialize(&x.clone().unwrap().1.to_owned()).unwrap()
            })
            .collect::<Vec<_>>())
    }
}

use tracing_subscriber::{EnvFilter, FmtSubscriber};
use warp::Filter;

#[tokio::main]
async fn main() {
    let filter = EnvFilter::from_default_env();
    let subscriber = FmtSubscriber::builder().with_env_filter(filter).finish();
    tracing::subscriber::set_global_default(subscriber).unwrap();

    let db = sled::open(&shellexpand::tilde("~/.lit.db").into_owned()).unwrap();
    let api = filters::entries(db.open_tree("entries").unwrap())
        .or(filters::streams(db.open_tree("entries").unwrap()));

    let cors = warp::cors()
        .allow_any_origin()
        .allow_headers(vec!["content-type"])
        .allow_methods(vec!["POST", "GET", "PUT", "DELETE"]);

    let routes = api.with(cors).with(warp::log("entries"));

    warp::serve(routes).run(([127, 0, 0, 1], 13371)).await;
}

mod models {
    use serde::{Deserialize, Serialize};

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct Entry {
        pub id: Option<String>,
        pub created: Option<u64>,
        pub meta: String,
        pub title: String,
        pub body: String,
    }

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct EntryList {
        pub total: usize,
        pub offset: usize,
        pub entries: Vec<Entry>,
    }

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct Stream {
        pub id: String,
        pub name: String,
    }

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct StreamList {
        pub total: usize,
        pub streams: Vec<Stream>,
    }

    #[derive(Debug, Deserialize)]
    pub struct ListOptions {
        pub query: Option<String>,
        pub offset: Option<usize>,
        pub limit: Option<usize>,
    }
}

mod filters {
    use super::handlers;
    use super::models::{Entry, ListOptions};
    use warp::Filter;

    fn with<T: Clone + Send>(
        t: T,
    ) -> impl Filter<Extract = (T,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || t.clone())
    }

    fn json_body() -> impl Filter<Extract = (Entry,), Error = warp::Rejection> + Clone {
        warp::body::content_length_limit(1024 * 16).and(warp::body::json())
    }

    pub fn entries(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        entries_list(db.clone())
            .or(entries_create(db.clone()))
            .or(entries_update(db.clone()))
            .or(entries_delete(db.clone()))
    }

    /// GET /entries?q=foo&offset=3&limit=5
    pub fn entries_list(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries")
            .and(warp::get())
            .and(warp::query::<ListOptions>())
            .and(with(db))
            .and_then(handlers::list_entries)
    }

    /// POST /entries with JSON body
    pub fn entries_create(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries")
            .and(warp::post())
            .and(json_body())
            .and(with(db))
            .and_then(handlers::create_entry)
    }

    /// PUT /entries/:id with JSON body
    pub fn entries_update(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries" / String)
            .and(warp::put())
            .and(json_body())
            .and(with(db))
            .and_then(handlers::update_entry)
    }

    /// DELETE /entries/:id
    pub fn entries_delete(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries" / String)
            .and(warp::delete())
            .and(with(db))
            .and_then(handlers::delete_entry)
    }

    pub fn streams(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        streams_list(db.clone())
    }

    /// GET /streams?q=foo&offset=3&limit=5
    pub fn streams_list(
        db: sled::Tree,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("streams")
            .and(warp::get())
            .and(warp::query::<ListOptions>())
            .and(with(db))
            .and_then(handlers::list_streams)
    }
}

mod handlers {
    use super::models::{Entry, EntryList, ListOptions, Stream, StreamList};
    use bincode::{deserialize, serialize};
    use lazy_static::lazy_static;
    use nanoid::nanoid;
    use regex::{Captures, Regex};
    use std::convert::Infallible;
    use std::time::SystemTime;

    pub fn extract_streams(s: &String) -> Vec<String> {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"\{[^\{\}]+\}").unwrap();
        }
        RE.captures_iter(s)
            .map(|c| String::from(&c[0]))
            .collect::<Vec<_>>()
    }

    pub fn match_meta(query: &String, entry: &Entry) -> bool {
        let q_streams = extract_streams(query);
        let m_streams = extract_streams(&entry.meta);
        q_streams.iter().for_each(|s| {
            tracing::debug!(steram = s.as_str(), "query stream");
        });
        m_streams.iter().for_each(|s| {
            tracing::debug!(steram = s.as_str(), "meta stream");
        });
        let mut m = true;
        for qs in q_streams {
            if !m {
                break;
            }
            m = m_streams.iter().any(|ms| *ms == qs);
        }
        tracing::debug!(is_match = m, "match");
        m
    }

    pub fn clean_streams(query: &String) -> String {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"\{[^\{\}]+\}").unwrap();
        }
        let s = String::from(RE.replace_all(query, |_: &Captures| "").trim());
        lazy_static! {
            static ref RE2: Regex = Regex::new(r"\{[^\{\}]*$").unwrap();
        }
        let s = String::from(RE2.replace_all(s.as_str(), |_: &Captures| "").trim());

        tracing::debug!(s = s.as_str(), "clean_streams");
        s
    }

    pub fn match_title(query: &String, entry: &Entry) -> bool {
        entry
            .title
            .to_lowercase()
            .contains(clean_streams(query).to_lowercase().as_str())
    }

    pub fn match_body(query: &String, entry: &Entry) -> bool {
        entry
            .body
            .to_lowercase()
            .contains(clean_streams(query).to_lowercase().as_str())
    }

    pub async fn list_entries(
        opts: ListOptions,
        db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let q = opts.query;
        let all_entries: Vec<Entry> = db
            .iter()
            .rev()
            .filter_map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                let e: Entry = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                match q.clone() {
                    None => Some(e),
                    Some(q) => {
                        if match_meta(&q, &e) && (match_title(&q, &e) || match_body(&q, &e)) {
                            Some(e)
                        } else {
                            None
                        }
                    }
                }
            })
            .collect::<Vec<_>>();
        let total = all_entries.len();

        let entries = all_entries
            .into_iter()
            .skip(opts.offset.unwrap_or(0))
            .take(opts.limit.unwrap_or(std::usize::MAX))
            .collect::<Vec<_>>();

        Ok(warp::reply::json(&EntryList {
            entries,
            total,
            offset: opts.offset.unwrap_or(0),
        }))
    }

    pub async fn create_entry(
        create: Entry,
        db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let entry = Entry {
            id: Some(format!("{}-{}", now, nanoid!())),
            created: Some(now),
            title: create.title,
            meta: create.meta,
            body: create.body,
        };

        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            created = entry.created.unwrap(),
            title = entry.title.clone().as_str(),
            meta = entry.meta.clone().as_str(),
            "create_entry",
        );

        db.insert(
            entry.id.clone().unwrap().as_bytes(),
            serialize(&entry).unwrap(),
        )
        .unwrap();

        Ok(warp::reply::json(&entry))
    }

    pub async fn update_entry(
        id: String,
        update: Entry,
        db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let mut entry: Entry = deserialize(&db.get(id).unwrap().unwrap()).unwrap();
        entry.title = update.title;
        entry.body = update.body;
        entry.meta = update.meta;

        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            created = entry.created.unwrap(),
            title = entry.title.clone().as_str(),
            meta = entry.meta.clone().as_str(),
            "update_entry",
        );
        db.insert(
            entry.id.clone().unwrap().as_bytes(),
            serialize(&entry).unwrap(),
        )
        .unwrap();

        Ok(warp::reply::json(&entry))
    }

    pub async fn delete_entry(id: String, db: sled::Tree) -> Result<impl warp::Reply, Infallible> {
        db.remove(id.as_bytes()).unwrap();
        Ok(warp::reply::json(&id))
    }

    pub async fn list_streams(
        _opts: ListOptions,
        _db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let streams: Vec<Stream> = vec![
            Stream {
                id: String::from("inbox"),
                name: String::from("Inbox"),
            },
            Stream {
                id: String::from("all"),
                name: String::from("All"),
            },
        ];
        let total = streams.len();

        Ok(warp::reply::json(&StreamList { streams, total }))
    }
}

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
        .allow_headers(vec!["*"])
        .allow_methods(vec!["POST", "GET", "PUT"]);

    let routes = api.with(cors).with(warp::log("entries"));

    warp::serve(routes).run(([127, 0, 0, 1], 13371)).await;
}

mod models {
    use serde::{Deserialize, Serialize};

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct Entry {
        pub id: Option<String>,
        pub title: String,
        pub body: String,
    }

    #[derive(Debug, Deserialize, Serialize, Clone)]
    pub struct Stream {
        pub id: String,
        pub name: String,
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
    use super::models::{Entry, ListOptions, Stream};
    use bincode::{deserialize, serialize};
    use nanoid::nanoid;
    use std::convert::Infallible;

    pub async fn list_entries(
        opts: ListOptions,
        db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let entries: Vec<Entry> = db
            .iter()
            .filter_map(|x| {
                // let id = std::str::from_utf8(&x.clone().unwrap().0.to_owned());
                let e: Entry = deserialize(&x.clone().unwrap().1.to_owned()).unwrap();
                Some(e)
            })
            .skip(opts.offset.unwrap_or(0))
            .take(opts.limit.unwrap_or(std::usize::MAX))
            .collect::<Vec<_>>();

        Ok(warp::reply::json(&entries))
    }

    pub async fn create_entry(
        create: Entry,
        db: sled::Tree,
    ) -> Result<impl warp::Reply, Infallible> {
        let entry = Entry {
            id: Some(nanoid!()),
            title: create.title,
            body: create.body,
        };

        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            title = entry.title.clone().as_str(),
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
        // TODO(spolu): check that the entry exists.
        let entry = Entry {
            id: Some(id),
            title: update.title,
            body: update.body,
        };
        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            title = entry.title.clone().as_str(),
            "update_entry",
        );
        db.insert(
            entry.id.clone().unwrap().as_bytes(),
            serialize(&entry).unwrap(),
        )
        .unwrap();

        Ok(warp::reply::json(&entry))
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

        Ok(warp::reply::json(&streams))
    }
}

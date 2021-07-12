use srv::db::DB;
use tracing_subscriber::{EnvFilter, FmtSubscriber};
use warp::Filter;

#[tokio::main]
async fn main() {
    let filter = EnvFilter::from_default_env();
    let subscriber = FmtSubscriber::builder().with_env_filter(filter).finish();
    tracing::subscriber::set_global_default(subscriber).unwrap();

    let db = DB::new(&shellexpand::tilde("~/.dump.db").into_owned()).unwrap();
    db.init().unwrap();

    let api = filters::entries(&db).or(filters::streams(&db));

    let cors = warp::cors()
        .allow_any_origin()
        .allow_headers(vec!["content-type"])
        .allow_methods(vec!["POST", "GET", "PUT", "DELETE"]);

    let routes = api
        // .or(warp::path("static").and(warp::fs::dir("../app/build/web")))
        .with(cors)
        .with(warp::log("entries"));

    warp::serve(routes).run(([127, 0, 0, 1], 13371)).await;
}

mod filters {
    use super::handlers;
    use srv::db::DB;
    use srv::models::{Entry, ListOptions, Stream};
    use warp::Filter;

    fn with<T: Clone + Send>(
        t: T,
    ) -> impl Filter<Extract = (T,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || t.clone())
    }

    fn entry_json_body() -> impl Filter<Extract = (Entry,), Error = warp::Rejection> + Clone {
        warp::body::content_length_limit(1024 * 16).and(warp::body::json())
    }
    fn stream_json_body() -> impl Filter<Extract = (Stream,), Error = warp::Rejection> + Clone {
        warp::body::content_length_limit(1024 * 16).and(warp::body::json())
    }

    pub fn entries(
        db: &DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        entries_list(db.clone())
            .or(entries_create(db.clone()))
            .or(entries_update(db.clone()))
            .or(entries_delete(db.clone()))
    }

    /// GET /entries?q=foo&offset=3&limit=5
    pub fn entries_list(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries")
            .and(warp::get())
            .and(warp::query::<ListOptions>())
            .and(with(db))
            .and_then(handlers::list_entries)
    }

    /// POST /entries with JSON body
    pub fn entries_create(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries")
            .and(warp::post())
            .and(entry_json_body())
            .and(with(db))
            .and_then(handlers::create_entry)
    }

    /// PUT /entries/:id with JSON body
    pub fn entries_update(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries" / String)
            .and(warp::put())
            .and(entry_json_body())
            .and(with(db))
            .and_then(handlers::update_entry)
    }

    /// DELETE /entries/:id
    pub fn entries_delete(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("entries" / String)
            .and(warp::delete())
            .and(with(db))
            .and_then(handlers::delete_entry)
    }

    pub fn streams(
        db: &DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        streams_list(db.clone())
            .or(streams_delete(db.clone()))
            .or(streams_update(db.clone()))
    }

    /// GET /streams?q=foo&offset=3&limit=5
    pub fn streams_list(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("streams")
            .and(warp::get())
            .and(warp::query::<ListOptions>())
            .and(with(db))
            .and_then(handlers::list_streams)
    }

    /// PUT /streams/:id with JSON body
    pub fn streams_update(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("streams" / String)
            .and(warp::put())
            .and(stream_json_body())
            .and(with(db))
            .and_then(handlers::update_stream)
    }

    /// DELETE /streams/:id
    pub fn streams_delete(
        db: DB,
    ) -> impl Filter<Extract = impl warp::Reply, Error = warp::Rejection> + Clone {
        warp::path!("streams" / String)
            .and(warp::delete())
            .and(with(db))
            .and_then(handlers::delete_stream)
    }
}

mod handlers {
    use srv::db::DB;
    use srv::models::{Entry, EntryList, ListOptions, Stream, StreamList};
    use std::convert::Infallible;

    pub async fn list_entries(opts: ListOptions, db: DB) -> Result<impl warp::Reply, Infallible> {
        let query = opts.query.unwrap_or(String::from(""));
        let offset = opts.offset.unwrap_or(0);
        let limit = opts.limit.unwrap_or(std::usize::MAX);

        let (total, entries) = db.list_entries(&query, offset, limit).unwrap();

        tracing::debug!(query = query.as_str(), offset, limit, total, "list_entries",);

        Ok(warp::reply::json(&EntryList {
            entries,
            total,
            offset,
        }))
    }

    pub async fn create_entry(create: Entry, db: DB) -> Result<impl warp::Reply, Infallible> {
        let entry = db.create_entry(&create).unwrap();

        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            created = entry.created.unwrap(),
            title = entry.title.clone().as_str(),
            meta = entry.meta.clone().as_str(),
            "create_entry",
        );

        Ok(warp::reply::json(&entry))
    }

    pub async fn update_entry(
        id: String,
        update: Entry,
        db: DB,
    ) -> Result<impl warp::Reply, Infallible> {
        let mut entry = db.get_entry(&id).unwrap().unwrap();
        entry.title = update.title;
        entry.body = update.body;
        entry.meta = update.meta;

        db.insert_entry(&entry).unwrap();

        tracing::debug!(
            id = entry.id.clone().unwrap().as_str(),
            created = entry.created.unwrap(),
            title = entry.title.clone().as_str(),
            meta = entry.meta.clone().as_str(),
            "update_entry",
        );

        Ok(warp::reply::json(&entry))
    }

    pub async fn delete_entry(id: String, db: DB) -> Result<impl warp::Reply, Infallible> {
        db.delete_entry(&id).unwrap();

        tracing::debug!(id = id.as_str(), "delete_entry",);

        Ok(warp::reply::json(&id))
    }

    pub async fn list_streams(_opts: ListOptions, db: DB) -> Result<impl warp::Reply, Infallible> {
        let streams: Vec<Stream> = db.list_streams().unwrap();
        let total = streams.len();

        tracing::debug!(total, "list_streams",);

        Ok(warp::reply::json(&StreamList { streams, total }))
    }

    pub async fn delete_stream(id: String, db: DB) -> Result<impl warp::Reply, Infallible> {
        db.delete_stream(&id).unwrap();

        tracing::debug!(id = id.as_str(), "delete_stream",);

        Ok(warp::reply::json(&id))
    }

    pub async fn update_stream(
        id: String,
        update: Stream,
        db: DB,
    ) -> Result<impl warp::Reply, Infallible> {
        let mut stream = db.get_stream(&id).unwrap().unwrap();
        stream.name = update.name;

        db.insert_stream(&stream).unwrap();

        tracing::debug!(
            id = stream.id.clone().as_str(),
            name = stream.name.clone().as_str(),
            "update_stream",
        );

        Ok(warp::reply::json(&stream))
    }
}

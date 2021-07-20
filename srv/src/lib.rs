use anyhow::Result;
use lazy_static::lazy_static;
use std::env;
use std::ffi::{CStr, CString};
use std::os::raw;
use std::path::Path;

mod db;
mod models;

lazy_static! {
    static ref DB: db::DB =
        db::DB::new(Path::new(&env::var("HOME").unwrap()).join(".dump.db")).unwrap();
}

#[no_mangle]
pub extern "C" fn response_free_ffi(response: *mut raw::c_char) {
    unsafe {
        if response.is_null() {
            return;
        }
        CString::from_raw(response)
    };
}

fn list_entries(options: models::ListOptions) -> Result<models::EntryList> {
    let (total, entries) = DB
        .list_entries(&options.query, options.offset, options.limit)
        .unwrap();

    tracing::debug!(
        query = options.query.as_str(),
        offset = options.offset,
        limit = options.limit,
        total,
        "list_entries",
    );

    Ok(models::EntryList {
        entries,
        total,
        offset: options.offset,
    })
}

macro_rules! make_ffi {
    ($function:expr, $request:expr, $type:ty) => {{
        let request_c_str = unsafe { CStr::from_ptr($request) };
        let json = match request_c_str.to_str() {
            Err(err) => serde_json::to_string(&models::ErrorResponse {
                error: format!("{}", err),
            })
            .unwrap(),
            Ok(query) => {
                let r: Result<$type, serde_json::Error> = serde_json::from_str(query);
                match r {
                    Err(err) => serde_json::to_string(&models::ErrorResponse {
                        error: format!("{}", err),
                    })
                    .unwrap(),
                    Ok(r) => serde_json::to_string(&$function(r).unwrap()).unwrap(),
                }
            }
        };

        CString::new(json.as_str()).unwrap().into_raw()
    }};
}

#[no_mangle]
pub extern "C" fn list_entries_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(list_entries, request, models::ListOptions)
}

fn create_entry(create: models::Entry) -> Result<models::Entry> {
    let entry = DB.create_entry(&create)?;

    tracing::debug!(
        id = entry.id.clone().unwrap().as_str(),
        created = entry.created.unwrap(),
        title = entry.title.clone().as_str(),
        meta = entry.meta.clone().as_str(),
        "create_entry",
    );

    Ok(entry)
}

#[no_mangle]
pub extern "C" fn create_entry_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(create_entry, request, models::Entry)
}

fn update_entry(update: models::Entry) -> Result<models::Entry> {
    // If the entry does not exist anymore, re-create it as we don't want to loose data. It will
    // get created with a new ID and creation date.
    let mut entry = match DB.get_entry(update.id.as_ref().unwrap())? {
        Some(e) => e,
        None => DB.create_entry(&update)?,
    };
    entry.title = update.title;
    entry.body = update.body;
    entry.meta = update.meta;

    DB.insert_entry(&entry)?;

    tracing::debug!(
        id = entry.id.clone().unwrap().as_str(),
        created = entry.created.unwrap(),
        title = entry.title.clone().as_str(),
        meta = entry.meta.clone().as_str(),
        "update_entry",
    );

    Ok(entry)
}

#[no_mangle]
pub extern "C" fn update_entry_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(update_entry, request, models::Entry)
}

fn delete_entry(delete: models::Entry) -> Result<models::Entry> {
    DB.delete_entry(delete.id.as_ref().unwrap())?;

    tracing::debug!(id = delete.id.as_ref().unwrap().as_str(), "delete_entry",);

    Ok(delete)
}

#[no_mangle]
pub extern "C" fn delete_entry_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(delete_entry, request, models::Entry)
}

fn list_streams(_options: models::ListOptions) -> Result<models::StreamList> {
    let streams: Vec<models::Stream> = DB.list_streams()?;
    let total = streams.len();

    tracing::debug!(total, "list_streams",);

    Ok(models::StreamList { streams, total })
}

#[no_mangle]
pub extern "C" fn list_streams_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(list_streams, request, models::ListOptions)
}

fn delete_stream(delete: models::Stream) -> Result<models::Stream> {
    DB.delete_stream(&delete.id)?;

    tracing::debug!(id = delete.id.as_str(), "delete_stream",);

    Ok(delete)
}

#[no_mangle]
pub extern "C" fn delete_stream_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(delete_stream, request, models::Stream)
}

fn update_stream(update: models::Stream) -> Result<models::Stream> {
    let stream = DB.get_stream(&update.id)?;
    if stream.is_none() {
        Ok(update)
    } else {
        let mut stream = stream.unwrap();
        stream.name = update.name;

        DB.insert_stream(&stream).unwrap();

        tracing::debug!(
            id = stream.id.clone().as_str(),
            name = stream.name.clone().as_str(),
            "update_stream",
        );

        Ok(stream)
    }
}

#[no_mangle]
pub extern "C" fn update_stream_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    make_ffi!(update_stream, request, models::Stream)
}

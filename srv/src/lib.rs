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

fn list_entries(query: &String, offset: usize, limit: usize) -> Result<models::EntryList> {
    let (total, entries) = DB.list_entries(query, offset, limit).unwrap();

    tracing::debug!(query = query.as_str(), offset, limit, total, "list_entries",);

    Ok(models::EntryList {
        entries,
        total,
        offset,
    })
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

#[no_mangle]
pub extern "C" fn list_entries_ffi(request: *const raw::c_char) -> *mut raw::c_char {
    let request_c_str = unsafe { CStr::from_ptr(request) };
    let json = match request_c_str.to_str() {
        Err(err) => serde_json::to_string(&models::ErrorResponse {
            error: format!("{}", err),
        })
        .unwrap(),
        Ok(query) => {
            let r: Result<models::ListOptions, serde_json::Error> = serde_json::from_str(query);
            match r {
                Err(err) => serde_json::to_string(&models::ErrorResponse {
                    error: format!("{}", err),
                })
                .unwrap(),
                Ok(r) => serde_json::to_string(&list_entries(&r.query, r.offset, r.limit).unwrap())
                    .unwrap(),
            }
        }
    };

    CString::new(json.as_str()).unwrap().into_raw()
}

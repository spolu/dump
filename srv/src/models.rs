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

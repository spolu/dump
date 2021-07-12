use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

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

#[derive(Debug, Deserialize, Serialize, Clone, Eq)]
pub struct Stream {
    pub id: String,
    pub name: String,
}

impl PartialEq for Stream {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl PartialOrd for Stream {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        if self.name == "Inbox" {
            Some(Ordering::Less)
        } else if other.name == "Inbox" {
            Some(Ordering::Greater)
        } else {
            self.name.partial_cmp(&other.name)
        }
    }
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

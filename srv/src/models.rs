use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct EntryCreation {
    pub meta: String,
    pub title: String,
    pub body: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct EntryPrev {
    pub id: Option<String>,
    pub created: Option<u64>,
    pub meta: String,
    pub title: String,
    pub body: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Entry {
    pub id: String,
    pub created: u64,
    pub meta: String,
    pub title: String,
    pub body: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct StreamPrev {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Eq)]
pub struct Stream {
    pub id: String,
    pub meta: String,
    pub name: String,
}

impl Stream {
    pub fn parent_names(&self) -> Vec<String> {
        let mut parents: Vec<String> = vec![];
        let components = self.name.split("/").collect::<Vec<_>>();
        for c in 0..components.len() {
            parents.push(String::from(&components[0..=c].join("/")))
        }
        parents
    }
}

impl PartialEq for Stream {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Ord for Stream {
    fn cmp(&self, other: &Self) -> Ordering {
        if self.name == "Inbox" {
            if other.name == "Inbox" {
                Ordering::Equal
            } else {
                Ordering::Less
            }
        } else if other.name == "Inbox" {
            Ordering::Greater
        } else {
            self.name.cmp(&other.name)
        }
    }
}

impl PartialOrd for Stream {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_stream_parent_names() {
        let s = Stream {
            id: String::from("foo"),
            meta: String::from(""),
            name: String::from("Foo/Bar"),
        };
        assert_eq!(vec!["Foo", "Foo/Bar"], s.parent_names());

        let s = Stream {
            id: String::from("foo"),
            meta: String::from(""),
            name: String::from("Foo"),
        };
        assert_eq!(vec!["Foo"], s.parent_names());

        let s = Stream {
            id: String::from("foo"),
            meta: String::from(""),
            name: String::from("Foo/Bar/Acme"),
        };
        assert_eq!(vec!["Foo", "Foo/Bar", "Foo/Bar/Acme"], s.parent_names());

        let s = Stream {
            id: String::from("foo"),
            meta: String::from(""),
            name: String::from("Foo/"),
        };
        assert_eq!(vec!["Foo", "Foo/"], s.parent_names());

        let s = Stream {
            id: String::from("foo"),
            meta: String::from(""),
            name: String::from("/Foo/"),
        };
        assert_eq!(vec!["", "/Foo", "/Foo/"], s.parent_names());
    }
}

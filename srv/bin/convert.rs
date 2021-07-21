use anyhow::Result;
use bincode::{deserialize, serialize};
use clap::{App, Arg};
use srv::models::{Entry, EntryPrev, Stream, StreamPrev};

fn main() -> Result<()> {
    let matches = App::new("convert")
        .about("Convert a DB")
        .arg(
            Arg::with_name("source")
                .value_name("SOURCE")
                .help("The path of the DB to convert")
                .required(true),
        )
        .arg(
            Arg::with_name("target")
                .value_name("TARGET")
                .help("The target path to dump")
                .required(true),
        )
        .get_matches();

    let src = sled::open(matches.value_of("source").unwrap())?;
    let src_entries = src.open_tree("entries")?;
    let src_streams = src.open_tree("streams")?;

    let tgt = sled::open(matches.value_of("target").unwrap())?;
    let tgt_entries = tgt.open_tree("entries")?;
    let tgt_streams = tgt.open_tree("streams")?;

    let entries = src_entries
        .iter()
        .filter_map(|x| match deserialize(&x.clone().unwrap().1.to_owned()) {
            Ok(e) => Some(e),
            _ => None,
        })
        .collect::<Vec<EntryPrev>>();

    entries.iter().for_each(|o| {
        let e = Entry {
            id: o.id.clone().unwrap(),
            created: o.created.clone().unwrap(),
            title: o.title.clone(),
            meta: o.meta.clone(),
            body: o.body.clone(),
        };
        tgt_entries.insert(e.id.clone().as_bytes(), serialize(&e).unwrap()).unwrap();
    });

    let streams = src_streams
        .iter()
        .filter_map(|x| match deserialize(&x.clone().unwrap().1.to_owned()) {
            Ok(s) => Some(s),
            _ => None,
        })
        .collect::<Vec<StreamPrev>>();

    streams.iter().for_each(|o| {
        let s = Stream {
            id: o.id.clone(),
            meta: String::from(""),
            name: o.name.clone(),
        };
        tgt_streams.insert(s.id.clone().as_bytes(), serialize(&s).unwrap()).unwrap();
    });

    Ok(())
}

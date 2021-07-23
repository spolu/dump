use anyhow::Result;
use clap::{App, Arg};
use tonic::{
    metadata::MetadataValue,
    transport::{Channel, ClientTlsConfig},
    Request,
};
use srv::google::firestore::v1::{
    firestore_client::FirestoreClient, value::ValueType, CreateDocumentRequest, Document, Value,
};
use srv::db::DB;

const URL: &'static str = "https://firestore.googleapis.com";
const DOMAIN: &'static str = "firestore.googleapis.com";
const PROJECT_ID: &'static str = "dump-42558";

async fn get_client(jwt: String) -> Result<FirestoreClient<Channel>> {
    let endpoint = Channel::from_static(URL).tls_config(ClientTlsConfig::new().domain_name(DOMAIN))?;

    let bearer_token = format!("Bearer {}", jwt);
    let header_value = MetadataValue::from_str(&bearer_token)?;

    let channel = endpoint.connect().await?;

    let service = FirestoreClient::with_interceptor(channel, move |mut req: Request<()>| {
        req.metadata_mut()
            .insert("authorization", header_value.clone());
        Ok(req)
    });
    Ok(service)
}

async fn create_document(uid: String, jwt: String) -> Result<Document> {
    let parent = format!("projects/{}/databases/(default)/documents", PROJECT_ID,);
    let collection_id = "users".into();
    let document_id = uid.clone();
    let mut fields = std::collections::HashMap::new();
    fields.insert(
        "message".into(),
        Value {
            value_type: Some(ValueType::StringValue("Hello world!".into())),
        },
    );
    let document = Some(Document {
        name: "".into(),
        fields,
        create_time: None,
        update_time: None,
    });
    let res = get_client(jwt)
        .await?
        .create_document(CreateDocumentRequest {
            parent,
            collection_id,
            document_id,
            document,
            mask: None,
        })
        .await?;
    Ok(res.into_inner())
}

#[tokio::main]
pub async fn main() -> Result<()> {
    let matches = App::new("force_resync")
        .about("Forces the resync of a DB")
        .arg(
            Arg::with_name("db")
                .value_name("DB")
                .help("The path of the DB to resync")
                .required(true),
        )
        .arg(
            Arg::with_name("uid")
                .value_name("UID")
                .help("The user id to use")
                .required(true),
        )
        .arg(
            Arg::with_name("jwt")
                .value_name("JWT")
                .help("The JWT token to use")
                .required(true),
        )
        .get_matches();

    let db: DB = DB::new(matches.value_of("db").unwrap()).unwrap();

    let sid: u64 = db.get_sync_id()?;
    println!("SYNC_ID: {}", sid);

    let d = create_document(String::from(matches.value_of("uid").unwrap()), String::from(matches.value_of("jwt").unwrap())).await?;

    Ok(())
}

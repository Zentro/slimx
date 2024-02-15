use std::{sync::Arc, collections::HashMap};
use tokio::sync::{mpsc, RwLock};

use serde_derive::{Deserialize, Serialize};
use warp::filters::ws::Message;
pub type Issuer = Arc<auth::Issuer>;
pub type Users = Arc<RwLock<HashMap<u64, mpsc::UnboundedSender<Message>>>>;

pub fn new_issuer() -> Issuer {
    use rand::{rngs::OsRng, RngCore};
    let mut hmac_key: [u8; 32] = [0; 32];
    OsRng.fill_bytes(&mut hmac_key);

    Arc::new(auth::Issuer::new(hmac_key))
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct LoginForm {
    pub email: String,
    pub password: String
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RegisterForm {
    pub username: String,
    pub password: String,
    pub email: String,
    pub phone: String
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct KeysForm {
    pub ik: String,
    pub spk: String,
    pub spk_sig: String,
    pub pqspk: String,
    pub pqspk_sig: String,
    pub opk_map: HashMap<String, String>,
    pub pqopk_map: HashMap<String, (String, String)>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct PrekeyBundle {
    pub handshake_id: u64,
    pub ik: String,
    pub spk: String,
    pub spk_sig: String,
    pub pqpk: String,
    pub pqpk_sig: String,
    pub opk: Option<String>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FillHandshake {
    pub handshake_id: u64,
    pub ek: String,
    pub pqkem_ct: String,
    pub ct: String
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct LoginComplete {
    pub id: u64,
    pub username: String,
    pub email: String,
    pub phone: Option<String>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MessageDetails {
    pub created: u64,
    pub sender: String,
    pub isMe: bool,
    pub msg: Vec<u8>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RecvMessage {
    pub sender: String,
    pub isMe: bool,
    #[serde(with = "serde_bytes")]
    pub text: Vec<u8>
}
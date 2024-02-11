use std::{sync::Arc, collections::HashMap};
use tokio::sync::Mutex;

use serde_derive::{Deserialize, Serialize};
pub type Issuer = Arc<auth::Issuer>;
pub type Connections = Arc<Mutex<HashMap<String, i32>>>;

pub fn new_issuer() -> Issuer {
    use rand::{rngs::OsRng, RngCore};
    let mut hmac_key: [u8; 32] = [0; 32];
    OsRng.fill_bytes(&mut hmac_key);

    Arc::new(auth::Issuer::new(hmac_key))
}

pub fn new_conn_list() -> Connections {
    Arc::new(Mutex::new(HashMap::new()))
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
    pub opk_arr: Vec<String>,
    pub opk_sig_arr: Vec<String>,
    pub pqopk_arr: Vec<String>,
    pub pqopk_sig_arr: Vec<String>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct PrekeyBundle {
    pub handshake_id: u64,
    pub ik: String,
    pub spk: String,
    pub spk_sig: String,
    pub pqpk: String,
    pub pqpk_sig: String,
    pub opk: Option<String>,
    pub opk_sig: Option<String>
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct FillHandshake {
    pub handshake_id: u64,
    pub ek: String,
    pub pqkem_ct: String,
    pub ct: String
}
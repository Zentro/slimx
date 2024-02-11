use diesel::prelude::*;
use serde_derive::Serialize;

use crate::schema::{
    users, 
    perm_keys, 
    onetime_keys, 
    onetime_pqkem, 
    handshakes,
    chats,
    messages
};
use chrono::NaiveDateTime;

#[derive(Queryable, Selectable, Identifiable, Debug, PartialEq, Serialize)]
#[diesel(table_name = users)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct User {
    pub id: u64,
    pub username: String,
    pub password: String,
    pub email: String,
    pub phone: Option<String>
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, PartialEq)]
#[diesel(belongs_to(User, foreign_key = user_id))]
#[diesel(table_name = messages)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct Message {
    pub id: u64,
    pub created: NaiveDateTime,
    pub updated: Option<NaiveDateTime>,
    pub user_id: u64,
    pub chat_id: u64,
    pub msg: Vec<u8>
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, PartialEq)]
#[diesel(belongs_to(User, foreign_key = user_id))]
#[diesel(table_name = perm_keys)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct PermKeys {
    pub id: u64,
    pub user_id: u64,
    pub ik: String,
    pub spk: String,
    pub spk_sig: String,
    pub pqspk: String,
    pub pqspk_sig: String
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, PartialEq)]
#[diesel(belongs_to(User, foreign_key = user_id))]
#[diesel(table_name = onetime_keys)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct OnetimeKey {
    pub id: u64,
    pub user_id: u64,
    pub opk: String,
    pub sig: String,
    pub i: u32
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, PartialEq)]
#[diesel(belongs_to(User, foreign_key = user_id))]
#[diesel(table_name = onetime_pqkem)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct OnetimePqkem {
    pub id: u64,
    pub user_id: u64,
    pub pqopk: String,
    pub sig: String,
    pub i: u32
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, PartialEq)]
#[diesel(belongs_to(User, foreign_key = sender_id))]
#[diesel(table_name = handshakes)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct Handshake {
    pub id: u64,
    pub sender_id: u64,
    pub receiver_id: u64,
    pub ik: String,
    pub ek: Option<String>,
    pub pqkem_ct: Option<String>,
    pub ct: Option<String>
}

#[derive(Queryable, Selectable, Identifiable, Debug, PartialEq)]
#[diesel(table_name = chats)]
#[diesel(check_for_backend(diesel::mysql::Mysql))]
pub struct Chat {
    pub id: u64,
    pub a: u64,
    pub b: u64
}

#[derive(Insertable)]
#[diesel(table_name = users)]
pub struct NewUser {
    pub username: String,
    pub password: String,
    pub email: String,
    pub phone: String
}

#[derive(Insertable)]
#[diesel(table_name = perm_keys)]
pub struct NewPermKeys {
    pub user_id: u64,
    pub ik: String,
    pub spk: String,
    pub spk_sig: String,
    pub pqspk: String,
    pub pqspk_sig: String
}

#[derive(Insertable)]
#[diesel(table_name = onetime_keys)]
pub struct NewOnetimeKey {
    pub user_id: u64,
    pub opk: String,
    pub sig: String,
    pub i: u32
}

#[derive(Insertable)]
#[diesel(table_name = onetime_pqkem)]
pub struct NewOnetimePqkem {
    pub user_id: u64,
    pub pqopk: String,
    pub sig: String,
    pub i: u32
}

#[derive(Insertable)]
#[diesel(table_name = handshakes)]
pub struct NewHandshake {
    pub sender_id: u64,
    pub receiver_id: u64,
    pub ik: String,
    pub ek: Option<String>,
    pub pqkem_ct: Option<String>,
    pub ct: Option<String>
}

impl NewHandshake {
    pub fn new(sid: u64, rid: u64, ik: String) -> NewHandshake {
        NewHandshake {
            sender_id: sid,
            receiver_id: rid,
            ik,
            ek: None,
            pqkem_ct: None,
            ct: None,
        }
    }
}
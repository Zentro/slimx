pub mod diesel_models;
pub mod http_models;
pub mod schema;
mod xeddsa;
mod logger;

#[tokio::main]
async fn main() {
    let issuer = http_models::new_issuer();
    let users = http_models::Users::default();
    let challenges = http_models::Challenges::default();

    let api = filters::server(issuer, challenges, users);
    
    warp::serve(api).run(([127, 0, 0, 1], 8080)).await;
}

mod filters {
    use serde::de::DeserializeOwned;
    use warp::Filter;

    use crate::logger::{self, LogLevel};

    use super::{
        handlers,
        http_models::*
    };

    pub fn server(
        iss: Issuer, chal: Challenges, users: Users
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        let users = warp::any().map(move || users.clone());
        let chat = warp::path("chat")
            .and(warp::path::param::<u64>())
            .and(warp::ws())
            .and(users.clone())
            .and(with_auth(iss.clone()))
            .and(warp::header("authorization"))
            .map(|chat_id, ws: warp::ws::Ws, users, iss, tok: String| {
                // This will call our function if the handshake succeeds.
                ws.on_upgrade(move |socket| handlers::chat(iss, tok, socket, users, chat_id))
            });

        login(iss.clone(), chal.clone())
            .or(login_challenge(iss.clone(), chal.clone()))
            .or(register())
            .or(upload_keys(iss.clone()))
            .or(init_handshake(iss.clone()))
            .or(fill_handshake(iss.clone()))
            .or(get_inbox(iss.clone()))
            .or(get_pending(iss.clone()))
            .or(complete_handshake(iss.clone()))
            .or(chat)
    }

    pub fn login(
        iss: Issuer,
        chal: Challenges
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("login")
            .and(warp::post())
            .and(body::<LoginForm>())
            .and(with_auth(iss))
            .and(with_challenges(chal))
            .and_then(handlers::login)
    }

    pub fn login_challenge(
        iss: Issuer,
        chal: Challenges
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("login")
            .and(warp::put())
            .and(with_challenges(chal))
            .and(warp::header("email"))
            .and(warp::header("signature"))
            .and_then(handlers::login_challenge)
    }

    pub fn register() -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("register")
            .and(warp::post())
            .and(body::<RegisterForm>())
            .and_then(handlers::register)
    }

    pub fn upload_keys(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("keys")
            .and(warp::post())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and(body::<KeysForm>())
            .and_then(handlers::upload_keys)
    }

    pub fn init_handshake(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("handshakes")
            .and(warp::post())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and(warp::header("email"))
            .and_then(handlers::init_handshake)
    }

    pub fn fill_handshake(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("handshakes")
            .and(warp::put())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and(body::<FillHandshake>())
            .and_then(handlers::fill_handshake)
    }

    pub fn get_inbox(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("inbox")
            .and(warp::get())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and_then(handlers::get_inbox)
    }

    pub fn get_pending(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("pending")
            .and(warp::get())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and_then(handlers::get_pending)
    }

    pub fn complete_handshake(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("complete")
            .and(warp::post())
            .and(with_auth(iss))
            .and(warp::header("authorization"))
            .and(warp::header("handshake_id"))
            .and_then(handlers::complete_handshake)
    }

    fn with_auth(iss: Issuer) -> impl Filter<Extract = (Issuer,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || iss.clone())
    }

    fn with_challenges(chal: Challenges) -> impl Filter<Extract = (Challenges,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || chal.clone())
    }

    fn body<T: std::marker::Send + DeserializeOwned>() -> impl Filter<Extract = (T,), Error = warp::Rejection> + Clone {
       warp::body::json()
    }
}

mod handlers {
    use rand::distributions::{Alphanumeric, DistString};
    use futures_util::{SinkExt, StreamExt, TryFutureExt};
    use serde_json::json;
    use tokio::sync::mpsc;
    use tokio_stream::wrappers::UnboundedReceiverStream;
    use diesel::{mysql::MysqlConnection, prelude::*};
    use warp::{filters::ws::{Message, WebSocket}, http::{Response, StatusCode}, hyper::Body};
    use argon2::{
        password_hash::{
            rand_core::OsRng,
            PasswordHasher, SaltString
        },
        Argon2, PasswordVerifier, PasswordHash
    };
    use dotenvy::dotenv;
    use std::{collections::HashMap, env, time::{SystemTime, UNIX_EPOCH}};


    use super::{
        logger::{self, LogLevel}, schema::{chats, messages},
        xeddsa::verify,
        diesel_models::*,
        http_models::*,
        schema::{users, handshakes, perm_keys, onetime_keys, onetime_pqkem}
    };

    /// Takes in an Issuer and a login_token and verifies its validity
    /// 
    /// verify_token!(iss: Issuer, login_token: &str)
    /// 
    /// Returns the payload if valid. 
    /// Exits from the function with Ok(warp::reply) if payload is invalid.
    macro_rules! verify_token {
        ($iss: ident, $token: ident) => {
            match $iss.verify(&$token) {
                Some(payload) => payload,
                None => return Ok(empty_response(StatusCode::UNAUTHORIZED)),
            }
        }
    }

    pub async fn login(
        info: LoginForm, iss: Issuer, chal: Challenges
    ) -> Result<impl warp::Reply, warp::Rejection> {
        use crate::schema::users::dsl::*;

        let conn = &mut establish_connection();

        // Search for this user
        let res: Vec<User> = users
            .filter(email.eq(&info.email))
            .limit(1)
            .select(User::as_select())
            .load(conn)
            .unwrap();
        if res.is_empty() {
            logger::log(LogLevel::Info, &format!("Cannot find user's email {}", &info.email));
            return Ok(empty_response(StatusCode::NOT_FOUND));
        }

        // If found, check the paswroidasdsasd
        let user = res.first().unwrap();
        let parsed_hash = PasswordHash::new(&user.password).unwrap();
        if Argon2::default().verify_password(info.password.as_bytes(), &parsed_hash).is_err() {
            logger::log(LogLevel::Info, &format!("Wrong password for {}", &info.email));
            return Ok(empty_response(StatusCode::UNAUTHORIZED));
        }

        // Check if keys have been uploaded
        let (perms, need_upload) = match perm_keys::table
            .filter(perm_keys::user_id.eq(user.id))
            .select(PermKeys::as_select())
            .get_result(conn) {
                Ok(r) =>(Some(r), false),
                Err(_) => (None, true)
            };

        // Issue a jwt auth token, can be overridden by next step
        let mut head = iss.issue(user.id, &user.email);
        let sent = LoginComplete { 
            id: user.id, username: user.username.clone(), email: user.email.clone(), phone: user.phone.clone()
        };
        let response_body = serde_json::to_string(&sent).unwrap();
        
        // If keys HAVE been uploaded, generate a random challenge
        // and have the client make an additional PUT request
        // with the signature for that challenge.
        if !need_upload {
            let perms: &PermKeys = &perms.unwrap();
            let challenge: String = Alphanumeric.sample_string(&mut rand::thread_rng(), 32);
            let mut user_ik: [u8; 32] = [0; 32];
            hex::decode_to_slice(perms.ik.clone(), &mut user_ik).unwrap();
            // Stored as 'user.email': (user_ik, challenge, jwt)
            chal.write().await.insert(user.email.clone(), (user_ik, challenge.clone(), head.to_owned()));
            head = challenge;
        }

        let response = Response::builder()
            .header(
                if need_upload {
                    "authorization"
                } else {
                    "challenge"
                }, 
                head.clone()
            )
            .status(
                if need_upload {
                    StatusCode::IM_A_TEAPOT
                } else {
                    StatusCode::OK
                }
            )
            .body(Body::from(response_body))
            .unwrap();

        if need_upload {
            logger::log(LogLevel::Info, &format!("User {} is a teapot!", &info.email));
        } else {
            logger::log(LogLevel::Info, &format!("User {} has initiated a challenge", &info.email));
        }
        Ok(response)
    }

    pub async fn login_challenge(
        chal: Challenges, email: String, signature: String
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let (user_ik, challenge, jwt) = match chal.read().await.get(&email) {
            Some(res) => (res.0.clone(), res.1.clone(), res.2.clone()),
            None => return Ok(empty_response(StatusCode::BAD_REQUEST)),
        };
        let mut sig: [u8; 64] = [0; 64];
        match hex::decode_to_slice(signature.clone(), &mut sig) {
            Ok(_) => (),
            Err(_) => {
                logger::log(LogLevel::Info, &format!(
                    "User {} sent a malformed signature", &email
                ));
                chal.write().await.remove(&email).unwrap();
                return Ok(empty_response(StatusCode::BAD_REQUEST))
            },
        };

        let success = verify(user_ik, challenge.clone().into_bytes(), sig);
        // Signature verification failed
        if !success {
            logger::log(LogLevel::Info, &format!(
                "User {} lacks the correct key", &email
            ));
            chal.write().await.remove(&email).unwrap();
            return Ok(empty_response(StatusCode::UNAUTHORIZED))
        }
        logger::log(LogLevel::Info, &format!(
            "User {} has been completed the challenge", &email
        ));

        // Signature verification succeeded
        chal.write().await.remove(&email).unwrap();
        let response = Response::builder()
            .header("authorization",jwt)
            .status(StatusCode::OK)
            .body(Body::empty())
            .unwrap();

        Ok(response)
    }

    pub async fn register(info: RegisterForm) -> Result<impl warp::Reply, warp::Rejection> {
        let conn: &mut MysqlConnection = &mut establish_connection();
            
        let salt = SaltString::generate(&mut OsRng);
        let password_hash = Argon2::default().hash_password(info.password.as_bytes(), &salt)
            .unwrap()
            .to_string();

        let new_user = NewUser {
            username: info.username,
            password: password_hash,
            email: info.email,
            phone: info.phone,
        };
        
        match conn.transaction( |conn| {
            diesel::insert_into(users::table)
                .values(&new_user)
                .execute(conn)
        }) {
            Ok(_) => Ok(StatusCode::OK),
            // change to better deal with cases
            Err(e) => {
                logger::log(LogLevel::Info, &format!("Error: {}", e.to_string()));
                Ok(StatusCode::BAD_REQUEST)
            },
        }
    }

    pub async fn upload_keys(
        iss: Issuer, login_token: String, keys: KeysForm
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let payload: auth::Payload = verify_token!(iss, login_token);
        logger::log(LogLevel::Debug, &format!(
            "User {} is uploading keys", payload.sub
        ));

        // Check for the existence of already uploaded keys
        let conn = &mut establish_connection();
        let res: Vec<PermKeys> = perm_keys::table
            .filter(perm_keys::user_id.eq(payload.sub_id))
            .select(PermKeys::as_select())
            .load(conn)
            .unwrap();

        // Keys have already been uploaded
        if !res.is_empty() {
            return Ok(empty_response(StatusCode::CONFLICT));
        }

        // Create the necessary structs for insertion
        let permkeys = NewPermKeys {
            user_id: payload.sub_id,
            ik: keys.ik,
            spk: keys.spk,
            spk_sig: keys.spk_sig,
            pqspk: keys.pqspk,
            pqspk_sig: keys.pqspk_sig,
        };
        let mut onetimekeys: Vec<NewOnetimeKey> = Vec::with_capacity(keys.opk_map.len());
        for (hash, opk) in keys.opk_map {
            let new = NewOnetimeKey {
                user_id: payload.sub_id,
                opk: opk,
                hash_id: hash
            };
            onetimekeys.push(new);
        }
        let mut onetimepqkem: Vec<NewOnetimePqkem> = Vec::with_capacity(keys.pqopk_map.len());
        for(hash, (pqopk, sig)) in keys.pqopk_map {
            let new = NewOnetimePqkem {
                user_id: payload.sub_id,
                pqopk: pqopk,
                sig: sig,
                hash_id: hash
            };
            onetimepqkem.push(new);
        }

        match conn.transaction::<(), diesel::result::Error, _>( |conn| {
            diesel::insert_into(perm_keys::table)
                .values(&permkeys)
                .execute(conn)?;
            diesel::insert_into(onetime_keys::table)
                .values(&onetimekeys)
                .execute(conn)?;
            diesel::insert_into(onetime_pqkem::table)
                .values(&onetimepqkem)
                .execute(conn)?;
            Ok(())
        }) {
            Ok(_) => Ok(empty_response(StatusCode::OK)),
            // change to better deal with cases
            Err(e) => {
                println!("{}", e.to_string());
                Ok(empty_response(StatusCode::BAD_REQUEST))
            },
        }
    }

    pub async fn init_handshake(
        iss: Issuer, login_token: String, query: String
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let payload: auth::Payload = verify_token!(iss, login_token);
        let conn = &mut establish_connection();

        logger::log(LogLevel::Debug, &format!(
            "User is init handshake"
        ));

        // Get receiver object
        let recv: User = match users::table
            .filter(users::email.eq(query))
            .select(User::as_select())
            .get_result(conn) {
                Ok(b) => b,
                Err(_) => return Ok(empty_response(StatusCode::INTERNAL_SERVER_ERROR)),
            };

        // Check if handshake to this person already exists
        // or vice versa
        if handshakes::table
            .filter(
                (handshakes::sender_id.eq(payload.sub_id).and(handshakes::receiver_id.eq(recv.id)))
                .or
                (handshakes::sender_id.eq(recv.id).and(handshakes::receiver_id.eq(payload.sub_id)))
            )
            .first::<Handshake>(conn).is_ok() {
                return Ok(empty_response(StatusCode::CONFLICT))
            };

        // TODO!! check for if handshake already completed with this person

        // Get receiver's keys
        let recv_perms: PermKeys = match PermKeys::belonging_to(&recv)
            .select(PermKeys::as_select())
            .get_result(conn) {
                Ok(b) => b,
                Err(_) => return Ok(empty_response(StatusCode::INTERNAL_SERVER_ERROR)),
            };
        let recv_pqpk: Option<OnetimePqkem> = OnetimePqkem::belonging_to(&recv)
            .select(OnetimePqkem::as_select())
            .first(conn).ok();
        let recv_opk: Option<OnetimeKey> = OnetimeKey::belonging_to(&recv)
            .select(OnetimeKey::as_select())
            .first(conn).ok();

        // Check for existence of pqkem onetimes
        let (recv_pqpk, recv_pqpk_sig, recv_pqpk_hash) = match recv_pqpk {
            Some(pq) => {
                let _ = diesel::delete(onetime_pqkem::table.filter(onetime_pqkem::id.eq(pq.id))).execute(conn);
                (pq.pqopk, pq.sig, pq.hash_id)
            },
            None => (recv_perms.pqspk, recv_perms.pqspk_sig, None),
        };
        let (recv_opk, recv_opk_hash) = match recv_opk {
            Some(op) => {
                let _ = diesel::delete(onetime_keys::table.filter(onetime_keys::id.eq(op.id))).execute(conn);
                (Some(op.opk), op.hash_id)
            },
            None => (None, None),
        };
        
        // Get the sender's identity key for the initial handshake request
        let send_ik: String = match perm_keys::table
            .filter(perm_keys::user_id.eq(payload.sub_id))
            .select(perm_keys::ik)
            .get_result::<String>(conn) {
                Ok(s) => s,
                Err(_) => return Ok(empty_response(StatusCode::INTERNAL_SERVER_ERROR)),
            };
        
        // Create a new pending handshake (prior to the actual steps being done)
        let Ok(handshake_id) = conn.transaction::<u64, diesel::result::Error, _>(|conn| {
            diesel::insert_into(handshakes::table)
                .values(NewHandshake::new(payload.sub_id, recv.id, send_ik.clone(), recv_opk_hash, recv_pqpk_hash))
                .execute(conn)?;
            let handshake: Handshake = handshakes::table
                .filter(
                    handshakes::sender_id.eq(payload.sub_id)
                    .and(handshakes::receiver_id.eq(recv.id))
                )
                .first(conn)?;

            Ok(handshake.id)
        }) else {
            return Ok(empty_response(StatusCode::INTERNAL_SERVER_ERROR))
        };
        
        // Respond with the prekey bundle of handshake receiver, along with handshake_id for later PUT req
        let prekey_bundle = PrekeyBundle {
            handshake_id,
            ik: recv_perms.ik,
            spk: recv_perms.spk,
            spk_sig: recv_perms.spk_sig,
            pqpk: recv_pqpk,
            pqpk_sig: recv_pqpk_sig,
            opk: recv_opk,
        };

        let response_body = serde_json::to_string(&prekey_bundle).unwrap();
        let response = Response::builder()
            .status(StatusCode::CREATED)
            .body(Body::from(response_body))
            .unwrap();

        Ok(response)
    }

    pub async fn fill_handshake(
        iss: Issuer, login_token: String, details: FillHandshake
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let _ = verify_token!(iss, login_token);
        let conn = &mut establish_connection();

        // Call an update function with handshake_id and
        // fill in the appropriate fields
        match conn.transaction::<(), diesel::result::Error, _>( |conn| {
            diesel::update(handshakes::table)
                .filter(handshakes::id.eq(details.handshake_id))
                .set((
                    handshakes::ct.eq(details.ct),
                    handshakes::ek.eq(details.ek),
                    handshakes::pqkem_ct.eq(details.pqkem_ct)
                ))
                .execute(conn)?;
            Ok(())
        }) {
            Ok(_) => Ok(empty_response(StatusCode::OK)),
            // change to better deal with cases
            Err(_) => Ok(empty_response(StatusCode::BAD_REQUEST)),
        }
    }

    pub async fn complete_handshake(
        iss: Issuer, login_token: String, handshake_id: u64
    ) -> Result<impl warp::Reply, warp::Rejection> {
        // Verify token
        let payload: auth::Payload = verify_token!(iss, login_token);

        let conn = &mut establish_connection();
        // Find handshake
        let shake: Handshake = handshakes::table
            .filter(handshakes::id.eq(handshake_id))
            .select(Handshake::as_select())
            .get_result(conn)
            .unwrap();

        // New chat
        diesel::insert_into(chats::table)
            .values(NewChat {
                a: shake.sender_id,
                b: shake.receiver_id
            })
            .execute(conn)
            .unwrap();

        let shakes: Vec<Handshake> = handshakes::table
        .filter(
            (handshakes::sender_id.eq(shake.sender_id)
            .and(handshakes::receiver_id.eq(shake.receiver_id))).or(
                handshakes::sender_id.eq(shake.receiver_id)
                .and(handshakes::receiver_id.eq(shake.sender_id))
            )
        )
        .select(Handshake::as_select())
        .load(conn)
        .unwrap();
        // Delete handshakse
        for handshake in shakes {
            diesel::delete(handshakes::table.filter(handshakes::id.eq(handshake.id))).execute(conn).unwrap();
        }

        // Return handshake
        let response_body = serde_json::to_string(&shake).unwrap();
        let response = Response::builder()
            .status(StatusCode::OK)
            .body(Body::from(response_body))
            .unwrap();
        
        Ok(response)
    }

    pub async fn get_pending(
        iss: Issuer, login_token: String
    ) -> Result<impl warp::Reply, warp::Rejection> {
        // Verify token and extract payload
        let payload: auth::Payload = verify_token!(iss, login_token);

        let conn = &mut establish_connection();
        // Get all requests that you are on receiving end of
        let recq: Vec<Handshake> = handshakes::table
            .filter(handshakes::receiver_id.eq(payload.sub_id))
            .select(Handshake::as_select())
            .load(conn)
            .unwrap();

        // Find sender's name and map to handshake id and send back
        let mut to_ret: Vec<serde_json::Value> = vec!();
        for r in recq {
            let send_id = r.sender_id;
            let email: String = users::table
                .filter(users::id.eq(send_id))
                .select(users::email)
                .get_result(conn)
                .unwrap();
            to_ret.push(json!({
                "email": email,
                "handshake_id": r.id
            }))
        }

        let response_body = serde_json::to_string(&to_ret).unwrap();
        println!("{}", response_body);
        let response = Response::builder()
            .status(StatusCode::OK)
            .body(Body::from(response_body))
            .unwrap();
        
        Ok(response)
    }

    pub async fn chat(
        iss: Issuer, tok: String, ws: WebSocket, users: Users, chat_id: u64
    ) {
        // Sockets that talk to the user
        let (mut user_ws_tx, mut user_ws_rx) = ws.split();

        // Sockets that communicate between async threads
        let (tx, rx) = mpsc::unbounded_channel::<Message>();
        let mut rx = UnboundedReceiverStream::new(rx);
        
        // Verify token
        let payload: auth::Payload = match iss.verify(&tok) {
            Some(payload) => payload,
            None => {
                user_ws_tx.close();
                return
            },
        };

        logger::log(LogLevel::Info, &format!(
            "User {} has entered chat_id {}", payload.sub, chat_id
        ));

        let conn = &mut establish_connection();

        // Get user details of this chat
        let chat: Chat = chats::table
            .filter(chats::id.eq(chat_id))
            .select(Chat::as_select())
            .get_result(conn)
            .unwrap();
        let members: Vec<User> = users::table
            .filter(users::id.eq(chat.a).or(users::id.eq(chat.b)))
            .select(User::as_select())
            .load(conn)
            .unwrap();

        let other: u64 = if payload.sub_id == chat.a {chat.b} else {chat.a};

        // Query for all missed messages in this chat...
        let messages: Vec<crate::diesel_models::Message> = messages::table
            .filter(messages::chat_id.eq(chat_id).and(messages::user_id.eq(other)))
            .order(messages::created.asc())
            .select(crate::diesel_models::Message::as_select())
            .load(conn)
            .unwrap();

        // Make an array of all messages accordingly to MessageDetails
        let mut messages_toret: Vec<MessageDetails> = vec!();
        for message in messages.clone() {
            let created: u64 = message.created.timestamp().try_into().unwrap();
            let sender: String = 
                if message.user_id == members[0].id {
                    members[0].username.clone()
                } else {
                    members[1].username.clone()
                };
            let isMe: bool = message.user_id == payload.sub_id;
            let msg: Vec<u8> = message.msg;
            let to_add: MessageDetails = MessageDetails {created, sender, isMe, msg};
            messages_toret.push(to_add);
        }

        // Send this message array to the user
        user_ws_tx.send(Message::text(serde_json::to_string(&messages_toret).unwrap()))
            .unwrap_or_else(|e| {
                eprintln!("websocket send error: {}", e);
            })
            .await;
        
        // Delete these messages from the server
        diesel::delete(messages::table.filter(messages::chat_id.eq(chat_id).and(messages::user_id.eq(other)))).execute(conn).unwrap();

        // Officially add yourself to the users list
        tokio::task::spawn(async move {
            while let Some(message) = rx.next().await {
                user_ws_tx
                    .send(message)
                    .unwrap_or_else(|e| {
                        eprintln!("websocket send error: {}", e);
                    })
                    .await;
            }
        });
        users.write().await.insert(payload.sub_id, tx.clone());

        
        // Listen for user's messages and broadcast to the other user if they are 
        // connnected
        while let Some(result) = user_ws_rx.next().await {
            let msg: RecvMessage = match result {
                Ok(msg) => {
                    let json_text = match msg.to_str() {
                        Ok(m) => m.to_owned(),
                        Err(_) => break,
                    };
                    serde_json::from_str(&json_text).unwrap()
                },
                Err(_) => {
                    break;
                }
            };
            let msg = msg;
            let new_msg = NewMessage {
                user_id: payload.sub_id,
                chat_id,
                msg: msg.text.clone(),
            };
            let sender: String = 
                if payload.sub_id == members[0].id {
                    members[0].username.clone()
                } else {
                    members[1].username.clone()
                };
            let created = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
            // Check if other is currently connected in the users list.
            // If they are, directly send it to them.
            // Otherwise, store until the next time they retrieve it.
            match &users.read().await.get(&other) {
                Some(other_ws_tx) => {
                    logger::log(LogLevel::Debug, &format!(
                        "Sending directly to other user"
                    ));
                    let isMe = false;
                    let other_send = [MessageDetails {created, sender: sender.clone(), isMe, msg: msg.text.clone()}];
                    other_ws_tx.send(Message::text(serde_json::to_string(&other_send).unwrap()))
                        .unwrap_or_else(|e| {
                            eprintln!("websocket send error: {}", e);
                        });
                },
                None => {
                    logger::log(LogLevel::Debug, &format!(
                        "Other user not in chat room, saving to send later"
                    ));
                    diesel::insert_into(messages::table)
                    .values(new_msg)
                    .execute(conn).unwrap();
                },
            }
            let isMe = true;
            let to_sendback = [MessageDetails {created, sender: sender.clone(), isMe, msg: msg.text.clone()}];
            tx.send(Message::text(serde_json::to_string(&to_sendback).unwrap()))
                .unwrap_or_else(|e| {
                    eprintln!("websocket send error: {}", e);
                });

            
        }
        logger::log(LogLevel::Info, &format!(
            "User {} has left chat_id {}", payload.sub, chat_id
        ));

        users.write().await.remove(&payload.sub_id);
    }

    pub async fn get_inbox(
        iss: Issuer, login_token: String
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let payload: auth::Payload = verify_token!(iss, login_token);
        
        // Query which chats this user is in
        let conn = &mut establish_connection();

        let chats: Vec<Chat> = chats::table
            .filter(chats::a.eq(payload.sub_id).or(chats::b.eq(payload.sub_id)))
            .select(Chat::as_select())
            .load(conn)
            .unwrap();

        let mut to_ret: Vec<serde_json::Value> = vec!();

        for chat in chats {
            if chat.a == payload.sub_id {
                let other: User = users::table
                    .filter(users::id.eq(chat.b))
                    .select(User::as_select())
                    .get_result(conn)
                    .unwrap();
                to_ret.push(json!({
                    "username": other.username,
                    "chat_id": chat.id,
                    "email": other.email
                }));
            } else {
                let other: User = users::table
                    .filter(users::id.eq(chat.a))
                    .select(User::as_select())
                    .get_result(conn)
                    .unwrap();
                to_ret.push(json!({
                    "username": other.username,
                    "chat_id": chat.id,
                    "email": other.email
                }));
            }
        }
        let response_body = serde_json::to_string(&to_ret).unwrap();
        let response = Response::builder()
            .status(StatusCode::OK)
            .body(Body::from(response_body))
            .unwrap();

        Ok(response)
    }

    fn empty_response(status: StatusCode) -> Response<Body> {
        Response::builder()
            .status(status)
            .body(Body::empty())
            .unwrap()
    }

    fn establish_connection() -> MysqlConnection {
        dotenv().ok();

        let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
        MysqlConnection::establish(&database_url)
            .unwrap_or_else( |_|
                panic!("Error connecting to {}", database_url)
            )
    }
}
pub mod diesel_models;
pub mod http_models;
pub mod schema;

#[tokio::main]
async fn main() {
    let issuer = http_models::new_issuer();
    let conns = http_models::new_conn_list();
    
    let api = filters::server(issuer, conns);
    
    warp::serve(api).run(([127, 0, 0, 1], 8080)).await;
}

mod filters {
    use std::collections::HashMap;

    use serde::de::DeserializeOwned;
    use warp::Filter;

    use super::{
        handlers,
        http_models::*
    };

    pub fn server(
        iss: Issuer, conns: Connections
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        login(iss.clone(), conns.clone())
            .or(register())
            .or(upload_keys(iss.clone()))
            .or(init_handshake(iss.clone()))
            .or(fill_handshake(iss.clone()))
    }

    pub fn login(
        iss: Issuer, conns: Connections
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("login")
            .and(warp::post())
            .and(body::<LoginForm>())
            .and(with_auth(iss))
            .and(with_list(conns))
            .and_then(handlers::login)
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
            .and(warp::header("login_token"))
            .and(body::<KeysForm>())
            .and_then(handlers::upload_keys)
    }

    pub fn init_handshake(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("handshakes")
            .and(warp::post())
            .and(with_auth(iss))
            .and(warp::header("login_token"))
            .and(warp::query::<HashMap<String, String>>())
            .and_then(handlers::init_handshake)
    }

    pub fn fill_handshake(
        iss: Issuer
    ) -> impl Filter<Extract = (impl warp::Reply,), Error = warp::Rejection> + Clone {
        warp::path!("handshakes")
            .and(warp::put())
            .and(with_auth(iss))
            .and(warp::header("login_token"))
            .and(body::<FillHandshake>())
            .and_then(handlers::fill_handshake)
    }

    fn with_auth(iss: Issuer) -> impl Filter<Extract = (Issuer,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || iss.clone())
    }

    fn with_list(conns: Connections) -> impl Filter<Extract = (Connections,), Error = std::convert::Infallible> + Clone {
        warp::any().map(move || conns.clone())
    }

    fn body<T: std::marker::Send + DeserializeOwned>() -> impl Filter<Extract = (T,), Error = warp::Rejection> + Clone {
        warp::body::content_length_limit(1024 * 16).and(warp::body::json())
    }
}

mod handlers {
    use diesel::{mysql::MysqlConnection, prelude::*};
    use warp::{hyper::Body, http::{StatusCode, Response}};
    use argon2::{
        password_hash::{
            rand_core::OsRng,
            PasswordHasher, SaltString
        },
        Argon2, PasswordVerifier, PasswordHash
    };
    use dotenvy::dotenv;
    use std::{env, collections::HashMap};
    use serde_json::json;

    use super::{
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
        info: LoginForm, iss: Issuer, conns: Connections,
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
            return Ok(empty_response(StatusCode::NOT_FOUND));
        }

        // If found, check the paswroidasdsasd
        let user = res.first().unwrap();
        let parsed_hash = PasswordHash::new(&user.password).unwrap();
        if Argon2::default().verify_password(info.password.as_bytes(), &parsed_hash).is_err() {
            return Ok(empty_response(StatusCode::UNAUTHORIZED));
        }

        // TODO! Don't use token as the connections key :3
        // Issue a jwt auth token
        let token = iss.issue(user.id, &user.email);
        // Change to be websocket connection????
        let todo = 1;
        conns.lock().await.insert(token.clone(), todo);

        let response_body = serde_json::to_string(&json!({"login_token": token})).unwrap();
        
        let response = Response::builder()
            .status(StatusCode::OK)
            .body(Body::from(response_body))
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
            Err(_) => Ok(StatusCode::BAD_REQUEST),
        }
    }

    pub async fn upload_keys(
        iss: Issuer, login_token: String, keys: KeysForm
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let payload: auth::Payload = verify_token!(iss, login_token);
        
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
        let mut onetimekeys: Vec<NewOnetimeKey> = Vec::with_capacity(keys.opk_arr.len());
        for (i, (opk, sig)) in keys.opk_arr.iter().zip(keys.opk_sig_arr.iter()).enumerate() {
            let new = NewOnetimeKey {
                user_id: payload.sub_id,
                opk: opk.to_string(),
                sig: sig.to_string(),
                i: i.try_into().unwrap()
            };
            onetimekeys.push(new);
        }
        let mut onetimepqkem: Vec<NewOnetimePqkem> = Vec::with_capacity(keys.pqopk_arr.len());
        for (i, (pqopk, sig)) in keys.pqopk_arr.iter().zip(keys.pqopk_sig_arr.iter()).enumerate() {
            let new = NewOnetimePqkem {
                user_id: payload.sub_id,
                pqopk: pqopk.to_string(),
                sig: sig.to_string(),
                i: i.try_into().unwrap()
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
            Err(_) => Ok(empty_response(StatusCode::BAD_REQUEST)),
        }
    }

    pub async fn init_handshake(
        iss: Issuer, login_token: String, query: HashMap<String, String>
    ) -> Result<impl warp::Reply, warp::Rejection> {
        let payload: auth::Payload = verify_token!(iss, login_token);
        let conn = &mut establish_connection();

        // Get receiver object
        let recv_email = match query.get("email") {
            Some(q) => q,
            None => return Ok(empty_response(StatusCode::BAD_REQUEST)),
        };
        let recv: User = match users::table
            .filter(users::email.eq(recv_email))
            .select(User::as_select())
            .get_result(conn) {
                Ok(b) => b,
                Err(_) => return Ok(empty_response(StatusCode::INTERNAL_SERVER_ERROR)),
            };

        // Check if handshake to this person already exists
        if handshakes::table
            .filter(
                handshakes::sender_id.eq(payload.sub_id)
                .and(handshakes::receiver_id.eq(recv.id))
            )
            .first::<Handshake>(conn).is_ok() {
                return Ok(empty_response(StatusCode::CONFLICT))
            };

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
        let (recv_pqpk, recv_pqpk_sig) = match recv_pqpk {
            Some(pq) => {
                let _ = diesel::delete(onetime_pqkem::table.filter(onetime_pqkem::id.eq(pq.id))).execute(conn);
                (pq.pqopk, pq.sig)
            },
            None => (recv_perms.pqspk, recv_perms.pqspk_sig),
        };
        let (recv_opk, recv_opk_sig) = match recv_opk {
            Some(op) => {
                let _ = diesel::delete(onetime_keys::table.filter(onetime_keys::id.eq(op.id))).execute(conn);
                (Some(op.opk), Some(op.sig))
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
                .values(NewHandshake::new(payload.sub_id, recv.id, send_ik.clone()))
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
            opk_sig: recv_opk_sig,
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
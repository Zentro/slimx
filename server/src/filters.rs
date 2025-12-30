use serde::de::DeserializeOwned;
use warp::Filter;
use crate::{
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
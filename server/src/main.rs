pub mod diesel_models;
pub mod http_models;
pub mod schema;
mod xeddsa;
mod logger;
mod filters;
mod handlers;

#[tokio::main]
async fn main() {
    let issuer = http_models::new_issuer();
    let users = http_models::Users::default();
    let challenges = http_models::Challenges::default();

    let api = filters::server(issuer, challenges, users);
    
    warp::serve(api).run(([127, 0, 0, 1], 8080)).await;
}
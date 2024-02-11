-- Your SQL goes here
CREATE TABLE onetime_pqkem (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    pqopk TEXT NOT NULL,
    sig VARCHAR(255) NOT NULL,
    i INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
)
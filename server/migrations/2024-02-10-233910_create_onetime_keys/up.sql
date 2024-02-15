-- Your SQL goes here
CREATE TABLE onetime_keys (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    opk VARCHAR(255) NOT NULL,
    hash_id TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
)
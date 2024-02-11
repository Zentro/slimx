-- Your SQL goes here
CREATE TABLE perm_keys (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    ik VARCHAR(255) NOT NULL,
    spk VARCHAR(255) NOT NULL,
    spk_sig VARCHAR(255) NOT NULL,
    pqspk TEXT NOT NULL,
    pqspk_sig VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
)
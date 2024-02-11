-- Your SQL goes here
CREATE TABLE handshakes (
    id SERIAL PRIMARY KEY,
    sender_id BIGINT UNSIGNED NOT NULL,
    receiver_id BIGINT UNSIGNED NOT NULL,
    ik VARCHAR(255) NOT NULL,
    ek VARCHAR(255),
    pqkem_ct VARCHAR(255),
    ct VARCHAR(255),
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
)
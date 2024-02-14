// @generated automatically by Diesel CLI.

diesel::table! {
    chats (id) {
        id -> Unsigned<Bigint>,
        a -> Unsigned<Bigint>,
        b -> Unsigned<Bigint>,
    }
}

diesel::table! {
    handshakes (id) {
        id -> Unsigned<Bigint>,
        sender_id -> Unsigned<Bigint>,
        receiver_id -> Unsigned<Bigint>,
        #[max_length = 255]
        ik -> Varchar,
        #[max_length = 255]
        ek -> Nullable<Varchar>,
        pqkem_ct -> Nullable<Text>,
        ct -> Nullable<Text>,
        opk_ind -> Integer,
        pqpk_ind -> Integer,
    }
}

diesel::table! {
    messages (id) {
        id -> Unsigned<Bigint>,
        created -> Timestamp,
        updated -> Nullable<Timestamp>,
        user_id -> Unsigned<Bigint>,
        chat_id -> Unsigned<Bigint>,
        msg -> Blob,
    }
}

diesel::table! {
    onetime_keys (id) {
        id -> Unsigned<Bigint>,
        user_id -> Unsigned<Bigint>,
        #[max_length = 255]
        opk -> Varchar,
        i -> Integer,
    }
}

diesel::table! {
    onetime_pqkem (id) {
        id -> Unsigned<Bigint>,
        user_id -> Unsigned<Bigint>,
        pqopk -> Text,
        #[max_length = 255]
        sig -> Varchar,
        i -> Integer,
    }
}

diesel::table! {
    perm_keys (id) {
        id -> Unsigned<Bigint>,
        user_id -> Unsigned<Bigint>,
        #[max_length = 255]
        ik -> Varchar,
        #[max_length = 255]
        spk -> Varchar,
        #[max_length = 255]
        spk_sig -> Varchar,
        pqspk -> Text,
        #[max_length = 255]
        pqspk_sig -> Varchar,
    }
}

diesel::table! {
    users (id) {
        id -> Unsigned<Bigint>,
        #[max_length = 255]
        username -> Varchar,
        #[max_length = 255]
        password -> Varchar,
        #[max_length = 255]
        email -> Varchar,
        #[max_length = 255]
        phone -> Nullable<Varchar>,
    }
}

diesel::joinable!(messages -> chats (chat_id));
diesel::joinable!(messages -> users (user_id));
diesel::joinable!(onetime_keys -> users (user_id));
diesel::joinable!(onetime_pqkem -> users (user_id));
diesel::joinable!(perm_keys -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    chats,
    handshakes,
    messages,
    onetime_keys,
    onetime_pqkem,
    perm_keys,
    users,
);

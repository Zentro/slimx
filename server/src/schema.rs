// @generated automatically by Diesel CLI.

diesel::table! {
    conversations (id) {
        id -> Unsigned<Bigint>,
        created -> Timestamp,
        updated -> Nullable<Timestamp>,
        sender_id -> Unsigned<Bigint>,
        receiver_id -> Unsigned<Bigint>,
        #[max_length = 255]
        msg -> Varbinary,
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
        #[max_length = 255]
        pqkem_ct -> Nullable<Varchar>,
        #[max_length = 255]
        ct -> Nullable<Varchar>,
    }
}

diesel::table! {
    onetime_keys (id) {
        id -> Unsigned<Bigint>,
        user_id -> Unsigned<Bigint>,
        #[max_length = 255]
        opk -> Varchar,
        #[max_length = 255]
        sig -> Varchar,
        i -> Unsigned<Integer>,
    }
}

diesel::table! {
    onetime_pqkem (id) {
        id -> Unsigned<Bigint>,
        user_id -> Unsigned<Bigint>,
        #[max_length = 255]
        pqopk -> Varchar,
        #[max_length = 255]
        sig -> Varchar,
        i -> Unsigned<Integer>,
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
        #[max_length = 255]
        pqspk -> Varchar,
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

diesel::joinable!(onetime_keys -> users (user_id));
diesel::joinable!(onetime_pqkem -> users (user_id));
diesel::joinable!(perm_keys -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    conversations,
    handshakes,
    onetime_keys,
    onetime_pqkem,
    perm_keys,
    users,
);

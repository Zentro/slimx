use std::collections::HashMap;

use pqc_kyber::*;
use rand::{rngs::StdRng, SeedableRng};
use serde_derive::{Deserialize, Serialize};
use serde_json::{Value, json};
use x25519_dalek::{StaticSecret, PublicKey, x25519};

use aes_gcm::{aead::{Aead, Nonce, Payload}, AeadCore, Aes256Gcm, Key, KeyInit};
use hkdf::Hkdf;
use sha2::{Sha256, Sha512, Digest};

use super::xeddsa::{self, sign};
const ONETIME_CURVE: usize = 32;
const ONETIME_PQKEM: usize = 32;

const HKDF_INFO: &[u8; 53] = b"LATIFAProtocol_CURVE25519_SHA-512_CRYSTALS-KYBER-1024";
const HKDF_SALT: [u8; 64] = [0; 64];
const HKDF_F: [u8; 32] = [0xFF; 32];

fn kdf(km: Vec<u8>) -> [u8; 32] {
    let ikm = [&HKDF_F, km.as_slice()].concat();
    let hk = Hkdf::<Sha512>::new(Some(&HKDF_SALT), &ikm);
    let mut okm: [u8; 32] = [0; 32];
    hk.expand(HKDF_INFO, &mut okm)
        .expect("valid");
    okm
}

/**
 
Generates all the needed keys for first time set up.
It will then dump all of the keys in the client folder.
The force argument will forcefully override all currently present
keys in the client folder. Note that this will require a complete
reupload of all keys to the server.
*/
pub fn generate_keys() -> String {
    // PQPK
    let pqspk_pair = keypair(&mut StdRng::from_entropy()).unwrap();
    let mut pqopk_pairs: Vec<Keypair> = vec![];
    for _ in 0..ONETIME_PQKEM {
        let to_add = keypair(&mut StdRng::from_entropy()).unwrap();
        pqopk_pairs.push(to_add);
    }

    // Generate all the secret portions of the keys
    let ik_sec = StaticSecret::random_from_rng(StdRng::from_entropy());
    let spk_sec = StaticSecret::random_from_rng(StdRng::from_entropy());
    let pqspk_sec = pqspk_pair.secret;

    // Derive the public versions here
    let ik_pub = PublicKey::from(&ik_sec);
    let spk_pub = PublicKey::from(&spk_sec);
    let pqspk_pub = pqspk_pair.public;

    // Derive all the one-time keys
    let mut opk_map: HashMap<String, (String, String)> = HashMap::new();
    for _ in 0..ONETIME_CURVE {
        let opk_sec = StaticSecret::random_from_rng(StdRng::from_entropy());
        let opk_pub = PublicKey::from(&opk_sec);

        let s_opk_sec = hex::encode(opk_sec.as_bytes());
        let s_opk_pub = hex::encode(opk_pub.as_bytes());
        let mut hasher = Sha256::new();
        hasher.update(s_opk_pub.as_bytes());
        let s_opk_hash = hex::encode(hasher.finalize());

        opk_map.insert(s_opk_hash, (s_opk_sec, s_opk_pub));
    }

    let mut pqopk_map: HashMap<String, (String, String)> = HashMap::new();
    for i in 0..ONETIME_PQKEM {
        let s_pqopk_sec = hex::encode(pqopk_pairs[i].secret);
        let s_pqopk_pub = hex::encode(pqopk_pairs[i].public);

        let mut hasher = Sha256::new();
        hasher.update(s_pqopk_pub.as_bytes());
        let s_pqopk_hash = hex::encode(hasher.finalize());

        pqopk_map.insert(s_pqopk_hash, (s_pqopk_sec, s_pqopk_pub));
    }

    // Stringify secrets
    let s_ik_sec: String = hex::encode(ik_sec.as_bytes());
    let s_spk_sec: String = hex::encode(spk_sec.as_bytes());
    let s_pqspk_sec: String = hex::encode(pqspk_sec);

    // Stringify publics
    let s_ik_pub: String = hex::encode(ik_pub.as_bytes());
    let s_spk_pub: String = hex::encode(spk_pub.as_bytes());
    let s_pqspk_pub: String = hex::encode(pqspk_pub);

    let dump = json!({
        "ik_sec": s_ik_sec,
        "ik_pub": s_ik_pub,
        "spk_sec": s_spk_sec,
        "spk_pub": s_spk_pub,
        "pqspk_sec": s_pqspk_sec,
        "pqspk_pub": s_pqspk_pub,
        "opk_map": opk_map,
        "pqopk_map": pqopk_map
    }).to_string();
    dump
}

#[flutter_rust_bridge::frb(sync)]
pub fn sign_challenge(s_ik_sec: String, chal: String) -> String {
    let mut csprg = StdRng::from_entropy();
    let mut nonce: [u8; 64] = [0; 64];
    csprg.fill_bytes(&mut nonce);

    let mut ik_sec: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_ik_sec, &mut ik_sec).unwrap();

    let signature = xeddsa::sign(ik_sec, chal.into_bytes(), nonce.to_vec());

    hex::encode(signature)
}

/**
 * Called upon registration to the server. Will publish all stored public
 * keys.
 */
pub fn sign_and_publish(key_json: String) -> String{
    // Generate all the nonces needed for signatures
    let mut csprg = StdRng::from_entropy();
    let mut z: [[u8; 64]; ONETIME_PQKEM+2] = [[0; 64]; ONETIME_PQKEM+2];
    for i in 0..ONETIME_PQKEM+2 {
        csprg.fill_bytes(&mut z[i]);
    }

    let keys: Value = serde_json::from_str(&key_json).unwrap();

    // Get secret identity key for signing
    let s_ik_sec = keys["ik_sec"].as_str().unwrap();
    let mut ik_sec: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_ik_sec, &mut ik_sec).unwrap();

    // Get all the hex-form public keys from json
    let s_spk_pub = keys["spk_pub"].as_str().unwrap();
    let s_pqspk_pub = keys["pqspk_pub"].as_str().unwrap();
    let pqopk_map = &keys["pqopk_map"].as_object().unwrap();
    let opk_map = &keys["opk_map"].as_object().unwrap();

    // Convert to byte arrays for signing
    let mut spk_pub: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_spk_pub, &mut spk_pub).unwrap();
    let mut pqspk_pub: [u8; KYBER_PUBLICKEYBYTES] = [0; KYBER_PUBLICKEYBYTES];
    hex::decode_to_slice(s_pqspk_pub, &mut pqspk_pub).unwrap();
    
    // Sign the PUBLIC versions of the curve prekey,
    // last-resort pqkem prekey, and the one-time pqkem prekeys
    // USING the ik_sec
    let spk_pub_sig = xeddsa::sign(
        ik_sec.clone(),
        spk_pub.to_vec(),
        z[0].to_vec()
    );
    let pqspk_pub_sig = xeddsa::sign(
        ik_sec.clone(),
        pqspk_pub.to_vec(),
        z[1].to_vec()
    );

    // Sign the pqopks
    let mut pqopk_pub_map: HashMap<String, (String, String)> = HashMap::new();
    for (i, hash) in pqopk_map.keys().enumerate() {
        let pqopk_pair = pqopk_map[hash].as_array().unwrap();
        let s_pqopk_pub = pqopk_pair.get(1).unwrap().as_str().unwrap();

        let mut pqopk_pub: [u8; KYBER_PUBLICKEYBYTES] = [0; KYBER_PUBLICKEYBYTES];
        hex::decode_to_slice(s_pqopk_pub, &mut pqopk_pub).unwrap();
        let s_pqopk_sig = hex::encode(xeddsa::sign(
            ik_sec.clone(),
            pqopk_pub.to_vec(),
            z[i+2].to_vec()
        ));
        pqopk_pub_map.insert(hash.to_string(), (s_pqopk_pub.to_owned(), s_pqopk_sig));
    }

    // Get opks as a map of their pubs associated with a hash
    let mut opk_pub_map: HashMap<String, String> = HashMap::new();
    for hash in opk_map.keys() {
        let opk_pair = opk_map[hash].as_array().unwrap();
        let s_opk_pub = opk_pair.get(1).unwrap().as_str().unwrap();
        opk_pub_map.insert(hash.to_string(), s_opk_pub.to_owned());
    }

    // Get signature as hex encoded data
    let s_spk_pub_sig: String = hex::encode(spk_pub_sig);
    let s_pqspk_pub_sig: String = hex::encode(pqspk_pub_sig);

    // This should match the KeyForm in the Rust server
    let body = serde_json::to_string(&json!({
        "ik": keys["ik_pub"],
        "spk": keys["spk_pub"],
        "spk_sig": s_spk_pub_sig,
        "pqspk": keys["pqspk_pub"],
        "pqspk_sig": s_pqspk_pub_sig,
        "opk_map": opk_pub_map,
        "pqopk_map": pqopk_pub_map
    })).unwrap();

    body
}

// Flutter sends back a key bundle when requesting a
/// connection with someone
pub fn init_handshake(key_bundle: String, s_ik_pub: String, s_ik_sec: String) -> Option<(String, String)> {
    // Parse the key_bundle into json and extract necessary info
    let keys_b: Value = serde_json::from_str(&key_bundle).unwrap();
    let mut ik_b: [u8; 32] = [0; 32];
    let mut spk_b: [u8; 32] = [0; 32];
    let mut spk_b_sig: [u8; 64] = [0; 64];
    let mut pqpk_b: [u8; KYBER_PUBLICKEYBYTES] = [0; KYBER_PUBLICKEYBYTES];
    let mut pqpk_b_sig: [u8; 64] = [0; 64];
    let handshake_id = keys_b["handshake_id"].as_u64().unwrap();
    hex::decode_to_slice(keys_b["ik"].as_str().unwrap(), &mut ik_b).unwrap();
    hex::decode_to_slice(keys_b["spk"].as_str().unwrap(), &mut spk_b).unwrap();
    hex::decode_to_slice(keys_b["spk_sig"].as_str().unwrap(), &mut spk_b_sig).unwrap();
    hex::decode_to_slice(keys_b["pqpk"].as_str().unwrap(), &mut pqpk_b).unwrap();
    hex::decode_to_slice(keys_b["pqpk_sig"].as_str().unwrap(), &mut pqpk_b_sig).unwrap();

    // Check if opk is provided
    let mut opk_b: [u8; 32] = [0; 32];
    let opk_provided: bool = match keys_b["opk"].as_str() {
        Some(s) => {
            hex::decode_to_slice(s, &mut opk_b).unwrap();
            true
        },
        None => false,
    };
    
    // Verify signatures
    let b1 = xeddsa::verify(ik_b.clone(), spk_b.to_vec(), spk_b_sig);
    let b2 = xeddsa::verify(ik_b.clone(), pqpk_b.to_vec(), pqpk_b_sig);
    if !(b1 || b2) {
        return None
    }

    // Just ephemeral secret
    let ek_sec: StaticSecret = StaticSecret::random_from_rng(StdRng::from_entropy());
    let ek_pub: PublicKey = PublicKey::from(&ek_sec);

    // PQKEM stuff
    let (ct, ss) = encapsulate(&pqpk_b, &mut StdRng::from_entropy()).unwrap();

    // Read in the identity key
    let mut ik_pub: [u8; 32] = [0; 32]; 
    hex::decode_to_slice(s_ik_pub.as_str(), &mut ik_pub).unwrap();
    let mut ik_sec: [u8; 32] = [0; 32]; 
    hex::decode_to_slice(s_ik_sec.as_str(), &mut ik_sec).unwrap();

    // Compute triple diffie hellman
    // Needs to account for dh4 with OPK
    let dh1 = x25519(ik_sec.clone(), spk_b.clone());
    let dh2 = x25519(ek_sec.to_bytes(), ik_b.clone());
    let dh3 = x25519(ek_sec.to_bytes(), spk_b.clone());
    let mut km = [dh1, dh2, dh3].concat();
    if opk_provided {
        let dh4 = x25519(ek_sec.to_bytes(), opk_b.clone());
        km = [km, dh4.to_vec()].concat();
    }
    km = [km, ss.to_vec()].concat();
    let sk = kdf(km);

    // Compute associated data
    let ad = [ik_pub, ik_b].concat();

    // Let the first message of this protocol be the 
    let aes_key = Key::<Aes256Gcm>::from_slice(&sk);
    let cipher = Aes256Gcm::new(&aes_key); 
    let nonce = Aes256Gcm::generate_nonce(&mut StdRng::from_entropy());
    let payload = Payload {
        msg: &ik_pub,
        aad: &ad,
    };
    let handshake = [nonce.to_vec(), cipher.encrypt(&nonce, payload).unwrap()].concat();

    // Convert all needed info into hex strings
    let s_ek_pub = hex::encode(ek_pub.as_bytes());
    let s_ct = hex::encode(ct);
    let s_handshake = hex::encode(&handshake);

    // Construct the JSON
    let body = serde_json::to_string(&json!({
        "handshake_id": handshake_id,
        "ek": s_ek_pub,
        "pqkem_ct": s_ct,
        "ct": s_handshake,
    })).unwrap();

    let sk = hex::encode(sk);
    Some((body, sk))
}

#[derive(Serialize, Deserialize)]
struct Handshake {
    pub id: u64,
    pub sender_id: u64,
    pub receiver_id: u64,
    pub ik: String,
    pub ek: Option<String>,
    pub pqkem_ct: Option<String>,
    pub ct: Option<String>,
    pub pqpk_hash: Option<String>,
    pub opk_hash: Option<String>
}

pub fn complete_handshake(
    handshake: String,
    s_ik_pub: String,
    s_ik_sec: String,
    s_spk_sec: String,
    s_pqpk_sec: String,
    s_opk_sec: Option<String>
) -> String {
    let hs: Handshake = serde_json::from_str(&handshake).unwrap();
    let mut ik_other: [u8; 32] = [0; 32];
    let mut ek_other: [u8; 32] = [0; 32];
    hex::decode_to_slice(hs.ik, &mut ik_other).unwrap();
    hex::decode_to_slice(hs.ek.unwrap(), &mut ek_other).unwrap();

    let mut ik_pub: [u8; 32] = [0; 32];
    let mut ik_sec: [u8; 32] = [0; 32];
    let mut spk_sec: [u8; 32] = [0; 32];
    let mut pqpk_sec: [u8; KYBER_SECRETKEYBYTES] = [0; KYBER_SECRETKEYBYTES];
    let mut opk_sec: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_ik_pub, &mut ik_pub).unwrap();
    hex::decode_to_slice(s_ik_sec, &mut ik_sec).unwrap();
    hex::decode_to_slice(s_spk_sec, &mut spk_sec).unwrap();
    hex::decode_to_slice(s_pqpk_sec, &mut pqpk_sec).unwrap();
    if s_opk_sec.is_some() {
        hex::decode_to_slice(s_opk_sec.as_ref().unwrap(), &mut opk_sec).unwrap();
    }

    // Get key from the KEM
    let mut pqkem_ct: [u8; KYBER_CIPHERTEXTBYTES] = [0; KYBER_CIPHERTEXTBYTES];
    hex::decode_to_slice(hs.pqkem_ct.unwrap(), &mut pqkem_ct).unwrap();
    let ss = decapsulate(&pqkem_ct, &pqpk_sec).unwrap();

    // Compute the 4 diffie hellman vals
    let dh1 = x25519(spk_sec.clone(), ik_other.clone());
    let dh2 = x25519(ik_sec.clone(), ek_other.clone());
    let dh3 = x25519(spk_sec.clone(), ek_other.clone());
    let mut km = [dh1, dh2, dh3].concat();
    if s_opk_sec.is_some() {
        let dh4 = x25519(opk_sec.clone(), ek_other.clone());
        km = [km, dh4.to_vec()].concat();
    }

    // Derive the secret shared key
    km = [km, ss.to_vec()].concat();
    let sk = kdf(km);

    // Separate the first handshake message accordingly
    let initial_msg: Vec<u8> = hex::decode(hs.ct.unwrap()).unwrap();
    let nonce = Nonce::<Aes256Gcm>::from_slice(&initial_msg[0..12]);
    let ct = &initial_msg[12..];

    let aes_key = Key::<Aes256Gcm>::from_slice(&sk);
    let cipher = Aes256Gcm::new(&aes_key);

    // Compute associated data and create payload for decryption
    let ad = [ik_other, ik_pub].concat();
    let payload = Payload {
        msg: &ct,
        aad: &ad,
    };

    let payload =  match cipher.decrypt(nonce, payload) {
        Ok(r) => r,
        Err(_) => {
            println!("Uh oh!");
            return "".to_string();
        },
    };

    hex::encode(sk)
}

#[flutter_rust_bridge::frb(sync)]
pub fn decrypt_message(s_sk: String, combined: Vec<u8>) -> String {
    let mut sk: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_sk, &mut sk).unwrap();

    let nonce = Nonce::<Aes256Gcm>::from_slice(&combined[0..12]);
    let ct = &combined[12..];

    let aes_key = Key::<Aes256Gcm>::from_slice(&sk);
    let cipher = Aes256Gcm::new(&aes_key);

    match cipher.decrypt(nonce, ct) {
        Ok(res) => {
            String::from_utf8(res).unwrap()
        },
        Err(_) => "Unable to decrypt".to_string(),
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_message(s_sk: String, msg: String) -> Vec<u8> {
    let mut sk: [u8; 32] = [0; 32];
    hex::decode_to_slice(s_sk, &mut sk).unwrap();

    let aes_key = Key::<Aes256Gcm>::from_slice(&sk);
    let cipher = Aes256Gcm::new(&aes_key); 
    let nonce = Aes256Gcm::generate_nonce(&mut StdRng::from_entropy());
    let combined = [nonce.to_vec(), cipher.encrypt(&nonce, msg.as_bytes()).unwrap()].concat();

    combined
}

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

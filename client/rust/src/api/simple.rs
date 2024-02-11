use pqc_kyber::*;
use rand::{rngs::StdRng, SeedableRng};
use serde_json::{Value, json};
use x25519_dalek::{StaticSecret, PublicKey, x25519};

use aes_gcm::{Aes256Gcm, Key, KeyInit, AeadCore, aead::{Payload, Aead}};
use hkdf::Hkdf;
use sha2::Sha512;

use super::xeddsa;

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
#[flutter_rust_bridge::frb(sync)]
pub fn generate_keys() -> String {
    // PQOPK
    let mut pqopk_pairs: Vec<Keypair> = vec![];
    for _ in 0..ONETIME_PQKEM {
        let to_add = keypair(&mut StdRng::from_entropy()).unwrap();
        pqopk_pairs.push(to_add);
    }

    // Generate all the secret portions of the keys
    let ik_sec = StaticSecret::random_from_rng(StdRng::from_entropy());
    let spk_sec = StaticSecret::random_from_rng(StdRng::from_entropy());
    let pqspk_pair = keypair(&mut StdRng::from_entropy()).unwrap();
    let pqspk_sec = pqspk_pair.secret;
    let mut opk_secs: Vec<StaticSecret> = vec![];
    for _ in 0..ONETIME_CURVE {
        let to_add = StaticSecret::random_from_rng(StdRng::from_entropy());
        opk_secs.push(to_add);
    }
    let mut pqopk_secs: Vec<pqc_kyber::SecretKey> = vec![];
    for i in 0..ONETIME_PQKEM {
        let to_add = pqopk_pairs[i].secret;
        pqopk_secs.push(to_add);
    }

    // Derive the public versions here
    let ik_pub = PublicKey::from(&ik_sec);
    let spk_pub = PublicKey::from(&spk_sec);
    let pqspk_pub = pqspk_pair.public;
    let mut opk_pubs: Vec<PublicKey> = vec![];
    for i in 0..ONETIME_CURVE {
        let to_add = PublicKey::from(&opk_secs[i]);
        opk_pubs.push(to_add);
    }
    let mut pqopk_pubs: Vec<pqc_kyber::PublicKey> = vec![];
    for i in 0..ONETIME_PQKEM {
        let to_add = pqopk_pairs[i].public;
        pqopk_pubs.push(to_add);
    }

    // JSON'ify secrets
    let s_ik_sec: String = hex::encode(ik_sec.as_bytes());
    let s_spk_sec: String = hex::encode(spk_sec.as_bytes());
    let s_pqspk_sec: String = hex::encode(pqspk_sec);
    let mut s_opk_secs: Vec<String> = vec![];
    for i in 0..ONETIME_CURVE {
        let to_add = hex::encode(opk_secs[i].as_bytes());
        s_opk_secs.push(to_add);
    }
    let mut s_pqopk_secs: Vec<String> = vec![];
    for i in 0..ONETIME_PQKEM {
        let to_add = hex::encode(pqopk_secs[i]);
        s_pqopk_secs.push(to_add);
    }

    // JSON'ify publics
    let s_ik_pub: String = hex::encode(ik_pub.as_bytes());
    let s_spk_pub: String = hex::encode(spk_pub.as_bytes());
    let s_pqspk_pub: String = hex::encode(pqspk_pub);
    let mut s_opk_pubs: Vec<String> = vec![];
    for i in 0..ONETIME_CURVE {
        let to_add = hex::encode(opk_pubs[i].as_bytes());
        s_opk_pubs.push(to_add);
    }
    let mut s_pqopk_pubs: Vec<String> = vec![];
    for i in 0..ONETIME_PQKEM {
        let to_add = hex::encode(pqopk_pubs[i]);
        s_pqopk_pubs.push(to_add);
    }

    let dump = json!({
        "ik_sec": s_ik_sec,
        "ik_pub": s_ik_pub,
        "spk_sec": s_spk_sec,
        "spk_pub": s_spk_pub,
        "pqspk_sec": s_pqspk_sec,
        "pqspk_pub": s_pqspk_pub,
        "opk_sec_arr": s_opk_secs,
        "opk_pub_arr": s_opk_pubs,
        "pqopk_sec_arr": s_pqopk_secs,
        "pqopk_pub_arr": s_pqopk_pubs,
    }).to_string();
    dump
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
    let s_pqopk_pub_arr = &keys["pqopk_pub_arr"];

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
    let mut pqopk_pub_sig_arr: Vec<[u8; 64]> = vec![];
    for i in 0..ONETIME_PQKEM {
        let s_pqopk_pub = s_pqopk_pub_arr[i].as_str().unwrap();
        let mut pqopk_pub: [u8; KYBER_PUBLICKEYBYTES] = [0; KYBER_PUBLICKEYBYTES];
        hex::decode_to_slice(s_pqopk_pub, &mut pqopk_pub).unwrap();
        let to_add = xeddsa::sign(
            ik_sec.clone(),
            pqopk_pub.to_vec(),
            z[i+2].to_vec()
        );
        pqopk_pub_sig_arr.push(to_add);
    }

    // Get signature as hex encoded data
    let s_spk_pub_sig: String = hex::encode(spk_pub_sig);
    let s_pqspk_pub_sig: String = hex::encode(pqspk_pub_sig);
    let mut s_pqopk_pub_sig_arr: Vec<String> = vec![];
    for i in 0..ONETIME_PQKEM {
        let to_add = hex::encode(pqopk_pub_sig_arr[i]);
        s_pqopk_pub_sig_arr.push(to_add);
    }

    // Send the registration POST request
    let body = serde_json::to_string(&json!({
        "ik": keys["ik_pub"],
        "spk": keys["spk_pub"],
        "spk_sig": s_spk_pub_sig,
        "pqspk": keys["pqspk_pub"],
        "pqspk_sig": s_pqspk_pub_sig,
        "opk_arr": keys["opk_pub_arr"],
        "pqopk_arr": keys["pqopk_pub_arr"],
        "pqopk_sig_arr": s_pqopk_pub_sig_arr,
    })).unwrap();

    body
}

// Flutter sends back a key bundle when requesting a
/// connection with someone
pub fn init_handshake(key_bundle: String, s_ik_pub: String, s_ik_sec: String) -> Option<String> {
    // Parse the key_bundle into json and extract necessary info
    let keys_b: Value = serde_json::from_str(&key_bundle).unwrap();
    let mut ik_b: [u8; 32] = [0; 32];
    let mut spk_b: [u8; 32] = [0; 32];
    let mut spk_b_sig: [u8; 64] = [0; 64];
    let mut pqpk_b: [u8; KYBER_PUBLICKEYBYTES] = [0; KYBER_PUBLICKEYBYTES];
    let mut pqpk_b_sig: [u8; 64] = [0; 64];
    let mut opk_b: [u8; 32] = [0; 32];
    hex::decode_to_slice(keys_b["ik"].as_str().unwrap(), &mut ik_b).unwrap();
    hex::decode_to_slice(keys_b["spk"].as_str().unwrap(), &mut spk_b).unwrap();
    hex::decode_to_slice(keys_b["spk_sig"].as_str().unwrap(), &mut spk_b_sig).unwrap();
    hex::decode_to_slice(keys_b["pqpk"].as_str().unwrap(), &mut pqpk_b).unwrap();
    hex::decode_to_slice(keys_b["pqpk_sig"].as_str().unwrap(), &mut pqpk_b_sig).unwrap();
    hex::decode_to_slice(keys_b["opk"].as_str().unwrap(), &mut opk_b).unwrap();

    // Verify signatures
    let b1 = xeddsa::verify(ik_b.clone(), spk_b.to_vec(), spk_b_sig);
    let b2 = xeddsa::verify(ik_b.clone(), pqpk_b.to_vec(), pqpk_b_sig);
    if b1 || b2 {
        // Abort
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
    let dh4 = x25519(ek_sec.to_bytes(), opk_b.clone());

    let km = [dh1, dh2, dh3, dh4, ss].concat();
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
    let handshake = cipher.encrypt(&nonce, payload).unwrap();

    // Convert all needed info into hex strings
    let s_ek_pub = hex::encode(ek_pub.as_bytes());
    let s_ct = hex::encode(ct);
    let s_handshake = hex::encode(&handshake);
    let s_pqpk_b = hex::encode(pqpk_b);
    let s_opk_b = hex::encode(opk_b);

    // Construct the JSON
    let body = serde_json::to_string(&json!({
        "ek": s_ek_pub,
        "pqkem_ct": s_ct,
        "ct": s_handshake,
    })).unwrap();

    Some(body)
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

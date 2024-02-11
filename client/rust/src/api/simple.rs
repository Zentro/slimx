use std::{fs::{self, File}, io::Write};

use pqc_kyber::*;
use rand::{rngs::StdRng, SeedableRng};
use serde_json::{Value, json};
use x25519_dalek::{StaticSecret, PublicKey};

use super::xeddsa;

const ONETIME_CURVE: usize = 32;
const ONETIME_PQKEM: usize = 32;

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

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

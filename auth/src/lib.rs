use rand::{rngs::OsRng, RngCore};
use sha2::Sha256;
use hmac::{Hmac, Mac};
use serde_derive::{Serialize, Deserialize};
use std::time::{Duration, SystemTime};
use std::str;

use base64::{Engine as _, engine::{self, general_purpose}, alphabet};
const CUSTOM_ENGINE: engine::GeneralPurpose =
    engine::GeneralPurpose::new(&alphabet::URL_SAFE, general_purpose::NO_PAD);

#[derive(Serialize, Deserialize)]
struct Header {
    alg: String,
    typ: String,
}

impl Header {
    pub fn default() -> Self {
        Header {
            alg: "HS256".to_owned(),
            typ: "JWT".to_owned()
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct Payload {
    iss: String,
    pub sub_id: u64,
    pub sub: String,
    exp: u64,
}

impl Payload {
    pub fn new(iss: String, sub_id: u64, sub: String, exp: u64) -> Self {
        Payload {iss, sub_id, sub, exp}
    }
}
pub struct Issuer {
    iss: String,
    hmac_key: [u8; 32],
}

impl Issuer {
    pub fn new(hmac_key: [u8; 32]) -> Self {
        // Issuer created once during lifetime of server starting up
        // If server goes down, all tokens become invalid on next startup
        let mut iss: [u8; 16] = [0; 16];
        OsRng.fill_bytes(&mut iss);
        let iss: String = hex::encode(iss);

        Issuer { 
            iss: iss, 
            hmac_key: hmac_key 
        }
    }

    /// Issues a jwt based on the subject's id and subject's email
    /// Returns a formatted string (header.payload.mac)
    pub fn issue(&self, sub_id: u64, sub: &str) -> String {
        // Access token expires in 15 minutes
        let exp = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH).unwrap()
            .checked_add(Duration::from_secs(900)).unwrap()
            .as_secs();

        let header = serde_json::to_string(&Header::default()).unwrap();
        let payload = serde_json::to_string(&Payload::new(self.iss.clone(), sub_id, sub.to_owned(), exp)).unwrap();

        let header_b64 = CUSTOM_ENGINE.encode(header);
        let payload_b64 = CUSTOM_ENGINE.encode(payload);

        let hp = header_b64 + "." + &payload_b64;

        let mut mac = Hmac::<Sha256>::new_from_slice(&self.hmac_key).expect("");
        mac.update(hp.as_bytes());
        let signature_b64 = CUSTOM_ENGINE.encode(mac.finalize().into_bytes());
        
        hp + "." + &signature_b64
    }

    /// Takes a JWT (header + . + body + . + hmac) and 
    /// verifies that mac matches with header and body. 
    /// 
    /// Returns the Payload if everything matches and 
    /// is valid.
    pub fn verify(&self, jwt: &str) -> Option<Payload>{
        let mut parsed: [&str; 3] = [""; 3];
        let parts = jwt.split('.');
        for (i, part) in parts.enumerate() {
            if i > 2 {
                return None;
            }
            parsed[i] = part;
        }

        if !self.verify_signature(&parsed) {
            return None
        }

        self.verify_hp(&parsed)
    }

    // Verifies the validity of header and payload
    fn verify_hp(&self, parsed: &[&str]) -> Option<Payload> {
        let header_b64 = parsed[0];
        let payload_b64 = parsed[1];

        let header: Header = serde_json::from_str(
            str::from_utf8(&CUSTOM_ENGINE.decode(header_b64).unwrap()).unwrap()
        ).unwrap();
        let payload: Payload = serde_json::from_str(
            str::from_utf8(&CUSTOM_ENGINE.decode(payload_b64).unwrap()).unwrap()
        ).unwrap();

        // Verify header
        if header.alg != "HS256" || header.typ != "JWT" {
            return None;
        };

        // Verify payload
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH).unwrap()
            .as_secs();
        if payload.iss != self.iss || now >= payload.exp {
            return None;
        }
        
        Some(payload)
    }

    // Verifies that nothing has been tampered with
    fn verify_signature(&self, parsed: &[&str]) -> bool {
        let signature = match CUSTOM_ENGINE.decode(parsed[2]) {
            Ok(s) => s,
            Err(_) => return false,
        };

        let header_b64 = parsed[0];
        let payload_b64 = parsed[1];

        let hp = header_b64.to_string() + "." + &payload_b64;

        let mut mac = Hmac::<Sha256>::new_from_slice(&self.hmac_key).expect("");
        mac.update(hp.as_bytes());

        match mac.verify_slice(&signature) {
            Ok(_) => true,
            Err(_) => false,
        }
    }

}

#[cfg(test)]
mod tests {
    use crate::Issuer;

    use rand::{rngs::OsRng, RngCore};

    #[test]
    fn basic() {
        let mut hmac_key: [u8; 32] = [0; 32];
        OsRng.fill_bytes(&mut hmac_key);

        let issuer: Issuer = Issuer::new(hmac_key);
        let jwt = issuer.issue(64, &"asd");
        assert!(issuer.verify(&jwt).is_some());
    }
}
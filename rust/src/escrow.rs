//! NUT-11 P2PK 2-of-3 escrow primitives.
//!
//! These are the cryptographic building blocks the Dart wallet orchestrates to
//! lock, release, cancel and refund a Cashu escrow token. They are exposed to
//! Dart through `flutter_rust_bridge` and delegate to the Cashu Development Kit
//! (`cashu` crate, MIT OR Apache-2.0):
//!
//! - [`build_escrow_spending_conditions`] — construct the NUT-10/NUT-11
//!   `SpendingConditions` for a 2-of-3 P2PK lock with a seller-recovery
//!   locktime (`num_sigs = 2` over {buyer, seller, escrow}; `refund_keys` lets
//!   the seller alone spend after `locktime`).
//! - [`sign_proof`] — add one party's Schnorr signature to a proof's P2PK
//!   witness (`cashu::Proof::sign_p2pk`), the unit step behind a release or a
//!   cooperative cancel (two parties co-sign to spend).
//! - [`verify_proof_p2pk`] — check a proof's witness against its spending
//!   conditions (`cashu::Proof::verify_p2pk`), the trust boundary before the
//!   wallet treats a token as unlocked.
//!
//! Only plain data (hex strings, JSON) crosses the FFI boundary; no secret key
//! material is exposed in the generated Dart API and no code is copied from the
//! AGPL-licensed upstream `MostroP2P/app` client.

use anyhow::{bail, Context, Result};
use cashu::{Conditions, Proof, PublicKey, SecretKey, SigFlag, SpendingConditions};

/// Construct the JSON-serialized NUT-11 P2PK 2-of-3 escrow spending conditions.
///
/// The three keys are 33-byte compressed secp256k1 public keys (66 hex chars).
/// `locktime_days` is the seller-recovery floor: the token cannot be spent by
/// the seller alone until `unix_time() + locktime_days * 86_400`.
///
/// Returns the `SpendingConditions` serialized as JSON so the Dart side can
/// store it and later attach it to freshly minted/selected proofs.
pub fn build_escrow_spending_conditions(
    buyer_pubkey_hex: String,
    seller_pubkey_hex: String,
    escrow_pubkey_hex: String,
    locktime_days: u32,
) -> Result<String> {
    let buyer = parse_pubkey(&buyer_pubkey_hex, "buyer")?;
    let seller = parse_pubkey(&seller_pubkey_hex, "seller")?;
    let escrow = parse_pubkey(&escrow_pubkey_hex, "escrow")?;

    let locktime = cashu::util::unix_time() + u64::from(locktime_days) * 86_400;

    // Primary key (`data`) is the buyer; the other two parties are the co-sign
    // set. Any 2 of 3 may spend, and after `locktime` the seller alone may
    // spend through the refund path.
    let conditions = Conditions::new(
        Some(locktime),
        Some(vec![seller.clone(), escrow.clone()]),
        Some(vec![seller.clone()]),
        Some(2),
        Some(SigFlag::SigInputs),
        Some(1),
    )
    .context("invalid 2-of-3 escrow conditions")?;

    let spending = SpendingConditions::new_p2pk(buyer, Some(conditions));
    serde_json::to_string(&spending).context("serialize spending conditions")
}

/// Sign a serialized Cashu [`Proof`] with `secret_key_hex`, appending the
/// party's signature to the proof's P2PK witness.
///
/// Returns the updated proof as JSON. Callers co-sign (2-of-3) with two of the
/// three keys to release or cooperatively cancel an escrow token.
pub fn sign_proof(proof_json: String, secret_key_hex: String) -> Result<String> {
    let mut proof: Proof = serde_json::from_str(&proof_json).context("parse proof json")?;
    let secret_key = SecretKey::from_hex(&secret_key_hex).context("parse secret key hex")?;

    proof.sign_p2pk(secret_key).context("sign proof p2pk")?;
    serde_json::to_string(&proof).context("serialize signed proof")
}

/// Verify a serialized Cashu [`Proof`] against its NUT-11 P2PK spending
/// conditions.
///
/// Returns `true` when the witness satisfies the lock's primary (2-of-3) or
/// refund (post-locktime seller) path. The wallet must treat `false` as "do not
/// trust this token".
pub fn verify_proof_p2pk(proof_json: String) -> Result<bool> {
    let proof: Proof = serde_json::from_str(&proof_json).context("parse proof json")?;
    // Any verification failure means "do not trust this token" (bad kind,
    // invalid signature, or spend conditions not met), so collapse to `false`.
    Ok(proof.verify_p2pk().is_ok())
}

/// Parse a 33-byte compressed secp256k1 public key from hex with a useful
/// error label for the caller.
fn parse_pubkey(hex: &str, role: &str) -> Result<PublicKey> {
    let trimmed = hex.trim();
    if trimmed.len() != 66 {
        bail!(
            "{role} public key must be 33 bytes (66 hex chars), got {} chars",
            trimmed.len()
        );
    }
    PublicKey::from_hex(trimmed).with_context(|| format!("parse {role} public key"))
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Valid 33-byte compressed secp256k1 public keys (fixed test vectors).
    const BUYER: &str = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    const SELLER: &str = "02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5";
    const ESCROW: &str = "02f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9";

    #[test]
    fn build_conditions_is_valid_2_of_3() {
        let json = build_escrow_spending_conditions(
            BUYER.to_string(),
            SELLER.to_string(),
            ESCROW.to_string(),
            7,
        )
        .expect("conditions should build");

        let parsed: SpendingConditions =
            serde_json::from_str(&json).expect("conditions should deserialize");
        assert_eq!(parsed.kind(), cashu::Kind::P2PK);
        assert_eq!(parsed.num_sigs(), Some(2));
        assert_eq!(parsed.refund_keys().map(|k| k.len()), Some(1));
        assert!(parsed.locktime().is_some());
    }

    #[test]
    fn build_conditions_rejects_short_key() {
        assert!(build_escrow_spending_conditions(
            "deadbeef".to_string(),
            SELLER.to_string(),
            ESCROW.to_string(),
            7,
        )
        .is_err());
    }
}

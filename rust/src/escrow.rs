//! NUT-11 P2PK 2-of-3 escrow primitives.
//!
//! These types mirror the Dart `CashuWalletApi` contract in
//! `lib/features/cashu/wallet/cashu_wallet_api.dart`. The operations are
//! stubbed at the type level for now; at FFI-integration time each one
//! delegates to the CDK:
//!
//! - lock: mint/select proofs, then `cashu::nuts::nut11::SpendingConditions`
//!   with a 2-of-3 `P2PKConditions` (buyer, seller, daemon escrow key) plus the
//!   seller-recovery `locktime`;
//! - release/cancel: `sign_p2pk` with the required two parties, then spend;
//! - refund: spend after `locktime` (single-party path), after a NUT-07 token
//!   state check against the mint.
//!
//! No signature or key material is exposed to the Dart side; only the plain
//! data below crosses the FFI boundary.

/// The three keys a NUT-11 P2PK 2-of-3 escrow token is locked to (hex pubkeys).
#[derive(Debug, Clone)]
pub struct EscrowKeys {
    /// The maker's (buyer's) spending key.
    pub buyer_public_key: String,
    /// The taker's (seller's) spending key.
    pub seller_public_key: String,
    /// The daemon's escrow / arbiter key.
    pub escrow_public_key: String,
}

/// A token locked into a 2-of-3 P2PK escrow. `proofs` holds serialized Cashu
/// `Proof` JSON (opaque to the Dart side); the wallet owns the spending
/// condition and any signing secret state in memory.
#[derive(Debug, Clone)]
pub struct EscrowLock {
    /// The mint holding the token.
    pub mint_url: String,
    /// Mint keyset id the proofs belong to.
    pub keyset_id: String,
    /// Total locked amount in sats.
    pub amount_sats: u64,
    /// Seller-recovery locktime floor in days.
    pub locktime_days: u32,
    /// Serialized proofs.
    pub proofs: Vec<String>,
}

/// Result of spending a locked token (release), carrying the settlement proof
/// id for traceability.
#[derive(Debug, Clone)]
pub struct Settlement {
    /// The proof id returned by the mint after the spend.
    pub proof_id: String,
}

import 'package:flutter/foundation.dart';

/// Client-side Cashu wallet contract (NUT-11 P2PK 2-of-3 escrow).
///
/// This is the Dart half of the future `flutter_rust_bridge` boundary. It is a
/// pure-Dart abstraction with **no** FFI dependency yet, so it stays fully
/// unit-testable with a fake. A later `CashuWalletFfi` implementation will
/// delegate each operation to the `satonero_cashu` Rust crate, which in turn
/// uses the Cashu Development Kit (`cashu` crate, MIT OR Apache-2.0).
///
/// All cryptography and mint communication run off the main isolate (Rust);
/// this interface only carries plain data across the boundary. Nothing here is
/// copied from the AGPL-licensed upstream `MostroP2P/app` client.

/// Error raised by any wallet operation. The `code` is stable across releases
/// so callers can branch on it; `message` is human-readable.
@immutable
class CashuWalletException implements Exception {
  const CashuWalletException(this.code, this.message);

  /// Stable machine-readable code (e.g. `mint_unreachable`, `spend_refused`).
  final String code;

  /// Human-readable detail, safe to surface in a snackbar after localization
  /// at the call site.
  final String message;

  @override
  String toString() => 'CashuWalletException($code): $message';
}

/// The three keys a NUT-11 P2PK 2-of-3 escrow token is locked to.
@immutable
class P2pkEscrowKeys {
  const P2pkEscrowKeys({
    required this.buyerPublicKey,
    required this.sellerPublicKey,
    required this.escrowPublicKey,
  });

  /// The maker's (buyer's) spending key (hex pubkey).
  final String buyerPublicKey;

  /// The taker's (seller's) spending key (hex pubkey).
  final String sellerPublicKey;

  /// The daemon's escrow / arbiter key (hex pubkey).
  final String escrowPublicKey;
}

/// A token the wallet has locked into a 2-of-3 P2PK escrow.
///
/// [proofs] are the Cashu proofs now guarded by the spending condition;
/// [locktimeDays] is the seller-recovery floor copied from the node's
/// `cashu_escrow_locktime_days`. Callers never see raw cryptography — the Rust
/// side owns `SpendingConditions` and the signing nonce/secret state.
@immutable
class CashuEscrowLock {
  const CashuEscrowLock({
    required this.mintUrl,
    required this.keysetId,
    required this.amountSats,
    required this.locktimeDays,
    required this.proofs,
  });

  /// The mint holding the token.
  final String mintUrl;

  /// Mint keyset id the proofs belong to.
  final String keysetId;

  /// Total locked amount in sats.
  final int amountSats;

  /// Seller-recovery locktime floor in days.
  final int locktimeDays;

  /// Serialized proofs (Cashu `Proof` JSON). Opaque to the Dart side.
  final List<String> proofs;
}

/// Contract the future wallet implementation fulfils.
///
/// A fake implementation lets order-flow code and tests run today; the real
/// `CashuWalletFfi` (flutter_rust_bridge → `satonero_cashu`) swaps in behind
/// this same interface without touching callers.
abstract class CashuWalletApi {
  /// Mint/select proofs and lock them under a NUT-11 P2PK 2-of-3 condition.
  ///
  /// Returns the locked token, or throws [CashuWalletException] when the mint
  /// is unreachable, refuses the quote, or the amount cannot be fulfilled.
  Future<CashuEscrowLock> lockEscrow({
    required String mintUrl,
    required P2pkEscrowKeys keys,
    required int amountSats,
    required int locktimeDays,
  });

  /// Co-sign (2-of-3) to spend the locked token to the seller.
  ///
  /// Returns the settlement proof id for traceability.
  Future<String> releaseEscrow(CashuEscrowLock lock);

  /// Co-sign (2-of-3) to return the locked token to the buyer.
  Future<void> cancelEscrow(CashuEscrowLock lock);

  /// After [CashuEscrowLock.locktimeDays] has elapsed, the seller alone may
  /// spend the token. Verifies the token state (NUT-07) against the mint first.
  Future<void> refundAfterLocktime(CashuEscrowLock lock);
}

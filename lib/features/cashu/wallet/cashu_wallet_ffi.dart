import 'package:flutter_rust_bridge/flutter_rust_bridge.dart'
    show AnyhowException;
import 'package:satonero_mobile/features/cashu/wallet/bridge/escrow.dart'
    as bridge;
import 'package:satonero_mobile/features/cashu/wallet/bridge/frb_generated.dart';
import 'package:satonero_mobile/features/cashu/wallet/bridge/wallet.dart'
    as wallet_bridge;
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_api.dart';

/// `flutter_rust_bridge` implementation of the Cashu wallet boundary.
///
/// This class connects the app to the `satonero_cashu` Rust crate, which in
/// turn delegates to the Cashu Development Kit (MIT OR Apache-2.0). It exposes
/// two generated surfaces:
///
/// Escrow primitives from `rust/src/escrow.rs`:
/// - [buildEscrowSpendingConditions] — 2-of-3 P2PK lock + seller locktime;
/// - [signProof] — add one party's co-signature to a locked proof;
/// - [verifyProofP2pk] — check a proof's witness before trusting it.
///
/// A working client wallet from `rust/src/wallet.rs` (CDK, NUT-04/05/06/07):
/// - [mintInfo] — mint metadata (NUT-06);
/// - [walletBalance] — spendable sats;
/// - [receiveInvoice] / [mintTokens] — Receive: invoice → proofs;
/// - [receiveToken] — redeem an encoded NUT-00 token;
/// - [sendInvoice] — Send: melt a BOLT11 invoice;
/// - [syncWallet] — check pending proofs + refresh metadata.
///
/// The escrow orchestrator ([CashuWalletApi.lockEscrow], [releaseEscrow],
/// [cancelEscrow], [refundAfterLocktime]) still requires a live trade session
/// and remains unwired; those fail fast with [CashuWalletException] until the
/// NUT-11 P2PK 2-of-3 settlement flow lands (see
/// `docs/architecture/CASHU_WALLET_CLIENT.md`).
class CashuWalletFfi implements CashuWalletApi {
  CashuWalletFfi._();

  /// Loads the native `satonero_cashu` library and returns a ready bridge.
  ///
  /// Throws [CashuWalletException] when the native library cannot be loaded —
  /// e.g. on a build where the Rust `.so` has not been compiled for the target
  /// (Android/iOS cross-compilation requires the NDK, which is documented as a
  /// separate build step).
  static Future<CashuWalletFfi> connect() async {
    try {
      await RustLib.init();
    } catch (_) {
      throw const CashuWalletException(
        'wallet_unavailable',
        'The native Cashu wallet library is not available in this build.',
      );
    }
    return CashuWalletFfi._();
  }

  /// Build the JSON-serialized NUT-11 P2PK 2-of-3 spending conditions.
  Future<String> buildEscrowSpendingConditions({
    required P2pkEscrowKeys keys,
    required int locktimeDays,
  }) {
    return _guard(
      () => bridge.buildEscrowSpendingConditions(
        buyerPubkeyHex: keys.buyerPublicKey,
        sellerPubkeyHex: keys.sellerPublicKey,
        escrowPubkeyHex: keys.escrowPublicKey,
        locktimeDays: locktimeDays,
      ),
      'build_spending_conditions',
    );
  }

  /// Sign a serialized Cashu proof with a secret key (one co-signature).
  Future<String> signProof({
    required String proofJson,
    required String secretKeyHex,
  }) {
    return _guard(
      () => bridge.signProof(
        proofJson: proofJson,
        secretKeyHex: secretKeyHex,
      ),
      'sign_proof',
    );
  }

  /// Verify a serialized Cashu proof's P2PK witness.
  Future<bool> verifyProofP2pk(String proofJson) {
    return _guard(
      () => bridge.verifyProofP2Pk(proofJson: proofJson),
      'verify_proof',
    );
  }

  /// Fetch the mint's metadata (NUT-06) as raw JSON.
  Future<String> mintInfo({
    required String mintUrl,
    required String dbPath,
  }) {
    return _guard(
      () => wallet_bridge.mintInfo(mintUrl: mintUrl, dbPath: dbPath),
      'mint_info',
    );
  }

  /// Return the wallet's spendable balance in satoshis.
  Future<BigInt> walletBalance({
    required String mintUrl,
    required String dbPath,
  }) {
    return _guard(
      () => wallet_bridge.walletBalance(mintUrl: mintUrl, dbPath: dbPath),
      'wallet_balance',
    );
  }

  /// Create a NUT-04 mint quote, returning JSON with `quote_id` and `invoice`.
  Future<String> receiveInvoice({
    required String mintUrl,
    required String dbPath,
    required BigInt amountSats,
  }) {
    return _guard(
      () => wallet_bridge.receiveInvoice(
        mintUrl: mintUrl,
        dbPath: dbPath,
        amountSats: amountSats,
      ),
      'receive_invoice',
    );
  }

  /// Settle a paid NUT-04 mint quote, returning the minted amount in sats.
  Future<BigInt> mintTokens({
    required String mintUrl,
    required String dbPath,
    required String quoteId,
  }) {
    return _guard(
      () => wallet_bridge.mintTokens(
        mintUrl: mintUrl,
        dbPath: dbPath,
        quoteId: quoteId,
      ),
      'mint_tokens',
    );
  }

  /// Redeem an encoded Cashu token (NUT-00), returning the received sats.
  Future<BigInt> receiveToken({
    required String mintUrl,
    required String dbPath,
    required String token,
  }) {
    return _guard(
      () => wallet_bridge.receiveToken(
        mintUrl: mintUrl,
        dbPath: dbPath,
        token: token,
      ),
      'receive_token',
    );
  }

  /// Pay a Lightning invoice (NUT-05 melt), returning JSON with `preimage` and
  /// `amount_sats`.
  Future<String> sendInvoice({
    required String mintUrl,
    required String dbPath,
    required String bolt11,
  }) {
    return _guard(
      () => wallet_bridge.sendInvoice(
        mintUrl: mintUrl,
        dbPath: dbPath,
        bolt11: bolt11,
      ),
      'send_invoice',
    );
  }

  /// Synchronize the wallet with the mint (NUT-07 + NUT-06), returning JSON
  /// with `balance_sats`, `freed_sats`, `mint_name` and `mint_version`.
  Future<String> syncWallet({
    required String mintUrl,
    required String dbPath,
  }) {
    return _guard(
      () => wallet_bridge.syncWallet(mintUrl: mintUrl, dbPath: dbPath),
      'sync_wallet',
    );
  }

  @override
  Future<CashuEscrowLock> lockEscrow({
    required String mintUrl,
    required P2pkEscrowKeys keys,
    required int amountSats,
    required int locktimeDays,
  }) {
    return _unavailable('lockEscrow');
  }

  @override
  Future<String> releaseEscrow(CashuEscrowLock lock) {
    return _unavailable('releaseEscrow');
  }

  @override
  Future<void> cancelEscrow(CashuEscrowLock lock) {
    return _unavailable('cancelEscrow');
  }

  @override
  Future<void> refundAfterLocktime(CashuEscrowLock lock) {
    return _unavailable('refundAfterLocktime');
  }

  /// Runs [operation] and maps any bridge failure onto [CashuWalletException].
  Future<T> _guard<T>(Future<T> Function() operation, String code) async {
    try {
      return await operation();
    } on AnyhowException catch (e) {
      throw CashuWalletException(code, e.message);
    } catch (e) {
      throw CashuWalletException(code, e.toString());
    }
  }

  Future<Never> _unavailable(String operation) {
    return Future.error(
      CashuWalletException(
        'wallet_unavailable',
        '$operation requires a live Cashu mint session, which is not wired '
            'into the app build yet (see docs/architecture/CASHU_WALLET_CLIENT.md).',
      ),
    );
  }
}

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show AnyhowException;
import 'package:satonero_mobile/features/cashu/wallet/bridge/escrow.dart' as bridge;
import 'package:satonero_mobile/features/cashu/wallet/bridge/frb_generated.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_api.dart';

/// `flutter_rust_bridge` implementation of the Cashu wallet boundary.
///
/// This class connects the app to the `satonero_cashu` Rust crate, which in
/// turn delegates the NUT-11 P2PK 2-of-3 cryptography to the Cashu Development
/// Kit (MIT OR Apache-2.0). It exposes the three verified primitives generated
/// from `rust/src/escrow.rs`:
///
/// - [buildEscrowSpendingConditions] — 2-of-3 P2PK lock + seller locktime;
/// - [signProof] — add one party's co-signature to a locked proof;
/// - [verifyProofP2pk] — check a proof's witness before trusting it.
///
/// The higher-level [CashuWalletApi] operations ([lockEscrow], [releaseEscrow],
/// [cancelEscrow], [refundAfterLocktime]) also require a live mint session,
/// proof selection and key management, which are not wired into the app build
/// yet. They therefore fail fast with [CashuWalletException] until that
/// orchestrator lands (see `docs/architecture/CASHU_WALLET_CLIENT.md`).
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

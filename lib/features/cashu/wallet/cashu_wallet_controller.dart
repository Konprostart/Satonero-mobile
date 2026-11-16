import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:satonero_mobile/features/cashu/cashu_mint_provider.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_api.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_ffi.dart';

/// Immutable snapshot of the client-side Cashu wallet.
///
/// This is the reactive state behind the Cashu wallet screen: which mint the
/// wallet is connected to, its spendable balance, and whether the native CDK
/// bridge is bundled in this build. Operations (Receive/Send/Sync) mutate the
/// snapshot through [CashuWalletController] and throw [CashuWalletException] on
/// failure so the UI can surface a localized error.
@immutable
class CashuWalletSnapshot {
  CashuWalletSnapshot({
    this.mintUrl,
    this.mintOptions = const [],
    BigInt? balance,
    this.mintName,
    this.mintVersion,
    this.nativeAvailable = false,
    this.syncing = false,
  }) : balance = balance ?? BigInt.zero;

  /// The mint the wallet is currently connected to, or null when none is
  /// selected yet (or the connected node runs Lightning).
  final String? mintUrl;

  /// Mints advertised by the connected node (empty for an open node).
  final List<String> mintOptions;

  /// Spendable balance in satoshis (as reported by the mint on last sync).
  final BigInt balance;

  /// Human-readable mint name from NUT-06, if the mint publishes one.
  final String? mintName;

  /// Mint software version string from NUT-06, if published.
  final String? mintVersion;

  /// Whether the native `satonero_cashu` library is bundled in this build.
  final bool nativeAvailable;

  /// True while a mint round-trip (sync/receive/send) is in flight.
  final bool syncing;

  bool get hasMint => mintUrl != null && mintUrl!.isNotEmpty;

  /// Whether Receive/Send/Sync can run: a mint is selected and the native
  /// library is present.
  bool get canOperate => nativeAvailable && hasMint;

  CashuWalletSnapshot copyWith({
    Object? mintUrl = _unset,
    List<String>? mintOptions,
    BigInt? balance,
    Object? mintName = _unset,
    Object? mintVersion = _unset,
    bool? nativeAvailable,
    bool? syncing,
  }) {
    return CashuWalletSnapshot(
      mintUrl: identical(mintUrl, _unset) ? this.mintUrl : mintUrl as String?,
      mintOptions: mintOptions ?? this.mintOptions,
      balance: balance ?? this.balance,
      mintName:
          identical(mintName, _unset) ? this.mintName : mintName as String?,
      mintVersion: identical(mintVersion, _unset)
          ? this.mintVersion
          : mintVersion as String?,
      nativeAvailable: nativeAvailable ?? this.nativeAvailable,
      syncing: syncing ?? this.syncing,
    );
  }
}

/// Sentinel used by [CashuWalletSnapshot.copyWith] to distinguish "leave
/// unchanged" from "set to null" for the nullable fields.
class _Unset {
  const _Unset();
}

const _unset = _Unset();

/// A NUT-04 mint quote awaiting payment.
@immutable
class CashuReceiveQuote {
  const CashuReceiveQuote({
    required this.quoteId,
    required this.invoice,
    required this.amountSats,
  });

  final String quoteId;
  final String invoice;
  final BigInt amountSats;
}

/// A settled NUT-05 melt (Lightning payment).
@immutable
class CashuSendResult {
  const CashuSendResult({required this.preimage, required this.amountSats});

  final String? preimage;
  final BigInt amountSats;
}

/// Orchestrates the client-side Cashu wallet.
///
/// It owns the CDK wallet's redb database path (one file per mint URL, derived
/// from a SHA-256 digest of the URL), connects the native bridge, seeds the
/// default mint from the connected node's kind-38385 info event, and exposes
/// the real wallet actions: Receive (invoice → mint), Send (melt BOLT11),
/// redeem a NUT-00 token, and Sync with mint.
///
/// All cryptography and mint I/O run in the Rust crate via
/// `flutter_rust_bridge`, so the Dart isolate never blocks and never sees raw
/// proof/secret material. No code is copied from the AGPL-licensed upstream
/// `MostroP2P/app` client.
class CashuWalletController extends AsyncNotifier<CashuWalletSnapshot> {
  CashuWalletFfi? _ffi;
  String? _dbDir;

  @override
  Future<CashuWalletSnapshot> build() async {
    // The connected node's escrow backend decides which mints are offered. A
    // single advertised mint is auto-selected; an open node (or a Lightning
    // node) leaves the wallet with no default and the user picks/enters one.
    final escrow = ref.watch(nodeEscrowInfoProvider).valueOrNull;
    final mintOptions = (escrow?.isCashu ?? false)
        ? (escrow?.mintUrls ?? const <String>[])
        : const <String>[];
    final mintUrl = mintOptions.length == 1 ? mintOptions.first : null;

    CashuWalletFfi? ffi;
    try {
      ffi = await CashuWalletFfi.connect();
    } on CashuWalletException {
      ffi = null;
    }
    _ffi = ffi;
    _dbDir = await _resolveDbDir();

    var snapshot = CashuWalletSnapshot(
      mintUrl: mintUrl,
      mintOptions: mintOptions,
      nativeAvailable: ffi != null,
    );

    if (ffi != null && mintUrl != null) {
      snapshot = await _refresh(ffi, snapshot);
    }
    return snapshot;
  }

  /// Switch the wallet to [mintUrl] (or disconnect when null) and refresh.
  Future<void> selectMint(String? mintUrl) async {
    final ffi = _ffi;
    final base = state.valueOrNull ?? CashuWalletSnapshot();
    var next = base.copyWith(mintUrl: mintUrl);
    state = AsyncData(next);

    if (ffi == null || mintUrl == null || mintUrl.isEmpty) {
      return;
    }
    state = AsyncData(next.copyWith(syncing: true));
    final refreshed = await _refresh(ffi, next);
    state = AsyncData(refreshed.copyWith(syncing: false));
  }

  /// Synchronize the wallet with the mint (NUT-07 proof check + NUT-06
  /// metadata refresh) and update the balance.
  ///
  /// Returns the number of sats freed from cancelled pending proofs, so the
  /// UI can acknowledge a refund.
  Future<BigInt> sync() async {
    final ffi = _requireOperable();
    final base = state.valueOrNull!;
    final mintUrl = base.mintUrl!;

    state = AsyncData(base.copyWith(syncing: true));
    try {
      final summary = jsonDecode(
              await ffi.syncWallet(mintUrl: mintUrl, dbPath: _dbPath(mintUrl)))
          as Map<String, dynamic>;
      final refreshed = base.copyWith(
        balance: BigInt.from(summary['balance_sats'] as int? ?? 0),
        mintName: summary['mint_name'] as String?,
        mintVersion: summary['mint_version'] as String?,
      );
      state = AsyncData(refreshed.copyWith(syncing: false));
      return BigInt.from(summary['freed_sats'] as int? ?? 0);
    } catch (_) {
      state = AsyncData(base.copyWith(syncing: false));
      rethrow;
    }
  }

  /// Create a NUT-04 mint quote for [amountSats] and return the Lightning
  /// invoice the user must pay before [mint] settles the deposit.
  Future<CashuReceiveQuote> receive(BigInt amountSats) async {
    final ffi = _requireOperable();
    final mintUrl = state.valueOrNull!.mintUrl!;

    final raw = await ffi.receiveInvoice(
      mintUrl: mintUrl,
      dbPath: _dbPath(mintUrl),
      amountSats: amountSats,
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CashuReceiveQuote(
      quoteId: json['quote_id'] as String,
      invoice: json['invoice'] as String,
      amountSats: amountSats,
    );
  }

  /// Settle a paid NUT-04 mint quote, refresh the balance and return the
  /// amount minted in sats.
  Future<BigInt> mint(String quoteId) async {
    final ffi = _requireOperable();
    final mintUrl = state.valueOrNull!.mintUrl!;

    final minted = await ffi.mintTokens(
      mintUrl: mintUrl,
      dbPath: _dbPath(mintUrl),
      quoteId: quoteId,
    );
    await _refreshAndStore();
    return minted;
  }

  /// Redeem an encoded NUT-00 Cashu token and refresh the balance.
  Future<BigInt> redeemToken(String token) async {
    final ffi = _requireOperable();
    final mintUrl = state.valueOrNull!.mintUrl!;

    final received = await ffi.receiveToken(
      mintUrl: mintUrl,
      dbPath: _dbPath(mintUrl),
      token: token,
    );
    await _refreshAndStore();
    return received;
  }

  /// Pay a Lightning invoice by melting ecash (NUT-05) and refresh the balance.
  Future<CashuSendResult> send(String bolt11) async {
    final ffi = _requireOperable();
    final mintUrl = state.valueOrNull!.mintUrl!;

    final raw = await ffi.sendInvoice(
      mintUrl: mintUrl,
      dbPath: _dbPath(mintUrl),
      bolt11: bolt11,
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    await _refreshAndStore();
    return CashuSendResult(
      preimage: json['preimage'] as String?,
      amountSats: BigInt.from(json['amount_sats'] as int? ?? 0),
    );
  }

  /// Per-mint redb database path (one file per mint URL).
  String _dbPath(String mintUrl) {
    final digest = sha256.convert(utf8.encode(mintUrl)).toString();
    return '${_dbDir!}/${digest.substring(0, 24)}.redb';
  }

  /// Resolve the app-support directory and ensure the wallet subdirectory
  /// exists (cdk-redb refuses to create its file in a missing parent).
  Future<String> _resolveDbDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/cashu_wallet');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Refresh the snapshot in place after an operation changes the balance.
  Future<void> _refreshAndStore() async {
    final ffi = _ffi;
    final base = state.valueOrNull;
    if (ffi == null || base == null || base.mintUrl == null) return;
    final refreshed = await _refresh(ffi, base);
    state = AsyncData(refreshed);
  }

  /// Load balance + mint metadata and fold the result into [snapshot].
  Future<CashuWalletSnapshot> _refresh(
    CashuWalletFfi ffi,
    CashuWalletSnapshot snapshot,
  ) async {
    final mintUrl = snapshot.mintUrl;
    if (mintUrl == null) return snapshot;
    try {
      final summary = jsonDecode(
              await ffi.syncWallet(mintUrl: mintUrl, dbPath: _dbPath(mintUrl)))
          as Map<String, dynamic>;
      return snapshot.copyWith(
        balance: BigInt.from(summary['balance_sats'] as int? ?? 0),
        mintName: summary['mint_name'] as String?,
        mintVersion: summary['mint_version'] as String?,
      );
    } on CashuWalletException {
      // Keep the previous snapshot; the balance is simply stale/unavailable.
      return snapshot;
    } catch (_) {
      return snapshot;
    }
  }

  CashuWalletFfi _requireOperable() {
    final ffi = _ffi;
    final base = state.valueOrNull;
    if (ffi == null) {
      throw const CashuWalletException(
        'wallet_unavailable',
        'The native Cashu wallet library is not available in this build.',
      );
    }
    if (base == null || !base.hasMint) {
      throw const CashuWalletException(
        'no_mint',
        'No Cashu mint is selected.',
      );
    }
    return ffi;
  }
}

/// Reactive access to the client-side Cashu wallet.
final cashuWalletProvider =
    AsyncNotifierProvider<CashuWalletController, CashuWalletSnapshot>(
  CashuWalletController.new,
);

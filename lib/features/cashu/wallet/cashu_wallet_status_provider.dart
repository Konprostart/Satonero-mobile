import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_api.dart';
import 'package:satonero_mobile/features/cashu/wallet/cashu_wallet_ffi.dart';

/// Whether the native `satonero_cashu` library is bundled into this build.
///
/// Probes the flutter_rust_bridge bootstrap exactly once and caches the result
/// for the app lifetime. When the library is missing — a web build, or an
/// Android/iOS build where the NDK cross-compiled `.so` has not been linked in
/// yet — the bridge fails fast with [CashuWalletException] and this resolves to
/// `false` instead of crashing the Cashu wallet screen.
final cashuNativeWalletAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    await CashuWalletFfi.connect();
    return true;
  } on CashuWalletException {
    return false;
  } catch (_) {
    return false;
  }
});

import 'package:flutter/foundation.dart';

/// A Cashu mint URL the connected node accepts for an order's escrow.
///
/// This is a thin value object: the mint is identified only by its canonical
/// URL, which is what the daemon stores, publishes and compares (see the
/// daemon's `cashu::mint_policy`). No wallet or cryptography lives here —
/// the actual Cashu escrow happens on the daemon via the open NUT spec.
@immutable
class CashuMint {
  const CashuMint(this.url);

  /// The mint's canonical URL, e.g. `https://mint.example.com`.
  final String url;

  /// Short, user-facing label: the host, falling back to the raw URL when it
  /// cannot be parsed.
  String get displayName {
    final uri = Uri.tryParse(url);
    final host = uri?.host;
    return (host == null || host.isEmpty) ? url : host;
  }

  @override
  bool operator ==(Object other) => other is CashuMint && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => url;
}

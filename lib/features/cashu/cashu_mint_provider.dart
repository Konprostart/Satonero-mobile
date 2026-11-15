import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/features/mostro/mostro_instance.dart';
import 'package:satonero_mobile/shared/providers/order_repository_provider.dart';

/// Immutable snapshot of the connected node's escrow capability, derived from
/// its kind-38385 info event.
///
/// A node runs exactly one escrow backend. [escrowMode] tells which; when it
/// is [EscrowMode.cashu], [mintUrls] lists the mints a maker may choose (empty
/// means the node is open and accepts any public mint) and
/// [escrowLocktimeDays] is the seller-recovery locktime floor.
@immutable
class NodeEscrowInfo {
  const NodeEscrowInfo({
    required this.escrowMode,
    this.mintUrls = const [],
    this.escrowLocktimeDays,
  });

  final EscrowMode escrowMode;
  final List<String> mintUrls;
  final int? escrowLocktimeDays;

  bool get isCashu => escrowMode == EscrowMode.cashu;

  /// The value used until the node's info event has been observed. Missing
  /// `escrow_mode` is indistinguishable from a legacy (Lightning) daemon, so
  /// the safe default is Lightning.
  static const NodeEscrowInfo unknown =
      NodeEscrowInfo(escrowMode: EscrowMode.lightning);
}

/// Reactively exposes the connected node's escrow capability.
///
/// Bridges [OpenOrdersRepository.mostroInstance] (a cached field updated on the
/// info event) with its change stream, so a mint selector appears as soon as
/// the node's `escrow_mode` is known instead of only on the first build.
final nodeEscrowInfoProvider = StreamProvider<NodeEscrowInfo>((ref) async* {
  final repository = ref.watch(orderRepositoryProvider);

  NodeEscrowInfo fromEvent(NostrEvent? event) => event == null
      ? NodeEscrowInfo.unknown
      : NodeEscrowInfo(
          escrowMode: event.escrowMode,
          mintUrls: event.cashuMintUrls,
          escrowLocktimeDays: event.cashuEscrowLocktimeDays,
        );

  // Emit the already-cached info event first, then follow live updates.
  yield fromEvent(repository.mostroInstance);
  await for (final event in repository.mostroInstanceStream) {
    yield fromEvent(event);
  }
});

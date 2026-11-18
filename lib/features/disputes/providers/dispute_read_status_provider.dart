import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/features/disputes/notifiers/dispute_chat_notifier.dart';
import 'package:satonero_mobile/services/dispute_read_status_service.dart';

/// Monotonic bump signal for when a dispute is marked as read.
///
/// The value is never used for comparison — the persisted read cursor lives in
/// [DisputeReadStatusService]. It only exists so [disputeHasUnreadProvider]
/// can `watch` it and recompute after the cursor write lands. A monotonic
/// counter is used instead of a wall-clock timestamp because a timestamp can
/// collide with the previous value within the same millisecond, in which case
/// the `StateProvider` treats the assignment as a no-op and the unread dot
/// stays stale.
final disputeReadStatusProvider = StateProvider.family<int, String>((ref, disputeId) {
  return 0;
});

/// Whether the dispute chat has admin messages newer than the read cursor.
/// Replaces a per-row FutureBuilder whose future (a prefs read) was recreated
/// on every rebuild. Watching [disputeReadStatusProvider] recomputes it when
/// the dispute is marked as read.
final disputeHasUnreadProvider =
    FutureProvider.family<bool, String>((ref, disputeId) async {
  ref.watch(disputeReadStatusProvider(disputeId));
  final messages = ref.watch(
    disputeChatNotifierProvider(disputeId).select((s) => s.messages),
  );
  if (messages.isEmpty) return false;
  final isFromUser =
      ref.read(disputeChatNotifierProvider(disputeId).notifier).isFromUser;
  return DisputeReadStatusService.hasUnreadMessages(
    disputeId,
    messages,
    isFromUser: isFromUser,
  );
});

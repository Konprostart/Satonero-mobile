import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/features/notifications/services/background_notification_service.dart';

/// The background isolate surfaces system ("local") notifications for events
/// it decrypts while the app is backgrounded. That display path must honor the
/// user's notifications setting: when the toggle is off, [showLocalNotification]
/// returns before decrypting or touching the notification plugin.
void main() {
  tearDown(() => localNotificationsEnabled = true);

  test('local notifications are enabled by default', () {
    expect(localNotificationsEnabled, isTrue);
  });

  test('showLocalNotification is a no-op when notifications are disabled',
      () async {
    localNotificationsEnabled = false;

    final event = NostrEvent(
      id: 'event-id',
      kind: 38383,
      content: '',
      sig: 'sig',
      pubkey: 'a' * 64,
      createdAt: DateTime.utc(2026, 1, 1),
      tags: const [],
    );

    // Must complete without throwing and without decrypting (the event above
    // is intentionally not decryptable).
    await showLocalNotification(event);
    expect(localNotificationsEnabled, isFalse);
  });

  test(
      'showLocalNotification is a no-op when notifications are disabled '
      'regardless of event shape', () async {
    localNotificationsEnabled = false;

    final event = NostrEvent(
      id: null,
      kind: null,
      content: null,
      sig: null,
      pubkey: '',
      createdAt: null,
      tags: null,
    );

    await showLocalNotification(event);
    expect(localNotificationsEnabled, isFalse);
  });
}

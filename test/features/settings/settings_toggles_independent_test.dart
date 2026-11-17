import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The Telegram and notification (push) toggles are two independent,
/// user-controlled preferences. Turning one on or off must never mutate the
/// other, and each must round-trip through persistence so a restart keeps the
/// user's choice.
void main() {
  late SettingsNotifier notifier;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    notifier = SettingsNotifier(SharedPreferencesAsync());
  });

  tearDown(() => notifier.dispose());

  test('enabling Telegram leaves the notifications setting untouched',
      () async {
    await notifier.updatePushNotificationsEnabled(true);
    await notifier.pushTransition;
    final pushBefore = notifier.state.pushNotificationsEnabled;

    await notifier.updateTelegramNotificationsEnabled(true);

    expect(notifier.state.telegramNotificationsEnabled, isTrue);
    expect(notifier.state.pushNotificationsEnabled, pushBefore);
  });

  test('disabling notifications leaves the Telegram setting untouched',
      () async {
    await notifier.updateTelegramNotificationsEnabled(true);
    await notifier.updatePushNotificationsEnabled(false);
    await notifier.pushTransition;

    expect(notifier.state.pushNotificationsEnabled, isFalse);
    expect(notifier.state.telegramNotificationsEnabled, isTrue);
  });

  test('telegram toggle round-trips through persistence', () async {
    await notifier.updateTelegramNotificationsEnabled(true);

    final reloaded = SettingsNotifier(SharedPreferencesAsync());
    await reloaded.init();
    addTearDown(reloaded.dispose);

    expect(reloaded.state.telegramNotificationsEnabled, isTrue);
  });

  test('notifications toggle round-trips through persistence', () async {
    await notifier.updatePushNotificationsEnabled(false);
    await notifier.pushTransition;

    final reloaded = SettingsNotifier(SharedPreferencesAsync());
    await reloaded.init();
    addTearDown(reloaded.dispose);

    expect(reloaded.state.pushNotificationsEnabled, isFalse);
  });
}

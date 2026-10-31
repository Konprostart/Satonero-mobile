import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/core/config/communities.dart';
import 'package:satonero_mobile/core/legacy_daemon_migration.dart';
import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/features/community/providers/community_selector_provider.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _customDaemon =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

/// Pubkey of a community listed in the selector (not the legacy default).
final _communityDaemon = trustedCommunities
    .map((c) => c.pubkey)
    .firstWhere((pk) => pk != legacyUpstreamDaemonPubkey);

Settings _settings(String pubkey, {List<String> relays = const []}) =>
    Settings(relays: relays, fullPrivacyMode: false, mostroPublicKey: pubkey);

Future<void> _storeSettings(SharedPreferencesAsync prefs, Settings s) =>
    prefs.setString(
      SharedPreferencesKeys.appSettings.value,
      jsonEncode(s.toJson()),
    );

Future<String?> _storedPubkey(SharedPreferencesAsync prefs) async {
  final raw = await prefs.getString(SharedPreferencesKeys.appSettings.value);
  if (raw == null) return null;
  return Settings.fromJson(jsonDecode(raw)).mostroPublicKey;
}

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  test('the legacy constant matches the upstream entry in the selector', () {
    expect(legacyUpstreamDaemonPubkey, defaultMostroPubkey);
  });

  group('legacy default reset', () {
    test('resets the stored legacy daemon and everything bound to it', () async {
      await _storeSettings(
        prefs,
        _settings(
          legacyUpstreamDaemonPubkey,
          relays: const ['wss://upstream-discovered.example'],
        ),
      );
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);
      await prefs.setString(
        SharedPreferencesKeys.backgroundFilters.value,
        '[{"authors":["$legacyUpstreamDaemonPubkey"]}]',
      );

      final changed = await migrateLegacyUpstreamDaemon(prefs);

      expect(changed, isTrue);
      final raw = await prefs.getString(SharedPreferencesKeys.appSettings.value);
      final migrated = Settings.fromJson(jsonDecode(raw!));
      expect(migrated.mostroPublicKey, isEmpty);
      expect(migrated.relays, isEmpty);
      expect(migrated.userRelays, isEmpty);
      expect(migrated.blacklistedRelays, isEmpty);
      expect(
        await prefs.getBool(SharedPreferencesKeys.communitySelected.value),
        isFalse,
      );
      expect(
        await prefs.getString(SharedPreferencesKeys.backgroundFilters.value),
        isNull,
      );
      expect(
        await prefs.getBool(SharedPreferencesKeys.legacyDaemonMigrated.value),
        isTrue,
      );
    });

    test('the reset is visible to a freshly loaded SettingsNotifier', () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));

      await migrateLegacyUpstreamDaemon(prefs);
      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      expect(notifier.state.mostroPublicKey, isEmpty);
    });

    test('a community that still has first_run_complete is not re-selected',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);
      await prefs.setBool(SharedPreferencesKeys.firstRunComplete.value, true);

      await migrateLegacyUpstreamDaemon(prefs);

      final notifier = CommunitySelectedNotifier(prefs);
      for (var i = 0; i < 100 && notifier.state.isLoading; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(notifier.state.value, isFalse,
          reason: 'the user must choose a daemon explicitly again');
    });
  });

  group('preservation', () {
    test('a custom daemon is preserved untouched', () async {
      await _storeSettings(
        prefs,
        _settings(_customDaemon, relays: const ['wss://mine.example']),
      );
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);

      final changed = await migrateLegacyUpstreamDaemon(prefs);

      expect(changed, isFalse);
      expect(await _storedPubkey(prefs), _customDaemon);
      expect(
        await prefs.getBool(SharedPreferencesKeys.communitySelected.value),
        isTrue,
      );
      final raw = await prefs.getString(SharedPreferencesKeys.appSettings.value);
      expect(Settings.fromJson(jsonDecode(raw!)).relays,
          ['wss://mine.example']);
    });

    test('a community daemon other than the legacy default is preserved',
        () async {
      await _storeSettings(prefs, _settings(_communityDaemon));
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);

      await migrateLegacyUpstreamDaemon(prefs);

      expect(await _storedPubkey(prefs), _communityDaemon);
      expect(
        await prefs.getBool(SharedPreferencesKeys.communitySelected.value),
        isTrue,
      );
    });

    test('background filters without the legacy author are kept', () async {
      const filters = '[{"authors":["$_customDaemon"]}]';
      await prefs.setString(
        SharedPreferencesKeys.backgroundFilters.value,
        filters,
      );

      await migrateLegacyUpstreamDaemon(prefs);

      expect(
        await prefs.getString(SharedPreferencesKeys.backgroundFilters.value),
        filters,
      );
    });

    test('no stored settings: marks done without creating a daemon', () async {
      final changed = await migrateLegacyUpstreamDaemon(prefs);

      expect(changed, isFalse);
      expect(
        await prefs.getString(SharedPreferencesKeys.appSettings.value),
        isNull,
      );
      expect(
        await prefs.getBool(SharedPreferencesKeys.legacyDaemonMigrated.value),
        isTrue,
      );
    });

    test('corrupt settings JSON does not throw and is left alone', () async {
      await prefs.setString(
        SharedPreferencesKeys.appSettings.value,
        '{not json',
      );

      final changed = await migrateLegacyUpstreamDaemon(prefs);

      expect(changed, isFalse);
      expect(
        await prefs.getString(SharedPreferencesKeys.appSettings.value),
        '{not json',
      );
    });
  });

  group('idempotence', () {
    test('a repeat run is a no-op', () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));

      expect(await migrateLegacyUpstreamDaemon(prefs), isTrue);
      expect(await migrateLegacyUpstreamDaemon(prefs), isFalse);
    });

    test('an explicit legacy choice after the reset is not reset again',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));
      await migrateLegacyUpstreamDaemon(prefs);

      // The user now picks the upstream entry from the list on purpose.
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);

      expect(await migrateLegacyUpstreamDaemon(prefs), isFalse);
      expect(await _storedPubkey(prefs), legacyUpstreamDaemonPubkey);
      expect(
        await prefs.getBool(SharedPreferencesKeys.communitySelected.value),
        isTrue,
      );
    });
  });

  group('defensive guard for other isolates', () {
    test('withoutLegacyDaemon blanks only the legacy pubkey', () {
      expect(
        withoutLegacyDaemon(_settings(legacyUpstreamDaemonPubkey))
            .mostroPublicKey,
        isEmpty,
      );
      expect(
        withoutLegacyDaemon(_settings(_customDaemon)).mostroPublicKey,
        _customDaemon,
      );
    });
  });
}

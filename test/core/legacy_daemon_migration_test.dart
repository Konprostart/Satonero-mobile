import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:satonero_mobile/data/repositories/open_orders_repository.dart';
import 'package:satonero_mobile/core/config/communities.dart';
import 'package:satonero_mobile/core/legacy_daemon_migration.dart';
import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/features/community/providers/community_selector_provider.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../mocks.mocks.dart';

const _customDaemon =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

/// Pubkey of a community listed in the selector (not the legacy default).
final _communityDaemon = trustedCommunities
    .map((c) => c.pubkey)
    .firstWhere((pk) => pk != legacyUpstreamDaemonPubkey);

Settings _settings(
  String pubkey, {
  List<String> relays = const [],
  List<Map<String, dynamic>> userRelays = const [],
  List<String> blacklistedRelays = const [],
}) =>
    Settings(
      relays: relays,
      fullPrivacyMode: false,
      mostroPublicKey: pubkey,
      userRelays: userRelays,
      blacklistedRelays: blacklistedRelays,
    );

Map<String, dynamic> _userRelay(String url) => {
      'url': url,
      'isHealthy': true,
      'source': 'user',
    };

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
    test('resets the stored legacy daemon and its discovered relays only', () async {
      await _storeSettings(
        prefs,
        _settings(
          legacyUpstreamDaemonPubkey,
          // Discovered from the legacy daemon's kind 10002: must be dropped.
          // The user-configured relay must survive.
          relays: const [
            'wss://upstream-discovered.example',
            'wss://mine.example',
          ],
          userRelays: [_userRelay('wss://mine.example')],
          blacklistedRelays: const ['wss://blocked.example'],
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
      expect(migrated.relays, ['wss://mine.example'],
          reason: 'discovered relays of the legacy daemon are removed');
      expect(migrated.userRelays.map((r) => r['url']).toList(),
          ['wss://mine.example'],
          reason: 'user-added relays are preserved');
      expect(migrated.blacklistedRelays, ['wss://blocked.example'],
          reason: 'the blacklist only filters and is preserved');
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

  group('startup ordering', () {
    test('SettingsNotifier.init migrates before exposing any settings',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, true);

      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      expect(notifier.state.mostroPublicKey, isEmpty);
      expect(await _storedPubkey(prefs), isEmpty,
          reason: 'the persisted copy is rewritten before init returns');
      expect(
        await prefs.getBool(SharedPreferencesKeys.legacyDaemonMigrated.value),
        isTrue,
      );
    });

    test('no order REQ can be built from the legacy pubkey after init',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));

      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      final nostr = MockNostrService();
      when(nostr.isInitialized).thenReturn(true);
      when(nostr.relayGenerationStream)
          .thenAnswer((_) => const Stream<int>.empty());
      when(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')))
          .thenAnswer((_) => const Stream<NostrEvent>.empty());

      OpenOrdersRepository(nostr, notifier.state);

      verifyNever(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')));
    });

    test('init keeps a custom daemon and its REQ untouched', () async {
      await _storeSettings(prefs, _settings(_customDaemon));

      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      expect(notifier.state.mostroPublicKey, _customDaemon);
    });
  });

  group('background entry points', () {
    test('the FCM / notification read returns post-migration settings only',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));

      final json = await readMigratedSettingsJson(prefs);

      expect(Settings.fromJson(jsonDecode(json!)).mostroPublicKey, isEmpty);
      expect(await _storedPubkey(prefs), isEmpty,
          reason: 'the persisted copy is clean for any later reader');
    });

    test('the FCM / notification read keeps a custom daemon', () async {
      await _storeSettings(prefs, _settings(_customDaemon));

      final json = await readMigratedSettingsJson(prefs);

      expect(Settings.fromJson(jsonDecode(json!)).mostroPublicKey,
          _customDaemon);
    });

    test('a message carrying the legacy pubkey is sanitized and migrates storage',
        () async {
      await _storeSettings(prefs, _settings(legacyUpstreamDaemonPubkey));

      final settings = await settingsFromBackgroundMessage(
        _settings(legacyUpstreamDaemonPubkey, relays: const ['wss://a.example'])
            .toJson(),
        prefs,
      );

      expect(settings.mostroPublicKey, isEmpty);
      expect(settings.relays, ['wss://a.example'],
          reason: 'message relays are not rewritten by the daemon guard');
      expect(await _storedPubkey(prefs), isEmpty);
    });

    test('a message with a custom daemon passes through unchanged', () async {
      final settings = await settingsFromBackgroundMessage(
        _settings(_customDaemon).toJson(),
        prefs,
      );

      expect(settings.mostroPublicKey, _customDaemon);
    });
  });

  group('fresh install', () {
    test('stays disconnected: no daemon, no relays, selector gate closed',
        () async {
      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      expect(notifier.state.mostroPublicKey, isEmpty);
      expect(notifier.state.relays, isEmpty);

      final selected = CommunitySelectedNotifier(prefs);
      for (var i = 0; i < 100 && selected.state.isLoading; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(selected.state.value, isFalse,
          reason: 'the router must send the user to the community selector');
    });

    test('issues no order REQ before an explicit daemon is selected', () async {
      final notifier = SettingsNotifier(prefs);
      await notifier.init();

      final nostr = MockNostrService();
      when(nostr.isInitialized).thenReturn(true);
      when(nostr.relayGenerationStream)
          .thenAnswer((_) => const Stream<int>.empty());
      when(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')))
          .thenAnswer((_) => const Stream<NostrEvent>.empty());

      OpenOrdersRepository(nostr, notifier.state);

      verifyNever(nostr.subscribeToEvents(any, onEose: anyNamed('onEose')));
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

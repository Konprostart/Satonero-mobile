import 'dart:convert';

import 'package:satonero_mobile/data/models/enums/storage_keys.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Upstream Mostro daemon that the legacy "Skip" button selected implicitly.
/// Only this exact value is reset by [migrateLegacyUpstreamDaemon]; any other
/// daemon (custom or community) is an explicit choice and is preserved.
const String legacyUpstreamDaemonPubkey =
    '82fa8cb978b43c79b2156585bac2c011176a21d2aead6d9f7c575c005be88390';

/// One-time, idempotent migration of the legacy implicit daemon selection.
///
/// Trigger: runs at the start of every code path that reads the persisted
/// settings before any daemon connection, order request or subscription:
///  - `bootstrapAndRun` (foreground app, before `SettingsNotifier.init`);
///  - the FCM background handler (before it starts the background service);
///  - the background service `start` handler (before `NostrService.init`);
///  - the background notification isolate's Mostro pubkey lookup.
///
/// Effect when the stored daemon equals [legacyUpstreamDaemonPubkey]:
///  - `mostro_settings`: `mostroPublicKey` becomes `''`; the instance-bound
///    relay state (`relays`, `userRelays`, `blacklistedRelays`) is cleared,
///    matching what an instance switch does in `updateMostroInstance`.
///  - `community_selected` is set to `false`, so the user must choose a
///    community or custom node explicitly. No other daemon is selected.
///  - `background_filters` is removed if it references the legacy pubkey.
///
/// Otherwise nothing but the marker is written. The marker
/// `legacy_daemon_migrated` makes every later run a no-op.
///
/// Returns `true` when stored state was changed.
Future<bool> migrateLegacyUpstreamDaemon(SharedPreferencesAsync prefs) async {
  final done = await prefs.getBool(
    SharedPreferencesKeys.legacyDaemonMigrated.value,
  );
  if (done == true) return false;

  var changed = false;

  final rawSettings = await prefs.getString(SharedPreferencesKeys.appSettings.value);
  if (rawSettings != null) {
    final json = _decodeObject(rawSettings);
    if (json != null &&
        json['mostroPublicKey'] == legacyUpstreamDaemonPubkey) {
      // Order matters: clear the selection flag before rewriting settings. If
      // the process dies in between, the marker is still unset and the next
      // run sees the legacy pubkey again and finishes the reset.
      await prefs.setBool(SharedPreferencesKeys.communitySelected.value, false);

      json['mostroPublicKey'] = '';
      json['relays'] = <String>[];
      json['blacklistedRelays'] = <String>[];
      json['userRelays'] = <Map<String, dynamic>>[];
      await prefs.setString(
        SharedPreferencesKeys.appSettings.value,
        jsonEncode(json),
      );
      changed = true;
    }
  }

  final rawFilters =
      await prefs.getString(SharedPreferencesKeys.backgroundFilters.value);
  if (rawFilters != null && rawFilters.contains(legacyUpstreamDaemonPubkey)) {
    await prefs.remove(SharedPreferencesKeys.backgroundFilters.value);
    changed = true;
  }

  // Written last: an interrupted run is repeated, never skipped.
  await prefs.setBool(SharedPreferencesKeys.legacyDaemonMigrated.value, true);
  return changed;
}

/// Defensive: a settings object received from another isolate must never
/// carry the legacy pubkey into `NostrService`, even before the migration has
/// rewritten the persisted copy.
Settings withoutLegacyDaemon(Settings settings) {
  if (settings.mostroPublicKey != legacyUpstreamDaemonPubkey) return settings;
  return settings.copyWith(mostroPublicKey: '');
}

Map<String, dynamic>? _decodeObject(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

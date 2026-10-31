import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satonero_mobile/features/settings/settings.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:satonero_mobile/shared/providers/storage_providers.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/features/settings/settings_notifier.dart';
import 'package:satonero_mobile/features/walkthrough/utils/first_launch_language.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('needsFirstLaunchLanguage', () {
    test('first run with no saved language shows the language screen', () {
      expect(
        needsFirstLaunchLanguage(isFirstRun: true, selectedLanguage: null),
        isTrue,
      );
    });

    test('first run with a saved language skips the language screen', () {
      expect(
        needsFirstLaunchLanguage(isFirstRun: true, selectedLanguage: 'it'),
        isFalse,
      );
    });

    test('completed first run never shows the language screen', () {
      expect(
        needsFirstLaunchLanguage(isFirstRun: false, selectedLanguage: null),
        isFalse,
      );
      expect(
        needsFirstLaunchLanguage(isFirstRun: false, selectedLanguage: 'de'),
        isFalse,
      );
    });
  });

  group('first-launch language options', () {
    test('offers only languages the app ships translations for', () {
      expect(
        firstLaunchLanguages.map((l) => l.code).toList(),
        ['en', 'es', 'it', 'fr', 'de', 'pt', 'nl'],
      );
    });

    test('does not offer system default as a first-launch choice', () {
      expect(firstLaunchLanguages.map((l) => l.code), isNot(contains(null)));
    });
  });

  group('saved language persistence', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('a chosen language is saved and read back on the next launch',
        () async {
      final prefs = SharedPreferencesAsync();

      final first = SettingsNotifier(prefs);
      await first.init();
      expect(first.state.selectedLanguage, isNull);
      await first.updateSelectedLanguage('it');

      final nextLaunch = SettingsNotifier(prefs);
      await nextLaunch.init();
      expect(nextLaunch.state.selectedLanguage, 'it');
      expect(
        needsFirstLaunchLanguage(
          isFirstRun: true,
          selectedLanguage: nextLaunch.state.selectedLanguage,
        ),
        isFalse,
      );
    });

    test('changing the language later overwrites the saved choice', () async {
      final prefs = SharedPreferencesAsync();

      final notifier = SettingsNotifier(prefs);
      await notifier.init();
      await notifier.updateSelectedLanguage('es');
      await notifier.updateSelectedLanguage('fr');

      final nextLaunch = SettingsNotifier(prefs);
      await nextLaunch.init();
      expect(nextLaunch.state.selectedLanguage, 'fr');
    });
  });
}

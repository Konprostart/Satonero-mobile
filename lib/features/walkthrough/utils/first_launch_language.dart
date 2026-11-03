/// Languages offered on the first-launch language screen.
///
/// Only codes the app already ships translations for (lib/l10n/intl_*.arb).
/// "System default" is not offered here: a null selectedLanguage is also what
/// legacy installs hold, so it cannot mark a deliberate choice. The language
/// can still be switched to system default later in Settings.
const List<({String code, String name})> firstLaunchLanguages = [
  (code: 'en', name: 'English'),
  (code: 'es', name: 'Español'),
  (code: 'it', name: 'Italiano'),
  (code: 'fr', name: 'Français'),
  (code: 'de', name: 'Deutsch'),
  (code: 'pt', name: 'Português'),
  (code: 'nl', name: 'Nederlands'),
];

/// True when the language screen must be shown before the walkthrough: the
/// first run has not finished and no language has been saved yet.
bool needsFirstLaunchLanguage({
  required bool isFirstRun,
  required String? selectedLanguage,
}) =>
    isFirstRun && selectedLanguage == null;

# Theme System (Light / Dark + OLED + Lightning identity)

**Status:** Active
**Scope:** `lib/core/app_theme.dart`, `lib/core/app.dart`, `lib/features/settings/settings.dart`

Satonero ships two full `ThemeData` instances — a deep **OLED dark** theme and a
**high-contrast light** theme — switched through a persisted `ThemeMode`
(`system` / `light` / `dark`). The visual identity is built from Bitcoin orange
and Lightning electric blue/yellow accents.

## Brand palette

| Token | Hex | Role |
|---|---|---|
| `AppTheme.bitcoinOrange` / `AppTheme.satoneroOrange` | `#F7931A` | Primary accent, buy/active states, buttons |
| `AppTheme.lightningBlue` | `#2979FF` | Lightning electric-blue accent |
| `AppTheme.lightningYellow` / `AppTheme.yellow` | `#F3CA29` | Lightning yellow accent |
| dark `scaffoldBackground` | `#000000` | Deep OLED black |
| dark `cardBackground` | `#121212` | Elevated surface |
| light `scaffoldBackground` | `#F7F7F8` | High-contrast light background |
| light `cardBackground` | `#FFFFFF` | Elevated surface |

`AppTheme.satoneroOrange` is kept as an alias of `AppTheme.bitcoinOrange` so the
existing ~100 references resolve to the Bitcoin-orange identity without a
mechanical rename.

## Architecture

### `AppTheme` (dual `ThemeData`)

- `AppTheme.darkTheme` — OLED black scaffold, built once (`static final`).
- `AppTheme.lightTheme` — high-contrast light scaffold, built once.
- `AppTheme.theme` — backward-compatible alias of `AppTheme.darkTheme`.

Both are memoized; the old test (`test/core/app_theme_test.dart`) still asserts
the shared-instance invariant via `AppTheme.theme`.

### `AppColors` (`ThemeExtension`)

Semantic tokens live in `AppColors` with `AppColors.dark` and `AppColors.light`
variants, registered on both themes via `ThemeData.extensions`. A widget
resolves the active palette with:

```dart
final colors = AppTheme.colors(context);
```

This is the recommended pattern for new widgets (the Cashu mint selector uses
it). The legacy `AppTheme.*` constants remain as the dark palette values and
stay correct in the default dark mode.

### `ThemeMode` persistence

`Settings` gains a `ThemeModePreference` field (a `material`-free enum:
`system` / `light` / `dark`), serialized as `themeMode` in the settings JSON.
`SettingsNotifier.updateThemeMode` persists it, and `SatoneroApp` maps the
preference to Flutter's `ThemeMode` on the root `MaterialApp.router`:

```dart
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: switch (themePreference) { ... },
```

The default is `ThemeModePreference.dark`, preserving the app's historical
dark-only appearance for existing installs.

## Light-mode migration status (staged)

The app originally shipped dark-only, so ~750 widget references still use the
`AppTheme.*` dark constants directly. Those constants were re-tuned to the OLED
palette, so the dark default stays correct, while light mode is adopted
progressively:

- **Theme-driven surfaces** (any widget using `Theme.of(context)` colours) and
  the migrated shell — `SatoneroAppBar`, `BottomNavBar`, and the settings
  screen's scaffold/AppBar/Appearance card — render correctly in both modes.
- **Remaining screens** still read the dark constants and keep their dark look
  until they are migrated to `AppTheme.colors(context)`.

Migration rule: replace `AppTheme.<token>` with the matching `AppColors` token
and drop `const` where the expression is no longer compile-time constant.

## Settings UI

The Settings screen exposes an **Appearance** card with a `SegmentedButton`
(System / Light / Dark). New user-facing strings live in `lib/l10n/`
(`appearance`, `appearanceDescription`, `themeSystem`, `themeLight`,
`themeDark`).

## License note

This theme is a pure Flutter colour system written from scratch; it uses no
third-party design assets or code.

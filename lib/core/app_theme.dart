import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic color tokens for a Satonero theme.
///
/// Exposed through Flutter's `ThemeExtension` mechanism so a widget can resolve
/// the correct color for the active [ThemeMode] via
/// `Theme.of(context).extension<AppColors>()!` instead of hardcoding a palette.
/// Both variants ship in this one file; the design intentionally stays a pure
/// color system (no assets, no icons) so it never depends on third-party
/// design code.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.inputBackground,
    required this.navBarBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInactive,
    required this.divider,
    required this.accent,
    required this.lightningBlue,
    required this.lightningYellow,
  });

  /// Main screen background. Deep OLED black in dark mode.
  final Color scaffoldBackground;

  /// Elevated surface color for cards and dialogs.
  final Color cardBackground;

  /// Field / embedded-control background.
  final Color inputBackground;

  /// Bottom navigation bar background.
  final Color navBarBackground;

  final Color textPrimary;
  final Color textSecondary;
  final Color textInactive;

  /// Hairline separators (borders between cards / app bar / nav bar).
  final Color divider;

  /// Primary brand accent: Bitcoin orange.
  final Color accent;

  /// Lightning-network electric blue accent.
  final Color lightningBlue;

  /// Lightning-network yellow accent.
  final Color lightningYellow;

  /// High-contrast light palette.
  static const AppColors light = AppColors(
    scaffoldBackground: Color(0xFFF7F7F8),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFEFEFF1),
    navBarBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF4B4B52),
    textInactive: Color(0xFF8A8A92),
    divider: Color(0xFFE3E3E6),
    accent: Color(0xFFF7931A),
    lightningBlue: Color(0xFF2979FF),
    lightningYellow: Color(0xFFF3CA29),
  );

  /// Deep OLED dark palette.
  static const AppColors dark = AppColors(
    scaffoldBackground: Color(0xFF000000),
    cardBackground: Color(0xFF121212),
    inputBackground: Color(0xFF1C1C1C),
    navBarBackground: Color(0xFF0A0A0A),
    textPrimary: Color(0xFFF9F8F1),
    textSecondary: Color(0xFFCCCCCC),
    textInactive: Color(0xFF8A8D98),
    divider: Color(0xFF1F1F1F),
    accent: Color(0xFFF7931A),
    lightningBlue: Color(0xFF2979FF),
    lightningYellow: Color(0xFFF3CA29),
  );

  @override
  AppColors copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? inputBackground,
    Color? navBarBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textInactive,
    Color? divider,
    Color? accent,
    Color? lightningBlue,
    Color? lightningYellow,
  }) {
    return AppColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textInactive: textInactive ?? this.textInactive,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      lightningBlue: lightningBlue ?? this.lightningBlue,
      lightningYellow: lightningYellow ?? this.lightningYellow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      navBarBackground:
          Color.lerp(navBarBackground, other.navBarBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textInactive: Color.lerp(textInactive, other.textInactive, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      lightningBlue: Color.lerp(lightningBlue, other.lightningBlue, t)!,
      lightningYellow: Color.lerp(lightningYellow, other.lightningYellow, t)!,
    );
  }
}

class AppTheme {
  // Brand accents
  /// Bitcoin orange, the Satonero primary accent.
  static const Color bitcoinOrange = Color(0xFFF7931A);

  /// Kept as an alias so the ~100 existing `AppTheme.satoneroOrange` references
  /// resolve to the Bitcoin orange identity without a mechanical rename.
  static const Color satoneroOrange = bitcoinOrange;

  /// Lightning electric blue accent.
  static const Color lightningBlue = Color(0xFF2979FF);

  /// Lightning yellow accent.
  static const Color lightningYellow = Color(0xFFF3CA29);

  // Original colors (dark palette)
  static const Color grey = Color(0xFFCCCCCC);
  static const Color grey2 = Color(0xFF92949A);
  static const Color yellow = Color(0xFFF3CA29);

  /// Red color for destructive actions, sell buttons, and critical operations
  /// Use for: Cancel buttons, dispute buttons, sell actions, inactive states
  static const Color red1 = Color(0xFFD84D4D);

  // Colors for backgrounds — deep OLED blacks.
  static const Color dark1 = Color(0xFF0A0A0A);
  static const Color dark2 = Color(0xFF1A1A1A);
  static const Color cream1 = Color(0xFFF9F8F1);

  // New colors

  // Colors for backgrounds
  static const Color backgroundDark = Color(0xFF000000); // OLED main background
  static const Color backgroundCard = Color(0xFF121212);
  static const Color backgroundInput = Color(0xFF1C1C1C);
  static const Color backgroundInactive = Color(0xFF1F1F1F);
  static const Color backgroundNavBar = Color(0xFF0A0A0A);

  // Colors for text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textInactive = Color(0xFF8A8D98);
  static const Color textSubtle = Colors.white60;

  // Colors for actions
  static const Color buyColor = satoneroOrange;
  static const Color sellColor = Color(0xFFFF8A8A);
  static const Color activeColor = satoneroOrange;

  /// Purple color for accent elements, buttons, and decorative UI elements
  /// Use for: Submit buttons, message bubbles, section accents, interactive elements
  static const Color purpleButton = Color(0xFF7856AF);

  // Colors for states
  static const Color statusSuccess = satoneroOrange;
  static const Color statusWarning = Color(0xFFF3CA29);

  /// Red color for error states, validation failures, and error notifications
  /// Use for: Error messages, failed operations, validation errors
  static const Color statusError = Color(0xFFEF6A6A);

  static const Color statusActive = satoneroOrange;
  static const Color statusInfo = Color.fromARGB(255, 42, 123, 214);

  // Colors for role chips
  static const Color createdByYouChip =
      Color(0xFF1565C0); // Colors.blue.shade700
  static const Color takenByYouChip = Color(0xFF00796B); // Colors.teal.shade700
  static const Color premiumPositiveChip =
      Color(0xFF388E3C); // Colors.green.shade700
  static const Color premiumNegativeChip =
      Color(0xFFC62828); // Colors.red.shade700

  // Colors for status chips
  static const Color statusPendingBackground = Color(0xFF854D0E);
  static const Color statusPendingText = Color(0xFFFCD34D);
  static const Color statusWaitingBackground = Color(0xFF7C2D12);
  static const Color statusWaitingText = Color(0xFFFED7AA);
  static const Color statusActiveBackground = Color(0xFF1E3A8A);
  static const Color statusActiveText = Color(0xFF93C5FD);
  static const Color statusSuccessBackground = Color(0xFF065F46);
  static const Color statusSuccessText = Color(0xFF6EE7B7);
  static const Color statusDisputeBackground = Color(0xFF7F1D1D);
  static const Color statusDisputeText = Color(0xFFFCA5A5);
  static const Color statusSettledBackground = Color(0xFF581C87);
  static const Color statusSettledText = Color(0xFFC084FC);
  static const Color statusInactiveBackground =
      Color(0xFF1F2937); // Colors.grey.shade800
  static const Color statusInactiveText =
      Color(0xFFD1D5DB); // Colors.grey.shade300

  // Text colors
  static const Color secondaryText = Color(0xFFBDBDBD); // Colors.grey.shade400

  // Padding  and margin constants
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets mediumPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);

  static const EdgeInsets smallMargin = EdgeInsets.all(4.0);
  static const EdgeInsets mediumMargin =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
  static const EdgeInsets largeMargin = EdgeInsets.all(20.0);

  /// Built once: `ThemeData` is immutable and this is read on every rebuild
  /// of the root `MaterialApp`, the drawer and the reactive buttons. A getter
  /// rebuilt the whole theme (plus ~20 `GoogleFonts` descriptors) per access.
  static final ThemeData darkTheme = _buildDarkTheme();
  static final ThemeData lightTheme = _buildLightTheme();

  /// Backward-compatible alias: the app's default (dark) theme.
  static final ThemeData theme = darkTheme;

  /// Resolves the semantic palette for the active theme. Falls back to the
  /// dark tokens when the extension is absent (e.g. in a bare test harness).
  static AppColors colors(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? AppColors.dark;

  static ThemeData _buildDarkTheme() {
    return _buildThemeData(
      brightness: Brightness.dark,
      colors: AppColors.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  static ThemeData _buildLightTheme() {
    return _buildThemeData(
      brightness: Brightness.light,
      colors: AppColors.light,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  static ThemeData _buildThemeData({
    required Brightness brightness,
    required AppColors colors,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      extensions: [colors],
      hoverColor: isDark ? dark1 : Colors.black12,
      primaryColor: satoneroOrange,
      colorScheme: ColorScheme.fromSeed(
        seedColor: satoneroOrange,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: systemOverlayStyle,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: colors.textPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBackground,
        titleTextStyle: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
          color: colors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.robotoCondensed(
          fontWeight: FontWeight.w400,
          fontSize: 16.0,
          color: colors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: _buildTextTheme(colors.textPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: satoneroOrange,
          textStyle: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          fixedSize: const Size.fromHeight(48),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: satoneroOrange,
          textStyle: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: satoneroOrange,
          side: const BorderSide(color: satoneroOrange),
          textStyle: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textInactive),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.textSecondary),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: satoneroOrange),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.divider),
        ),
      ),
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: 24.0,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(
          color: colors.textSecondary,
          fontFamily: GoogleFonts.robotoCondensed().fontFamily,
        ),
      ),
      dividerColor: colors.divider,
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.robotoCondensedTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24.0,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20.0,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.0,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18.0,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 16.0,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14.0,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.0,
        ),
      ),
    ).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }

  // helpers for shadows
  static final List<BoxShadow> cardShadow = List.unmodifiable([
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.7),
      blurRadius: 15,
      offset: const Offset(0, 5),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.07),
      blurRadius: 1,
      offset: const Offset(0, -1),
      spreadRadius: 0,
    ),
  ]);

  static final List<BoxShadow> buttonShadow = List.unmodifiable([
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 6,
      offset: const Offset(0, 3),
      spreadRadius: -2,
    ),
  ]);
}

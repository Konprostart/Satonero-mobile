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
    required this.textSubtle,
    required this.divider,
    required this.accent,
    required this.lightningBlue,
    required this.sell,
    required this.danger,
    required this.info,
    required this.purple,
    required this.warning,
    required this.onAccent,
    required this.onDanger,
    required this.success,
    required this.qrBackground,
    required this.qrForeground,
    required this.statusPendingBackground,
    required this.statusPendingText,
    required this.statusWaitingBackground,
    required this.statusWaitingText,
    required this.statusActiveBackground,
    required this.statusActiveText,
    required this.statusSuccessBackground,
    required this.statusSuccessText,
    required this.statusDisputeBackground,
    required this.statusDisputeText,
    required this.statusSettledBackground,
    required this.statusSettledText,
    required this.statusInactiveBackground,
    required this.statusInactiveText,
    required this.createdByYouChip,
    required this.takenByYouChip,
    required this.premiumPositiveChip,
    required this.premiumNegativeChip,
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

  /// Low-emphasis text (timestamps, hints). White60 / black54.
  final Color textSubtle;

  /// Hairline separators (borders between cards / app bar / nav bar).
  final Color divider;

  /// Primary brand accent: Bitcoin orange.
  final Color accent;

  /// Lightning-network electric blue accent.
  final Color lightningBlue;

  /// Sell / negative-action accent.
  final Color sell;

  /// Error and destructive-action red.
  final Color danger;

  /// Informational blue.
  final Color info;

  /// Decorative / interactive purple accent.
  final Color purple;

  /// Warning accent (Bitcoin orange; darkened in light mode for contrast).
  final Color warning;

  /// Foreground (text/icon) on the Bitcoin-orange accent. Fixed black in both
  /// modes so it always contrasts against the brand orange.
  final Color onAccent;

  /// Foreground on danger/sell/error fills. Fixed white in both modes.
  final Color onDanger;

  /// Success green for positive indicators. Brighter in dark mode and deeper
  /// in light mode for contrast on each surface.
  final Color success;

  /// QR-code quiet zone. Always white regardless of theme so scanners can read
  /// the code (drawn with [qrForeground] modules).
  final Color qrBackground;

  /// QR-code modules. Always near-black regardless of theme for scannability.
  final Color qrForeground;

  // Order status chip pairs (background + foreground).
  final Color statusPendingBackground;
  final Color statusPendingText;
  final Color statusWaitingBackground;
  final Color statusWaitingText;
  final Color statusActiveBackground;
  final Color statusActiveText;
  final Color statusSuccessBackground;
  final Color statusSuccessText;
  final Color statusDisputeBackground;
  final Color statusDisputeText;
  final Color statusSettledBackground;
  final Color statusSettledText;
  final Color statusInactiveBackground;
  final Color statusInactiveText;

  // Role / premium chips (white text on a saturated fill, same in both modes).
  final Color createdByYouChip;
  final Color takenByYouChip;
  final Color premiumPositiveChip;
  final Color premiumNegativeChip;

  /// High-contrast light palette.
  static const AppColors light = AppColors(
    scaffoldBackground: Color(0xFFF7F7F8),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFEFEFF1),
    navBarBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF4B4B52),
    textInactive: Color(0xFF8A8A92),
    textSubtle: Color(0x8A000000),
    divider: Color(0xFFE3E3E6),
    accent: Color(0xFFF7931A),
    lightningBlue: Color(0xFF2979FF),
    sell: Color(0xFFC62828),
    danger: Color(0xFFC62828),
    info: Color(0xFF1565C0),
    purple: Color(0xFF5E35B1),
    warning: Color(0xFFB45309),
    onAccent: Color(0xFF000000),
    onDanger: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D32),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF000000),
    statusPendingBackground: Color(0xFFFDE8D0),
    statusPendingText: Color(0xFF9A5B12),
    statusWaitingBackground: Color(0xFFFDE8D0),
    statusWaitingText: Color(0xFF9A5B12),
    statusActiveBackground: Color(0xFFDBEAFE),
    statusActiveText: Color(0xFF1E40AF),
    statusSuccessBackground: Color(0xFFD1FAE5),
    statusSuccessText: Color(0xFF065F46),
    statusDisputeBackground: Color(0xFFFEE2E2),
    statusDisputeText: Color(0xFF991B1B),
    statusSettledBackground: Color(0xFFF3E8FF),
    statusSettledText: Color(0xFF6B21A8),
    statusInactiveBackground: Color(0xFFE5E7EB),
    statusInactiveText: Color(0xFF374151),
    createdByYouChip: Color(0xFF1565C0),
    takenByYouChip: Color(0xFF00796B),
    premiumPositiveChip: Color(0xFF388E3C),
    premiumNegativeChip: Color(0xFFC62828),
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
    textSubtle: Color(0x99FFFFFF),
    divider: Color(0xFF1F1F1F),
    accent: Color(0xFFF7931A),
    lightningBlue: Color(0xFF2979FF),
    sell: Color(0xFFFF8A8A),
    danger: Color(0xFFEF6A6A),
    info: Color(0xFF2A7BD6),
    purple: Color(0xFF7856AF),
    warning: Color(0xFFF7931A),
    onAccent: Color(0xFF000000),
    onDanger: Color(0xFFFFFFFF),
    success: Color(0xFF4CAF50),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF000000),
    statusPendingBackground: Color(0xFF3A2A14),
    statusPendingText: Color(0xFFF7931A),
    statusWaitingBackground: Color(0xFF3A2A14),
    statusWaitingText: Color(0xFFF0A55C),
    statusActiveBackground: Color(0xFF1E3A8A),
    statusActiveText: Color(0xFF93C5FD),
    statusSuccessBackground: Color(0xFF065F46),
    statusSuccessText: Color(0xFF6EE7B7),
    statusDisputeBackground: Color(0xFF7F1D1D),
    statusDisputeText: Color(0xFFFCA5A5),
    statusSettledBackground: Color(0xFF581C87),
    statusSettledText: Color(0xFFC084FC),
    statusInactiveBackground: Color(0xFF1F2937),
    statusInactiveText: Color(0xFFD1D5DB),
    createdByYouChip: Color(0xFF1565C0),
    takenByYouChip: Color(0xFF00796B),
    premiumPositiveChip: Color(0xFF388E3C),
    premiumNegativeChip: Color(0xFFC62828),
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
    Color? textSubtle,
    Color? divider,
    Color? accent,
    Color? lightningBlue,
    Color? sell,
    Color? danger,
    Color? info,
    Color? purple,
    Color? warning,
    Color? onAccent,
    Color? onDanger,
    Color? success,
    Color? qrBackground,
    Color? qrForeground,
    Color? statusPendingBackground,
    Color? statusPendingText,
    Color? statusWaitingBackground,
    Color? statusWaitingText,
    Color? statusActiveBackground,
    Color? statusActiveText,
    Color? statusSuccessBackground,
    Color? statusSuccessText,
    Color? statusDisputeBackground,
    Color? statusDisputeText,
    Color? statusSettledBackground,
    Color? statusSettledText,
    Color? statusInactiveBackground,
    Color? statusInactiveText,
    Color? createdByYouChip,
    Color? takenByYouChip,
    Color? premiumPositiveChip,
    Color? premiumNegativeChip,
  }) {
    return AppColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textInactive: textInactive ?? this.textInactive,
      textSubtle: textSubtle ?? this.textSubtle,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      lightningBlue: lightningBlue ?? this.lightningBlue,
      sell: sell ?? this.sell,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      purple: purple ?? this.purple,
      warning: warning ?? this.warning,
      onAccent: onAccent ?? this.onAccent,
      onDanger: onDanger ?? this.onDanger,
      success: success ?? this.success,
      qrBackground: qrBackground ?? this.qrBackground,
      qrForeground: qrForeground ?? this.qrForeground,
      statusPendingBackground:
          statusPendingBackground ?? this.statusPendingBackground,
      statusPendingText: statusPendingText ?? this.statusPendingText,
      statusWaitingBackground:
          statusWaitingBackground ?? this.statusWaitingBackground,
      statusWaitingText: statusWaitingText ?? this.statusWaitingText,
      statusActiveBackground:
          statusActiveBackground ?? this.statusActiveBackground,
      statusActiveText: statusActiveText ?? this.statusActiveText,
      statusSuccessBackground:
          statusSuccessBackground ?? this.statusSuccessBackground,
      statusSuccessText: statusSuccessText ?? this.statusSuccessText,
      statusDisputeBackground:
          statusDisputeBackground ?? this.statusDisputeBackground,
      statusDisputeText: statusDisputeText ?? this.statusDisputeText,
      statusSettledBackground:
          statusSettledBackground ?? this.statusSettledBackground,
      statusSettledText: statusSettledText ?? this.statusSettledText,
      statusInactiveBackground:
          statusInactiveBackground ?? this.statusInactiveBackground,
      statusInactiveText: statusInactiveText ?? this.statusInactiveText,
      createdByYouChip: createdByYouChip ?? this.createdByYouChip,
      takenByYouChip: takenByYouChip ?? this.takenByYouChip,
      premiumPositiveChip: premiumPositiveChip ?? this.premiumPositiveChip,
      premiumNegativeChip: premiumNegativeChip ?? this.premiumNegativeChip,
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
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      lightningBlue: Color.lerp(lightningBlue, other.lightningBlue, t)!,
      sell: Color.lerp(sell, other.sell, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      success: Color.lerp(success, other.success, t)!,
      qrBackground: Color.lerp(qrBackground, other.qrBackground, t)!,
      qrForeground: Color.lerp(qrForeground, other.qrForeground, t)!,
      statusPendingBackground: Color.lerp(
          statusPendingBackground, other.statusPendingBackground, t)!,
      statusPendingText:
          Color.lerp(statusPendingText, other.statusPendingText, t)!,
      statusWaitingBackground: Color.lerp(
          statusWaitingBackground, other.statusWaitingBackground, t)!,
      statusWaitingText:
          Color.lerp(statusWaitingText, other.statusWaitingText, t)!,
      statusActiveBackground:
          Color.lerp(statusActiveBackground, other.statusActiveBackground, t)!,
      statusActiveText:
          Color.lerp(statusActiveText, other.statusActiveText, t)!,
      statusSuccessBackground: Color.lerp(
          statusSuccessBackground, other.statusSuccessBackground, t)!,
      statusSuccessText:
          Color.lerp(statusSuccessText, other.statusSuccessText, t)!,
      statusDisputeBackground: Color.lerp(
          statusDisputeBackground, other.statusDisputeBackground, t)!,
      statusDisputeText:
          Color.lerp(statusDisputeText, other.statusDisputeText, t)!,
      statusSettledBackground: Color.lerp(
          statusSettledBackground, other.statusSettledBackground, t)!,
      statusSettledText:
          Color.lerp(statusSettledText, other.statusSettledText, t)!,
      statusInactiveBackground: Color.lerp(
          statusInactiveBackground, other.statusInactiveBackground, t)!,
      statusInactiveText:
          Color.lerp(statusInactiveText, other.statusInactiveText, t)!,
      createdByYouChip:
          Color.lerp(createdByYouChip, other.createdByYouChip, t)!,
      takenByYouChip: Color.lerp(takenByYouChip, other.takenByYouChip, t)!,
      premiumPositiveChip:
          Color.lerp(premiumPositiveChip, other.premiumPositiveChip, t)!,
      premiumNegativeChip:
          Color.lerp(premiumNegativeChip, other.premiumNegativeChip, t)!,
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

  // Original colors (dark palette)
  static const Color grey = Color(0xFFCCCCCC);
  static const Color grey2 = Color(0xFF92949A);

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

  // Colors for status chips (Bitcoin orange, no yellow).
  static const Color statusPendingBackground = Color(0xFF3A2A14);
  static const Color statusPendingText = Color(0xFFF7931A);
  static const Color statusWaitingBackground = Color(0xFF3A2A14);
  static const Color statusWaitingText = Color(0xFFF0A55C);
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
      colorScheme: _buildColorScheme(brightness: brightness, colors: colors),
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
          foregroundColor: colors.onAccent,
          backgroundColor: satoneroOrange,
          elevation: 0,
          textStyle: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          fixedSize: const Size.fromHeight(48),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: satoneroOrange,
        foregroundColor: colors.onAccent,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textPrimary;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.divider;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.accent;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.onAccent;
            }
            return colors.textPrimary;
          }),
          iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.onAccent;
            }
            return colors.textPrimary;
          }),
          side: WidgetStateProperty.all(BorderSide(color: colors.divider)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accent,
        unselectedLabelColor: colors.textInactive,
        indicatorColor: colors.accent,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: colors.onAccent,
        fillColor: colors.accent,
        color: colors.textPrimary,
        borderColor: colors.divider,
        selectedBorderColor: colors.accent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.onAccent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.textInactive;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textInactive,
        backgroundColor: colors.navBarBackground,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navBarBackground,
        indicatorColor: colors.accent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.onAccent);
          }
          return IconThemeData(color: colors.textInactive);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.onAccent
                : colors.textInactive,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }

  /// Builds an explicit [ColorScheme] with no amber/yellow tones.
  ///
  /// The previous `ColorScheme.fromSeed` derived `secondaryContainer` and
  /// `tertiary` from the orange seed, producing amber/yellow fills that leaked
  /// into `SegmentedButton`, `Switch` and other Material widgets which read the
  /// scheme instead of the semantic [AppColors] tokens. Pinning the scheme to
  /// Bitcoin orange, neutral greys and Lightning blue guarantees a clean OLED
  /// look on every interactive element in both brightness modes.
  static ColorScheme _buildColorScheme({
    required Brightness brightness,
    required AppColors colors,
  }) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        primaryContainer: const Color(0xFF3A2A14),
        onPrimaryContainer: const Color(0xFFF0A55C),
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        secondaryContainer: const Color(0xFF1F1F1F),
        onSecondaryContainer: colors.textPrimary,
        tertiary: colors.lightningBlue,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: const Color(0xFF1E3A8A),
        onTertiaryContainer: const Color(0xFF93C5FD),
        error: colors.danger,
        onError: colors.onDanger,
        errorContainer: const Color(0xFF7F1D1D),
        onErrorContainer: const Color(0xFFFCA5A5),
        surface: colors.scaffoldBackground,
        onSurface: colors.textPrimary,
        outline: const Color(0xFF3A3A3A),
        outlineVariant: const Color(0xFF1F1F1F),
        inversePrimary: const Color(0xFF9A5B12),
        surfaceTint: Colors.transparent,
      );
    }
    return ColorScheme.light(
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: const Color(0xFFFDE8D0),
      onPrimaryContainer: const Color(0xFF9A5B12),
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      secondaryContainer: const Color(0xFFFDE8D0),
      onSecondaryContainer: const Color(0xFF9A5B12),
      tertiary: colors.info,
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFDBEAFE),
      onTertiaryContainer: const Color(0xFF1E40AF),
      error: colors.danger,
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF991B1B),
      surface: colors.scaffoldBackground,
      onSurface: colors.textPrimary,
      outline: const Color(0xFF8A8A92),
      outlineVariant: const Color(0xFFE3E3E6),
      inversePrimary: const Color(0xFFF0A55C),
      surfaceTint: Colors.transparent,
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

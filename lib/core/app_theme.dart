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

  /// Primary accent. Pure white on dark, pure black on light (Zen monochrome).
  final Color accent;

  /// Lightning accent, unified with [accent] in the monochrome identity.
  final Color lightningBlue;

  /// Sell / negative-action accent.
  final Color sell;

  /// Error and destructive-action accent.
  final Color danger;

  /// Informational accent.
  final Color info;

  /// Decorative / interactive accent.
  final Color purple;

  /// Warning accent.
  final Color warning;

  /// Foreground (text/icon) drawn on the [accent] fill. Flips per mode so the
  /// white-on-black / black-on-white contrast always holds.
  final Color onAccent;

  /// Foreground on danger/sell/error fills. Flips per mode like [onAccent].
  final Color onDanger;

  /// Success accent for positive indicators.
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

  /// High-contrast light palette. Strictly monochrome: pure white surfaces,
  /// pure black text and accents, and neutral grey for secondary emphasis.
  static const AppColors light = AppColors(
    scaffoldBackground: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFF5F5F5),
    navBarBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF3A3A3A),
    textInactive: Color(0xFF8A8A8A),
    textSubtle: Color(0x8A000000),
    divider: Color(0xFFE5E5E5),
    accent: Color(0xFF000000),
    lightningBlue: Color(0xFF000000),
    sell: Color(0xFF000000),
    danger: Color(0xFF000000),
    info: Color(0xFF000000),
    purple: Color(0xFF000000),
    warning: Color(0xFF000000),
    onAccent: Color(0xFFFFFFFF),
    onDanger: Color(0xFFFFFFFF),
    success: Color(0xFF000000),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF000000),
    statusPendingBackground: Color(0xFFF0F0F0),
    statusPendingText: Color(0xFF000000),
    statusWaitingBackground: Color(0xFFF0F0F0),
    statusWaitingText: Color(0xFF3A3A3A),
    statusActiveBackground: Color(0xFFF0F0F0),
    statusActiveText: Color(0xFF000000),
    statusSuccessBackground: Color(0xFFF0F0F0),
    statusSuccessText: Color(0xFF000000),
    statusDisputeBackground: Color(0xFFF0F0F0),
    statusDisputeText: Color(0xFF000000),
    statusSettledBackground: Color(0xFFF0F0F0),
    statusSettledText: Color(0xFF000000),
    statusInactiveBackground: Color(0xFFF0F0F0),
    statusInactiveText: Color(0xFF8A8A8A),
    createdByYouChip: Color(0xFF000000),
    takenByYouChip: Color(0xFF000000),
    premiumPositiveChip: Color(0xFF000000),
    premiumNegativeChip: Color(0xFF000000),
  );

  /// Deep OLED dark palette. Strictly monochrome: pure black surfaces, pure
  /// white text and accents, and neutral grey for secondary emphasis.
  static const AppColors dark = AppColors(
    scaffoldBackground: Color(0xFF000000),
    cardBackground: Color(0xFF0A0A0A),
    inputBackground: Color(0xFF141414),
    navBarBackground: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textInactive: Color(0xFF8A8D98),
    textSubtle: Color(0x99FFFFFF),
    divider: Color(0xFF2A2A2A),
    accent: Color(0xFFFFFFFF),
    lightningBlue: Color(0xFFFFFFFF),
    sell: Color(0xFFFFFFFF),
    danger: Color(0xFFFFFFFF),
    info: Color(0xFFFFFFFF),
    purple: Color(0xFFFFFFFF),
    warning: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    onDanger: Color(0xFF000000),
    success: Color(0xFFFFFFFF),
    qrBackground: Color(0xFFFFFFFF),
    qrForeground: Color(0xFF000000),
    statusPendingBackground: Color(0xFF1A1A1A),
    statusPendingText: Color(0xFFFFFFFF),
    statusWaitingBackground: Color(0xFF1A1A1A),
    statusWaitingText: Color(0xFFCCCCCC),
    statusActiveBackground: Color(0xFF1A1A1A),
    statusActiveText: Color(0xFFFFFFFF),
    statusSuccessBackground: Color(0xFF1A1A1A),
    statusSuccessText: Color(0xFFFFFFFF),
    statusDisputeBackground: Color(0xFF1A1A1A),
    statusDisputeText: Color(0xFFFFFFFF),
    statusSettledBackground: Color(0xFF1A1A1A),
    statusSettledText: Color(0xFFFFFFFF),
    statusInactiveBackground: Color(0xFF1A1A1A),
    statusInactiveText: Color(0xFF8A8D98),
    createdByYouChip: Color(0xFFFFFFFF),
    takenByYouChip: Color(0xFFFFFFFF),
    premiumPositiveChip: Color(0xFFFFFFFF),
    premiumNegativeChip: Color(0xFFFFFFFF),
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
  // Brand accents — monochrome (Zen identity): white in dark, black in light.
  /// Primary accent. Legacy alias kept for compatibility; resolves to white so
  /// no coloured tone ever renders.
  static const Color bitcoinOrange = Color(0xFFFFFFFF);

  /// Legacy alias of [bitcoinOrange]; kept so existing references stay valid
  /// without a mechanical rename while still resolving to a monochrome accent.
  static const Color satoneroOrange = bitcoinOrange;

  /// Legacy Lightning accent, unified with the monochrome accent.
  static const Color lightningBlue = Color(0xFFFFFFFF);

  // Original colors (dark palette)
  static const Color grey = Color(0xFFCCCCCC);
  static const Color grey2 = Color(0xFF92949A);

  /// Destructive-action accent (monochrome).
  static const Color red1 = Color(0xFFFFFFFF);

  // Colors for backgrounds — deep OLED blacks.
  static const Color dark1 = Color(0xFF0A0A0A);
  static const Color dark2 = Color(0xFF1A1A1A);
  static const Color cream1 = Color(0xFFFFFFFF);

  // New colors

  // Colors for backgrounds
  static const Color backgroundDark = Color(0xFF000000); // OLED main background
  static const Color backgroundCard = Color(0xFF0A0A0A);
  static const Color backgroundInput = Color(0xFF141414);
  static const Color backgroundInactive = Color(0xFF2A2A2A);
  static const Color backgroundNavBar = Color(0xFF000000);

  // Colors for text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textInactive = Color(0xFF8A8D98);
  static const Color textSubtle = Colors.white60;

  // Colors for actions
  static const Color buyColor = satoneroOrange;
  static const Color sellColor = Color(0xFFFFFFFF);
  static const Color activeColor = satoneroOrange;

  /// Accent for buttons and decorative elements (monochrome).
  static const Color purpleButton = Color(0xFFFFFFFF);

  // Colors for states
  static const Color statusSuccess = satoneroOrange;

  /// Accent for error states, validation failures, and error notifications.
  static const Color statusError = Color(0xFFFFFFFF);

  static const Color statusActive = satoneroOrange;
  static const Color statusInfo = Color(0xFFFFFFFF);

  // Colors for role chips (monochrome).
  static const Color createdByYouChip = Color(0xFFFFFFFF);
  static const Color takenByYouChip = Color(0xFFFFFFFF);
  static const Color premiumPositiveChip = Color(0xFFFFFFFF);
  static const Color premiumNegativeChip = Color(0xFFFFFFFF);

  // Colors for status chips (monochrome).
  static const Color statusPendingBackground = Color(0xFF1A1A1A);
  static const Color statusPendingText = Color(0xFFFFFFFF);
  static const Color statusWaitingBackground = Color(0xFF1A1A1A);
  static const Color statusWaitingText = Color(0xFFCCCCCC);
  static const Color statusActiveBackground = Color(0xFF1A1A1A);
  static const Color statusActiveText = Color(0xFFFFFFFF);
  static const Color statusSuccessBackground = Color(0xFF1A1A1A);
  static const Color statusSuccessText = Color(0xFFFFFFFF);
  static const Color statusDisputeBackground = Color(0xFF1A1A1A);
  static const Color statusDisputeText = Color(0xFFFFFFFF);
  static const Color statusSettledBackground = Color(0xFF1A1A1A);
  static const Color statusSettledText = Color(0xFFFFFFFF);
  static const Color statusInactiveBackground = Color(0xFF1A1A1A);
  static const Color statusInactiveText = Color(0xFF8A8D98);

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
      primaryColor: colors.accent,
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
          backgroundColor: colors.accent,
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
          foregroundColor: colors.accent,
          textStyle: GoogleFonts.robotoCondensed(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent),
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
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accent),
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
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.onAccent;
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

  /// Builds an explicit, fully monochrome [ColorScheme].
  ///
  /// Every hue is eliminated: `primary`/`secondary` resolve to the pure accent
  /// (white on dark, black on light), `tertiary` and the container surfaces to
  /// neutral greys, and `error` to the same accent so no semantic state can
  /// reintroduce a coloured tone. `surfaceTint` is transparent so cards stay
  /// pure black (dark) / pure white (light).
  static ColorScheme _buildColorScheme({
    required Brightness brightness,
    required AppColors colors,
  }) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        primaryContainer: const Color(0xFF1A1A1A),
        onPrimaryContainer: const Color(0xFFFFFFFF),
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        secondaryContainer: const Color(0xFF1A1A1A),
        onSecondaryContainer: const Color(0xFFFFFFFF),
        tertiary: colors.textSecondary,
        onTertiary: const Color(0xFF000000),
        tertiaryContainer: const Color(0xFF1A1A1A),
        onTertiaryContainer: const Color(0xFFFFFFFF),
        error: colors.danger,
        onError: colors.onDanger,
        errorContainer: const Color(0xFF1A1A1A),
        onErrorContainer: const Color(0xFFFFFFFF),
        surface: colors.scaffoldBackground,
        onSurface: colors.textPrimary,
        outline: const Color(0xFF3A3A3A),
        outlineVariant: const Color(0xFF2A2A2A),
        inversePrimary: const Color(0xFF000000),
        inverseSurface: const Color(0xFFFFFFFF),
        onInverseSurface: const Color(0xFF000000),
        surfaceTint: Colors.transparent,
      );
    }
    return ColorScheme.light(
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: const Color(0xFFF0F0F0),
      onPrimaryContainer: const Color(0xFF000000),
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      secondaryContainer: const Color(0xFFF0F0F0),
      onSecondaryContainer: const Color(0xFF000000),
      tertiary: colors.textSecondary,
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFF0F0F0),
      onTertiaryContainer: const Color(0xFF000000),
      error: colors.danger,
      onError: colors.onDanger,
      errorContainer: const Color(0xFFF0F0F0),
      onErrorContainer: const Color(0xFF000000),
      surface: colors.scaffoldBackground,
      onSurface: colors.textPrimary,
      outline: const Color(0xFFC0C0C0),
      outlineVariant: const Color(0xFFE5E5E5),
      inversePrimary: const Color(0xFFFFFFFF),
      inverseSurface: const Color(0xFF000000),
      onInverseSurface: const Color(0xFFFFFFFF),
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

import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  sunny,
  night,
  emerald,
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final AppThemeMode mode;
  final bool isDark;

  // Primary & Accents
  final Color primary;
  final Color primaryHover;
  final Color primaryLight;
  final Color primaryMuted;
  final Color secondary;
  final Color secondaryLight;

  // Surfaces & Backgrounds
  final Color scaffoldBackground;
  final Color canvas;
  final Color cardBackground;
  final Color surfaceLevel1;
  final Color surfaceLevel2;
  final Color surfaceElevated;

  // Borders & Dividers
  final Color borderSubtle;
  final Color borderLight;

  // Typography
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;

  // Components & Inputs
  final Color fillDisabled;
  final Color tableHeaderBackground;
  final Color inputBackground;
  final Color inputBorder;
  final Color badgeBackground;
  final Color activeGlow;

  const AppThemeColors({
    required this.mode,
    required this.isDark,
    required this.primary,
    required this.primaryHover,
    required this.primaryLight,
    required this.primaryMuted,
    required this.secondary,
    required this.secondaryLight,
    required this.scaffoldBackground,
    required this.canvas,
    required this.cardBackground,
    required this.surfaceLevel1,
    required this.surfaceLevel2,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.fillDisabled,
    required this.tableHeaderBackground,
    required this.inputBackground,
    required this.inputBorder,
    required this.badgeBackground,
    required this.activeGlow,
  });

  // ─── 1. Light Mode (نهاري كلاسيكي - Eyadty Official) ─────────────────────
  static const AppThemeColors light = AppThemeColors(
    mode: AppThemeMode.light,
    isDark: false,
    primary: Color(0xFFE0583E),
    primaryHover: Color(0xFFCD482F),
    primaryLight: Color(0xFFFDEEEB),
    primaryMuted: Color(0xFFF8DDD7),
    secondary: Color(0xFF2D6A4F),
    secondaryLight: Color(0xFFEEF6F2),
    scaffoldBackground: Color(0xFFF6F6F8),
    canvas: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    surfaceLevel1: Color(0xFFF6F6F8),
    surfaceLevel2: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFEAEAEA),
    borderLight: Color(0xFFF0F0F2),
    textPrimary: Color(0xFF121214),
    textSecondary: Color(0xFF7A7A82),
    textMuted: Color(0xFFA6A6AE),
    textInverse: Color(0xFFFFFFFF),
    fillDisabled: Color(0xFFF0F0F2),
    tableHeaderBackground: Color(0xFFF6F6F8),
    inputBackground: Color(0xFFF1F3F6),
    inputBorder: Color(0xFFDDE1E6),
    badgeBackground: Color(0xFFFDEEEB),
    activeGlow: Color(0x33E0583E),
  );

  // ─── 2. Dark Mode (داكن فاحم - Obsidian & Charcoal) ──────────────────────
  static const AppThemeColors dark = AppThemeColors(
    mode: AppThemeMode.dark,
    isDark: true,
    primary: Color(0xFFFF6B50),
    primaryHover: Color(0xFFE0583E),
    primaryLight: Color(0xFF381E19),
    primaryMuted: Color(0xFF2A1713),
    secondary: Color(0xFF34D399),
    secondaryLight: Color(0xFF132A20),
    scaffoldBackground: Color(0xFF0F0F12),
    canvas: Color(0xFF151518),
    cardBackground: Color(0xFF18181D),
    surfaceLevel1: Color(0xFF151518),
    surfaceLevel2: Color(0xFF1F1F26),
    surfaceElevated: Color(0xFF25252D),
    borderSubtle: Color(0xFF2A2A35),
    borderLight: Color(0xFF22222C),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    textInverse: Color(0xFF0F0F12),
    fillDisabled: Color(0xFF1F1F26),
    tableHeaderBackground: Color(0xFF151518),
    inputBackground: Color(0xFF151518),
    inputBorder: Color(0xFF2A2A35),
    badgeBackground: Color(0xFF381E19),
    activeGlow: Color(0x55FF6B50),
  );

  // ─── 3. Sunny Mode (مشمس دافئ - Amber Sand & Sunlit Gold) ────────────────
  static const AppThemeColors sunny = AppThemeColors(
    mode: AppThemeMode.sunny,
    isDark: false,
    primary: Color(0xFFD97706),
    primaryHover: Color(0xFFB45309),
    primaryLight: Color(0xFFFEF3C7),
    primaryMuted: Color(0xFFFDE68A),
    secondary: Color(0xFFB45309),
    secondaryLight: Color(0xFFFFFBEB),
    scaffoldBackground: Color(0xFFFBF8F1),
    canvas: Color(0xFFFFFDF9),
    cardBackground: Color(0xFFFFFFFF),
    surfaceLevel1: Color(0xFFF5EFE3),
    surfaceLevel2: Color(0xFFFFFDF9),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFE8DFC8),
    borderLight: Color(0xFFEFE8D6),
    textPrimary: Color(0xFF291F18),
    textSecondary: Color(0xFF6B584B),
    textMuted: Color(0xFF9E897A),
    textInverse: Color(0xFFFFFFFF),
    fillDisabled: Color(0xFFF1EAD8),
    tableHeaderBackground: Color(0xFFF5EFE3),
    inputBackground: Color(0xFFF6EFE3),
    inputBorder: Color(0xFFE2D6C0),
    badgeBackground: Color(0xFFFEF3C7),
    activeGlow: Color(0x44D97706),
  );

  // ─── 4. Night Mode (ليلي كحلي - Midnight Navy & Cyan Glow) ────────────────
  static const AppThemeColors night = AppThemeColors(
    mode: AppThemeMode.night,
    isDark: true,
    primary: Color(0xFF38BDF8),
    primaryHover: Color(0xFF0284C7),
    primaryLight: Color(0xFF0C2A44),
    primaryMuted: Color(0xFF081F33),
    secondary: Color(0xFF818CF8),
    secondaryLight: Color(0xFF171E3D),
    scaffoldBackground: Color(0xFF0A0F1D),
    canvas: Color(0xFF0E162B),
    cardBackground: Color(0xFF131D38),
    surfaceLevel1: Color(0xFF0E162B),
    surfaceLevel2: Color(0xFF182444),
    surfaceElevated: Color(0xFF1E2C52),
    borderSubtle: Color(0xFF1F2F57),
    borderLight: Color(0xFF1A284A),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textInverse: Color(0xFF0A0F1D),
    fillDisabled: Color(0xFF182444),
    tableHeaderBackground: Color(0xFF0E162B),
    inputBackground: Color(0xFF0E162B),
    inputBorder: Color(0xFF1F2F57),
    badgeBackground: Color(0xFF0C2A44),
    activeGlow: Color(0x5538BDF8),
  );

  // ─── 5. Emerald Clinical (زمردي طبي - Healing Sage & Mint) ────────────────
  static const AppThemeColors emerald = AppThemeColors(
    mode: AppThemeMode.emerald,
    isDark: false,
    primary: Color(0xFF059669),
    primaryHover: Color(0xFF047857),
    primaryLight: Color(0xFFD1FAE5),
    primaryMuted: Color(0xFFA7F3D0),
    secondary: Color(0xFF0D9488),
    secondaryLight: Color(0xFFCCFBF1),
    scaffoldBackground: Color(0xFFF0F6F3),
    canvas: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    surfaceLevel1: Color(0xFFE5EFEA),
    surfaceLevel2: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFD2E3DA),
    borderLight: Color(0xFFDEEDE5),
    textPrimary: Color(0xFF132A20),
    textSecondary: Color(0xFF4A6B5D),
    textMuted: Color(0xFF7A998B),
    textInverse: Color(0xFFFFFFFF),
    fillDisabled: Color(0xFFE2EEE7),
    tableHeaderBackground: Color(0xFFE5EFEA),
    inputBackground: Color(0xFFEAF3EE),
    inputBorder: Color(0xFFC5DCD0),
    badgeBackground: Color(0xFFD1FAE5),
    activeGlow: Color(0x33059669),
  );

  static AppThemeColors forMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.sunny:
        return sunny;
      case AppThemeMode.night:
        return night;
      case AppThemeMode.emerald:
        return emerald;
    }
  }

  @override
  ThemeExtension<AppThemeColors> copyWith({
    AppThemeMode? mode,
    bool? isDark,
    Color? primary,
    Color? primaryHover,
    Color? primaryLight,
    Color? primaryMuted,
    Color? secondary,
    Color? secondaryLight,
    Color? scaffoldBackground,
    Color? canvas,
    Color? cardBackground,
    Color? surfaceLevel1,
    Color? surfaceLevel2,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? fillDisabled,
    Color? tableHeaderBackground,
    Color? inputBackground,
    Color? inputBorder,
    Color? badgeBackground,
    Color? activeGlow,
  }) {
    return AppThemeColors(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      canvas: canvas ?? this.canvas,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceLevel1: surfaceLevel1 ?? this.surfaceLevel1,
      surfaceLevel2: surfaceLevel2 ?? this.surfaceLevel2,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderLight: borderLight ?? this.borderLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      fillDisabled: fillDisabled ?? this.fillDisabled,
      tableHeaderBackground: tableHeaderBackground ?? this.tableHeaderBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      activeGlow: activeGlow ?? this.activeGlow,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      mode: t < 0.5 ? mode : other.mode,
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t) ?? primaryHover,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t) ?? primaryMuted,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t) ?? secondaryLight,
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t) ?? scaffoldBackground,
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      surfaceLevel1: Color.lerp(surfaceLevel1, other.surfaceLevel1, t) ?? surfaceLevel1,
      surfaceLevel2: Color.lerp(surfaceLevel2, other.surfaceLevel2, t) ?? surfaceLevel2,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderLight: Color.lerp(borderLight, other.borderLight, t) ?? borderLight,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textInverse: Color.lerp(textInverse, other.textInverse, t) ?? textInverse,
      fillDisabled: Color.lerp(fillDisabled, other.fillDisabled, t) ?? fillDisabled,
      tableHeaderBackground: Color.lerp(tableHeaderBackground, other.tableHeaderBackground, t) ?? tableHeaderBackground,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t) ?? inputBackground,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t) ?? inputBorder,
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t) ?? badgeBackground,
      activeGlow: Color.lerp(activeGlow, other.activeGlow, t) ?? activeGlow,
    );
  }
}

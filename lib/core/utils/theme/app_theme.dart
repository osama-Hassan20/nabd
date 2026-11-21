import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_theme_mode.dart';

class MyAppTheme {
  /// Resolves the corresponding ThemeData for any AppThemeMode
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.sunny:
        return sunnyTheme;
      case AppThemeMode.night:
        return nightTheme;
      case AppThemeMode.emerald:
        return emeraldTheme;
    }
  }

  static final ThemeData lightTheme = _buildTheme(AppThemeColors.light);
  static final ThemeData darkTheme = _buildTheme(AppThemeColors.dark);
  static final ThemeData sunnyTheme = _buildTheme(AppThemeColors.sunny);
  static final ThemeData nightTheme = _buildTheme(AppThemeColors.night);
  static final ThemeData emeraldTheme = _buildTheme(AppThemeColors.emerald);

  static ThemeData _buildTheme(AppThemeColors colors) {
    final isDark = colors.isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      fontFamily: AppConstants.arabicFontFamily,
      scaffoldBackgroundColor: colors.scaffoldBackground,
      cardColor: colors.cardBackground,
      canvasColor: colors.canvas,
      dividerColor: colors.borderSubtle,
      primaryColor: colors.primary,

      extensions: [colors],

      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.textInverse,
        secondary: colors.primaryLight,
        onSecondary: colors.primary,
        surface: colors.cardBackground,
        onSurface: colors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: colors.borderSubtle,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: colors.cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        contentPadding: const EdgeInsets.all(14.0),
        hintStyle: TextStyle(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderSubtle),
        ),
        hourMinuteColor: colors.primaryLight,
        hourMinuteTextColor: colors.primary,
        hourMinuteTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        dayPeriodColor: colors.primaryLight,
        dayPeriodTextColor: colors.primary,
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.borderSubtle),
        ),
        dayPeriodBorderSide: BorderSide(color: colors.borderSubtle),
        dayPeriodTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        dialHandColor: colors.primary,
        dialBackgroundColor: colors.fillDisabled,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textInverse;
          }
          return colors.textPrimary;
        }),
        dialTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        entryModeIconColor: colors.primary,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: colors.textSecondary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.arabicFontFamily,
          ),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: AppConstants.arabicFontFamily,
          ),
        ),
        helpTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        timeSelectorSeparatorColor: WidgetStateProperty.all(colors.textPrimary),
        timeSelectorSeparatorTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        dividerColor: colors.borderSubtle,
        headerBackgroundColor: colors.primary,
        headerForegroundColor: colors.textInverse,
        headerHeadlineStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.textInverse,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        headerHelpStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.textInverse.withValues(alpha: 0.85),
          fontFamily: AppConstants.arabicFontFamily,
        ),
        weekdayStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        dayStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        yearStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: AppConstants.arabicFontFamily,
        ),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.primaryLight;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textInverse;
          }
          return colors.primary;
        }),
        todayBorder: BorderSide(color: colors.primary, width: 1.5),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textInverse;
          if (states.contains(WidgetState.disabled)) return colors.textMuted;
          return colors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return null;
        }),
        dayOverlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textInverse;
          if (states.contains(WidgetState.disabled)) return colors.textMuted;
          return colors.textPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: colors.textSecondary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppConstants.arabicFontFamily,
          ),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: AppConstants.arabicFontFamily,
          ),
        ),
      ),
    );
  }
}

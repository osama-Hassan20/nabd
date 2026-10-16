import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_colors.dart';

class MyAppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    fontFamily: AppConstants.arabicFontFamily,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.darkBackground,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkBackground,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.primary,
      surface: Colors.white,
      onSurface: AppColors.black,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.grayBorder,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.black,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(14.0),
      hintStyle: const TextStyle(color: AppColors.inputColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.darkBackground),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.darkBackground),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayE2E8F0),
      ),
      hourMinuteColor: AppColors.primaryLight,
      hourMinuteTextColor: AppColors.primary,
      hourMinuteTextStyle: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      dayPeriodColor: AppColors.primaryLight,
      dayPeriodTextColor: AppColors.primary,
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.grayE2E8F0),
      ),
      dayPeriodBorderSide: const BorderSide(color: AppColors.grayE2E8F0),
      dayPeriodTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      dialHandColor: AppColors.primary,
      dialBackgroundColor: AppColors.fillDisableColor,
      dialTextColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.white;
        }
        return AppColors.darkText;
      }),
      dialTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      entryModeIconColor: AppColors.primary,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.gray71717A,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      helpTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.gray71717A,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      timeSelectorSeparatorColor: WidgetStateProperty.all(AppColors.darkText),
      timeSelectorSeparatorTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      dividerColor: AppColors.grayE2E8F0,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: AppColors.white,
      headerHeadlineStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      headerHelpStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.white.withValues(alpha: 0.85),
        fontFamily: AppConstants.arabicFontFamily,
      ),
      weekdayStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.gray71717A,
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

      // ─── Today Styling (Executive Theme Fit) ───────────────────────────────
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.primaryLight;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.white;
        }
        return AppColors.primary;
      }),
      todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),

      // ─── Day Selection & Interaction ───────────────────────────────────────
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.grayMuted;
        return AppColors.darkText;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),
      dayOverlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppColors.primary.withValues(alpha: 0.08);
        }
        return null;
      }),

      // ─── Year Selection ────────────────────────────────────────────────────
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.grayMuted;
        return AppColors.darkText;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),

      // ─── Dialog Actions ────────────────────────────────────────────────────
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.gray71717A,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),

      // ─── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(14.0),
        hintStyle: const TextStyle(color: AppColors.gray7A828E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grayE2E8F0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grayE2E8F0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    fontFamily: AppConstants.arabicFontFamily,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.lightWarm,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lightWarm,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.darkBlue,
      onSecondary: Colors.white,
      surface: AppColors.darkBackground,
      onSurface: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.black,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkBlue,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBlue,
      contentPadding: const EdgeInsets.all(14.0),
      hintStyle: const TextStyle(color: AppColors.grayDim),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.grayDim),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightWarm,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.darkBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBlue),
      ),
      hourMinuteColor: AppColors.darkBlue,
      hourMinuteTextColor: Colors.white,
      hourMinuteTextStyle: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      dayPeriodColor: AppColors.darkBlue,
      dayPeriodTextColor: Colors.white,
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.darkBlue),
      ),
      dayPeriodBorderSide: const BorderSide(color: AppColors.darkBlue),
      dayPeriodTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      dialHandColor: AppColors.primary,
      dialBackgroundColor: AppColors.darkBlue,
      dialTextColor: Colors.white,
      dialTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      entryModeIconColor: AppColors.primary,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.grayMuted,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      helpTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.grayMuted,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      timeSelectorSeparatorColor: WidgetStateProperty.all(Colors.white),
      timeSelectorSeparatorTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      dividerColor: AppColors.darkBlue,
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: AppConstants.arabicFontFamily,
      ),
      headerHelpStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.85),
        fontFamily: AppConstants.arabicFontFamily,
      ),
      weekdayStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.grayMuted,
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

      // ─── Today Styling (Dark) ──────────────────────────────────────────────
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.darkBlue;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.primaryLight;
      }),
      todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),

      // ─── Day Selection & Interaction (Dark) ────────────────────────────────
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.grayDim;
        return Colors.white;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),
      dayOverlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppColors.primary.withValues(alpha: 0.15);
        }
        return null;
      }),

      // ─── Year Selection (Dark) ─────────────────────────────────────────────
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return AppColors.grayDim;
        return Colors.white;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),

      // ─── Dialog Actions (Dark) ─────────────────────────────────────────────
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.grayMuted,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: AppConstants.arabicFontFamily,
        ),
      ),
    ),
  );
}

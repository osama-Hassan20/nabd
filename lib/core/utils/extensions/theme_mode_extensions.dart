import 'package:flutter/material.dart';
import '../theme/app_theme_mode.dart';

extension ThemeModeExtensions on BuildContext {
  /// True when current theme brightness is dark (Dark or Night modes)
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// True when current theme brightness is light (Light, Sunny, or Emerald modes)
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;

  Brightness get currentBrightness => Theme.of(this).brightness;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Active theme color tokens
  AppThemeColors get themeColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;

  /// Current theme mode enum
  AppThemeMode get appThemeMode => themeColors.mode;

  bool get isSunnyMode => appThemeMode == AppThemeMode.sunny;
  bool get isNightMode => appThemeMode == AppThemeMode.night;
  bool get isEmeraldMode => appThemeMode == AppThemeMode.emerald;
}

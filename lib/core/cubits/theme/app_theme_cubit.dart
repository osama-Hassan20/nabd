import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../storage/cache_helper.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_theme_mode.dart';

class AppThemeState extends Equatable {
  final AppThemeMode themeMode;

  const AppThemeState({required this.themeMode});

  AppThemeColors get colors => AppThemeColors.forMode(themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class AppThemeCubit extends Cubit<AppThemeState> {
  AppThemeCubit() : super(AppThemeState(themeMode: _loadInitialTheme()));

  static AppThemeMode _loadInitialTheme() {
    final savedMode = AppSharedPreferences.getString(key: AppConstants.themeMode);
    if (savedMode != null) {
      for (final mode in AppThemeMode.values) {
        if (mode.name == savedMode) return mode;
      }
    }
    // Backward compatibility with legacy isDarkMode boolean
    final legacyDark = AppSharedPreferences.getBool(key: AppConstants.isDarkMode);
    if (legacyDark == true) {
      return AppThemeMode.dark;
    }
    return AppThemeMode.light;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state.themeMode == mode) return;
    await AppSharedPreferences.setString(key: AppConstants.themeMode, value: mode.name);
    // Keep legacy boolean in sync
    await AppSharedPreferences.setBool(
      key: AppConstants.isDarkMode,
      value: mode == AppThemeMode.dark || mode == AppThemeMode.night,
    );
    emit(AppThemeState(themeMode: mode));
  }

  void cycleNextTheme() {
    final nextIndex = (state.themeMode.index + 1) % AppThemeMode.values.length;
    setThemeMode(AppThemeMode.values[nextIndex]);
  }
}

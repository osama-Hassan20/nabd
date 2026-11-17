import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../storage/cache_helper.dart';
import '../../utils/constants/app_constants.dart';
import 'local_passcode_state.dart';

class LocalPasscodeCubit extends Cubit<LocalPasscodeState> {
  Timer? _inactivityTimer;

  LocalPasscodeCubit() : super(LocalPasscodeState.initial()) {
    _loadSettings();
  }

  void _loadSettings() {
    final isEnabled =
        AppSharedPreferences.getBool(key: AppConstants.isLocalPasscodeEnabledKey) ??
            false;
    final autoLockMinutes = AppSharedPreferences.getInt(
            key: AppConstants.localPasscodeAutoLockMinutesKey) ??
        5;

    emit(
      state.copyWith(
        isEnabled: isEnabled,
        isLocked: isEnabled, // Lock upon cold launch if passcode is enabled
        autoLockMinutes: autoLockMinutes,
      ),
    );

    if (isEnabled && !state.isLocked) {
      _startInactivityTimer();
    }
  }

  /// Sets up a new passcode
  Future<bool> setPasscode(String passcode) async {
    final clean = passcode.trim();
    if (clean.length < 4) {
      emit(state.copyWith(errorMessage: 'passcode_min_length_error'));
      return false;
    }

    await AppSharedPreferences.setString(
      key: AppConstants.localPasscodeKey,
      value: clean,
    );
    await AppSharedPreferences.setBool(
      key: AppConstants.isLocalPasscodeEnabledKey,
      value: true,
    );

    emit(
      state.copyWith(
        isEnabled: true,
        isLocked: false,
        clearError: true,
      ),
    );

    _startInactivityTimer();
    return true;
  }

  /// Changes an existing passcode
  Future<bool> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) async {
    final stored = AppSharedPreferences.getString(
      key: AppConstants.localPasscodeKey,
    );

    if (stored != oldPasscode.trim()) {
      emit(state.copyWith(errorMessage: 'passcode_wrong_current'));
      return false;
    }

    final cleanNew = newPasscode.trim();
    if (cleanNew.length < 4) {
      emit(state.copyWith(errorMessage: 'passcode_min_length_error'));
      return false;
    }

    await AppSharedPreferences.setString(
      key: AppConstants.localPasscodeKey,
      value: cleanNew,
    );

    emit(state.copyWith(clearError: true));
    return true;
  }

  /// Disables passcode
  Future<bool> disablePasscode(String currentPasscode) async {
    final stored = AppSharedPreferences.getString(
      key: AppConstants.localPasscodeKey,
    );

    if (stored != null && stored != currentPasscode.trim()) {
      emit(state.copyWith(errorMessage: 'passcode_wrong_current'));
      return false;
    }

    await AppSharedPreferences.remove(key: AppConstants.localPasscodeKey);
    await AppSharedPreferences.setBool(
      key: AppConstants.isLocalPasscodeEnabledKey,
      value: false,
    );

    _stopInactivityTimer();

    emit(
      state.copyWith(
        isEnabled: false,
        isLocked: false,
        clearError: true,
      ),
    );
    return true;
  }

  /// Changes the auto-lock inactivity threshold
  Future<void> setAutoLockDuration(int minutes) async {
    await AppSharedPreferences.setInt(
      key: AppConstants.localPasscodeAutoLockMinutesKey,
      value: minutes,
    );

    emit(state.copyWith(autoLockMinutes: minutes));

    if (state.isEnabled && !state.isLocked) {
      _startInactivityTimer();
    }
  }

  /// Locks the app immediately
  void lock() {
    if (!state.isEnabled) return;
    _stopInactivityTimer();
    emit(state.copyWith(isLocked: true, clearError: true));
  }

  /// Attempts to unlock the app with the entered passcode
  bool unlock(String enteredPasscode) {
    if (!state.isEnabled) {
      emit(state.copyWith(isLocked: false, clearError: true));
      return true;
    }

    final stored = AppSharedPreferences.getString(
      key: AppConstants.localPasscodeKey,
    );

    if (stored == enteredPasscode.trim()) {
      emit(state.copyWith(isLocked: false, clearError: true));
      _startInactivityTimer();
      return true;
    } else {
      emit(state.copyWith(errorMessage: 'passcode_incorrect'));
      return false;
    }
  }

  /// Called whenever user taps, hovers, or interacts
  void recordActivity() {
    if (!state.isEnabled || state.isLocked) return;
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _stopInactivityTimer();
    if (state.autoLockMinutes <= 0) return; // 0 = Never

    _inactivityTimer = Timer(Duration(minutes: state.autoLockMinutes), () {
      lock();
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  @override
  Future<void> close() {
    _stopInactivityTimer();
    return super.close();
  }
}

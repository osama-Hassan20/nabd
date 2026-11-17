import 'package:equatable/equatable.dart';

class LocalPasscodeState extends Equatable {
  final bool isEnabled;
  final bool isLocked;
  final int autoLockMinutes;
  final String? errorMessage;

  const LocalPasscodeState({
    required this.isEnabled,
    required this.isLocked,
    required this.autoLockMinutes,
    this.errorMessage,
  });

  factory LocalPasscodeState.initial() {
    return const LocalPasscodeState(
      isEnabled: false,
      isLocked: false,
      autoLockMinutes: 5, // default 5 minutes
      errorMessage: null,
    );
  }

  LocalPasscodeState copyWith({
    bool? isEnabled,
    bool? isLocked,
    int? autoLockMinutes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LocalPasscodeState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        isLocked,
        autoLockMinutes,
        errorMessage,
      ];
}

part of 'login_cubit.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class ChangeVisibilityState extends LoginState {
  final bool value;

  ChangeVisibilityState({required this.value});
}

final class LoginPushState extends LoginState {}

final class LoadingLoginPushState extends LoginPushState {}

final class FailedLoginPushState extends LoginPushState {
  final String errMessage;

  FailedLoginPushState({required this.errMessage});
}

final class SuccessLoginPushState extends LoginPushState {}

final class RememberMeState extends LoginState {
  final bool value;

  RememberMeState({required this.value});
}

final class FillRemeberMeDataState extends LoginState {
  final String userName;
  final String password;

  FillRemeberMeDataState({required this.userName, required this.password});
}

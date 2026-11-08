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

final class SuccessLoginPushState extends LoginPushState {
  final StaffUserModel? user;

  SuccessLoginPushState({this.user});
}

final class MustChangePasswordLoginState extends LoginPushState {
  final String userId;
  final String temporaryPassword;

  MustChangePasswordLoginState({
    required this.userId,
    required this.temporaryPassword,
  });
}

final class RememberMeState extends LoginState {
  final bool value;

  RememberMeState({required this.value});
}

final class FillRemeberMeDataState extends LoginState {
  final String userName;

  FillRemeberMeDataState({required this.userName});
}

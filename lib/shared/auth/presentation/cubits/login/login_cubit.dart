// import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';

// import '../../../../../core/enums/role_enum.dart';
//  import '../../../../../core/helpers/notification_helper/firebase_notifications.dart';
// import '../../../../../core/storage/cache_helper.dart';
// import '../../../../../core/utils/constants/app_constants.dart';
import '../../../data/models/login/login_param_model.dart';
// import '../../../data/models/user_model.dart';
import '../../../domain/use_cases/login/login_use_case.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required this.loginUseCase}) : super(LoginInitial());
  final LoginUseCase loginUseCase;
  @override
  void emit(LoginState state) {
    if (isClosed) {
      return;
    }
    super.emit(state);
  }

  void changeVisibility(bool value) {
    emit(ChangeVisibilityState(value: !value));
  }

  void checkRemeberMe() async {
    final userName = AppSharedPreferences.getString(key: AppConstants.userName);
    final password = AppSharedPreferences.getString(
      key: AppConstants.remeberMePassword,
    );
    if (userName != null && password != null) {
      emit(RememberMeState(value: true));
      await AppSharedPreferences.setBool(
        key: AppConstants.remeberMeKey,
        value: true,
      );
      emit(FillRemeberMeDataState(userName: userName, password: password));
    }
  }

  Future<void> loginInto({required LoginParamModel model}) async {
    emit(LoadingLoginPushState());

    // Simulated local login without backend for now
    await Future.delayed(const Duration(milliseconds: 400));
    await AppSharedPreferences.setString(
      key: AppConstants.accessToken,
      value: 'mock_access_token_purexo',
    );
    await AppSharedPreferences.setString(key: AppConstants.userId, value: '1');

    emit(SuccessLoginPushState());
    final bool isRememberMe =
        AppSharedPreferences.getBool(key: AppConstants.remeberMeKey) ?? false;
    if (isRememberMe) {
      AppSharedPreferences.setString(
        key: AppConstants.userName,
        value: model.userName,
      );
      AppSharedPreferences.setString(
        key: AppConstants.remeberMePassword,
        value: model.password,
      );
    }
  }

  void rememberMe(bool value) {
    if (value) {
      AppSharedPreferences.setBool(
        key: AppConstants.remeberMeKey,
        value: value,
      );
    } else {
      AppSharedPreferences.remove(key: AppConstants.remeberMeKey);
    }
    emit(RememberMeState(value: value));
  }
}

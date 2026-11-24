import 'package:bloc/bloc.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final StaffUsersRepo staffUsersRepo;
  final SessionCubit sessionCubit;

  LoginCubit({
    required this.staffUsersRepo,
    required this.sessionCubit,
  }) : super(LoginInitial());

  @override
  void emit(LoginState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void changeVisibility(bool value) {
    emit(ChangeVisibilityState(value: !value));
  }

  void checkRemeberMe() {
    final isRememberMe =
        AppSharedPreferences.getBool(key: AppConstants.remeberMeKey) ?? false;
    final userName = AppSharedPreferences.getString(key: AppConstants.userName);

    if (isRememberMe && userName != null && userName.isNotEmpty) {
      emit(RememberMeState(value: true));
      emit(FillRemeberMeDataState(userName: userName));
    }
  }

  void rememberMe(bool value) {
    if (value) {
      AppSharedPreferences.setBool(
        key: AppConstants.remeberMeKey,
        value: true,
      );
    } else {
      AppSharedPreferences.remove(key: AppConstants.remeberMeKey);
      AppSharedPreferences.remove(key: AppConstants.userName);
    }
    emit(RememberMeState(value: value));
  }

  Future<void> loginInto({
    required String identifier,
    required String password,
  }) async {
    emit(LoadingLoginPushState());

    final cleanIdentifier = identifier.trim();
    final result = await staffUsersRepo.authenticate(
      identifier: cleanIdentifier,
      password: password,
    );

    await result.fold(
      (failure) async {
        if (failure is MustChangePasswordFailure) {
          emit(
            MustChangePasswordLoginState(
              userId: failure.userId ?? '',
              temporaryPassword: password,
            ),
          );
        } else {
          emit(FailedLoginPushState(errMessage: failure.errMessage));
        }
      },
      (user) async {
        final token = AppConfig.generateDemoToken(user.id ?? '');
        await AppSharedPreferences.setString(
          key: AppConstants.accessToken,
          value: token,
        );
        await AppSharedPreferences.setString(
          key: AppConstants.userId,
          value: user.id ?? '',
        );

        final isRememberMe =
            AppSharedPreferences.getBool(key: AppConstants.remeberMeKey) ?? false;
        if (isRememberMe) {
          await AppSharedPreferences.setString(
            key: AppConstants.userName,
            value: cleanIdentifier,
          );
        } else {
          await AppSharedPreferences.remove(key: AppConstants.userName);
        }

        sessionCubit.switchMockUser(user);
        emit(SuccessLoginPushState(user: user));
      },
    );
  }

  Future<void> handlePasswordChangedSuccess(StaffUserModel user) async {
    final token = AppConfig.generateDemoToken(user.id ?? '');
    await AppSharedPreferences.setString(
      key: AppConstants.accessToken,
      value: token,
    );
    await AppSharedPreferences.setString(
      key: AppConstants.userId,
      value: user.id ?? '',
    );
    sessionCubit.switchMockUser(user);
    emit(SuccessLoginPushState(user: user));
  }
}

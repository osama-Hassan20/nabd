import 'package:equatable/equatable.dart';
import 'package:purexo/core/base/safe_cubit.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/shared/app_layout/domain/use_cases/get_profile_use_case.dart';
import 'package:purexo/shared/auth/data/models/profile_model.dart';
import 'package:purexo/shared/auth/data/models/user_model.dart';

part 'basic_states.dart';

class BasicCubit extends SafeCubit<BasicState> {
  final GetProfileUseCase getProfileUseCase;

  BasicCubit({
    required this.getProfileUseCase,
  }) : super(const BasicState(profileStatus: RequestStatusEnum.success)) {
    // Default single role admin profile
    profile = const ProfileModel(
      id: '1',
      name: 'مدير بيوركسو',
      email: 'admin@purexo.com',
      roles: AdminRoles.admin,
    );
    emit(state.copyWith(
      profileStatus: RequestStatusEnum.success,
      profile: profile,
    ));
  }

  ProfileModel? profile;

  void clearData() {
    profile = null;
    emit(const BasicState());
  }

  /// Single role admin - all permissions are always granted
  bool hasPermission(Enum key) => true;

  /// Fetches shared lookup lists and the user profile.
  Future<void> loadSharedData() async {
    emit(state.copyWith(
      profileStatus: RequestStatusEnum.success,
      profile: profile,
    ));
  }

  Future<void> getProfile() async {
    emit(state.copyWith(
      profileStatus: RequestStatusEnum.success,
      profile: profile,
    ));
  }
}

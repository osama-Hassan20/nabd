import 'package:dartz/dartz.dart';
import '../../../../core/base/safe_cubit.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/role_definition_model.dart';
import '../../data/models/staff_user_model.dart';
import '../../data/repositories/staff_users_repo.dart';
import 'staff_users_state.dart';

class StaffUsersCubit extends SafeCubit<StaffUsersState> {
  final StaffUsersRepo staffUsersRepo;

  StaffUsersCubit({
    required this.staffUsersRepo,
  }) : super(const StaffUsersState());

  Future<void> loadData({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: RequestStatusEnum.loading));
    }

    final results = await Future.wait([
      staffUsersRepo.getStaffUsers(),
      staffUsersRepo.getRoles(),
    ]);

    final usersRes = results[0] as Either<Failure, List<StaffUserModel>>;
    final rolesRes = results[1] as Either<Failure, List<RoleDefinitionModel>>;

    usersRes.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (users) {
        rolesRes.fold(
          (failure) => emit(
            state.copyWith(
              status: RequestStatusEnum.failure,
              errMessage: failure.errMessage,
            ),
          ),
          (roles) => emit(
            state.copyWith(
              status: RequestStatusEnum.success,
              users: users,
              roles: roles,
            ),
          ),
        );
      },
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setStatusFilter(StaffUserStatusFilter filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void setBranchFilter(String? branchId) {
    emit(
      state.copyWith(
        branchFilter: branchId,
        clearBranchFilter: branchId == null || branchId.isEmpty,
      ),
    );
  }

  void setRoleFilter(String? roleId) {
    emit(
      state.copyWith(
        roleFilter: roleId,
        clearRoleFilter: roleId == null || roleId.isEmpty,
      ),
    );
  }

  Future<bool> toggleUserStatus({
    required String userId,
    required bool isActive,
    required String currentUserId,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await staffUsersRepo.toggleStaffUserStatus(
      userId: userId,
      isActive: isActive,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        final updatedUsers = state.users.map((u) {
          if (u.id == userId) {
            return u.copyWith(isActive: isActive);
          }
          return u;
        }).toList();

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            users: updatedUsers,
            successMessage: isActive
                ? 'user_activated_successfully'
                : 'user_deactivated_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<Either<Failure, Unit>> deleteUser({
    required String userId,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await staffUsersRepo.deleteStaffUser(
      userId: userId,
      currentUserId: currentUserId,
      forceWithActiveBookings: forceWithActiveBookings,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
      },
      (_) {
        final updatedUsers =
            state.users.where((u) => u.id != userId).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            users: updatedUsers,
            successMessage: 'user_deleted_successfully',
          ),
        );
      },
    );

    return result;
  }

  Future<bool> resetPassword({
    required String userId,
    required String newTempPassword,
    required String currentUserId,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await staffUsersRepo.resetPassword(
      userId: userId,
      newTemporaryPassword: newTempPassword,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        final updatedUsers = state.users.map((u) {
          if (u.id == userId) {
            return u.copyWith(mustChangePassword: true);
          }
          return u;
        }).toList();

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            users: updatedUsers,
            successMessage: 'password_reset_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> saveUser({
    required StaffUserModel user,
    String? temporaryPassword,
    required String currentUserId,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final isEdit = user.id != null && user.id!.isNotEmpty;
    final result = isEdit
        ? await staffUsersRepo.updateStaffUser(
            user: user,
            currentUserId: currentUserId,
          )
        : await staffUsersRepo.createStaffUser(
            user: user,
            temporaryPassword: temporaryPassword ?? '12345678',
            currentUserId: currentUserId,
          );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedUser) {
        List<StaffUserModel> updatedUsers;
        if (isEdit) {
          updatedUsers = state.users.map((u) {
            return u.id == savedUser.id ? savedUser : u;
          }).toList();
        } else {
          updatedUsers = [savedUser, ...state.users];
        }

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            users: updatedUsers,
            successMessage: isEdit
                ? 'user_updated_successfully'
                : 'user_created_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> saveRole({
    required RoleDefinitionModel role,
    required String currentUserId,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await staffUsersRepo.saveRole(
      role: role,
      currentUserId: currentUserId,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedRole) {
        final existingIndex = state.roles.indexWhere((r) => r.id == savedRole.id);
        List<RoleDefinitionModel> updatedRoles;
        if (existingIndex != -1) {
          updatedRoles = List<RoleDefinitionModel>.from(state.roles);
          updatedRoles[existingIndex] = savedRole;
        } else {
          updatedRoles = [...state.roles, savedRole];
        }

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            roles: updatedRoles,
            successMessage: 'role_saved_successfully',
          ),
        );
        return true;
      },
    );
  }
}


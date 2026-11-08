import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../models/role_definition_model.dart';
import '../models/staff_user_model.dart';

abstract class StaffUsersRepo {
  Future<Either<Failure, StaffUserModel>> authenticate({
    required String identifier,
    required String password,
  });

  Future<Either<Failure, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  });

  Future<Either<Failure, StaffUserModel>> getStaffUserById(String id);

  Future<Either<Failure, StaffUserModel>> createStaffUser({
    required StaffUserModel user,
    required String temporaryPassword,
    required String currentUserId,
  });

  Future<Either<Failure, StaffUserModel>> updateStaffUser({
    required StaffUserModel user,
    required String currentUserId,
  });

  Future<Either<Failure, Unit>> toggleStaffUserStatus({
    required String userId,
    required bool isActive,
    required String currentUserId,
  });

  Future<Either<Failure, Unit>> deleteStaffUser({
    required String userId,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  });

  Future<Either<Failure, Unit>> resetPassword({
    required String userId,
    required String newTemporaryPassword,
    required String currentUserId,
  });

  Future<Either<Failure, Unit>> changePasswordOnFirstLogin({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, List<RoleDefinitionModel>>> getRoles();

  Future<Either<Failure, RoleDefinitionModel>> saveRole({
    required RoleDefinitionModel role,
    required String currentUserId,
  });
}


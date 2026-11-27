import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/active_bookings_count_provider.dart';
import '../../../../core/services/audit_logger.dart';
import '../models/role_definition_model.dart';
import '../models/staff_user_model.dart';
import 'staff_users_repo.dart';

class StaffUsersRepoImpl implements StaffUsersRepo {
  final ApiConsumer? _apiConsumer;
  final AuditLogger auditLogger;
  final ActiveBookingsCountProvider? activeBookingsProvider;

  StaffUsersRepoImpl({
    ApiConsumer? apiConsumer,
    required this.auditLogger,
    this.activeBookingsProvider,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failure, StaffUserModel>> authenticate({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await _api.post(
        path: 'staff-users/authenticate',
        body: {'identifier': identifier, 'password': password},
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final user = StaffUserModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger.log(
        eventType: 'login_success',
        performedByUserId: user.id ?? '',
        details: user.mustChangePassword == true
            ? 'User authenticated but must change temporary password'
            : 'User authenticated',
      );
      return Right(user);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async {
    try {
      final res = await _api.get(
        path: 'staff-users',
        queryParameters: {
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
          if (roleId != null && roleId.isNotEmpty) 'roleId': roleId,
          if (isActive != null) 'isActive': isActive,
          if (searchQuery != null && searchQuery.isNotEmpty) 'searchQuery': searchQuery,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list.map((e) => StaffUserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, StaffUserModel>> getStaffUserById(String id) async {
    try {
      final res = await _api.get(path: 'staff-users/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(StaffUserModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, StaffUserModel>> createStaffUser({
    required StaffUserModel user,
    required String temporaryPassword,
    required String currentUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'staff-users',
        body: {
          ...user.toJson(),
          'temporaryPassword': temporaryPassword,
          'currentUserId': currentUserId,
        },
        options: IdempotencyHelper.options(user.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final created = StaffUserModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger.log(
        eventType: 'staff_user_created',
        performedByUserId: currentUserId,
        targetUserId: created.id,
      );
      return Right(created);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, StaffUserModel>> updateStaffUser({
    required StaffUserModel user,
    required String currentUserId,
  }) async {
    try {
      final res = await _api.put(
        path: 'staff-users/${user.id}',
        body: {...user.toJson(), 'currentUserId': currentUserId},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final updated = StaffUserModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger.log(
        eventType: 'staff_user_updated',
        performedByUserId: currentUserId,
        targetUserId: updated.id,
      );
      return Right(updated);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleStaffUserStatus({
    required String userId,
    required bool isActive,
    required String currentUserId,
  }) async {
    try {
      await _api.patch(
        path: 'staff-users/$userId/status',
        body: {'isActive': isActive, 'currentUserId': currentUserId},
        options: IdempotencyHelper.options(),
      );
      auditLogger.log(
        eventType: isActive ? 'staff_user_activated' : 'staff_user_deactivated',
        performedByUserId: currentUserId,
        targetUserId: userId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteStaffUser({
    required String userId,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    try {
      if (!forceWithActiveBookings && activeBookingsProvider != null) {
        final userRes = await getStaffUserById(userId);
        final doctorId = userRes.fold((_) => null, (u) => u.linkedDoctorId);
        if (doctorId != null && doctorId.isNotEmpty) {
          final count =
              await activeBookingsProvider!.countActiveFutureBookingsForDoctor(doctorId);
          if (count > 0) {
            return Left(ActiveBookingsWarningFailure(
              activeBookingsCount: count,
              errMessage: 'doctor_has_future_bookings',
            ));
          }
        }
      }
      await _api.delete(
        path: 'staff-users/$userId',
        body: {
          'currentUserId': currentUserId,
          'forceWithActiveBookings': forceWithActiveBookings,
        },
        options: IdempotencyHelper.options(),
      );
      auditLogger.log(
        eventType: 'staff_user_deleted',
        performedByUserId: currentUserId,
        targetUserId: userId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String userId,
    required String newTemporaryPassword,
    required String currentUserId,
  }) async {
    try {
      await _api.post(
        path: 'staff-users/$userId/reset-password',
        body: {
          'newTemporaryPassword': newTemporaryPassword,
          'currentUserId': currentUserId,
        },
        options: IdempotencyHelper.options(),
      );
      auditLogger.log(
        eventType: 'password_reset',
        performedByUserId: currentUserId,
        targetUserId: userId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> changePasswordOnFirstLogin({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post(
        path: 'staff-users/$userId/change-password-first-login',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: IdempotencyHelper.options(),
      );
      auditLogger.log(
        eventType: 'first_login_password_changed',
        performedByUserId: userId,
        targetUserId: userId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, List<RoleDefinitionModel>>> getRoles() async {
    try {
      final res = await _api.get(path: 'roles');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list.map((e) => RoleDefinitionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failure, RoleDefinitionModel>> saveRole({
    required RoleDefinitionModel role,
    required String currentUserId,
  }) async {
    try {
      final res = await _api.put(
        path: 'roles/${role.id}',
        body: {...role.toJson(), 'currentUserId': currentUserId},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final saved = RoleDefinitionModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger.log(
        eventType: 'role_saved',
        performedByUserId: currentUserId,
        details: 'roleId: ${saved.id}',
      );
      return Right(saved);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/active_bookings_count_provider.dart';
import '../../../../core/services/audit_logger.dart';
import '../../domain/repo/branches_repo.dart';
import '../models/branch_model.dart';
import '../models/copy_branch_settings_param.dart';

class BranchesRepoImpl implements BranchesRepo {
  final ApiConsumer? _apiConsumer;
  final AuditLogger? auditLogger;
  final ActiveBookingsCountProvider? activeBookingsProvider;

  BranchesRepoImpl({
    ApiConsumer? apiConsumer,
    this.auditLogger,
    this.activeBookingsProvider,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failures, List<BranchModel>>> getBranches() async {
    try {
      final res = await _api.get(path: 'branches');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list.map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> getBranchById(String id) async {
    try {
      final res = await _api.get(path: 'branches/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(BranchModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> createBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'branches',
        body: branch.toJson(),
        options: IdempotencyHelper.options(branch.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final created = BranchModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger?.log(
        eventType: 'create_branch',
        performedByUserId: currentUserId,
        branchId: created.id,
        details: 'name: ${created.name}',
      );
      return Right(created);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> updateBranch(
    BranchModel branch, {
    required String currentUserId,
  }) async {
    try {
      final res = await _api.put(
        path: 'branches/${branch.id}',
        body: branch.toJson(),
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final updated = BranchModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger?.log(
        eventType: 'update_branch',
        performedByUserId: currentUserId,
        branchId: updated.id,
      );
      return Right(updated);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> toggleBranchStatus({
    required String branchId,
    required bool isActive,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    try {
      if (!isActive && !forceWithActiveBookings && activeBookingsProvider != null) {
        final activeCount =
            await activeBookingsProvider!.countActiveFutureBookingsForBranch(branchId);
        if (activeCount > 0) {
          return Left(ActiveBookingsWarningFailure(
            activeBookingsCount: activeCount,
            errMessage: 'branch_has_future_bookings_warning',
          ));
        }
      }
      final res = await _api.patch(
        path: 'branches/$branchId/status',
        body: {
          'isActive': isActive,
          'forceWithActiveBookings':
              forceWithActiveBookings || activeBookingsProvider != null,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final updated = BranchModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger?.log(
        eventType: isActive ? 'activate_branch' : 'deactivate_branch',
        performedByUserId: currentUserId,
        branchId: branchId,
      );
      return Right(updated);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> setMainBranch({
    required String branchId,
    required String currentUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'branches/$branchId/set-main',
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final updated = BranchModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger?.log(
        eventType: 'set_main_branch',
        performedByUserId: currentUserId,
        branchId: branchId,
      );
      return Right(updated);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BranchModel>> copySettingsFromBranch(
    CopyBranchSettingsParam param, {
    required String currentUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'branches/${param.targetBranchId}/copy-settings',
        body: {
          'sourceBranchId': param.sourceBranchId,
          'copyWorkingHours': param.copyWorkingHours ?? false,
          'copySpecialHolidays': param.copySpecialHolidays ?? false,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      final updated = BranchModel.fromJson(Map<String, dynamic>.from(data as Map));
      auditLogger?.log(
        eventType: 'copy_branch_settings',
        performedByUserId: currentUserId,
        branchId: param.targetBranchId,
        details: 'sourceBranchId: ${param.sourceBranchId}',
      );
      return Right(updated);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

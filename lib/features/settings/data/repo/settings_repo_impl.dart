import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/settings_repo.dart';
import '../models/company_settings_model.dart';
import '../models/special_holiday_model.dart';

class SettingsRepoImpl implements SettingsRepo {
  final ApiConsumer? apiConsumer;

  SettingsRepoImpl({this.apiConsumer});

  ApiConsumer get _api => apiConsumer ?? getIt<ApiConsumer>();

  String _getActiveBranchId() {
    if (getIt.isRegistered<SessionCubit>()) {
      final active = getIt<SessionCubit>().state.activeBranchId;
      if (active != null && active.isNotEmpty) {
        return active;
      }
    }
    return 'branch_1';
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> getCompanySettings() async {
    try {
      final branchId = _getActiveBranchId();
      final res = await _api.get(
        path: 'settings/company',
        queryParameters: {'branchId': branchId},
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        CompanySettingsModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, CompanySettingsModel>> updateCompanySettings(
    CompanySettingsModel settings,
  ) async {
    try {
      final branchId = _getActiveBranchId();
      final res = await _api.put(
        path: 'settings/company',
        body: {...settings.toJson(), 'branchId': branchId},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        CompanySettingsModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, SpecialHolidayModel>> addSpecialHoliday(
    SpecialHolidayModel holiday,
  ) async {
    try {
      final branchId = _getActiveBranchId();
      final res = await _api.post(
        path: 'settings/special-holidays',
        body: {...holiday.toJson(), 'branchId': branchId},
        options: IdempotencyHelper.options(holiday.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        SpecialHolidayModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteSpecialHoliday(String holidayId) async {
    try {
      final branchId = _getActiveBranchId();
      await _api.delete(
        path: 'settings/special-holidays/$holidayId',
        queryParameters: {'branchId': branchId},
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.put(
        path: 'users/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

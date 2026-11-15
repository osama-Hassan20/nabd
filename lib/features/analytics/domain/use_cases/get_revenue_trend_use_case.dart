import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../../data/models/revenue_trend_point_model.dart';
import '../repo/analytics_repo.dart';

class GetRevenueTrendUseCase {
  final AnalyticsRepo analyticsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetRevenueTrendUseCase({
    required this.analyticsRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, List<RevenueTrendPointModel>>> call({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final canAccess = permissionEvaluator!.can(
        StaffPermissionEnum.accessAnalytics,
        branchId: branchId,
      );
      final canViewFinancial = permissionEvaluator!.can(
        StaffPermissionEnum.viewFinancialReports,
        branchId: branchId,
      );
      if (!canAccess || !canViewFinancial) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return analyticsRepo.getRevenueTrend(
      branchId: branchId,
      timeRange: timeRange,
      customStart: customStart,
      customEnd: customEnd,
    );
  }
}

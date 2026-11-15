import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../../data/models/hourly_traffic_metric_model.dart';
import '../repo/analytics_repo.dart';

class GetHourlyTrafficUseCase {
  final AnalyticsRepo analyticsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetHourlyTrafficUseCase({
    required this.analyticsRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, List<HourlyTrafficMetricModel>>> call({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
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
      if (!canAccess) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return analyticsRepo.getHourlyTraffic(
      branchId: branchId,
      timeRange: timeRange,
    );
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/branch_analytics_comparison_model.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../repo/analytics_repo.dart';

class GetBranchComparisonUseCase {
  final AnalyticsRepo analyticsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetBranchComparisonUseCase({
    required this.analyticsRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, List<BranchAnalyticsComparisonModel>>> call({
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final canAccess = permissionEvaluator!.can(StaffPermissionEnum.accessAnalytics);
      if (!canAccess) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return analyticsRepo.getBranchComparison(
      timeRange: timeRange,
      customStart: customStart,
      customEnd: customEnd,
    );
  }
}

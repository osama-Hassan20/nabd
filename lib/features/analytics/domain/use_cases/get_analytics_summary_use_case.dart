import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/analytics_summary_kpi_model.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../repo/analytics_repo.dart';

class GetAnalyticsSummaryUseCase {
  final AnalyticsRepo analyticsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const GetAnalyticsSummaryUseCase({
    required this.analyticsRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, AnalyticsSummaryKpiModel>> call({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    // 1. Check accessAnalytics permission
    if (permissionEvaluator != null) {
      final canAccess = permissionEvaluator!.can(
        StaffPermissionEnum.accessAnalytics,
        branchId: branchId,
      );
      if (!canAccess) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 2. Fetch summary from repository
    final result = await analyticsRepo.getAnalyticsSummary(
      branchId: branchId,
      timeRange: timeRange,
      customStart: customStart,
      customEnd: customEnd,
    );

    // 3. Privacy Masking: If user lacks viewFinancialReports, mask financial amounts
    return result.map((summary) {
      bool canViewFinancial = true;
      if (permissionEvaluator != null) {
        canViewFinancial = permissionEvaluator!.can(
          StaffPermissionEnum.viewFinancialReports,
          branchId: branchId,
        );
      }

      final effectiveSummary = canViewFinancial
          ? summary
          : AnalyticsSummaryKpiModel(
              totalVisitsCount: summary.totalVisitsCount,
              completedVisitsCount: summary.completedVisitsCount,
              cancelledVisitsCount: summary.cancelledVisitsCount,
              noShowVisitsCount: summary.noShowVisitsCount,
              totalBookingsCount: summary.totalBookingsCount,
              averageWaitTimeMinutes: summary.averageWaitTimeMinutes,
              averageConsultationMinutes: summary.averageConsultationMinutes,
              patientReturnRatePercent: summary.patientReturnRatePercent,
              visitsGrowthRatePercent: summary.visitsGrowthRatePercent,
            );

      // 4. Audit Log on success ONLY (whitelist details: no clinical/patient data)
      auditLogger?.log(
        eventType: 'analytics_summary_viewed',
        performedByUserId: user.id,
        performedByUserName: user.fullName ?? 'Unknown',
        branchId: branchId,
        details:
            'branchId: ${branchId ?? "all"}, timeRange: ${timeRange.name}, '
            'financialIncluded: $canViewFinancial',
      );

      return effectiveSummary;
    });
  }
}

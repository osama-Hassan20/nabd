import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_performance_metric_model.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../repo/analytics_repo.dart';

class GetDoctorPerformanceUseCase {
  final AnalyticsRepo analyticsRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetDoctorPerformanceUseCase({
    required this.analyticsRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, List<DoctorPerformanceMetricModel>>> call({
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
      if (!canAccess) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    final result = await analyticsRepo.getDoctorPerformance(
      branchId: branchId,
      timeRange: timeRange,
      customStart: customStart,
      customEnd: customEnd,
    );

    return result.map((list) {
      bool canViewFinancial = true;
      if (permissionEvaluator != null) {
        canViewFinancial = permissionEvaluator!.can(
          StaffPermissionEnum.viewFinancialReports,
          branchId: branchId,
        );
      }

      if (canViewFinancial) return list;

      // Mask financial numbers if user lacks viewFinancialReports
      return list.map((doc) {
        return DoctorPerformanceMetricModel(
          doctorId: doc.doctorId,
          doctorName: doc.doctorName,
          specialty: doc.specialty,
          visitsCount: doc.visitsCount,
          avgConsultationDurationMinutes: doc.avgConsultationDurationMinutes,
          patientSatisfactionRating: doc.patientSatisfactionRating,
        );
      }).toList();
    });
  }
}

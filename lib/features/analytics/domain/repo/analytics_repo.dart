import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/analytics_summary_kpi_model.dart';
import '../../data/models/branch_analytics_comparison_model.dart';
import '../../data/models/doctor_performance_metric_model.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../../data/models/hourly_traffic_metric_model.dart';
import '../../data/models/revenue_trend_point_model.dart';
import '../../data/models/service_revenue_distribution_model.dart';

abstract class AnalyticsRepo {
  Future<Either<Failures, AnalyticsSummaryKpiModel>> getAnalyticsSummary({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<Either<Failures, List<RevenueTrendPointModel>>> getRevenueTrend({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<Either<Failures, List<BranchAnalyticsComparisonModel>>> getBranchComparison({
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<Either<Failures, List<DoctorPerformanceMetricModel>>> getDoctorPerformance({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  });

  Future<Either<Failures, List<HourlyTrafficMetricModel>>> getHourlyTraffic({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
  });

  Future<Either<Failures, List<ServiceRevenueDistributionModel>>> getServiceDistribution({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
  });
}

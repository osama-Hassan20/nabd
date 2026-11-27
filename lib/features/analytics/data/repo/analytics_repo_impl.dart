import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../domain/repo/analytics_repo.dart';
import '../models/analytics_summary_kpi_model.dart';
import '../models/branch_analytics_comparison_model.dart';
import '../models/doctor_performance_metric_model.dart';
import '../models/enums/analytics_time_range_enum.dart';
import '../models/hourly_traffic_metric_model.dart';
import '../models/revenue_trend_point_model.dart';
import '../models/service_revenue_distribution_model.dart';

class AnalyticsRepoImpl implements AnalyticsRepo {
  final ApiConsumer? _apiConsumer;
  final bool seedInitialData;

  const AnalyticsRepoImpl({
    ApiConsumer? apiConsumer,
    this.seedInitialData = true,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  ({DateTime start, DateTime end}) resolveDateRange({
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = CairoTimeHelper.now();
    switch (timeRange) {
      case AnalyticsTimeRangeEnum.today:
        return (
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case AnalyticsTimeRangeEnum.thisWeek:
        final startOfWeek = now.subtract(Duration(days: (now.weekday + 1) % 7));
        return (
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case AnalyticsTimeRangeEnum.thisMonth:
        final lastDay = DateTime(now.year, now.month + 1, 0);
        return (
          start: DateTime(now.year, now.month, 1, 0, 0, 0),
          end: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
        );
      case AnalyticsTimeRangeEnum.lastMonth:
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final lastDay = DateTime(now.year, now.month, 0);
        return (
          start: DateTime(prevMonth.year, prevMonth.month, 1, 0, 0, 0),
          end: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
        );
      case AnalyticsTimeRangeEnum.custom:
        final s = customStart ?? now.subtract(const Duration(days: 7));
        final e = customEnd ?? now;
        return (start: s, end: e);
    }
  }

  @override
  Future<Either<Failures, AnalyticsSummaryKpiModel>> getAnalyticsSummary({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (!seedInitialData) {
      return const Right(AnalyticsSummaryKpiModel());
    }
    try {
      final res = await _api.get(
        path: 'analytics/summary',
        queryParameters: {
          if (branchId != null) 'branchId': branchId,
          'range': timeRange.name,
          if (customStart != null) 'from': customStart.toIso8601String(),
          if (customEnd != null) 'to': customEnd.toIso8601String(),
        },
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        AnalyticsSummaryKpiModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<RevenueTrendPointModel>>> getRevenueTrend({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (!seedInitialData) return const Right([]);
    try {
      final res = await _api.get(
        path: 'analytics/revenue-trend',
        queryParameters: {
          if (branchId != null) 'branchId': branchId,
          'range': timeRange.name,
          if (customStart != null) 'from': customStart.toIso8601String(),
          if (customEnd != null) 'to': customEnd.toIso8601String(),
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => RevenueTrendPointModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<BranchAnalyticsComparisonModel>>> getBranchComparison({
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (!seedInitialData) return const Right([]);
    try {
      final res = await _api.get(
        path: 'analytics/branch-comparison',
        queryParameters: {'range': timeRange.name},
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map(
              (e) => BranchAnalyticsComparisonModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<DoctorPerformanceMetricModel>>> getDoctorPerformance({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    if (!seedInitialData) return const Right([]);
    try {
      final res = await _api.get(
        path: 'analytics/doctor-performance',
        queryParameters: {
          if (branchId != null) 'branchId': branchId,
          'range': timeRange.name,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map(
              (e) => DoctorPerformanceMetricModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<HourlyTrafficMetricModel>>> getHourlyTraffic({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
  }) async {
    if (!seedInitialData) return const Right([]);
    try {
      final res = await _api.get(
        path: 'analytics/hourly-traffic',
        queryParameters: {
          if (branchId != null) 'branchId': branchId,
          'range': timeRange.name,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => HourlyTrafficMetricModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<ServiceRevenueDistributionModel>>> getServiceDistribution({
    String? branchId,
    required AnalyticsTimeRangeEnum timeRange,
  }) async {
    if (!seedInitialData) return const Right([]);
    try {
      final res = await _api.get(
        path: 'analytics/service-distribution',
        queryParameters: {
          if (branchId != null) 'branchId': branchId,
          'range': timeRange.name,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map(
              (e) => ServiceRevenueDistributionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

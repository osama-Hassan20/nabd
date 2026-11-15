import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/analytics_summary_kpi_model.dart';
import '../../data/models/branch_analytics_comparison_model.dart';
import '../../data/models/doctor_performance_metric_model.dart';
import '../../data/models/enums/analytics_tab_enum.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../../data/models/hourly_traffic_metric_model.dart';
import '../../data/models/revenue_trend_point_model.dart';
import '../../data/models/service_revenue_distribution_model.dart';

class AnalyticsState extends Equatable {
  // Navigation & Filtering
  final AnalyticsTabEnum activeTab;
  final AnalyticsTimeRangeEnum selectedTimeRange;
  final String? selectedBranchId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  // Granular Section Statuses (skill: dashboard-section-builder)
  final RequestStatusEnum summaryStatus;
  final RequestStatusEnum trendStatus;
  final RequestStatusEnum branchesStatus;
  final RequestStatusEnum doctorsStatus;
  final RequestStatusEnum trafficStatus;
  final RequestStatusEnum servicesStatus;

  // Data Payloads
  final AnalyticsSummaryKpiModel? summary;
  final List<RevenueTrendPointModel> revenueTrend;
  final List<BranchAnalyticsComparisonModel> branchComparisons;
  final List<DoctorPerformanceMetricModel> doctorPerformances;
  final List<HourlyTrafficMetricModel> hourlyTraffic;
  final List<ServiceRevenueDistributionModel> serviceDistribution;

  // Granular Section Errors
  final String? summaryError;
  final String? trendError;
  final String? branchesError;
  final String? doctorsError;
  final String? trafficError;
  final String? servicesError;

  const AnalyticsState({
    this.activeTab = AnalyticsTabEnum.executive,
    this.selectedTimeRange = AnalyticsTimeRangeEnum.thisMonth,
    this.selectedBranchId,
    this.customStartDate,
    this.customEndDate,
    this.summaryStatus = RequestStatusEnum.initial,
    this.trendStatus = RequestStatusEnum.initial,
    this.branchesStatus = RequestStatusEnum.initial,
    this.doctorsStatus = RequestStatusEnum.initial,
    this.trafficStatus = RequestStatusEnum.initial,
    this.servicesStatus = RequestStatusEnum.initial,
    this.summary,
    this.revenueTrend = const [],
    this.branchComparisons = const [],
    this.doctorPerformances = const [],
    this.hourlyTraffic = const [],
    this.serviceDistribution = const [],
    this.summaryError,
    this.trendError,
    this.branchesError,
    this.doctorsError,
    this.trafficError,
    this.servicesError,
  });

  AnalyticsState copyWith({
    AnalyticsTabEnum? activeTab,
    AnalyticsTimeRangeEnum? selectedTimeRange,
    String? selectedBranchId,
    bool clearBranchId = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
    RequestStatusEnum? summaryStatus,
    RequestStatusEnum? trendStatus,
    RequestStatusEnum? branchesStatus,
    RequestStatusEnum? doctorsStatus,
    RequestStatusEnum? trafficStatus,
    RequestStatusEnum? servicesStatus,
    AnalyticsSummaryKpiModel? summary,
    List<RevenueTrendPointModel>? revenueTrend,
    List<BranchAnalyticsComparisonModel>? branchComparisons,
    List<DoctorPerformanceMetricModel>? doctorPerformances,
    List<HourlyTrafficMetricModel>? hourlyTraffic,
    List<ServiceRevenueDistributionModel>? serviceDistribution,
    String? summaryError,
    bool clearSummaryError = false,
    String? trendError,
    bool clearTrendError = false,
    String? branchesError,
    bool clearBranchesError = false,
    String? doctorsError,
    bool clearDoctorsError = false,
    String? trafficError,
    bool clearTrafficError = false,
    String? servicesError,
    bool clearServicesError = false,
  }) {
    return AnalyticsState(
      activeTab: activeTab ?? this.activeTab,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
      selectedBranchId: clearBranchId ? null : (selectedBranchId ?? this.selectedBranchId),
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      trendStatus: trendStatus ?? this.trendStatus,
      branchesStatus: branchesStatus ?? this.branchesStatus,
      doctorsStatus: doctorsStatus ?? this.doctorsStatus,
      trafficStatus: trafficStatus ?? this.trafficStatus,
      servicesStatus: servicesStatus ?? this.servicesStatus,
      summary: summary ?? this.summary,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      branchComparisons: branchComparisons ?? this.branchComparisons,
      doctorPerformances: doctorPerformances ?? this.doctorPerformances,
      hourlyTraffic: hourlyTraffic ?? this.hourlyTraffic,
      serviceDistribution: serviceDistribution ?? this.serviceDistribution,
      summaryError: clearSummaryError ? null : (summaryError ?? this.summaryError),
      trendError: clearTrendError ? null : (trendError ?? this.trendError),
      branchesError: clearBranchesError ? null : (branchesError ?? this.branchesError),
      doctorsError: clearDoctorsError ? null : (doctorsError ?? this.doctorsError),
      trafficError: clearTrafficError ? null : (trafficError ?? this.trafficError),
      servicesError: clearServicesError ? null : (servicesError ?? this.servicesError),
    );
  }

  @override
  List<Object?> get props => [
        activeTab,
        selectedTimeRange,
        selectedBranchId,
        customStartDate,
        customEndDate,
        summaryStatus,
        trendStatus,
        branchesStatus,
        doctorsStatus,
        trafficStatus,
        servicesStatus,
        summary,
        revenueTrend,
        branchComparisons,
        doctorPerformances,
        hourlyTraffic,
        serviceDistribution,
        summaryError,
        trendError,
        branchesError,
        doctorsError,
        trafficError,
        servicesError,
      ];
}

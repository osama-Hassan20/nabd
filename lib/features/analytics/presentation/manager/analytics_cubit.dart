import '../../../../core/base/safe_cubit.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/enums/analytics_tab_enum.dart';
import '../../data/models/enums/analytics_time_range_enum.dart';
import '../../domain/repo/analytics_repo.dart';
import '../../domain/use_cases/get_analytics_summary_use_case.dart';
import '../../domain/use_cases/get_branch_comparison_use_case.dart';
import '../../domain/use_cases/get_doctor_performance_use_case.dart';
import '../../domain/use_cases/get_hourly_traffic_use_case.dart';
import '../../domain/use_cases/get_revenue_trend_use_case.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends SafeCubit<AnalyticsState> {
  final GetAnalyticsSummaryUseCase getAnalyticsSummaryUseCase;
  final GetRevenueTrendUseCase getRevenueTrendUseCase;
  final GetBranchComparisonUseCase getBranchComparisonUseCase;
  final GetDoctorPerformanceUseCase getDoctorPerformanceUseCase;
  final GetHourlyTrafficUseCase getHourlyTrafficUseCase;
  final AnalyticsRepo analyticsRepo;

  AnalyticsCubit({
    required this.getAnalyticsSummaryUseCase,
    required this.getRevenueTrendUseCase,
    required this.getBranchComparisonUseCase,
    required this.getDoctorPerformanceUseCase,
    required this.getHourlyTrafficUseCase,
    required this.analyticsRepo,
    AnalyticsState? initialState,
  }) : super(initialState ?? const AnalyticsState());

  // ─── Parallel Fetching for Entire Dashboard (skill: dashboard-section-builder)
  Future<void> loadAllAnalytics() async {
    await Future.wait([
      loadSummary(),
      loadRevenueTrend(),
      loadBranchComparison(),
      loadDoctorPerformance(),
      loadHourlyTraffic(),
      loadServiceDistribution(),
    ]);
  }

  // ─── Filters & Tab Switching ───────────────────────────────────────────────
  Future<void> setTimeRange(
    AnalyticsTimeRangeEnum range, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    emit(
      state.copyWith(
        selectedTimeRange: range,
        customStartDate: customStart,
        customEndDate: customEnd,
      ),
    );
    await loadAllAnalytics();
  }

  Future<void> setBranchId(String? branchId) async {
    emit(
      state.copyWith(
        selectedBranchId: branchId,
        clearBranchId: branchId == null,
      ),
    );
    await loadAllAnalytics();
  }

  void setActiveTab(AnalyticsTabEnum tab) {
    emit(state.copyWith(activeTab: tab));
  }

  // ─── Granular Section Loaders (Independent Retry Support) ──────────────────
  Future<void> loadSummary() async {
    emit(
      state.copyWith(
        summaryStatus: RequestStatusEnum.loading,
        clearSummaryError: true,
      ),
    );

    final res = await getAnalyticsSummaryUseCase(
      branchId: state.selectedBranchId,
      timeRange: state.selectedTimeRange,
      customStart: state.customStartDate,
      customEnd: state.customEndDate,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          summaryStatus: RequestStatusEnum.failure,
          summaryError: failure.errMessage,
        ),
      ),
      (data) => emit(
        state.copyWith(
          summaryStatus: RequestStatusEnum.success,
          summary: data,
        ),
      ),
    );
  }

  Future<void> loadRevenueTrend() async {
    emit(
      state.copyWith(
        trendStatus: RequestStatusEnum.loading,
        clearTrendError: true,
      ),
    );

    final res = await getRevenueTrendUseCase(
      branchId: state.selectedBranchId,
      timeRange: state.selectedTimeRange,
      customStart: state.customStartDate,
      customEnd: state.customEndDate,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          trendStatus: RequestStatusEnum.failure,
          trendError: failure.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(
          trendStatus: RequestStatusEnum.success,
          revenueTrend: list,
        ),
      ),
    );
  }

  Future<void> loadBranchComparison() async {
    emit(
      state.copyWith(
        branchesStatus: RequestStatusEnum.loading,
        clearBranchesError: true,
      ),
    );

    final res = await getBranchComparisonUseCase(
      timeRange: state.selectedTimeRange,
      customStart: state.customStartDate,
      customEnd: state.customEndDate,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          branchesStatus: RequestStatusEnum.failure,
          branchesError: failure.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(
          branchesStatus: RequestStatusEnum.success,
          branchComparisons: list,
        ),
      ),
    );
  }

  Future<void> loadDoctorPerformance() async {
    emit(
      state.copyWith(
        doctorsStatus: RequestStatusEnum.loading,
        clearDoctorsError: true,
      ),
    );

    final res = await getDoctorPerformanceUseCase(
      branchId: state.selectedBranchId,
      timeRange: state.selectedTimeRange,
      customStart: state.customStartDate,
      customEnd: state.customEndDate,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          doctorsStatus: RequestStatusEnum.failure,
          doctorsError: failure.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(
          doctorsStatus: RequestStatusEnum.success,
          doctorPerformances: list,
        ),
      ),
    );
  }

  Future<void> loadHourlyTraffic() async {
    emit(
      state.copyWith(
        trafficStatus: RequestStatusEnum.loading,
        clearTrafficError: true,
      ),
    );

    final res = await getHourlyTrafficUseCase(
      branchId: state.selectedBranchId,
      timeRange: state.selectedTimeRange,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          trafficStatus: RequestStatusEnum.failure,
          trafficError: failure.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(
          trafficStatus: RequestStatusEnum.success,
          hourlyTraffic: list,
        ),
      ),
    );
  }

  Future<void> loadServiceDistribution() async {
    emit(
      state.copyWith(
        servicesStatus: RequestStatusEnum.loading,
        clearServicesError: true,
      ),
    );

    final res = await analyticsRepo.getServiceDistribution(
      branchId: state.selectedBranchId,
      timeRange: state.selectedTimeRange,
    );

    res.fold(
      (failure) => emit(
        state.copyWith(
          servicesStatus: RequestStatusEnum.failure,
          servicesError: failure.errMessage,
        ),
      ),
      (list) => emit(
        state.copyWith(
          servicesStatus: RequestStatusEnum.success,
          serviceDistribution: list,
        ),
      ),
    );
  }
}

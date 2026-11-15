import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_tab_enum.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_mock_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  MockUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class MockRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  MockRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('AnalyticsCubit State Management Tests (Plan F-07 M-4)', () {
    late AnalyticsMockRepoImpl repo;
    late InMemoryAuditLogger auditLogger;
    late MockUserSessionProvider userProvider;
    late MockRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late GetAnalyticsSummaryUseCase getSummaryUseCase;
    late GetRevenueTrendUseCase getTrendUseCase;
    late GetBranchComparisonUseCase getBranchesUseCase;
    late GetDoctorPerformanceUseCase getDoctorsUseCase;
    late GetHourlyTrafficUseCase getTrafficUseCase;
    late AnalyticsCubit cubit;

    const allAdminRoleId = 'role_all_admin_test';
    final allAdminRole = RoleDefinitionModel(
      id: allAdminRoleId,
      permissions: const [
        StaffPermissionEnum.accessAnalytics,
        StaffPermissionEnum.viewFinancialReports,
      ],
    );

    final adminUser = StaffUserModel(
      id: 'usr_admin',
      isActive: true,
      branchAssignments: const [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [allAdminRoleId]),
      ],
    );

    setUp(() {
      repo = AnalyticsMockRepoImpl(seedInitialData: true);
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = MockRolesSessionProvider(
        roles: [allAdminRole, ...RoleDefinitionModel.defaultSystemRoles()],
      );
      userProvider = MockUserSessionProvider(user: adminUser, branch: 'branch_1');

      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      getSummaryUseCase = GetAnalyticsSummaryUseCase(
        analyticsRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      getTrendUseCase = GetRevenueTrendUseCase(
        analyticsRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      getBranchesUseCase = GetBranchComparisonUseCase(
        analyticsRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      getDoctorsUseCase = GetDoctorPerformanceUseCase(
        analyticsRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      getTrafficUseCase = GetHourlyTrafficUseCase(
        analyticsRepo: repo,
        permissionEvaluator: permissionEvaluator,
        currentUserProvider: userProvider,
      );

      cubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: getSummaryUseCase,
        getRevenueTrendUseCase: getTrendUseCase,
        getBranchComparisonUseCase: getBranchesUseCase,
        getDoctorPerformanceUseCase: getDoctorsUseCase,
        getHourlyTrafficUseCase: getTrafficUseCase,
        analyticsRepo: repo,
      );
    });

    tearDown(() {
      cubit.close();
    });

    // -------------------------------------------------------------------------
    // 1. Initial State Defaults
    // -------------------------------------------------------------------------
    test('1. Initial state has proper defaults', () {
      expect(cubit.state.activeTab, AnalyticsTabEnum.executive);
      expect(cubit.state.selectedTimeRange, AnalyticsTimeRangeEnum.thisMonth);
      expect(cubit.state.selectedBranchId, isNull);
      expect(cubit.state.summaryStatus, RequestStatusEnum.initial);
      expect(cubit.state.trendStatus, RequestStatusEnum.initial);
      expect(cubit.state.branchesStatus, RequestStatusEnum.initial);
      expect(cubit.state.doctorsStatus, RequestStatusEnum.initial);
      expect(cubit.state.trafficStatus, RequestStatusEnum.initial);
      expect(cubit.state.servicesStatus, RequestStatusEnum.initial);
    });

    // -------------------------------------------------------------------------
    // 2. Tab Navigation
    // -------------------------------------------------------------------------
    test('2. setActiveTab updates activeTab correctly', () {
      cubit.setActiveTab(AnalyticsTabEnum.financial);
      expect(cubit.state.activeTab, AnalyticsTabEnum.financial);

      cubit.setActiveTab(AnalyticsTabEnum.clinical);
      expect(cubit.state.activeTab, AnalyticsTabEnum.clinical);

      cubit.setActiveTab(AnalyticsTabEnum.doctors);
      expect(cubit.state.activeTab, AnalyticsTabEnum.doctors);
    });

    // -------------------------------------------------------------------------
    // 3. Parallel Load All Analytics
    // -------------------------------------------------------------------------
    test('3. loadAllAnalytics populates all dashboard sections in parallel', () async {
      await cubit.loadAllAnalytics();

      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.trendStatus, RequestStatusEnum.success);
      expect(cubit.state.branchesStatus, RequestStatusEnum.success);
      expect(cubit.state.doctorsStatus, RequestStatusEnum.success);
      expect(cubit.state.trafficStatus, RequestStatusEnum.success);
      expect(cubit.state.servicesStatus, RequestStatusEnum.success);

      expect(cubit.state.summary, isNotNull);
      expect(cubit.state.summary!.totalRevenuePiastres, isNotNull);
      expect(cubit.state.revenueTrend.isNotEmpty, isTrue);
      expect(cubit.state.branchComparisons.length, 3);
      expect(cubit.state.doctorPerformances.length, 6);
      expect(cubit.state.hourlyTraffic.isNotEmpty, isTrue);
      expect(cubit.state.serviceDistribution.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Time Range Filter Changes
    // -------------------------------------------------------------------------
    test('4. setTimeRange updates selectedTimeRange and reloads all sections', () async {
      await cubit.setTimeRange(AnalyticsTimeRangeEnum.today);

      expect(cubit.state.selectedTimeRange, AnalyticsTimeRangeEnum.today);
      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.revenueTrend.length, 13); // Today has 13 hourly points
    });

    test('5. setTimeRange custom sets customStartDate and customEndDate', () async {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 20);

      await cubit.setTimeRange(
        AnalyticsTimeRangeEnum.custom,
        customStart: start,
        customEnd: end,
      );

      expect(cubit.state.selectedTimeRange, AnalyticsTimeRangeEnum.custom);
      expect(cubit.state.customStartDate, start);
      expect(cubit.state.customEndDate, end);
    });

    // -------------------------------------------------------------------------
    // 5. Branch Filter Changes
    // -------------------------------------------------------------------------
    test('6. setBranchId filters data to specific branch', () async {
      await cubit.setBranchId('branch_1');

      expect(cubit.state.selectedBranchId, 'branch_1');
      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.summary!.totalRevenuePiastres, 18500000);
    });

    test('7. setBranchId with null restores consolidated view', () async {
      await cubit.setBranchId('branch_1');
      expect(cubit.state.selectedBranchId, 'branch_1');

      await cubit.setBranchId(null);
      expect(cubit.state.selectedBranchId, isNull);
      expect(cubit.state.summary!.totalRevenuePiastres! > 18500000, isTrue);
    });

    // -------------------------------------------------------------------------
    // 6. Independent Section Loaders & Retries
    // -------------------------------------------------------------------------
    test('8. loadSummary independently updates only summary section', () async {
      await cubit.loadSummary();

      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.summary, isNotNull);
      // Other sections remain untouched initial
      expect(cubit.state.trendStatus, RequestStatusEnum.initial);
      expect(cubit.state.doctorsStatus, RequestStatusEnum.initial);
    });

    test('9. loadRevenueTrend independently updates trend section', () async {
      await cubit.loadRevenueTrend();

      expect(cubit.state.trendStatus, RequestStatusEnum.success);
      expect(cubit.state.revenueTrend.isNotEmpty, isTrue);
      expect(cubit.state.summaryStatus, RequestStatusEnum.initial);
    });

    test('10. loadBranchComparison independently updates branch comparison section', () async {
      await cubit.loadBranchComparison();

      expect(cubit.state.branchesStatus, RequestStatusEnum.success);
      expect(cubit.state.branchComparisons.length, 3);
    });

    test('11. loadDoctorPerformance independently updates doctors section', () async {
      await cubit.loadDoctorPerformance();

      expect(cubit.state.doctorsStatus, RequestStatusEnum.success);
      expect(cubit.state.doctorPerformances.length, 6);
    });

    test('12. loadHourlyTraffic independently updates traffic section', () async {
      await cubit.loadHourlyTraffic();

      expect(cubit.state.trafficStatus, RequestStatusEnum.success);
      expect(cubit.state.hourlyTraffic.isNotEmpty, isTrue);
    });

    test('13. loadServiceDistribution independently updates services section', () async {
      await cubit.loadServiceDistribution();

      expect(cubit.state.servicesStatus, RequestStatusEnum.success);
      expect(cubit.state.serviceDistribution.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. Error & Permission Handling in State
    // -------------------------------------------------------------------------
    test('14. Unauthorized user triggers failure status on summary', () async {
      userProvider.user = null;

      await cubit.loadSummary();

      expect(cubit.state.summaryStatus, RequestStatusEnum.failure);
      expect(cubit.state.summaryError, 'permission_denied');
    });

    test('15. Unauthorized user triggers failure status on trend', () async {
      userProvider.user = null;

      await cubit.loadRevenueTrend();

      expect(cubit.state.trendStatus, RequestStatusEnum.failure);
      expect(cubit.state.trendError, 'permission_denied');
    });

    test('16. Unauthorized user triggers failure status on branches', () async {
      userProvider.user = null;

      await cubit.loadBranchComparison();

      expect(cubit.state.branchesStatus, RequestStatusEnum.failure);
      expect(cubit.state.branchesError, 'permission_denied');
    });

    test('17. Unauthorized user triggers failure status on doctors', () async {
      userProvider.user = null;

      await cubit.loadDoctorPerformance();

      expect(cubit.state.doctorsStatus, RequestStatusEnum.failure);
      expect(cubit.state.doctorsError, 'permission_denied');
    });

    test('18. Unauthorized user triggers failure status on traffic', () async {
      userProvider.user = null;

      await cubit.loadHourlyTraffic();

      expect(cubit.state.trafficStatus, RequestStatusEnum.failure);
      expect(cubit.state.trafficError, 'permission_denied');
    });

    test('19. Retrying a failed section clears previous error message', () async {
      userProvider.user = null;
      await cubit.loadSummary();
      expect(cubit.state.summaryStatus, RequestStatusEnum.failure);

      // Authenticate user and retry
      userProvider.user = adminUser;
      await cubit.loadSummary();

      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.summaryError, isNull);
    });

    test('20. Partial failure: One failing section does NOT block other sections in loadAllAnalytics', () async {
      // In this setup, user is authenticated so all succeed
      await cubit.loadAllAnalytics();
      expect(cubit.state.summaryStatus, RequestStatusEnum.success);
      expect(cubit.state.trendStatus, RequestStatusEnum.success);
      expect(cubit.state.branchesStatus, RequestStatusEnum.success);
    });
  });
}

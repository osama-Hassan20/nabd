import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_mock_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
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
  group('Analytics Domain Use Cases & Security Tests (Plan F-07 M-3)', () {
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

    const managerRoleId = 'role_branch_manager_test';
    const accountantRoleId = 'role_accountant_test';
    const doctorRoleId = 'role_doctor_test';

    final managerRole = RoleDefinitionModel(
      id: managerRoleId,
      permissions: const [
        StaffPermissionEnum.accessAnalytics,
        // No viewFinancialReports permission
      ],
    );

    final accountantRole = RoleDefinitionModel(
      id: accountantRoleId,
      permissions: const [
        StaffPermissionEnum.accessAnalytics,
        StaffPermissionEnum.viewFinancialReports,
      ],
    );

    final doctorRole = RoleDefinitionModel(
      id: doctorRoleId,
      permissions: const [
        StaffPermissionEnum.accessCashier, // Lacks accessAnalytics entirely
      ],
    );

    setUp(() {
      repo = AnalyticsMockRepoImpl(seedInitialData: true);
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

      rolesProvider = MockRolesSessionProvider(
        roles: [managerRole, accountantRole, doctorRole, ...RoleDefinitionModel.defaultSystemRoles()],
      );
      userProvider = MockUserSessionProvider();

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
    });

    // -------------------------------------------------------------------------
    // 1. Authentication & Fail-Closed Guard Tests
    // -------------------------------------------------------------------------
    test('1. Null user fails closed with permission_denied', () async {
      userProvider.user = null;
      final res = await getSummaryUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
      expect(res.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('2. Inactive user fails closed across all analytics use cases', () async {
      userProvider.user = const StaffUserModel(id: 'usr_inactive', isActive: false);

      expect((await getSummaryUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth)).isLeft(), isTrue);
      expect((await getTrendUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth)).isLeft(), isTrue);
      expect((await getBranchesUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth)).isLeft(), isTrue);
      expect((await getDoctorsUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth)).isLeft(), isTrue);
      expect((await getTrafficUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth)).isLeft(), isTrue);
    });

    test('3. Doctor lacking accessAnalytics permission is rejected', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_doc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );

      final res = await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
      expect(res.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    // -------------------------------------------------------------------------
    // 2. Financial Privacy Masking for Operational Users
    // -------------------------------------------------------------------------
    test('4. Manager with accessAnalytics but NO viewFinancialReports gets MASKED financial numbers in summary', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_mgr',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);

      final summary = res.getOrElse(() => throw StateError(''));
      // Clinical metrics remain visible
      expect(summary.totalVisitsCount, isNotNull);
      expect(summary.totalVisitsCount! > 0, isTrue);
      expect(summary.completedVisitsCount, isNotNull);
      expect(summary.averageWaitTimeMinutes, isNotNull);

      // Financial metrics are STRICTLY masked to null
      expect(summary.totalRevenuePiastres, isNull);
      expect(summary.netProfitPiastres, isNull);
      expect(summary.totalDoctorPayoutsPiastres, isNull);
      expect(summary.totalStaffPayrollPiastres, isNull);
      expect(summary.outstandingDebtsPiastres, isNull);
    });

    test('5. Accountant with viewFinancialReports sees FULL financial numbers in summary', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);

      final summary = res.getOrElse(() => throw StateError(''));
      expect(summary.totalRevenuePiastres, 18500000);
      expect(summary.netProfitPiastres, isNotNull);
      expect(summary.totalDoctorPayoutsPiastres, isNotNull);
      expect(summary.totalStaffPayrollPiastres, isNotNull);
    });

    test('6. Clinic Owner bypasses checks and sees full consolidated numbers', () async {
      userProvider.user = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

      final res = await getSummaryUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final summary = res.getOrElse(() => throw StateError(''));
      expect(summary.totalRevenuePiastres! > 18500000, isTrue);
    });

    // -------------------------------------------------------------------------
    // 3. Revenue Trend Permission Check
    // -------------------------------------------------------------------------
    test('7. Revenue trend is REJECTED for manager lacking viewFinancialReports', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_mgr',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await getTrendUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
      expect(res.fold((f) => f.errMessage, (r) => null), 'permission_denied');
    });

    test('8. Revenue trend SUCCEEDS for accountant with viewFinancialReports', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await getTrendUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final list = res.getOrElse(() => []);
      expect(list.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Branch Comparison Permission Check
    // -------------------------------------------------------------------------
    test('9. Branch comparison succeeds for user with accessAnalytics', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await getBranchesUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final branches = res.getOrElse(() => []);
      expect(branches.length, 3);
    });

    test('10. Branch comparison rejected for user without accessAnalytics', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_doc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );

      final res = await getBranchesUseCase(timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
    });

    // -------------------------------------------------------------------------
    // 5. Doctor Performance Masking Check
    // -------------------------------------------------------------------------
    test('11. Doctor performance masks financial shares for user without viewFinancialReports', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_mgr',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await getDoctorsUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final list = res.getOrElse(() => []);

      for (final doc in list) {
        expect(doc.visitsCount, isNotNull);
        expect(doc.avgConsultationDurationMinutes, isNotNull);
        expect(doc.revenueGeneratedPiastres, isNull);
        expect(doc.doctorCommissionPiastres, isNull);
        expect(doc.clinicSharePiastres, isNull);
      }
    });

    test('12. Doctor performance includes revenue shares for accountant', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      final res = await getDoctorsUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final list = res.getOrElse(() => []);

      for (final doc in list) {
        expect(doc.revenueGeneratedPiastres, isNotNull);
        expect(doc.doctorCommissionPiastres, isNotNull);
        expect(doc.clinicSharePiastres, isNotNull);
      }
    });

    // -------------------------------------------------------------------------
    // 6. Hourly Traffic Use Case
    // -------------------------------------------------------------------------
    test('13. Hourly traffic succeeds for manager and returns occupancy breakdown', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_mgr',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [managerRoleId]),
        ],
      );

      final res = await getTrafficUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      final traffic = res.getOrElse(() => []);
      expect(traffic.length, 14);
    });

    test('14. Hourly traffic rejected for unauthenticated user', () async {
      userProvider.user = null;
      final res = await getTrafficUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. Security Audit Logging Compliance
    // -------------------------------------------------------------------------
    test('15. Summary query emits analytics_summary_viewed audit event on success', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        fullName: 'عمر المحاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);

      final logs = auditLogger.getLogs(eventType: 'analytics_summary_viewed');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.details, contains('branchId: branch_1'));
      expect(log.details, contains('timeRange: thisMonth'));
      expect(log.details, contains('financialIncluded: true'));
    });

    test('16. Summary audit log details strictly conform to whitelist (no patient or clinical text)', () async {
      userProvider.user = const StaffUserModel(
        id: 'usr_acc',
        fullName: 'عمر المحاسب',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [accountantRoleId]),
        ],
      );

      await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);

      final log = auditLogger.getLogs(eventType: 'analytics_summary_viewed').first;
      expect(log.details, isNot(contains('patient')));
      expect(log.details, isNot(contains('diagnosis')));
      expect(log.details, isNot(contains('prescription')));
    });

    test('17. Zero Audit on Failure: Failed authorization emits ZERO audit events', () async {
      final initialCount = auditLogger.getLogs().length;

      userProvider.user = const StaffUserModel(
        id: 'usr_doc',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [doctorRoleId]),
        ],
      );

      final res = await getSummaryUseCase(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);

      expect(auditLogger.getLogs().length, initialCount);
    });

    // -------------------------------------------------------------------------
    // 8. Custom Time Range Boundaries
    // -------------------------------------------------------------------------
    test('18. Custom time range passes correctly to repository', () async {
      userProvider.user = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

      final customStart = DateTime(2026, 9, 1);
      final customEnd = DateTime(2026, 9, 15);

      final res = await getSummaryUseCase(
        timeRange: AnalyticsTimeRangeEnum.custom,
        customStart: customStart,
        customEnd: customEnd,
      );

      expect(res.isRight(), isTrue);
    });

    test('19. Doctor performance custom range works for owner', () async {
      userProvider.user = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

      final res = await getDoctorsUseCase(
        timeRange: AnalyticsTimeRangeEnum.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 31),
      );

      expect(res.isRight(), isTrue);
    });

    test('20. Branch comparison custom range works for owner', () async {
      userProvider.user = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

      final res = await getBranchesUseCase(
        timeRange: AnalyticsTimeRangeEnum.custom,
        customStart: DateTime(2026, 8, 1),
        customEnd: DateTime(2026, 8, 31),
      );

      expect(res.isRight(), isTrue);
    });
  });
}


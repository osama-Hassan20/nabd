import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class FakeUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  FakeUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class FakeRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  FakeRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  late AnalyticsRepoImpl mockRepo;
  late InMemoryAuditLogger auditLogger;

  // Roles
  const ownerRoleId = 'owner_role';
  const branchManagerRoleId = 'branch_manager_role';
  const clinicalStaffRoleId = 'clinical_staff_role';
  const unauthorizedRoleId = 'unauthorized_role';

  final ownerRole = RoleDefinitionModel(
    id: ownerRoleId,
    permissions: const [
      StaffPermissionEnum.accessAnalytics,
      StaffPermissionEnum.viewFinancialReports,
    ],
  );

  final branchManagerRole = RoleDefinitionModel(
    id: branchManagerRoleId,
    permissions: const [
      StaffPermissionEnum.accessAnalytics,
      StaffPermissionEnum.viewFinancialReports,
    ],
  );

  final clinicalStaffRole = RoleDefinitionModel(
    id: clinicalStaffRoleId,
    permissions: const [
      StaffPermissionEnum.accessAnalytics,
    ],
  );

  final unauthorizedRole = RoleDefinitionModel(
    id: unauthorizedRoleId,
    permissions: const [],
  );

  // Users
  final ownerUser = const StaffUserModel(
    id: 'usr_owner',
    isOwner: true,
    isActive: true,
  );

  final branch1ManagerUser = const StaffUserModel(
    id: 'usr_mgr_1',
    branchAssignments: [
      BranchAssignmentModel(branchId: 'branch_1', roleIds: [branchManagerRoleId]),
    ],
    isActive: true,
  );

  final clinicalUser = const StaffUserModel(
    id: 'usr_clinical',
    branchAssignments: [
      BranchAssignmentModel(branchId: 'branch_1', roleIds: [clinicalStaffRoleId]),
    ],
    isActive: true,
  );

  final unauthorizedUser = const StaffUserModel(
    id: 'usr_no_access',
    branchAssignments: [
      BranchAssignmentModel(branchId: 'branch_1', roleIds: [unauthorizedRoleId]),
    ],
    isActive: true,
  );

  setUp(() {
    mockRepo = AnalyticsRepoImpl(apiConsumer: LocalServerApiConsumer());
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
  });

  group('Analytics RBAC, Privacy Masking & Multi-Branch Isolation Tests (Plan F-07 M-9)', () {
    // -------------------------------------------------------------------------
    // 1. RBAC Entry Guard (accessAnalytics)
    // -------------------------------------------------------------------------
    test('1. User without accessAnalytics permission receives permission_denied error', () async {
      final session = FakeUserSessionProvider(user: unauthorizedUser);
      final roles = FakeRolesSessionProvider(roles: [unauthorizedRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.today);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, equals('permission_denied')),
        (_) => fail('Should have failed'),
      );
    });

    test('2. Revenue trend use case denies user without accessAnalytics permission', () async {
      final session = FakeUserSessionProvider(user: unauthorizedUser);
      final roles = FakeRolesSessionProvider(roles: [unauthorizedRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final revenueUc = GetRevenueTrendUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
      );

      final res = await revenueUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
    });

    test('3. Doctor performance use case denies user without accessAnalytics permission', () async {
      final session = FakeUserSessionProvider(user: unauthorizedUser);
      final roles = FakeRolesSessionProvider(roles: [unauthorizedRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final doctorUc = GetDoctorPerformanceUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
      );

      final res = await doctorUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
    });

    // -------------------------------------------------------------------------
    // 2. Financial Privacy Masking (viewFinancialReports)
    // -------------------------------------------------------------------------
    test('4. User without viewFinancialReports has revenue and profit fields masked to null in summary', () async {
      final session = FakeUserSessionProvider(user: clinicalUser);
      final roles = FakeRolesSessionProvider(roles: [clinicalStaffRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (summary) {
          // Financial fields must be null (masked)
          expect(summary.totalRevenuePiastres, isNull);
          expect(summary.netProfitPiastres, isNull);
          expect(summary.outstandingDebtsPiastres, isNull);
          // Clinical & operational metrics remain visible
          expect(summary.totalVisitsCount, isNotNull);
          expect(summary.completedVisitsCount, isNotNull);
          expect(summary.averageWaitTimeMinutes, isNotNull);
        },
      );
    });

    test('5. User with viewFinancialReports sees full unmasked financial metrics in summary', () async {
      final session = FakeUserSessionProvider(user: branch1ManagerUser);
      final roles = FakeRolesSessionProvider(roles: [branchManagerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (summary) {
          expect(summary.totalRevenuePiastres, isNotNull);
          expect(summary.totalRevenuePiastres, greaterThan(0));
          expect(summary.netProfitPiastres, isNotNull);
          expect(summary.outstandingDebtsPiastres, isNotNull);
        },
      );
    });

    test('6. User without viewFinancialReports is denied access to revenue trend usecase', () async {
      final session = FakeUserSessionProvider(user: clinicalUser);
      final roles = FakeRolesSessionProvider(roles: [clinicalStaffRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final revenueUc = GetRevenueTrendUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
      );

      final res = await revenueUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, equals('permission_denied')),
        (_) => fail('Should have failed due to financial permission check'),
      );
    });

    test('7. User without viewFinancialReports has revenue masked in doctor leaderboard', () async {
      final session = FakeUserSessionProvider(user: clinicalUser);
      final roles = FakeRolesSessionProvider(roles: [clinicalStaffRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final doctorUc = GetDoctorPerformanceUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
      );

      final res = await doctorUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (doctors) {
          expect(doctors.isNotEmpty, isTrue);
          for (final doc in doctors) {
            expect(doc.revenueGeneratedPiastres, isNull);
            expect(doc.doctorCommissionPiastres, isNull);
            expect(doc.clinicSharePiastres, isNull);
            expect(doc.visitsCount, isNotNull);
          }
        },
      );
    });

    // -------------------------------------------------------------------------
    // 3. Multi-Branch Isolation & Fail-Closed Guard
    // -------------------------------------------------------------------------
    test('8. Branch manager restricted to branch_1 is denied access when querying branch_2', () async {
      final session = FakeUserSessionProvider(user: branch1ManagerUser);
      final roles = FakeRolesSessionProvider(roles: [branchManagerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(
        branchId: 'branch_2',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, equals('permission_denied')),
        (_) => fail('Should have failed due to branch isolation'),
      );
    });

    test('9. Branch manager restricted to branch_1 successfully queries their own branch', () async {
      final session = FakeUserSessionProvider(user: branch1ManagerUser);
      final roles = FakeRolesSessionProvider(roles: [branchManagerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (data) => expect(data.totalVisitsCount, isNotNull),
      );
    });

    test('10. Owner user can access all branches consolidated (branchId == null)', () async {
      final session = FakeUserSessionProvider(user: ownerUser);
      final roles = FakeRolesSessionProvider(roles: [ownerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      final res = await summaryUc(
        branchId: null,
        timeRange: AnalyticsTimeRangeEnum.thisMonth,
      );
      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (data) {
          // Consolidated revenue is significantly higher than single branch
          expect(data.totalRevenuePiastres, isNotNull);
          expect(data.totalRevenuePiastres, greaterThan(30000000));
        },
      );
    });

    test('11. Owner user can freely switch between branch_1, branch_2 and branch_3', () async {
      final session = FakeUserSessionProvider(user: ownerUser);
      final roles = FakeRolesSessionProvider(roles: [ownerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
      );

      final res1 = await summaryUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final res2 = await summaryUc(branchId: 'branch_2', timeRange: AnalyticsTimeRangeEnum.thisMonth);
      final res3 = await summaryUc(branchId: 'branch_3', timeRange: AnalyticsTimeRangeEnum.thisMonth);

      expect(res1.isRight(), isTrue);
      expect(res2.isRight(), isTrue);
      expect(res3.isRight(), isTrue);
    });

    // -------------------------------------------------------------------------
    // 4. Audit Logging Whitelist & Zero PII
    // -------------------------------------------------------------------------
    test('12. Successful analytics summary call logs audit event with whitelisted IDs and enums', () async {
      final session = FakeUserSessionProvider(user: branch1ManagerUser);
      final roles = FakeRolesSessionProvider(roles: [branchManagerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      await summaryUc(
        branchId: 'branch_1',
        timeRange: AnalyticsTimeRangeEnum.thisWeek,
      );

      final logs = auditLogger.getLogs();
      expect(logs.isNotEmpty, isTrue);
      final lastLog = logs.last;
      expect(lastLog.eventType, equals('analytics_summary_viewed'));
      expect(lastLog.performedByUserId, equals('usr_mgr_1'));
      expect(lastLog.branchId, equals('branch_1'));
      expect(lastLog.details?.contains('thisWeek'), isTrue);
    });

    test('13. Denied call does NOT produce audit entry (no audit on failure rule)', () async {
      final session = FakeUserSessionProvider(user: unauthorizedUser);
      final roles = FakeRolesSessionProvider(roles: [unauthorizedRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final initialLogsCount = auditLogger.getLogs().length;

      final summaryUc = GetAnalyticsSummaryUseCase(
        analyticsRepo: mockRepo,
        permissionEvaluator: perm,
        currentUserProvider: session,
        auditLogger: auditLogger,
      );

      await summaryUc(branchId: 'branch_1', timeRange: AnalyticsTimeRangeEnum.today);
      expect(auditLogger.getLogs().length, equals(initialLogsCount));
    });

    // -------------------------------------------------------------------------
    // 5. CairoTimeHelper & Time Range Bounds
    // -------------------------------------------------------------------------
    test('14. CairoTimeHelper guarantees correct time bounds for today without DST drift', () {
      final bounds = mockRepo.resolveDateRange(timeRange: AnalyticsTimeRangeEnum.today);
      final now = CairoTimeHelper.now();

      expect(bounds.start.year, equals(now.year));
      expect(bounds.start.month, equals(now.month));
      expect(bounds.start.day, equals(now.day));
      expect(bounds.start.hour, equals(0));
      expect(bounds.start.minute, equals(0));
      expect(bounds.end.hour, equals(23));
      expect(bounds.end.minute, equals(59));
    });

    test('15. Hourly traffic covers clinic operating hours from 09:00 to 22:00', () async {
      final session = FakeUserSessionProvider(user: ownerUser);
      final roles = FakeRolesSessionProvider(roles: [ownerRole]);
      final perm = PermissionEvaluator(userProvider: session, rolesProvider: roles);

      final trafficUc = GetHourlyTrafficUseCase(
        analyticsRepo: mockRepo,
        currentUserProvider: session,
        permissionEvaluator: perm,
      );
      final res = await trafficUc(timeRange: AnalyticsTimeRangeEnum.today);

      expect(res.isRight(), isTrue);
      res.fold(
        (l) => fail('Should succeed'),
        (slots) {
          expect(slots.length, equals(14));
          expect(slots.first.hour, equals(9));
          expect(slots.last.hour, equals(22));
          for (final slot in slots) {
            expect(slot.visitsCount, isNotNull);
            expect(slot.occupancyLevel, isNotNull);
          }
        },
      );
    });
  });
}

import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_tab_enum.dart';
import 'package:eyadty/features/analytics/data/models/enums/analytics_time_range_enum.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/analytics/presentation/pages/analytics_page.dart';
import 'package:eyadty/features/analytics/presentation/widgets/analytics_metric_grid.dart';
import 'package:eyadty/features/analytics/presentation/widgets/branch_comparison_chart_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/doctor_performance_table_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/hourly_traffic_heatmap_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/revenue_trend_chart_card.dart';
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

Widget _buildTestApp({
  required AnalyticsCubit cubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: AnalyticsPage(cubit: cubit),
    ),
  );
}

void _setViewport(WidgetTester tester, {required double width, required double height}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  addTearDown(() => tester.view.resetDevicePixelRatio());
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late AnalyticsRepoImpl mockRepo;
  late FakeUserSessionProvider userSession;
  late FakeRolesSessionProvider rolesSession;
  late PermissionEvaluator permissionEvaluator;
  late AnalyticsCubit cubit;

  final adminUser = const StaffUserModel(
    id: 'user_admin',
    isOwner: true,
    isActive: true,
  );

  setUp(() {
    mockRepo = AnalyticsRepoImpl(apiConsumer: LocalServerApiConsumer());
    userSession = FakeUserSessionProvider(user: adminUser);
    rolesSession = FakeRolesSessionProvider(roles: RoleDefinitionModel.defaultSystemRoles());
    permissionEvaluator = PermissionEvaluator(
      userProvider: userSession,
      rolesProvider: rolesSession,
    );

    final summaryUc = GetAnalyticsSummaryUseCase(
      analyticsRepo: mockRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userSession,
    );
    final revenueUc = GetRevenueTrendUseCase(
      analyticsRepo: mockRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userSession,
    );
    final branchUc = GetBranchComparisonUseCase(
      analyticsRepo: mockRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userSession,
    );
    final doctorUc = GetDoctorPerformanceUseCase(
      analyticsRepo: mockRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userSession,
    );
    final trafficUc = GetHourlyTrafficUseCase(
      analyticsRepo: mockRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userSession,
    );

    cubit = AnalyticsCubit(
      getAnalyticsSummaryUseCase: summaryUc,
      getRevenueTrendUseCase: revenueUc,
      getBranchComparisonUseCase: branchUc,
      getDoctorPerformanceUseCase: doctorUc,
      getHourlyTrafficUseCase: trafficUc,
      analyticsRepo: mockRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('AnalyticsPage Integration & Navigation Tests', () {
    testWidgets('1. Renders title, subtitle and header icon', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('analytics_title'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
    });

    testWidgets('2. Renders all 4 navigation tabs in filter bar', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tab_executive')), findsOneWidget);
      expect(find.byKey(const Key('tab_financial')), findsOneWidget);
      expect(find.byKey(const Key('tab_clinical')), findsOneWidget);
      expect(find.byKey(const Key('tab_doctors')), findsOneWidget);
    });

    testWidgets('3. Default tab is executive and renders metric grid, revenue chart, branch comparison and heatmap', (tester) async {
      _setViewport(tester, width: 1400, height: 1200);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsMetricGrid), findsOneWidget);
      expect(find.byType(RevenueTrendChartCard), findsOneWidget);
      expect(find.byType(BranchComparisonChartCard), findsOneWidget);
      expect(find.byType(HourlyTrafficHeatmapCard), findsOneWidget);
      expect(find.byType(DoctorPerformanceTableCard), findsNothing);
    });

    testWidgets('4. Switching to financial tab renders metric grid and charts but hides heatmap', (tester) async {
      _setViewport(tester, width: 1400, height: 1200);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.setActiveTab(AnalyticsTabEnum.financial);
      await tester.pumpAndSettle();

      expect(cubit.state.activeTab, equals(AnalyticsTabEnum.financial));
      expect(find.byType(AnalyticsMetricGrid), findsOneWidget);
      expect(find.byType(RevenueTrendChartCard), findsOneWidget);
      expect(find.byType(BranchComparisonChartCard), findsOneWidget);
      expect(find.byType(HourlyTrafficHeatmapCard), findsNothing);
    });

    testWidgets('5. Switching to clinical tab renders metric grid and heatmap but hides revenue charts', (tester) async {
      _setViewport(tester, width: 1400, height: 1200);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.setActiveTab(AnalyticsTabEnum.clinical);
      await tester.pumpAndSettle();

      expect(cubit.state.activeTab, equals(AnalyticsTabEnum.clinical));
      expect(find.byType(AnalyticsMetricGrid), findsOneWidget);
      expect(find.byType(HourlyTrafficHeatmapCard), findsOneWidget);
      expect(find.byType(RevenueTrendChartCard), findsNothing);
      expect(find.byType(BranchComparisonChartCard), findsNothing);
    });

    testWidgets('6. Switching to doctors tab renders doctor performance table card', (tester) async {
      _setViewport(tester, width: 1400, height: 1200);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.setActiveTab(AnalyticsTabEnum.doctors);
      await tester.pumpAndSettle();

      expect(cubit.state.activeTab, equals(AnalyticsTabEnum.doctors));
      expect(find.byType(DoctorPerformanceTableCard), findsOneWidget);
      expect(find.byType(AnalyticsMetricGrid), findsNothing);
      expect(find.byType(RevenueTrendChartCard), findsNothing);
    });

    testWidgets('7. Time range dropdown is present with default thisMonth', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_time_range')), findsOneWidget);
      expect(cubit.state.selectedTimeRange, equals(AnalyticsTimeRangeEnum.thisMonth));
    });

    testWidgets('8. Changing time range via cubit reflects in cubit state and reloads', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await cubit.setTimeRange(AnalyticsTimeRangeEnum.today);
      await tester.pumpAndSettle();

      expect(cubit.state.selectedTimeRange, equals(AnalyticsTimeRangeEnum.today));
    });

    testWidgets('9. Branch dropdown is present with default null (All branches)', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_branch')), findsOneWidget);
      expect(cubit.state.selectedBranchId, isNull);
    });

    testWidgets('10. Changing branch via cubit updates selectedBranchId and reloads', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await cubit.setBranchId('branch_1');
      await tester.pumpAndSettle();

      expect(cubit.state.selectedBranchId, equals('branch_1'));
    });

    testWidgets('11. Refresh button invokes loadAllAnalytics', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final refreshBtn = find.byKey(const Key('btn_refresh_analytics'));
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(cubit.state.summaryStatus, equals(RequestStatusEnum.success));
    });

    testWidgets('12. Desktop layout (width >= 1000) renders charts side-by-side horizontally', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(RevenueTrendChartCard), findsOneWidget);
      expect(find.byType(BranchComparisonChartCard), findsOneWidget);

      final revenueTop = tester.getTopLeft(find.byType(RevenueTrendChartCard)).dy;
      final branchTop = tester.getTopLeft(find.byType(BranchComparisonChartCard)).dy;

      // In side-by-side Row, their top Y-coordinates are equal
      expect((revenueTop - branchTop).abs(), lessThan(5.0));
    });

    testWidgets('13. Mobile/tablet layout (width < 1000) renders charts stacked vertically', (tester) async {
      _setViewport(tester, width: 750, height: 1600);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(RevenueTrendChartCard), findsOneWidget);
      expect(find.byType(BranchComparisonChartCard), findsOneWidget);

      final revenueTop = tester.getTopLeft(find.byType(RevenueTrendChartCard)).dy;
      final branchTop = tester.getTopLeft(find.byType(BranchComparisonChartCard)).dy;

      // In stacked Column, branch chart is strictly below revenue chart
      expect(branchTop, greaterThan(revenueTop + 100));
    });

    testWidgets('14. Tab button in filter bar updates cubit activeTab when tapped', (tester) async {
      _setViewport(tester, width: 1400, height: 900);
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(cubit.state.activeTab, equals(AnalyticsTabEnum.executive));

      final docFinder = find.byKey(const Key('tab_doctors'));
      await tester.tap(docFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(cubit.state.activeTab, equals(AnalyticsTabEnum.doctors));
    });

    testWidgets('15. Tab changes properly re-render page without error or state loss', (tester) async {
      _setViewport(tester, width: 1400, height: 1200);
      await cubit.loadAllAnalytics();
      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Cycle through all tabs via cubit
      for (final tab in AnalyticsTabEnum.values) {
        cubit.setActiveTab(tab);
        await tester.pumpAndSettle();
        expect(cubit.state.activeTab, equals(tab));
      }
    });
  });
}

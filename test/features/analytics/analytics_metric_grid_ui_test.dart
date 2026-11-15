import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/analytics/data/models/analytics_summary_kpi_model.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_mock_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_state.dart';
import 'package:eyadty/features/analytics/presentation/widgets/analytics_metric_grid.dart';
import 'package:eyadty/features/analytics/presentation/widgets/shimmers/analytics_grid_shimmer.dart';
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

Widget _buildTestApp({
  required Widget child,
  required AnalyticsCubit cubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: BlocProvider<AnalyticsCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
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

  group('AnalyticsMetricGrid UI & Responsiveness Tests (Plan F-07 M-5)', () {
    late AnalyticsMockRepoImpl repo;
    late MockUserSessionProvider userProvider;
    late MockRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late AnalyticsCubit cubit;

    final ownerUser = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

    setUp(() {
      repo = AnalyticsMockRepoImpl(seedInitialData: true);
      rolesProvider = MockRolesSessionProvider(roles: RoleDefinitionModel.defaultSystemRoles());
      userProvider = MockUserSessionProvider(user: ownerUser, branch: 'branch_1');
      permissionEvaluator = PermissionEvaluator(userProvider: userProvider, rolesProvider: rolesProvider);

      cubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        analyticsRepo: repo,
      );
    });

    tearDown(() {
      cubit.close();
    });

    // -------------------------------------------------------------------------
    // 1. Loading & Error States
    // -------------------------------------------------------------------------
    testWidgets('1. Shimmer displays when summaryStatus == loading and summary is null', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final loadingCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(summaryStatus: RequestStatusEnum.loading),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: loadingCubit));
      await tester.pump();

      expect(find.byType(AnalyticsGridShimmer), findsOneWidget);
      loadingCubit.close();
    });

    testWidgets('2. Error state displays retry button and error message', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final errorCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          summaryStatus: RequestStatusEnum.failure,
          summaryError: 'فشل تحميل البيانات',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: errorCubit));
      await tester.pumpAndSettle();

      expect(find.text('فشل تحميل البيانات'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      errorCubit.close();
    });

    testWidgets('3. Clicking retry button triggers loadSummary', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final retryCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          summaryStatus: RequestStatusEnum.failure,
          summaryError: 'خطأ مؤقت',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: retryCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(
        retryCubit.state.summaryStatus == RequestStatusEnum.loading ||
            retryCubit.state.summaryStatus == RequestStatusEnum.success,
        isTrue,
      );
      retryCubit.close();
    });

    // -------------------------------------------------------------------------
    // 2. Card Content & Currency Verification
    // -------------------------------------------------------------------------
    testWidgets('4. Renders total revenue card with formatted currency when loaded', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_total_revenue')), findsOneWidget);
      expect(find.text('analytics_total_revenue'.tr()), findsOneWidget);
      expect(find.textContaining('ج.م'), findsWidgets);
    });

    testWidgets('5. Renders net profit card with formatted currency when loaded', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_net_profit')), findsOneWidget);
      expect(find.text('analytics_net_profit'.tr()), findsOneWidget);
    });

    testWidgets('6. Renders total visits card with completed visits count', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_total_visits')), findsOneWidget);
      expect(find.text('analytics_total_visits'.tr()), findsOneWidget);
      expect(find.textContaining('analytics_completed_visits'.tr()), findsOneWidget);
    });

    testWidgets('7. Renders average wait time card with minutes unit', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_avg_wait_time')), findsOneWidget);
      expect(find.text('analytics_avg_wait_time'.tr()), findsOneWidget);
      expect(find.textContaining('minutes_short'.tr()), findsOneWidget);
    });

    testWidgets('8. Renders patient return rate card with percent format', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_return_rate')), findsOneWidget);
      expect(find.text('analytics_patient_return_rate'.tr()), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('9. Renders outstanding debts card with formatted currency', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_outstanding_debts')), findsOneWidget);
      expect(find.text('analytics_outstanding_debts'.tr()), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 3. Masked State Verification (No Financial Permission)
    // -------------------------------------------------------------------------
    testWidgets('10. When financial numbers are masked (null), revenue card displays —', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final maskedCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          summaryStatus: RequestStatusEnum.success,
          summary: AnalyticsSummaryKpiModel(
            totalVisitsCount: 150,
            completedVisitsCount: 140,
            averageWaitTimeMinutes: 12,
            patientReturnRatePercent: 40.0,
            // All financial null
          ),
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: maskedCubit));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
      expect(find.text('150'), findsOneWidget);
      maskedCubit.close();
    });

    testWidgets('11. When financial numbers are masked (null), net profit card displays —', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final maskedCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          summaryStatus: RequestStatusEnum.success,
          summary: AnalyticsSummaryKpiModel(totalVisitsCount: 50),
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: maskedCubit));
      await tester.pumpAndSettle();

      final profitCard = find.byKey(const Key('card_net_profit'));
      expect(profitCard, findsOneWidget);
      expect(find.descendant(of: profitCard, matching: find.text('—')), findsOneWidget);
      maskedCubit.close();
    });

    testWidgets('12. When financial numbers are masked (null), debts card displays —', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final maskedCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          summaryStatus: RequestStatusEnum.success,
          summary: AnalyticsSummaryKpiModel(totalVisitsCount: 50),
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: maskedCubit));
      await tester.pumpAndSettle();

      final debtsCard = find.byKey(const Key('card_outstanding_debts'));
      expect(debtsCard, findsOneWidget);
      expect(find.descendant(of: debtsCard, matching: find.text('—')), findsOneWidget);
      maskedCubit.close();
    });

    // -------------------------------------------------------------------------
    // 4. Responsive Viewports
    // -------------------------------------------------------------------------
    testWidgets('13. Responsive layout: 3 columns on desktop (> 1100 px)', (tester) async {
      _setViewport(tester, width: 1280, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('14. Responsive layout: 2 columns on tablet (> 650 px and <= 1100 px)', (tester) async {
      _setViewport(tester, width: 800, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('15. Responsive layout: 1 column on mobile (<= 650 px)', (tester) async {
      _setViewport(tester, width: 400, height: 800);
      await cubit.loadSummary();

      await tester.pumpWidget(_buildTestApp(child: const AnalyticsMetricGrid(), cubit: cubit));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
    });
  });
}

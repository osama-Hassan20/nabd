import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/analytics/data/models/revenue_trend_point_model.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_state.dart';
import 'package:eyadty/features/analytics/presentation/widgets/branch_comparison_chart_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/revenue_trend_chart_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/shimmers/analytics_chart_shimmer.dart';
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

  group('Analytics Charts UI Tests (Plan F-07 M-6)', () {
    late AnalyticsRepoImpl repo;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late AnalyticsCubit cubit;

    final ownerUser = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

    setUp(() {
      repo = AnalyticsRepoImpl(seedInitialData: true);
      rolesProvider = FakeRolesSessionProvider(roles: RoleDefinitionModel.defaultSystemRoles());
      userProvider = FakeUserSessionProvider(user: ownerUser, branch: 'branch_1');
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
    // 1. Revenue Trend Chart Tests
    // -------------------------------------------------------------------------
    testWidgets('1. Revenue trend shimmer displays when trendStatus == loading and data is empty', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final loadingCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(trendStatus: RequestStatusEnum.loading),
      );

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: loadingCubit));
      await tester.pump();

      expect(find.byType(AnalyticsChartShimmer), findsOneWidget);
      loadingCubit.close();
    });

    testWidgets('2. Revenue trend error state displays retry button', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final errorCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trendStatus: RequestStatusEnum.failure,
          trendError: 'خطأ في جلب بيانات الاتجاه',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: errorCubit));
      await tester.pumpAndSettle();

      expect(find.text('خطأ في جلب بيانات الاتجاه'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      errorCubit.close();
    });

    testWidgets('3. Revenue trend renders LineChart with title and legends when loaded', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadRevenueTrend();

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('analytics_revenue_trend_title'.tr()), findsOneWidget);
      expect(find.text('analytics_total_revenue'.tr()), findsWidgets);
      expect(find.text('analytics_net_profit'.tr()), findsWidgets);
    });

    testWidgets('4. Revenue trend empty state displays no_data message', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final emptyCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trendStatus: RequestStatusEnum.success,
          revenueTrend: [],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: emptyCubit));
      await tester.pumpAndSettle();

      expect(find.text('no_data'.tr()), findsOneWidget);
      emptyCubit.close();
    });

    testWidgets('5. Revenue trend clicking retry calls loadRevenueTrend', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final retryCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trendStatus: RequestStatusEnum.failure,
          trendError: 'خطأ مؤقت',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: retryCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(
        retryCubit.state.trendStatus == RequestStatusEnum.loading ||
            retryCubit.state.trendStatus == RequestStatusEnum.success,
        isTrue,
      );
      retryCubit.close();
    });

    // -------------------------------------------------------------------------
    // 2. Branch Comparison Chart Tests
    // -------------------------------------------------------------------------
    testWidgets('6. Branch comparison shimmer displays when branchesStatus == loading and data is empty', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final loadingCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(branchesStatus: RequestStatusEnum.loading),
      );

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: loadingCubit));
      await tester.pump();

      expect(find.byType(AnalyticsChartShimmer), findsOneWidget);
      loadingCubit.close();
    });

    testWidgets('7. Branch comparison error state displays retry button', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final errorCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          branchesStatus: RequestStatusEnum.failure,
          branchesError: 'فشل في مقارنة الفروع',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: errorCubit));
      await tester.pumpAndSettle();

      expect(find.text('فشل في مقارنة الفروع'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      errorCubit.close();
    });

    testWidgets('8. Branch comparison renders BarChart and all three branches', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadBranchComparison();

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('analytics_branch_comparison_title'.tr()), findsOneWidget);
      expect(find.textContaining('المعادي'), findsWidgets);
      expect(find.textContaining('المهندسين'), findsWidgets);
      expect(find.textContaining('سموحة'), findsWidgets);
    });

    testWidgets('9. Branch comparison displays percentage share badges', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadBranchComparison();

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('10. Branch comparison empty state displays no_data message', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final emptyCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          branchesStatus: RequestStatusEnum.success,
          branchComparisons: [],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: emptyCubit));
      await tester.pumpAndSettle();

      expect(find.text('no_data'.tr()), findsOneWidget);
      emptyCubit.close();
    });

    testWidgets('11. Branch comparison clicking retry triggers loadBranchComparison', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final retryCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          branchesStatus: RequestStatusEnum.failure,
          branchesError: 'خطأ مؤقت',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: retryCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(
        retryCubit.state.branchesStatus == RequestStatusEnum.loading ||
            retryCubit.state.branchesStatus == RequestStatusEnum.success,
        isTrue,
      );
      retryCubit.close();
    });

    testWidgets('12. Revenue trend updates properly when custom points passed', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final customCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trendStatus: RequestStatusEnum.success,
          revenueTrend: [
            RevenueTrendPointModel(label: 'P1', revenuePiastres: 50000, netProfitPiastres: 25000),
            RevenueTrendPointModel(label: 'P2', revenuePiastres: 80000, netProfitPiastres: 40000),
          ],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: customCubit));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      customCubit.close();
    });

    testWidgets('13. Branch comparison displays formatted currency for each branch', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadBranchComparison();

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('ج.م'), findsWidgets);
    });

    testWidgets('14. Responsive viewport for charts on mobile view', (tester) async {
      _setViewport(tester, width: 400, height: 800);
      await cubit.loadRevenueTrend();

      await tester.pumpWidget(_buildTestApp(child: const RevenueTrendChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('15. Responsive viewport for branch comparison on tablet view', (tester) async {
      _setViewport(tester, width: 768, height: 1024);
      await cubit.loadBranchComparison();

      await tester.pumpWidget(_buildTestApp(child: const BranchComparisonChartCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
    });
  });
}

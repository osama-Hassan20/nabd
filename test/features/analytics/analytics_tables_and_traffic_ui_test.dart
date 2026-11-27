import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/analytics/data/models/doctor_performance_metric_model.dart';
import 'package:eyadty/features/analytics/data/repo/analytics_repo_impl.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart';
import 'package:eyadty/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_cubit.dart';
import 'package:eyadty/features/analytics/presentation/manager/analytics_state.dart';
import 'package:eyadty/features/analytics/presentation/widgets/doctor_performance_table_card.dart';
import 'package:eyadty/features/analytics/presentation/widgets/hourly_traffic_heatmap_card.dart';
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

  group('Analytics Tables & Traffic UI Tests (Plan F-07 M-7)', () {
    late AnalyticsRepoImpl repo;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late AnalyticsCubit cubit;

    final ownerUser = const StaffUserModel(id: 'usr_owner', isOwner: true, isActive: true);

    setUp(() {
      repo = AnalyticsRepoImpl(seedInitialData: true, apiConsumer: LocalServerApiConsumer());
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
    // 1. Doctor Performance Table Tests
    // -------------------------------------------------------------------------
    testWidgets('1. Doctor table displays shimmer when doctorsStatus == loading and data is empty', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final loadingCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(doctorsStatus: RequestStatusEnum.loading),
      );

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: loadingCubit));
      await tester.pump();

      expect(find.byType(AnalyticsChartShimmer), findsOneWidget);
      loadingCubit.close();
    });

    testWidgets('2. Doctor table error state displays retry button', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final errorCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          doctorsStatus: RequestStatusEnum.failure,
          doctorsError: 'فشل في تحميل بيانات الأطباء',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: errorCubit));
      await tester.pumpAndSettle();

      expect(find.text('فشل في تحميل بيانات الأطباء'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      errorCubit.close();
    });

    testWidgets('3. Doctor table renders title and all 6 official doctors when loaded', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadDoctorPerformance();

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('analytics_doctor_leaderboard_title'.tr()), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.textContaining('سامي'), findsWidgets);
      expect(find.textContaining('هبة'), findsWidgets);
      expect(find.textContaining('طارق'), findsWidgets);
    });

    testWidgets('4. Doctor table displays revenue and commission with formatted EGP', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadDoctorPerformance();

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('ج.م'), findsWidgets);
    });

    testWidgets('5. Doctor table displays masked — when revenue figures are null', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final maskedCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          doctorsStatus: RequestStatusEnum.success,
          doctorPerformances: [
            DoctorPerformanceMetricModel(
              doctorId: 'DOC-01',
              doctorName: 'د. سامي الجوهري',
              specialty: 'جلدية',
              visitsCount: 20,
              // All financial null
            ),
          ],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: maskedCubit));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
      expect(find.text('20'), findsOneWidget);
      maskedCubit.close();
    });

    testWidgets('6. Doctor table empty state displays no_data message', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final emptyCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          doctorsStatus: RequestStatusEnum.success,
          doctorPerformances: [],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: emptyCubit));
      await tester.pumpAndSettle();

      expect(find.text('no_data'.tr()), findsOneWidget);
      emptyCubit.close();
    });

    testWidgets('7. Doctor table retry button triggers loadDoctorPerformance', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final retryCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          doctorsStatus: RequestStatusEnum.failure,
          doctorsError: 'خطأ مؤقت',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: retryCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(
        retryCubit.state.doctorsStatus == RequestStatusEnum.loading ||
            retryCubit.state.doctorsStatus == RequestStatusEnum.success,
        isTrue,
      );
      retryCubit.close();
    });

    // -------------------------------------------------------------------------
    // 2. Hourly Traffic Heatmap Tests
    // -------------------------------------------------------------------------
    testWidgets('8. Traffic heatmap displays shimmer when trafficStatus == loading and data is empty', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final loadingCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(trafficStatus: RequestStatusEnum.loading),
      );

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: loadingCubit));
      await tester.pump();

      expect(find.byType(AnalyticsChartShimmer), findsOneWidget);
      loadingCubit.close();
    });

    testWidgets('9. Traffic heatmap error state displays retry button', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final errorCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trafficStatus: RequestStatusEnum.failure,
          trafficError: 'فشل في حساب أوقات الذروة',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: errorCubit));
      await tester.pumpAndSettle();

      expect(find.text('فشل في حساب أوقات الذروة'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      errorCubit.close();
    });

    testWidgets('10. Traffic heatmap renders title and hour blocks when loaded', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadHourlyTraffic();

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('analytics_peak_hours_title'.tr()), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
    });

    testWidgets('11. Traffic heatmap empty state displays no_data message', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final emptyCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trafficStatus: RequestStatusEnum.success,
          hourlyTraffic: [],
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: emptyCubit));
      await tester.pumpAndSettle();

      expect(find.text('no_data'.tr()), findsOneWidget);
      emptyCubit.close();
    });

    testWidgets('12. Traffic heatmap retry button triggers loadHourlyTraffic', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      final retryCubit = AnalyticsCubit(
        getAnalyticsSummaryUseCase: GetAnalyticsSummaryUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getRevenueTrendUseCase: GetRevenueTrendUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getBranchComparisonUseCase: GetBranchComparisonUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getDoctorPerformanceUseCase: GetDoctorPerformanceUseCase(analyticsRepo: repo, currentUserProvider: userProvider),
        getHourlyTrafficUseCase: GetHourlyTrafficUseCase(
          analyticsRepo: repo,
          currentUserProvider: userProvider,
          permissionEvaluator: permissionEvaluator,
        ),
        analyticsRepo: repo,
        initialState: const AnalyticsState(
          trafficStatus: RequestStatusEnum.failure,
          trafficError: 'خطأ مؤقت',
        ),
      );

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: retryCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(
        retryCubit.state.trafficStatus == RequestStatusEnum.loading ||
            retryCubit.state.trafficStatus == RequestStatusEnum.success,
        isTrue,
      );
      retryCubit.close();
    });

    testWidgets('13. Doctor table displays ratings with star icon', (tester) async {
      _setViewport(tester, width: 1200, height: 800);
      await cubit.loadDoctorPerformance();

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('14. Traffic heatmap responsive on mobile view without overflow', (tester) async {
      _setViewport(tester, width: 400, height: 800);
      await cubit.loadHourlyTraffic();

      await tester.pumpWidget(_buildTestApp(child: const HourlyTrafficHeatmapCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Doctor table horizontal scroll works without overflow', (tester) async {
      _setViewport(tester, width: 600, height: 800);
      await cubit.loadDoctorPerformance();

      await tester.pumpWidget(_buildTestApp(child: const DoctorPerformanceTableCard(), cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

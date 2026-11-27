import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/audit_logs/data/repo/audit_logs_repo_impl.dart';
import 'package:eyadty/features/audit_logs/domain/repo/audit_logs_repo.dart';
import 'package:eyadty/features/audit_logs/presentation/cubit/audit_logs_cubit.dart';
import 'package:eyadty/features/audit_logs/presentation/pages/audit_logs_page.dart';
import 'package:eyadty/features/audit_logs/presentation/pages/dialogs/audit_log_details_dialog.dart';
import 'package:eyadty/features/audit_logs/presentation/widgets/audit_logs_filter_bar.dart';
import 'package:eyadty/features/audit_logs/presentation/widgets/audit_logs_table.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/shared/widgets/custom_empty_widget.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

Widget _buildLocalizedApp({
  required Widget child,
  required SessionCubit sessionCubit,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: BlocProvider<SessionCubit>.value(
      value: sessionCubit,
      child: MaterialApp(
        locale: const Locale('ar', 'EG'),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAuditLogger auditLogger;
  late AuditLogsRepoImpl repo;
  late AuditLogsCubit cubit;
  late SessionCubit sessionCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar', null);
  });

  setUp(() async {
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: true);
    repo = AuditLogsRepoImpl(auditLogger: auditLogger);
    cubit = AuditLogsCubit(repo: repo);
    sessionCubit = SessionCubit(SessionState.initial());

    getIt.registerSingleton<AuditLogger>(auditLogger);
    getIt.registerSingleton<AuditLogsRepo>(repo);
    getIt.registerSingleton<AuditLogsCubit>(cubit);
    getIt.registerSingleton<SessionCubit>(sessionCubit);

    // Set active owner session
    final owner = const StaffUserModel(
      id: 'owner_01',
      fullName: 'د. خالد عبد الرحمن (المالك)',
      isOwner: true,
      isActive: true,
    );
    sessionCubit.switchDemoUser(owner);
    sessionCubit.switchBranch('branch_1');
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('F-03 Milestone 3: AuditLogsCubit Unit Tests', () {
    test('loadLogs populates logs and sets status to success', () async {
      expect(cubit.state.status, RequestStatusEnum.initial);
      await cubit.loadLogs();

      expect(cubit.state.status, RequestStatusEnum.success);
      expect(cubit.state.logs.length, greaterThanOrEqualTo(10));
      expect(cubit.state.filteredLogs.length, greaterThanOrEqualTo(10));
      expect(cubit.state.totalEventsCount, greaterThanOrEqualTo(10));
      expect(cubit.state.securityEventsCount, greaterThan(0));
      expect(cubit.state.patientAccessCount, greaterThan(0));
    });

    test('Filter by search query filters filteredLogs correctly', () async {
      await cubit.loadLogs();
      cubit.setSearchQuery('المعادي');

      final filtered = cubit.state.filteredLogs;
      expect(filtered, isNotEmpty);
      for (final log in filtered) {
        final matches = (log.branchName ?? '').contains('المعادي') ||
            (log.details ?? '').contains('المعادي') ||
            (log.performedByUserName ?? '').contains('المعادي');
        expect(matches, isTrue);
      }
    });

    test('Filter by eventType isolates specified event category', () async {
      await cubit.loadLogs();
      cubit.setEventTypeFilter('view_patient_profile');

      final filtered = cubit.state.filteredLogs;
      expect(filtered, isNotEmpty);
      expect(filtered.every((e) => e.eventType == 'view_patient_profile'), isTrue);
    });

    test('Filter by branch isolates specified branch', () async {
      await cubit.loadLogs();
      cubit.setBranchFilter('branch_3');

      final filtered = cubit.state.filteredLogs;
      expect(filtered, isNotEmpty);
      expect(filtered.every((e) => e.branchId == 'branch_3'), isTrue);
    });

    test('clearFilters resets all filtering criteria', () async {
      await cubit.loadLogs();
      cubit.setSearchQuery('test query');
      cubit.setEventTypeFilter('login_success');
      cubit.setBranchFilter('branch_2');

      cubit.clearFilters();
      expect(cubit.state.searchQuery, isEmpty);
      expect(cubit.state.selectedEventType, 'all');
      expect(cubit.state.selectedBranchId, 'all');
      expect(cubit.state.startDate, isNull);
      expect(cubit.state.endDate, isNull);
    });

    test('exportLogs produces CSV string with headers and content', () async {
      await cubit.loadLogs();
      final success = await cubit.exportLogs();

      expect(success, isTrue);
      expect(cubit.state.exportStatus, RequestStatusEnum.success);
      expect(cubit.state.exportData, isNotNull);
      expect(cubit.state.exportData, contains('ID,Timestamp,EventType,Actor,Target,Branch,IP,Details'));
      expect(cubit.state.exportData, contains('login_success'));
    });
  });

  group('F-03 Milestone 4: AuditLogsPage & Table Widget Tests', () {
    testWidgets('Renders page header, KPI summary cards, filter bar, and table', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const AuditLogsPage(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('audit_logs_title'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // KPI Cards
      expect(find.text('إجمالي السجلات'), findsOneWidget);
      expect(find.text('عمليات الأمان'), findsOneWidget);
      expect(find.text('استعراض ملفات المرضى'), findsOneWidget);
      expect(find.text('عمليات الفروع'), findsOneWidget);

      // Filter bar & Table
      expect(find.byType(AuditLogsFilterBar), findsOneWidget);
      expect(find.byType(AuditLogsTable), findsOneWidget);
      expect(find.byType(CustomTextFormField), findsWidgets);
    });

    testWidgets('Search query filters table rows dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const AuditLogsPage(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(CustomTextFormField).first, 'محمد أحمد محمود');
      await tester.pumpAndSettle();

      // Table should show matching row
      expect(find.text('محمد أحمد محمود'), findsWidgets);
    });

    testWidgets('Tapping view details action icon opens AuditLogDetailsDialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const AuditLogsPage(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap first eye action icon in table
      final eyeBtn = find.byIcon(Icons.remove_red_eye_outlined).first;
      await tester.tap(eyeBtn);
      await tester.pumpAndSettle();

      // Details dialog appears
      expect(find.byType(AuditLogDetailsDialog), findsOneWidget);
      expect(find.text('audit_log_details_title'.tr()), findsOneWidget);
    });

    testWidgets('Empty search results display CustomEmptyWidget', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const AuditLogsPage(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Enter impossible search query
      await tester.enterText(find.byType(CustomTextFormField).first, 'ZZZZ_NO_MATCH_9999');
      await tester.pumpAndSettle();

      expect(find.byType(CustomEmptyWidget), findsOneWidget);
      expect(find.text('no_audit_logs_found'.tr()), findsOneWidget);
    });
  });
}


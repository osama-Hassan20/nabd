import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_list.dart';
import 'package:eyadty/features/audit_logs/presentation/pages/audit_logs_page.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/shared/presentation/pages/forbidden_403_page.dart';

Widget _buildLocalizedApp({
  required Widget child,
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionCubit sessionCubit;
  late InMemoryAuditLogger auditLogger;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: true);
    sessionCubit = SessionCubit(SessionState.initial());

    getIt.registerSingleton<AuditLogger>(auditLogger);
    getIt.registerSingleton<SessionCubit>(sessionCubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  final testRoutes = [
    GoRoute(
      path: AppRouter.login,
      name: AppRouter.login,
      builder: (context, state) =>
          const Scaffold(key: Key('login_page'), body: Text('Login Page')),
    ),
    GoRoute(
      path: AppRouter.forbidden,
      name: AppRouter.forbidden,
      builder: (context, state) => const Forbidden403Page(),
    ),
    GoRoute(
      path: AppRouter.bookings,
      name: AppRouter.bookings,
      builder: (context, state) =>
          const Scaffold(key: Key('bookings_page'), body: Text('Bookings Page')),
    ),
    GoRoute(
      path: AppRouter.auditLogs,
      name: AppRouter.auditLogs,
      builder: (context, state) => const AuditLogsPage(),
    ),
  ];

  group('F-03 Milestone 2: Route Guard & Sidebar Integration Tests', () {
    test('getRequiredPermissionForRoute correctly maps auditLogs route', () {
      expect(
        getRequiredPermissionForRoute(AppRouter.auditLogs),
        StaffPermissionEnum.viewAuditLogs,
      );
      expect(
        getRequiredPermissionForRoute('/settings/audit-logs'),
        StaffPermissionEnum.viewAuditLogs,
      );
    });

    testWidgets('Unauthenticated user navigating to /settings/audit-logs redirects to /login', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Explicitly logout to simulate unauthenticated state
      sessionCubit.logout();

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.auditLogs,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ar', 'EG'),
          startLocale: const Locale('ar', 'EG'),
          saveLocale: false,
          useOnlyLangCode: false,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentLoc = router.routerDelegate.currentConfiguration.uri.toString();
      expect(currentLoc, contains('/login'));
      expect(currentLoc, contains(Uri.encodeComponent(AppRouter.auditLogs)));
    });

    testWidgets('Staff user without viewAuditLogs redirects to /forbidden', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Login as regular receptionist
      final receptionist = const StaffUserModel(
        id: 'reception_01',
        fullName: 'Receptionist User',
        isOwner: false,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.reception],
          ),
        ],
      );
      sessionCubit.switchMockUser(receptionist);
      sessionCubit.switchBranch('branch_1');

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.auditLogs,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ar', 'EG'),
          startLocale: const Locale('ar', 'EG'),
          saveLocale: false,
          useOnlyLangCode: false,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentLoc = router.routerDelegate.currentConfiguration.uri.toString();
      expect(currentLoc, contains('/forbidden'));
      expect(find.byType(Forbidden403Page), findsOneWidget);
    });

    testWidgets('Owner user navigating to /settings/audit-logs lands on AuditLogsPage', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Login as Owner
      final owner = const StaffUserModel(
        id: 'owner_01',
        fullName: 'Clinic Owner',
        isOwner: true,
        isActive: true,
      );
      sessionCubit.switchMockUser(owner);
      sessionCubit.switchBranch('branch_1');

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.auditLogs,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ar', 'EG'),
          startLocale: const Locale('ar', 'EG'),
          saveLocale: false,
          useOnlyLangCode: false,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentLoc = router.routerDelegate.currentConfiguration.uri.toString();
      expect(currentLoc, AppRouter.auditLogs);
      expect(find.byType(AuditLogsPage), findsOneWidget);
    });

    testWidgets('Sidebar dynamic filtering shows auditLogs for Owner and hides it for Receptionist', (tester) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          child: Builder(
            builder: (context) {
              // 1. Owner evaluation
              final owner = const StaffUserModel(
                id: 'owner_01',
                fullName: 'Clinic Owner',
                isOwner: true,
                isActive: true,
              );
              sessionCubit.switchMockUser(owner);
              final ownerItems = layoutItems(context);
              final hasAuditLogForOwner = ownerItems.any((item) => item.id == 'audit_logs');
              expect(hasAuditLogForOwner, isTrue);

              // 2. Receptionist evaluation
              final receptionist = const StaffUserModel(
                id: 'reception_01',
                fullName: 'Receptionist User',
                isOwner: false,
                isActive: true,
                branchAssignments: [
                  BranchAssignmentModel(
                    branchId: 'branch_1',
                    isPrimary: true,
                    roleIds: [RoleIds.reception],
                  ),
                ],
              );
              sessionCubit.switchMockUser(receptionist);
              final receptionistItems = layoutItems(context);
              final hasAuditLogForReceptionist = receptionistItems.any((item) => item.id == 'audit_logs');
              expect(hasAuditLogForReceptionist, isFalse);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

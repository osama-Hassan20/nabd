import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/shared/presentation/pages/forbidden_403_page.dart';

Widget wrapWithTestApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: child,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('R-3: GoRouter Guard & Live Permission Evaluation Tests', () {
    late SessionCubit sessionCubit;

    // Test Users
    const ownerUser = StaffUserModel(
      id: 'USER-OWNER',
      fullName: 'د. طارق المنشاوي (المالك)',
      isOwner: true,
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          isPrimary: true,
          roleIds: [RoleIds.branchManager],
        ),
      ],
    );

    const receptionUser = StaffUserModel(
      id: 'USER-REC',
      fullName: 'مروة عبد الرحمن (استقبال)',
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
        path: AppRouter.usersManagement,
        name: AppRouter.usersManagement,
        builder: (context, state) => const Scaffold(
          key: Key('users_management_page'),
          body: Text('Users Management Page'),
        ),
      ),
    ];

    testWidgets('1. Unauthenticated user navigating to protected page is redirected to /login with target query param', (tester) async {
      // Session with no authenticated user
      sessionCubit = SessionCubit(const SessionState(currentUser: null));

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.usersManagement,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          MaterialApp.router(
            locale: const Locale('ar', 'EG'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be redirected to /login
      expect(find.byKey(const Key('login_page')), findsOneWidget);
      expect(find.byKey(const Key('users_management_page')), findsNothing);
      expect(router.state.uri.path, equals(AppRouter.login));
      expect(router.state.uri.queryParameters['from'], equals(AppRouter.usersManagement));
    });

    testWidgets('2. Authenticated user lacking permission attempting to access /settings/users is redirected to /forbidden and 403 page renders', (tester) async {
      // Receptionist has no manageRolesAndPermissions permission
      sessionCubit = SessionCubit(const SessionState(currentUser: receptionUser));

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.usersManagement,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          MaterialApp.router(
            locale: const Locale('ar', 'EG'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be redirected to /forbidden
      expect(find.byType(Forbidden403Page), findsOneWidget);
      expect(find.byKey(const Key('users_management_page')), findsNothing);
      expect(router.state.uri.path, equals(AppRouter.forbidden));
      expect(router.state.uri.queryParameters['from'], equals(AppRouter.usersManagement));
    });

    testWidgets('3. Authenticated user with permission opens /settings/users successfully without redirect', (tester) async {
      // Owner has all permissions including manageRolesAndPermissions
      sessionCubit = SessionCubit(const SessionState(currentUser: ownerUser));

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.usersManagement,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          MaterialApp.router(
            locale: const Locale('ar', 'EG'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Target page renders directly
      expect(find.byKey(const Key('users_management_page')), findsOneWidget);
      expect(find.byType(Forbidden403Page), findsNothing);
      expect(router.state.uri.path, equals(AppRouter.usersManagement));
    });

    testWidgets('4. Role switch while on forbidden page immediately re-evaluates permissions and redirects back to target', (tester) async {
      // Start as Receptionist on /settings/users -> redirected to /forbidden
      sessionCubit = SessionCubit(const SessionState(currentUser: receptionUser));

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRouter.usersManagement,
        routes: testRoutes,
      );

      await tester.pumpWidget(
        wrapWithTestApp(
          MaterialApp.router(
            locale: const Locale('ar', 'EG'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirmed on /forbidden
      expect(find.byType(Forbidden403Page), findsOneWidget);
      expect(router.state.uri.path, equals(AppRouter.forbidden));

      // Switch user to Owner live while on the page
      sessionCubit.switchDemoUser(ownerUser);
      await tester.pumpAndSettle();

      // GoRouter automatically re-evaluated via refreshListenable and redirected to /settings/users!
      expect(find.byKey(const Key('users_management_page')), findsOneWidget);
      expect(find.byType(Forbidden403Page), findsNothing);
      expect(router.state.uri.path, equals(AppRouter.usersManagement));
    });
  });
}

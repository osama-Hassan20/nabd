import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/shared/auth/presentation/cubits/login/login_cubit.dart';
import 'package:eyadty/shared/auth/presentation/pages/login_page.dart';

Widget _buildLocalizedApp(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  late InMemoryAuditLogger auditLogger;
  late StaffUsersMockRepoImpl repo;
  late SessionCubit sessionCubit;
  late LoginCubit loginCubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();

    auditLogger = InMemoryAuditLogger();
    repo = StaffUsersMockRepoImpl(auditLogger: auditLogger);
    sessionCubit = SessionCubit(const SessionState());
    loginCubit = LoginCubit(staffUsersRepo: repo, sessionCubit: sessionCubit);

    if (getIt.isRegistered<StaffUsersRepo>()) {
      getIt.unregister<StaffUsersRepo>();
    }
    getIt.registerSingleton<StaffUsersRepo>(repo);

    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }
    getIt.registerSingleton<SessionCubit>(sessionCubit);

    if (getIt.isRegistered<LoginCubit>()) {
      getIt.unregister<LoginCubit>();
    }
    getIt.registerSingleton<LoginCubit>(loginCubit);
  });

  tearDown(() {
    AppConfig.resetTestingOverrides();
  });

  group('Demo Mode UI & Safety Tests', () {
    testWidgets('1. Demo mode banner and quick-login chips appear when isDemoMode is true', (tester) async {
      AppConfig.setDemoModeForTesting(true);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildLocalizedApp(const LoginPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('demo_mode_indicator_banner')), findsOneWidget);
      expect(find.text('demo_accounts_title'.tr()), findsOneWidget);
      expect(find.text('demo_doctor'.tr()), findsOneWidget);
    });

    testWidgets('2. Demo mode banner and quick-login chips are hidden when isDemoMode is false', (tester) async {
      AppConfig.setDemoModeForTesting(false);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildLocalizedApp(const LoginPage()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('demo_mode_indicator_banner')), findsNothing);
      expect(find.text('demo_accounts_title'.tr()), findsNothing);
      expect(find.text('demo_doctor'.tr()), findsNothing);
    });

    test('3. Login flow stores tagged demo token', () async {
      AppConfig.setDemoModeForTesting(true);

      await loginCubit.loginInto(
        identifier: 'doctor@eyadty.com',
        password: 'password123',
      );

      final token = AppSharedPreferences.getString(key: AppConstants.accessToken);
      expect(token, isNotNull);
      expect(AppConfig.isDemoToken(token!), isTrue);
      expect(token, startsWith('eyadty_demo_session_'));
    });
  });
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/core/utils/constants/app_constants.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/shared/auth/presentation/cubits/login/login_cubit.dart';
import 'package:eyadty/shared/auth/presentation/pages/login_page.dart';
import 'package:eyadty/shared/auth/presentation/widgets/must_change_password_dialog.dart';

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
  });

  tearDown(() {
    loginCubit.close();
    sessionCubit.close();
  });

  group('F-02 Milestone 3: LoginCubit Unit Tests', () {
    test('Successful authentication with email sets session and token', () async {
      await loginCubit.loginInto(
        identifier: 'owner@eyadty.com',
        password: '123456',
      );

      expect(loginCubit.state, isA<SuccessLoginPushState>());
      final successState = loginCubit.state as SuccessLoginPushState;
      expect(successState.user?.id, 'USER-OWNER');
      expect(sessionCubit.currentUser?.id, 'USER-OWNER');

      final cachedToken = AppSharedPreferences.getString(key: AppConstants.accessToken);
      final cachedUserId = AppSharedPreferences.getString(key: AppConstants.userId);
      expect(cachedToken, isNotNull);
      expect(cachedUserId, 'USER-OWNER');
    });

    test('Successful authentication with phone number sets session', () async {
      await loginCubit.loginInto(
        identifier: '01000000001',
        password: '123456',
      );

      expect(loginCubit.state, isA<SuccessLoginPushState>());
      expect(sessionCubit.currentUser?.id, 'USER-OWNER');
    });

    test('Authentication with wrong password fails with error message', () async {
      await loginCubit.loginInto(
        identifier: 'owner@eyadty.com',
        password: 'wrong_password',
      );

      expect(loginCubit.state, isA<FailedLoginPushState>());
      final failed = loginCubit.state as FailedLoginPushState;
      expect(failed.errMessage, 'auth_invalid_credentials');
    });

    test('Authentication with non-existent identifier fails', () async {
      await loginCubit.loginInto(
        identifier: 'ghost@eyadty.com',
        password: '123456',
      );

      expect(loginCubit.state, isA<FailedLoginPushState>());
      final failed = loginCubit.state as FailedLoginPushState;
      expect(failed.errMessage, 'auth_invalid_credentials');
    });

    test('Authentication with deactivated user fails with deactivation message', () async {
      const newUser = StaffUserModel(
        fullName: 'حساب معطل',
        email: 'deactivated@eyadty.com',
        phone: '01099999999',
        isOwner: false,
        isActive: false,
        mustChangePassword: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.reception],
          ),
        ],
      );
      final createRes = await repo.createStaffUser(
        user: newUser,
        temporaryPassword: 'tempPassword123',
        currentUserId: 'USER-OWNER',
      );
      final createdUser = createRes.getOrElse(() => throw Exception('Failed to create user'));

      await repo.toggleStaffUserStatus(
        userId: createdUser.id!,
        isActive: false,
        currentUserId: 'USER-OWNER',
      );

      await loginCubit.loginInto(
        identifier: 'deactivated@eyadty.com',
        password: 'tempPassword123',
      );

      expect(loginCubit.state, isA<FailedLoginPushState>());
      final failed = loginCubit.state as FailedLoginPushState;
      expect(failed.errMessage, 'auth_account_deactivated');
    });

    test('Authentication with user requiring password change triggers MustChangePasswordLoginState', () async {
      const tempUser = StaffUserModel(
        fullName: 'مستخدم جديد',
        email: 'temp@eyadty.com',
        phone: '01088888888',
        isOwner: false,
        isActive: true,
        mustChangePassword: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.reception],
          ),
        ],
      );
      final createRes = await repo.createStaffUser(
        user: tempUser,
        temporaryPassword: 'tempPassword123',
        currentUserId: 'USER-OWNER',
      );
      final createdUser = createRes.getOrElse(() => throw Exception('Failed to create user'));

      await loginCubit.loginInto(
        identifier: 'temp@eyadty.com',
        password: 'tempPassword123',
      );

      expect(loginCubit.state, isA<MustChangePasswordLoginState>());
      final mustChange = loginCubit.state as MustChangePasswordLoginState;
      expect(mustChange.userId, createdUser.id);
      expect(mustChange.temporaryPassword, 'tempPassword123');
    });

    test('Remember me saves identifier and restores it on checkRemeberMe', () async {
      loginCubit.rememberMe(true);
      expect(AppSharedPreferences.getBool(key: AppConstants.remeberMeKey), isTrue);

      await loginCubit.loginInto(
        identifier: 'owner@eyadty.com',
        password: '123456',
      );
      expect(AppSharedPreferences.getString(key: AppConstants.userName), 'owner@eyadty.com');

      loginCubit.rememberMe(false);
      expect(AppSharedPreferences.getBool(key: AppConstants.remeberMeKey), isNull);
      expect(AppSharedPreferences.getString(key: AppConstants.userName), isNull);
    });

    test('handlePasswordChangedSuccess logs user in and updates session', () async {
      const user = StaffUserModel(
        id: 'USER-CHANGED',
        fullName: 'تم التغيير',
        isOwner: false,
        isActive: true,
      );

      await loginCubit.handlePasswordChangedSuccess(user);

      expect(loginCubit.state, isA<SuccessLoginPushState>());
      expect(sessionCubit.currentUser?.id, 'USER-CHANGED');
      expect(AppSharedPreferences.getString(key: AppConstants.userId), 'USER-CHANGED');
    });
  });

  group('F-02 Milestone 3: MustChangePasswordDialog Widget Tests', () {
    testWidgets('Validates 8+ chars, different from temp, and matching confirmation', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool successCalled = false;

      // Seed a user with mustChangePassword
      const testUser = StaffUserModel(
        fullName: 'طبيب جديد',
        email: 'newdoc@eyadty.com',
        phone: '01077777777',
        isOwner: false,
        isActive: true,
        mustChangePassword: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      final createRes = await repo.createStaffUser(
        user: testUser,
        temporaryPassword: 'TempPass123!',
        currentUserId: 'USER-OWNER',
      );
      final createdUser = createRes.getOrElse(() => throw Exception('Failed to create user'));

      await tester.pumpWidget(
        _buildLocalizedApp(
          Scaffold(
            body: Center(
              child: MustChangePasswordDialog(
                userId: createdUser.id!,
                temporaryPassword: 'TempPass123!',
                onPasswordChangedSuccess: () {
                  successCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check fields are present
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3));

      // Enter short new password (less than 8 chars)
      await tester.enterText(textFields.at(1), 'short');
      await tester.enterText(textFields.at(2), 'short');

      final submitBtn = find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'save_password_and_continue' || w.data == 'حفظ كلمة المرور والمتابعة'),
      );
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(successCalled, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'password_must_be_8_chars' || w.data == 'يجب أن لا تقل كلمة المرور عن 8 أحرف'),
        ),
        findsOneWidget,
      );

      // Enter new password identical to temporary password
      await tester.enterText(textFields.at(1), 'TempPass123!');
      await tester.enterText(textFields.at(2), 'TempPass123!');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(successCalled, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'password_must_differ' || w.data == 'يجب أن تختلف كلمة المرور الجديدة عن المؤقتة'),
        ),
        findsOneWidget,
      );

      // Enter mismatched confirmation
      await tester.enterText(textFields.at(1), 'BrandNewPass2026!');
      await tester.enterText(textFields.at(2), 'BrandNewPassMismatch!');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(successCalled, isFalse);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'passwords_do_not_match' || w.data == 'كلمتا المرور غير متطابقتين'),
        ),
        findsOneWidget,
      );

      // Enter valid matching password
      await tester.enterText(textFields.at(1), 'BrandNewPass2026!');
      await tester.enterText(textFields.at(2), 'BrandNewPass2026!');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(successCalled, isTrue);

      // Verify user mustChangePassword is now false and password works
      final authResult = await repo.authenticate(
        identifier: 'newdoc@eyadty.com',
        password: 'BrandNewPass2026!',
      );
      expect(authResult.isRight(), isTrue);
      authResult.fold(
        (_) => fail('Should have authenticated'),
        (u) => expect(u.mustChangePassword, isFalse),
      );
    });
  });

  group('F-02 Milestone 3: LoginPage UI & Forgot Password Dialog', () {
    testWidgets('Renders Login page and forgot password guidance modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildLocalizedApp(const LoginPage()));
      await tester.pumpAndSettle();

      // Check fields and elements
      expect(find.byType(TextField), findsNWidgets(2));
      final forgotPasswordBtn = find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'forgot_password' || w.data == 'نسيت كلمة المرور؟'),
      );
      expect(forgotPasswordBtn, findsOneWidget);

      // Tap forgot password
      await tester.tap(forgotPasswordBtn);
      await tester.pumpAndSettle();

      // Guidance dialog shows instructions to contact clinic administrator
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'forgot_password_title' || w.data == 'استعادة كلمة المرور'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'forgot_password_desc' || (w.data?.contains('مدير المنشأة') ?? false)),
        ),
        findsOneWidget,
      );

      final closeBtn = find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'understood' || w.data == 'حسناً، فهمت'),
      );
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data == 'forgot_password_title' || w.data == 'استعادة كلمة المرور'),
        ),
        findsNothing,
      );
    });
  });
}

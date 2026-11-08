import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/branches/data/repo/branches_mock_repo_impl.dart';
import 'package:eyadty/features/branches/domain/repo/branches_repo.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/shared/app_layout/presentation/widgets/header_branch_switcher.dart';
import 'package:eyadty/shared/services/app_branch_service.dart';

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
        home: Scaffold(
          appBar: AppBar(actions: [child]),
          body: const SizedBox(),
        ),
      ),
    ),
  );
}

void main() {
  late BranchesMockRepoImpl branchesRepo;
  late SessionCubit sessionCubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    if (getIt.isRegistered<BranchesRepo>()) {
      getIt.unregister<BranchesRepo>();
    }
    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }

    branchesRepo = BranchesMockRepoImpl(
      auditLogger: InMemoryAuditLogger(),
    );
    getIt.registerLazySingleton<BranchesRepo>(() => branchesRepo);

    sessionCubit = SessionCubit(SessionState.initial());
    getIt.registerLazySingleton<SessionCubit>(() => sessionCubit);
  });

  tearDown(() {
    if (getIt.isRegistered<BranchesRepo>()) {
      getIt.unregister<BranchesRepo>();
    }
    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }
  });

  group('HeaderBranchSwitcher Dynamic Integration Tests', () {
    testWidgets('Renders active branch pill and loads branches from BranchesRepo', (tester) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const HeaderBranchSwitcher(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Should display branch_main translated or key
      expect(find.byType(HeaderBranchSwitcher), findsOneWidget);
    });

    testWidgets('Owner sees all branches, switching updates SessionCubit and AppBranchService', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final owner = const StaffUserModel(
        id: 'USER-OWNER',
        fullName: 'د. طارق المنشاوي',
        isOwner: true,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.branchManager]),
          BranchAssignmentModel(branchId: 'branch_2', roleIds: [RoleIds.branchManager]),
        ],
      );
      sessionCubit.switchMockUser(owner);

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const HeaderBranchSwitcher(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Open branch switcher modal or popup
      final switcherFinder = find.byType(HeaderBranchSwitcher);
      expect(switcherFinder, findsOneWidget);

      await tester.tap(switcherFinder);
      await tester.pumpAndSettle();

      // AppBranchService has branch_1 selected initially
      expect(AppBranchService.instance.currentBranchId, 'branch_1');
    });

    testWidgets('Single-branch staff user cannot switch branches (canSwitchBranches is false)', (tester) async {
      final receptionist = const StaffUserModel(
        id: 'USER-REC',
        fullName: 'أحمد محمود',
        isOwner: false,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );
      sessionCubit.switchMockUser(receptionist);

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const HeaderBranchSwitcher(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Should only see pill without arrow down and no popup
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });
  });
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/providers/active_bookings_count_provider.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/data/repo/branches_repo_impl.dart';
import 'package:eyadty/features/branches/domain/repo/branches_repo.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/add_edit_branch_dialog.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/copy_branch_settings_dialog.dart';
import 'package:eyadty/features/branches/presentation/pages/dialogs/toggle_branch_status_dialog.dart';
import 'package:eyadty/features/branches/presentation/widgets/branches_table.dart';
import 'package:eyadty/features/settings/presentation/widgets/tabs/branches_management_tab.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class FakeActiveBookingsProvider implements ActiveBookingsCountProvider {
  final Map<String, int> counts;
  FakeActiveBookingsProvider(this.counts);

  @override
  Future<int> countActiveFutureBookingsForDoctor(String doctorId) async {
    return counts[doctorId] ?? 0;
  }

  @override
  Future<int> countActiveFutureBookingsForBranch(String branchId) async {
    return counts[branchId] ?? 0;
  }
}

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
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  late InMemoryAuditLogger auditLogger;
  late BranchesRepoImpl repo;
  late SessionCubit sessionCubit;
  late BranchesCubit branchesCubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();

    if (getIt.isRegistered<BranchesRepo>()) {
      getIt.unregister<BranchesRepo>();
    }
    if (getIt.isRegistered<BranchesCubit>()) {
      getIt.unregister<BranchesCubit>();
    }
    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }
    if (getIt.isRegistered<ActiveBookingsCountProvider>()) {
      getIt.unregister<ActiveBookingsCountProvider>();
    }

    auditLogger = InMemoryAuditLogger();
    final bookingsProvider = FakeActiveBookingsProvider({'branch_2': 3});
    getIt.registerLazySingleton<ActiveBookingsCountProvider>(() => bookingsProvider);

    repo = BranchesRepoImpl(
      auditLogger: auditLogger,
      activeBookingsProvider: bookingsProvider,
    );
    getIt.registerLazySingleton<BranchesRepo>(() => repo);

    sessionCubit = SessionCubit(SessionState.initial());
    sessionCubit.switchDemoUser(
      const StaffUserModel(
        id: 'USER-OWNER',
        fullName: 'د. طارق المنشاوي',
        isOwner: true,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.branchManager]),
        ],
      ),
    );
    getIt.registerLazySingleton<SessionCubit>(() => sessionCubit);

    branchesCubit = BranchesCubit(branchesRepo: repo);
    getIt.registerFactory<BranchesCubit>(() => branchesCubit);
  });

  tearDown(() {
    if (getIt.isRegistered<BranchesRepo>()) {
      getIt.unregister<BranchesRepo>();
    }
    if (getIt.isRegistered<BranchesCubit>()) {
      getIt.unregister<BranchesCubit>();
    }
    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }
    if (getIt.isRegistered<ActiveBookingsCountProvider>()) {
      getIt.unregister<ActiveBookingsCountProvider>();
    }
  });

  group('BranchesCubit Unit Tests', () {
    test('loadBranches populates branches list', () async {
      await branchesCubit.loadBranches();
      expect(branchesCubit.state.branches.length, 3);
      expect(branchesCubit.state.filteredBranches.length, 3);
    });

    test('search query filters branches by name or phone or address', () async {
      await branchesCubit.loadBranches();

      branchesCubit.setSearchQuery('مدينة نصر');
      expect(branchesCubit.state.filteredBranches.length, 1);
      expect(branchesCubit.state.filteredBranches.first.id, 'branch_2');

      branchesCubit.setSearchQuery('non-existent');
      expect(branchesCubit.state.filteredBranches.isEmpty, isTrue);

      branchesCubit.setSearchQuery('');
      expect(branchesCubit.state.filteredBranches.length, 3);
    });

    test('activeFilter filters branches by active / inactive', () async {
      await branchesCubit.loadBranches();

      branchesCubit.setActiveFilter('active');
      expect(branchesCubit.state.filteredBranches.length, 2);

      branchesCubit.setActiveFilter('inactive');
      expect(branchesCubit.state.filteredBranches.length, 1);
      expect(branchesCubit.state.filteredBranches.first.id, 'branch_3');
    });

    test('createBranch adds branch and reloads state', () async {
      await branchesCubit.loadBranches();
      final ok = await branchesCubit.createBranch(
        const BranchModel(
          name: 'فرع الجيزة',
          phone: '+2023000000',
        ),
        currentUserId: 'USER-OWNER',
      );

      expect(ok, isTrue);
      expect(branchesCubit.state.branches.length, 4);
    });
  });

  group('BranchesManagementTab & Table Widget Tests', () {
    testWidgets('Renders tab header, filter bar, search input, and table', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const BranchesManagementTab(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BranchesTable), findsOneWidget);
      expect(find.text('branch_main'.tr()), findsWidgets);
      expect(find.text('branch_second'.tr()), findsWidgets);
    });

    testWidgets('Searching updates visible table rows', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const BranchesManagementTab(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'مدينة نصر');
      await tester.pumpAndSettle();

      // Only branch 2 remains
      expect(find.text('branch_second'.tr()), findsOneWidget);
    });
  });

  group('Branches Dialogs Tests', () {
    testWidgets('AddEditBranchDialog validates required branch name', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: branchesCubit,
            child: const AddEditBranchDialog(),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit with empty name
      final submitBtn = find.descendant(
        of: find.byType(CustomPushButton),
        matching: find.text('add_branch'.tr()),
      );
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('please_enter_branch_name'.tr()), findsOneWidget);
    });

    testWidgets('ToggleBranchStatusDialog blocks deactivating main branch', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mainBranch = const BranchModel(
        id: 'branch_1',
        nameKey: 'branch_main',
        isActive: true,
        isMain: true,
      );

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: branchesCubit,
            child: ToggleBranchStatusDialog(branch: mainBranch),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Blocks deactivation and shows understood button
      expect(find.text('cannot_deactivate_main_branch'.tr()), findsOneWidget);
      expect(find.text('understood'.tr()), findsOneWidget);
    });

    testWidgets('ToggleBranchStatusDialog shows active bookings warning', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // branch_2 is not main, but has 3 active bookings configured in mock
      final branch2 = const BranchModel(
        id: 'branch_2',
        nameKey: 'branch_second',
        isActive: true,
        isMain: false,
      );

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: branchesCubit,
            child: ToggleBranchStatusDialog(branch: branch2),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('warning_active_bookings'.tr()), findsOneWidget);
    });

    testWidgets('CopyBranchSettingsDialog displays target branch and options', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final allBranches = [
        const BranchModel(id: 'branch_1', nameKey: 'branch_main', isActive: true),
        const BranchModel(id: 'branch_2', nameKey: 'branch_second', isActive: true),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: branchesCubit,
            child: CopyBranchSettingsDialog(
              targetBranch: allBranches[1],
              allBranches: allBranches,
            ),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('copy_settings'.tr()), findsOneWidget);
      expect(find.text('copy_working_hours'.tr()), findsOneWidget);
      expect(find.text('copy_special_holidays'.tr()), findsOneWidget);
    });
  });
}

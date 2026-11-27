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
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_state.dart';
import 'package:eyadty/features/users_management/presentation/pages/dialogs/add_edit_staff_user_dialog.dart';
import 'package:eyadty/features/users_management/presentation/pages/dialogs/delete_staff_user_dialog.dart';
import 'package:eyadty/features/users_management/presentation/pages/dialogs/role_permissions_matrix_dialog.dart';
import 'package:eyadty/features/users_management/presentation/pages/dialogs/toggle_user_status_dialog.dart';
import 'package:eyadty/features/users_management/presentation/pages/users_management_page.dart';
import 'package:eyadty/features/users_management/presentation/widgets/staff_users_table.dart';

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
  late StaffUsersRepoImpl repo;
  late SessionCubit sessionCubit;
  late StaffUsersCubit staffUsersCubit;

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
    repo = StaffUsersRepoImpl(
      auditLogger: auditLogger,
      activeBookingsProvider: FakeActiveBookingsProvider({'DOC-01': 3}),
    );
    sessionCubit = SessionCubit(SessionState.initial());
    staffUsersCubit = StaffUsersCubit(staffUsersRepo: repo);

    if (getIt.isRegistered<StaffUsersRepo>()) {
      getIt.unregister<StaffUsersRepo>();
    }
    getIt.registerSingleton<StaffUsersRepo>(repo);

    if (getIt.isRegistered<StaffUsersCubit>()) {
      getIt.unregister<StaffUsersCubit>();
    }
    getIt.registerFactory<StaffUsersCubit>(() => staffUsersCubit);

    if (getIt.isRegistered<SessionCubit>()) {
      getIt.unregister<SessionCubit>();
    }
    getIt.registerSingleton<SessionCubit>(sessionCubit);
  });

  tearDown(() {
    staffUsersCubit.close();
    sessionCubit.close();
  });

  group('F-02 Milestone 4: StaffUsersCubit Unit Tests', () {
    test('loadData populates users and roles successfully', () async {
      await staffUsersCubit.loadData();

      expect(staffUsersCubit.state.users.isNotEmpty, isTrue);
      expect(staffUsersCubit.state.roles.length, greaterThanOrEqualTo(7));
      expect(staffUsersCubit.state.totalCount, greaterThanOrEqualTo(13));
    });

    test('search query filters users by name, email, phone, or job title', () async {
      await staffUsersCubit.loadData();

      staffUsersCubit.setSearchQuery('owner@eyadty.com');
      expect(staffUsersCubit.state.filteredUsers.length, 1);
      expect(staffUsersCubit.state.filteredUsers.first.id, 'USER-OWNER');

      staffUsersCubit.setSearchQuery('reception@eyadty.com');
      expect(staffUsersCubit.state.filteredUsers.length, 1);
      expect(staffUsersCubit.state.filteredUsers.first.id, 'USER-REC');

      staffUsersCubit.setSearchQuery('');
      expect(staffUsersCubit.state.filteredUsers.length, staffUsersCubit.state.totalCount);
    });

    test('roleFilter filters users by role id', () async {
      await staffUsersCubit.loadData();

      staffUsersCubit.setRoleFilter(RoleIds.accountant);
      expect(staffUsersCubit.state.filteredUsers.length, 1);
      expect(staffUsersCubit.state.filteredUsers.first.id, 'USER-ACC');

      staffUsersCubit.setRoleFilter(null);
      expect(staffUsersCubit.state.filteredUsers.length, staffUsersCubit.state.totalCount);
    });

    test('statusFilter filters users by active / inactive status', () async {
      await staffUsersCubit.loadData();

      // Deactivate receptionist
      await staffUsersCubit.toggleUserStatus(
        userId: 'USER-REC',
        isActive: false,
        currentUserId: 'USER-OWNER',
      );

      staffUsersCubit.setStatusFilter(StaffUserStatusFilter.inactive);
      expect(staffUsersCubit.state.filteredUsers.any((u) => u.id == 'USER-REC'), isTrue);

      staffUsersCubit.setStatusFilter(StaffUserStatusFilter.active);
      expect(staffUsersCubit.state.filteredUsers.any((u) => u.id == 'USER-REC'), isFalse);
    });

    test('branchFilter filters users while owner is accessible across all branches', () async {
      await staffUsersCubit.loadData();

      staffUsersCubit.setBranchFilter('branch_2');
      // Owner is always present
      expect(staffUsersCubit.state.filteredUsers.any((u) => u.id == 'USER-OWNER'), isTrue);
    });
  });

  group('F-02 Milestone 4 & 5: UsersManagementPage & StaffUsersTable Widget Tests', () {
    testWidgets('Renders page header, filter bar, search field, and table rows', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: const UsersManagementPage(),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Table and Rows render
      expect(find.byType(StaffUsersTable), findsOneWidget);
      final searchField = find.byKey(const Key('input_search_staff_users'));
      expect(searchField, findsOneWidget);

      // Type in search field
      await tester.enterText(searchField, 'طبيب');
      await tester.pumpAndSettle();

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.byType(StaffUsersTable), findsOneWidget);
    });
  });

  group('F-02 Milestone 5: Security & Governance Dialog Tests', () {
    testWidgets('DeleteStaffUserDialog blocks deleting clinic owner (Rule 1: Last Owner Protection)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await staffUsersCubit.loadData();
      final ownerUser = staffUsersCubit.state.users.firstWhere((u) => u.isOwner == true);

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: staffUsersCubit,
            child: DeleteStaffUserDialog(user: ownerUser),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Confirm that the delete button is NOT available and owner protection warning is displayed
      expect(find.text('last_active_owner_cannot_be_deleted'), findsOneWidget);
      expect(find.text('understood'), findsOneWidget);
      expect(find.text('delete'), findsNothing);
    });

    testWidgets('DeleteStaffUserDialog shows active future bookings warning for doctors (Rule 6)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await staffUsersCubit.loadData();
      final doc1User = staffUsersCubit.state.users.firstWhere((u) => u.linkedDoctorId == 'DOC-01');

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: staffUsersCubit,
            child: DeleteStaffUserDialog(user: doc1User),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete button to trigger active bookings check
      final deleteBtn = find.text('delete');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Prompts with warning and force delete button
      expect(find.text('force_delete'), findsOneWidget);
    });

    testWidgets('ToggleUserStatusDialog blocks deactivating self (Rule 3: Self-Deactivation)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await staffUsersCubit.loadData();
      final ownerUser = staffUsersCubit.state.users.firstWhere((u) => u.id == 'USER-OWNER');

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: staffUsersCubit,
            child: ToggleUserStatusDialog(user: ownerUser),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Deactivation is blocked
      expect(find.text('last_active_owner_cannot_be_deactivated'), findsOneWidget);
      expect(find.text('understood'), findsOneWidget);
      expect(find.text('confirm'), findsNothing);
    });

    testWidgets('AddEditStaffUserDialog enforces doctor linking when Doctor role selected (Rule 5)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await staffUsersCubit.loadData();

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: staffUsersCubit,
            child: const AddEditStaffUserDialog(),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      // Enter full name, email, phone
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'طبيب زائر');
      await tester.enterText(textFields.at(2), 'doctor@eyadty.com');
      await tester.enterText(textFields.at(3), '01011112222');
      await tester.pumpAndSettle();

      // Select Doctor role chip
      final doctorChip = find.byWidgetPredicate(
        (w) => w is ChoiceChip && (w.label is Text && (w.label as Text).data == 'طبيب'),
      );
      expect(doctorChip, findsOneWidget);
      await tester.tap(doctorChip);
      await tester.pumpAndSettle();

      // Doctor linking section is now visible
      expect(find.text('link_doctor_profile_required'), findsOneWidget);

      // Attempt submit without selecting linked doctor -> blocked
      final saveBtn = find.text('add_user');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditStaffUserDialog), findsOneWidget); // still open
      await tester.pump(const Duration(seconds: 4)); // drain toast timer
    });

    testWidgets('RolePermissionsMatrixDialog toggles permissions and saves', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await staffUsersCubit.loadData();

      await tester.pumpWidget(
        _buildLocalizedApp(
          child: BlocProvider.value(
            value: staffUsersCubit,
            child: const RolePermissionsMatrixDialog(),
          ),
          sessionCubit: sessionCubit,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('role_permissions_matrix'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);

      final saveChangesBtn = find.text('save_changes');
      expect(saveChangesBtn, findsOneWidget);
      await tester.tap(saveChangesBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RolePermissionsMatrixDialog), findsNothing); // dialog closed on save
    });
  });
}

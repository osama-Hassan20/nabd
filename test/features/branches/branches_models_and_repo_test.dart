import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/providers/active_bookings_count_provider.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/data/models/copy_branch_settings_param.dart';
import 'package:eyadty/features/branches/data/repo/branches_repo_impl.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class FakeActiveBookingsProvider implements ActiveBookingsCountProvider {
  final Map<String, int> doctorCounts;
  final Map<String, int> branchCounts;

  FakeActiveBookingsProvider({
    this.doctorCounts = const {},
    this.branchCounts = const {},
  });

  @override
  Future<int> countActiveFutureBookingsForDoctor(String doctorId) async {
    return doctorCounts[doctorId] ?? 0;
  }

  @override
  Future<int> countActiveFutureBookingsForBranch(String branchId) async {
    return branchCounts[branchId] ?? 0;
  }
}

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

void main() {
  group('BranchModel & CopyBranchSettingsParam Tests', () {
    test('BranchModel serialization, deserialization and copyWith', () {
      final model = BranchModel(
        id: 'branch_test',
        name: 'فرع الاختبار',
        nameKey: 'branch_test_key',
        address: 'عنوان الاختبار',
        phone: '+20100000000',
        email: 'test@eyadty.com',
        isActive: true,
        isMain: true,
        openingTime: '09:00',
        closingTime: '21:00',
        workingDays: const ['saturday', 'sunday'],
        specialHolidays: [
          SpecialHolidayModel(
            id: 'H1',
            name: 'Holiday 1',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 1),
          ),
        ],
        activeRoomsCount: 5,
        staffMembersCount: 8,
      );

      expect(model.isBranchActive, isTrue);
      expect(model.isMainBranch, isTrue);

      final json = model.toJson();
      expect(json['id'], 'branch_test');
      expect(json['name'], 'فرع الاختبار');
      expect(json['isMain'], isTrue);

      final fromJson = BranchModel.fromJson(json);
      expect(fromJson.id, 'branch_test');
      expect(fromJson.name, 'فرع الاختبار');
      expect(fromJson.workingDays?.length, 2);
      expect(fromJson.specialHolidays?.length, 1);

      final copied = model.copyWith(name: 'فرع معدل', isActive: false);
      expect(copied.name, 'فرع معدل');
      expect(copied.isActive, isFalse);
      expect(copied.isBranchActive, isFalse);
    });

    test('CopyBranchSettingsParam serialization and copyWith', () {
      const param = CopyBranchSettingsParam(
        sourceBranchId: 'branch_1',
        targetBranchId: 'branch_2',
        copyWorkingHours: true,
        copySpecialHolidays: false,
        copyMedicalServices: true,
        copyDoctorSchedules: false,
      );

      final json = param.toJson();
      expect(json['sourceBranchId'], 'branch_1');
      expect(json['targetBranchId'], 'branch_2');
      expect(json['copyWorkingHours'], isTrue);

      final fromJson = CopyBranchSettingsParam.fromJson(json);
      expect(fromJson.sourceBranchId, 'branch_1');
      expect(fromJson.targetBranchId, 'branch_2');
      expect(fromJson.copyWorkingHours, isTrue);
      expect(fromJson.copySpecialHolidays, isFalse);
    });
  });

  group('BranchesRepoImpl Unit Tests', () {
    late InMemoryAuditLogger auditLogger;
    late BranchesRepoImpl repo;

    setUp(() {
      auditLogger = InMemoryAuditLogger();
      repo = BranchesRepoImpl(apiConsumer: LocalServerApiConsumer(), 
        auditLogger: auditLogger,
        activeBookingsProvider: FakeActiveBookingsProvider(
          branchCounts: {'branch_2': 5},
        ),
      );
    });

    test('getBranches returns 3 seeded official branches', () async {
      final result = await repo.getBranches();
      expect(result.isRight(), isTrue);
      final branches = result.getOrElse(() => []);
      expect(branches.length, 3);
      expect(branches[0].id, 'branch_1');
      expect(branches[0].isMain, isTrue);
      expect(branches[1].id, 'branch_2');
      expect(branches[1].isMain, isFalse);
      expect(branches[2].id, 'branch_3');
      expect(branches[2].isActive, isFalse);
    });

    test('getBranchById returns branch or fails if not found', () async {
      final res1 = await repo.getBranchById('branch_1');
      expect(res1.isRight(), isTrue);
      expect(res1.getOrElse(() => const BranchModel()).nameKey, 'branch_main');

      final res2 = await repo.getBranchById('non_existent');
      expect(res2.isLeft(), isTrue);
      res2.fold((f) => expect(f, isA<BranchNotFoundFailure>()), (_) {});
    });

    test('createBranch adds branch and demotes existing main if isMain=true', () async {
      final newBranch = const BranchModel(
        name: 'فرع الإسكندرية',
        address: 'سموحة، الإسكندرية',
        phone: '+2034000000',
        isMain: true,
      );

      final result = await repo.createBranch(newBranch, currentUserId: 'USER-OWNER');
      expect(result.isRight(), isTrue);
      final created = result.getOrElse(() => const BranchModel());
      expect(created.isMain, isTrue);

      final allBranchesRes = await repo.getBranches();
      final all = allBranchesRes.getOrElse(() => []);
      expect(all.length, 4);

      // Previous main branch branch_1 should now have isMain = false
      final branch1 = all.firstWhere((b) => b.id == 'branch_1');
      expect(branch1.isMain, isFalse);

      // Audit log event was written
      final logs = auditLogger.getLogs();
      expect(logs.any((l) => l.eventType == 'create_branch'), isTrue);
    });

    test('toggleBranchStatus: Rule 1 cannot deactivate main branch', () async {
      final result = await repo.toggleBranchStatus(
        branchId: 'branch_1',
        isActive: false,
        currentUserId: 'USER-OWNER',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CannotDeactivateMainBranchFailure>()),
        (_) => fail('Should not succeed'),
      );
    });

    test('toggleBranchStatus: Rule 2 cannot deactivate last active branch', () async {
      // First, set branch_2 as main
      await repo.setMainBranch(branchId: 'branch_2', currentUserId: 'USER-OWNER');

      // Now deactivate branch_1 (which has no bookings in mock)
      final deact1 = await repo.toggleBranchStatus(
        branchId: 'branch_1',
        isActive: false,
        currentUserId: 'USER-OWNER',
      );
      expect(deact1.isRight(), isTrue);

      // Now only branch_2 is active. Trying to deactivate branch_2 must fail:
      final deact2 = await repo.toggleBranchStatus(
        branchId: 'branch_2',
        isActive: false,
        currentUserId: 'USER-OWNER',
        forceWithActiveBookings: true,
      );

      expect(deact2.isLeft(), isTrue);
      deact2.fold(
        (failure) => expect(failure, isA<CannotDeactivateMainBranchFailure>()),
        (_) => fail('Should not succeed'),
      );
    });

    test('toggleBranchStatus: Rule 3 warns on active bookings unless forceWithActiveBookings', () async {
      // branch_2 has 5 active bookings configured in mock provider
      final result = await repo.toggleBranchStatus(
        branchId: 'branch_2',
        isActive: false,
        currentUserId: 'USER-OWNER',
        forceWithActiveBookings: false,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ActiveBookingsWarningFailure>());
        final warning = failure as ActiveBookingsWarningFailure;
        expect(warning.activeBookingsCount, 5);
      }, (_) => fail('Should have warned about active bookings'));

      // If forced, it succeeds
      final forcedResult = await repo.toggleBranchStatus(
        branchId: 'branch_2',
        isActive: false,
        currentUserId: 'USER-OWNER',
        forceWithActiveBookings: true,
      );
      expect(forcedResult.isRight(), isTrue);
    });

    test('setMainBranch sets target as main and demotes others', () async {
      final result = await repo.setMainBranch(
        branchId: 'branch_2',
        currentUserId: 'USER-OWNER',
      );
      expect(result.isRight(), isTrue);

      final b1 = (await repo.getBranchById('branch_1')).getOrElse(() => const BranchModel());
      final b2 = (await repo.getBranchById('branch_2')).getOrElse(() => const BranchModel());

      expect(b1.isMain, isFalse);
      expect(b2.isMain, isTrue);

      // Attempting to set inactive branch_3 as main fails
      final resInactive = await repo.setMainBranch(
        branchId: 'branch_3',
        currentUserId: 'USER-OWNER',
      );
      expect(resInactive.isLeft(), isTrue);
      resInactive.fold(
        (f) => expect(f, isA<InvalidBranchOperationFailure>()),
        (_) => fail('Cannot set inactive branch as main'),
      );
    });

    test('copySettingsFromBranch copies hours and holidays', () async {
      // Copy from branch_1 to branch_3
      const param = CopyBranchSettingsParam(
        sourceBranchId: 'branch_1',
        targetBranchId: 'branch_3',
        copyWorkingHours: true,
        copySpecialHolidays: true,
      );

      final result = await repo.copySettingsFromBranch(param, currentUserId: 'USER-OWNER');
      expect(result.isRight(), isTrue);

      final updatedB3 = result.getOrElse(() => const BranchModel());
      expect(updatedB3.openingTime, '09:00');
      expect(updatedB3.closingTime, '22:00');
      expect(updatedB3.workingDays?.length, 6);
      expect(updatedB3.specialHolidays?.length, 2);

      // Copying to same branch fails
      final failRes = await repo.copySettingsFromBranch(
        const CopyBranchSettingsParam(
          sourceBranchId: 'branch_1',
          targetBranchId: 'branch_1',
        ),
        currentUserId: 'USER-OWNER',
      );
      expect(failRes.isLeft(), isTrue);
      failRes.fold((f) => expect(f, isA<InvalidBranchOperationFailure>()), (_) {});
    });
  });

  group('PermissionEvaluator & manageBranches RBAC Tests', () {
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator evaluator;

    setUp(() {
      rolesProvider = FakeRolesSessionProvider(
        roles: RoleDefinitionModel.defaultSystemRoles(),
      );
      userProvider = FakeUserSessionProvider();
      evaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );
    });

    test('Owner is granted manageBranches across any branch', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-OWNER',
        fullName: 'د. طارق المنشاوي',
        isOwner: true,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.branchManager]),
        ],
      );

      final canManage = evaluator.can(
        StaffPermissionEnum.manageBranches,
        branchId: 'branch_1',
      );
      expect(canManage, isTrue);

      final canManageOtherBranch = evaluator.can(
        StaffPermissionEnum.manageBranches,
        branchId: 'branch_2',
      );
      expect(canManageOtherBranch, isTrue);
    });

    test('Non-owners (Branch Manager, Doctor, Reception, etc.) are DENIED manageBranches', () {
      const roles = [
        RoleIds.branchManager,
        RoleIds.medicalDirector,
        RoleIds.doctor,
        RoleIds.nurse,
        RoleIds.reception,
        RoleIds.accountant,
        RoleIds.hr,
      ];

      for (final roleId in roles) {
        userProvider.user = StaffUserModel(
          id: 'USER-$roleId',
          fullName: 'Staff $roleId',
          isOwner: false,
          isActive: true,
          branchAssignments: [
            BranchAssignmentModel(branchId: 'branch_1', roleIds: [roleId]),
          ],
        );

        final canManage = evaluator.can(
          StaffPermissionEnum.manageBranches,
          branchId: 'branch_1',
        );
        expect(canManage, isFalse, reason: 'Role $roleId must not have manageBranches');
      }
    });
  });
}

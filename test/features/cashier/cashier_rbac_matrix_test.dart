import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class _MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branchId = 'branch_1';

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branchId;
}

class _MockRolesSessionProvider implements RolesProvider {
  final List<RoleDefinitionModel> roles;
  const _MockRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  group('Cashier RBAC Matrix - M-5 Tests', () {
    late _MockUserSessionProvider userProvider;
    late _MockRolesSessionProvider rolesProvider;
    late PermissionEvaluator evaluator;

    setUp(() {
      final systemRoles = RoleDefinitionModel.defaultSystemRoles();
      final managerDef =
          systemRoles.firstWhere((r) => r.id == RoleIds.branchManager);
      final updatedManager = managerDef.copyWith(
        permissions: [
          ...?managerDef.permissions,
          StaffPermissionEnum.manageCashierShifts,
          StaffPermissionEnum.manageDrawerMovements,
        ],
      );
      final testRoles = systemRoles
          .map((r) => r.id == RoleIds.branchManager ? updatedManager : r)
          .toList();

      rolesProvider = _MockRolesSessionProvider(roles: testRoles);
      userProvider = _MockUserSessionProvider();
      evaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );
    });

    StaffUserModel createUserWithRole(String roleId, {String branch = 'branch_1'}) {
      return StaffUserModel(
        id: 'USER-$roleId',
        fullName: 'User $roleId',
        isActive: true,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(branchId: branch, roleIds: [roleId]),
        ],
      );
    }

    test('1. Branch Manager has full cashier operations including shifts and drawer movements', () {
      userProvider.user = createUserWithRole(RoleIds.branchManager);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.viewCashierShift, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.manageCashierShifts, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isTrue);
    });

    test('2. Medical Director has zero cashier permissions (Fail-Closed)', () {
      userProvider.user = createUserWithRole(RoleIds.medicalDirector);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.viewCashierShift, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageCashierShifts, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isFalse);
    });

    test('3. Doctor has zero cashier permissions (Fail-Closed)', () {
      userProvider.user = createUserWithRole(RoleIds.doctor);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageCashierShifts, branchId: 'branch_1'), isFalse);
    });

    test('4. Nurse has zero cashier permissions (Fail-Closed)', () {
      userProvider.user = createUserWithRole(RoleIds.nurse);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);
    });

    test('5. Receptionist can collect payments and view shifts, but CANNOT refund or manage shifts/movements', () {
      userProvider.user = createUserWithRole(RoleIds.reception);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.viewCashierShift, branchId: 'branch_1'), isTrue);

      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageCashierShifts, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isFalse);
    });

    test('6. Accountant can collect, refund, and view shifts, but CANNOT manage drawer movements', () {
      userProvider.user = createUserWithRole(RoleIds.accountant);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.viewCashierShift, branchId: 'branch_1'), isTrue);

      // Accountant cannot perform capital injections / withdrawals
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isFalse);
    });

    test('7. HR Specialist has zero cashier permissions (Fail-Closed)', () {
      userProvider.user = createUserWithRole(RoleIds.hr);

      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);
    });

    test('8. Clinic Owner has full access across all cashier operations in any branch', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-OWNER',
        fullName: 'مالك العيادة',
        isActive: true,
        isOwner: true,
      );

      for (final p in [
        StaffPermissionEnum.accessCashier,
        StaffPermissionEnum.collectPayment,
        StaffPermissionEnum.refundPayment,
        StaffPermissionEnum.viewCashierShift,
        StaffPermissionEnum.manageCashierShifts,
        StaffPermissionEnum.manageDrawerMovements,
      ]) {
        expect(evaluator.can(p, branchId: 'branch_1'), isTrue);
        expect(evaluator.can(p, branchId: 'branch_2'), isTrue);
      }
    });

    test('9. Branch isolation: cashier permissions in branch_1 do NOT grant access in branch_2', () {
      userProvider.user = createUserWithRole(RoleIds.reception, branch: 'branch_1');

      // Allowed in branch_1
      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isTrue);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isTrue);

      // Blocked in branch_2
      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_2'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_2'), isFalse);
    });

    test('10. Fail-Closed safety: null user or deactivated user has zero cashier permissions', () {
      userProvider.user = null;
      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.collectPayment, branchId: 'branch_1'), isFalse);

      userProvider.user = const StaffUserModel(
        id: 'USER-INACTIVE',
        isActive: false,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.branchManager]),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.accessCashier, branchId: 'branch_1'), isFalse);
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isFalse);
    });

    test('11. Drawer movements governance: Manager has permission, Accountant does not', () {
      final manager = createUserWithRole(RoleIds.branchManager);
      final accountant = createUserWithRole(RoleIds.accountant);

      userProvider.user = manager;
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isTrue);

      userProvider.user = accountant;
      expect(evaluator.can(StaffPermissionEnum.manageDrawerMovements, branchId: 'branch_1'), isFalse);
    });

    test('12. Refund governance: Receptionist denied, Manager and Accountant allowed', () {
      final receptionist = createUserWithRole(RoleIds.reception);
      final manager = createUserWithRole(RoleIds.branchManager);
      final accountant = createUserWithRole(RoleIds.accountant);

      userProvider.user = receptionist;
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isFalse);

      userProvider.user = manager;
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isTrue);

      userProvider.user = accountant;
      expect(evaluator.can(StaffPermissionEnum.refundPayment, branchId: 'branch_1'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/routing/app_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

class MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  MockUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class MockRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  MockRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator evaluator;

  setUp(() {
    rolesProvider = MockRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );
    userProvider = MockUserSessionProvider();
    evaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );
  });

  group('PermissionEvaluator: Fail-Closed Core Safety', () {
    test('Null user returns false for all permissions', () {
      userProvider.user = null;
      for (final p in StaffPermissionEnum.values) {
        expect(evaluator.can(p), isFalse, reason: 'Must fail-closed when user is null: $p');
      }
    });

    test('Deactivated or soft-deleted user returns false', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-DEACTIVATED',
        isActive: false,
        isOwner: true, // Even an owner when deactivated must have zero access!
      );
      expect(evaluator.can(StaffPermissionEnum.accessLiveQueue), isFalse);

      userProvider.user = const StaffUserModel(
        id: 'USER-DELETED',
        isActive: true,
        isDeleted: true,
      );
      expect(evaluator.can(StaffPermissionEnum.accessLiveQueue), isFalse);
    });

    test('User with no branch assignment for target branch returns false', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-BRANCH1-ONLY',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );
      // Accessing branch_1 is allowed
      expect(evaluator.can(StaffPermissionEnum.accessLiveQueue, branchId: 'branch_1'), isTrue);
      // Accessing branch_2 is rejected
      expect(evaluator.can(StaffPermissionEnum.accessLiveQueue, branchId: 'branch_2'), isFalse);
    });
  });

  group('PermissionEvaluator: 7 System Roles Truth Table', () {
    void testRolePermissions(String roleId, Set<StaffPermissionEnum> expected) {
      userProvider.user = StaffUserModel(
        id: 'USER-TEST-$roleId',
        isActive: true,
        isOwner: false,
        linkedDoctorId: roleId == RoleIds.doctor ? 'DOC-01' : null,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [roleId]),
        ],
      );

      for (final p in StaffPermissionEnum.values) {
        // Clinical permissions requiring doctor assignment context are tested with assignment
        final hasAccess = evaluator.can(
          p,
          patientDoctorIds: {'DOC-01'},
        );

        if (expected.contains(p)) {
          expect(hasAccess, isTrue, reason: 'Role $roleId should HAVE permission $p');
        } else {
          expect(hasAccess, isFalse, reason: 'Role $roleId should NOT have permission $p');
        }
      }
    }

    test('1. Branch Manager Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.branchManager,
        {
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.createBooking,
          StaffPermissionEnum.editBooking,
          StaffPermissionEnum.cancelBooking,
          StaffPermissionEnum.reorderQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.createPatient,
          StaffPermissionEnum.editPatient,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorSchedules,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.approveLeavesAndReferrals,
          StaffPermissionEnum.viewClinicalPerformance,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.refundPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.applyManualDiscount,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.viewFinancialReports,
          StaffPermissionEnum.accessSettings,
          StaffPermissionEnum.manageMedicalServices,
        },
      );
    });

    test('2. Medical Director Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.medicalDirector,
        {
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.approveLeavesAndReferrals,
          StaffPermissionEnum.viewClinicalPerformance,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.manageMedicalServices,
        },
      );
    });

    test('3. Doctor Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.doctor,
        {
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.editMedicalDiagnosis,
          StaffPermissionEnum.issuePrescription,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.viewClinicalPerformance,
        },
      );
    });

    test('4. Nurse Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.nurse,
        {
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
        },
      );
    });

    test('5. Reception Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.reception,
        {
          StaffPermissionEnum.accessLiveQueue,
          StaffPermissionEnum.createBooking,
          StaffPermissionEnum.editBooking,
          StaffPermissionEnum.cancelBooking,
          StaffPermissionEnum.reorderQueue,
          StaffPermissionEnum.accessPatients,
          StaffPermissionEnum.createPatient,
          StaffPermissionEnum.editPatient,
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.viewCashierShift,
        },
      );
    });

    test('6. Accountant Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.accountant,
        {
          StaffPermissionEnum.accessCashier,
          StaffPermissionEnum.collectPayment,
          StaffPermissionEnum.refundPayment,
          StaffPermissionEnum.viewCashierShift,
          StaffPermissionEnum.applyManualDiscount,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessAnalytics,
          StaffPermissionEnum.viewFinancialReports,
        },
      );
    });

    test('7. HR Specialist Permissions Truth Table', () {
      testRolePermissions(
        RoleIds.hr,
        {
          StaffPermissionEnum.accessDoctors,
          StaffPermissionEnum.manageDoctorSchedules,
          StaffPermissionEnum.manageDoctorLeaves,
          StaffPermissionEnum.accessHr,
          StaffPermissionEnum.calculateDoctorSettlement,
          StaffPermissionEnum.accessSettings,
          StaffPermissionEnum.createStaffUser,
          StaffPermissionEnum.editStaffUser,
          StaffPermissionEnum.deleteStaffUser,
          StaffPermissionEnum.toggleStaffUserStatus,
        },
      );
    });
  });

  group('PermissionEvaluator: Fail-Closed Clinical Guard Matrix', () {
    test('Non-practicing owner can view diagnostics but CANNOT write prescription or diagnosis', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-OWNER',
        isOwner: true,
        isActive: true,
        linkedDoctorId: null, // Non-practicing owner
      );

      // Owner can view diagnostics without being the assigned doctor
      expect(evaluator.can(StaffPermissionEnum.viewMedicalRecordDiagnostics), isTrue);

      // But writing diagnosis or prescription is STRICTLY REJECTED
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-01'},
        ),
        isFalse,
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.issuePrescription,
          patientDoctorIds: {'DOC-01'},
        ),
        isFalse,
      );
    });

    test('Practicing owner can prescribe ONLY for their assigned patients', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-OWNER-PRACTICING',
        isOwner: true,
        isActive: true,
        linkedDoctorId: 'DOC-01', // Practicing doctor profile
      );

      // Patient assigned to DOC-01: ALLOWED
      expect(
        evaluator.can(
          StaffPermissionEnum.issuePrescription,
          patientDoctorIds: {'DOC-01'},
        ),
        isTrue,
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-01'},
        ),
        isTrue,
      );

      // Patient assigned to DOC-02 only: REJECTED even for the owner!
      expect(
        evaluator.can(
          StaffPermissionEnum.issuePrescription,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });

    test('Medical Director with viewAllDoctorsMedicalRecords can VIEW all, but CANNOT edit diagnosis', () {
      // Add custom role with viewAllDoctorsMedicalRecords
      const medDirReviewRole = RoleDefinitionModel(
        id: 'role_med_dir_review',
        permissions: [
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          StaffPermissionEnum.viewAllDoctorsMedicalRecords,
          StaffPermissionEnum.editMedicalDiagnosis, // Even if role contains it!
        ],
      );
      rolesProvider.roles = [...rolesProvider.roles, medDirReviewRole];

      userProvider.user = const StaffUserModel(
        id: 'USER-MED-DIR',
        isActive: true,
        linkedDoctorId: null, // Administrative, not patient doctor
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: ['role_med_dir_review']),
        ],
      );

      // Can VIEW diagnostics of any doctor's patient
      expect(
        evaluator.can(
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          patientDoctorIds: {'DOC-02'},
        ),
        isTrue,
      );

      // CANNOT EDIT diagnosis of another doctor's patient
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );

      // CANNOT ISSUE prescription
      expect(
        evaluator.can(
          StaffPermissionEnum.issuePrescription,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });

    test('Doctor viewing/editing permissions strictly limited to assigned patients', () {
      userProvider.user = const StaffUserModel(
        id: 'USER-DOC-01',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      // Assigned patient: can view and edit
      expect(
        evaluator.can(
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          patientDoctorIds: {'DOC-01', 'DOC-03'},
        ),
        isTrue,
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-01'},
        ),
        isTrue,
      );

      // Unassigned patient: CANNOT view and CANNOT edit
      expect(
        evaluator.can(
          StaffPermissionEnum.viewMedicalRecordDiagnostics,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });
  });

  group('Dynamic Roles Update in Memory', () {
    test('Updating role permissions immediately reflects in evaluator without restart', () {
      final sessionCubit = SessionCubit(
        const SessionState(
          currentUser: StaffUserModel(
            id: 'USER-ACC',
            isActive: true,
            branchAssignments: [
              BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.accountant]),
            ],
          ),
          activeBranchId: 'branch_1',
        ),
      );

      // Initially accountant does NOT have accessLiveQueue
      expect(sessionCubit.can(StaffPermissionEnum.accessLiveQueue), isFalse);

      // Dynamically grant accessLiveQueue to accountant role
      final currentRoles = List<RoleDefinitionModel>.from(sessionCubit.currentRoles);
      final accIndex = currentRoles.indexWhere((r) => r.id == RoleIds.accountant);
      final accRole = currentRoles[accIndex];
      currentRoles[accIndex] = accRole.copyWith(
        permissions: [...?accRole.permissions, StaffPermissionEnum.accessLiveQueue],
      );

      sessionCubit.updateCachedRoles(currentRoles);

      // Now accountant IMMEDIATELY has accessLiveQueue
      expect(sessionCubit.can(StaffPermissionEnum.accessLiveQueue), isTrue);
    });
  });

  group('Route Guards: Permission Mapping Test', () {
    test('Routes correctly map to required permissions', () {
      expect(
        getRequiredPermissionForRoute(AppRouter.usersManagement),
        equals(StaffPermissionEnum.manageRolesAndPermissions),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.bookings),
        equals(StaffPermissionEnum.accessLiveQueue),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.patients),
        equals(StaffPermissionEnum.accessPatients),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.doctors),
        equals(StaffPermissionEnum.accessDoctors),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.cashier),
        equals(StaffPermissionEnum.accessCashier),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.hr),
        equals(StaffPermissionEnum.accessHr),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.analytics),
        equals(StaffPermissionEnum.accessAnalytics),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.settings),
        equals(StaffPermissionEnum.accessSettings),
      );
      expect(
        getRequiredPermissionForRoute('/settings/medical-services'),
        equals(StaffPermissionEnum.manageMedicalServices),
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.login),
        isNull,
      );
      expect(
        getRequiredPermissionForRoute(AppRouter.forbidden),
        isNull,
      );
    });
  });
}


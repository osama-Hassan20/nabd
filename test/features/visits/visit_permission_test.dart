import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
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

  group('Visit RBAC & PermissionEvaluator Tests', () {
    test('T1: PermissionEvaluator.can(viewVisitsQueue) = true for Doctor', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewVisitsQueue), isTrue);
    });

    test('T2: PermissionEvaluator.can(viewVisitsQueue) = true for Nurse', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewVisitsQueue), isTrue);
    });

    test('T3: PermissionEvaluator.can(viewVisitsQueue) = false for Accountant', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-ACC',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.accountant],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewVisitsQueue), isFalse);
    });

    test('T4: PermissionEvaluator.can(startConsultation) = true for Doctor assigned to patient', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.startConsultation,
          patientDoctorIds: {'DOC-01'},
        ),
        isTrue,
      );
    });

    test('T5: PermissionEvaluator.can(startConsultation) = false for Doctor NOT assigned to patient', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.startConsultation,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });

    test('T6: PermissionEvaluator.can(editMedicalDiagnosis) = false if linkedDoctorId != visit.doctorId', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });

    test('T7: PermissionEvaluator.can(recordVitals) = true for Nurse', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.recordVitals), isTrue);
    });

    test('T8: PermissionEvaluator.can(viewMedicalRecordDiagnostics) = false for Reception', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-REC',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.reception],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewMedicalRecordDiagnostics), isFalse);
    });

    test('T9: Owner with isPracticingDoctor = false cannot start consultation', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER',
        isActive: true,
        isOwner: true,
        linkedDoctorId: null, // Non-practicing
      );
      expect(evaluator.can(StaffPermissionEnum.startConsultation), isFalse);
    });

    test('T10: Owner with isPracticingDoctor = true but different doctorId cannot edit diagnosis', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER-DOC',
        isActive: true,
        isOwner: true,
        linkedDoctorId: 'DOC-01',
      );
      expect(
        evaluator.can(
          StaffPermissionEnum.editMedicalDiagnosis,
          patientDoctorIds: {'DOC-02'},
        ),
        isFalse,
      );
    });

    test('T11: PermissionEvaluator.can(viewConsultationNotes) is true for Doctor, false for Nurse', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewConsultationNotes), isFalse);

      userProvider.user = const StaffUserModel(
        id: 'USR-DOC',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewConsultationNotes), isTrue);
    });

    test('T12: PermissionEvaluator.can(viewConsultationNotes) is true for Owner, Medical Director, Branch Manager', () {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER',
        isActive: true,
        isOwner: true,
      );
      expect(evaluator.can(StaffPermissionEnum.viewConsultationNotes), isTrue);

      userProvider.user = const StaffUserModel(
        id: 'USR-MED-DIR',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.medicalDirector],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewConsultationNotes), isTrue);

      userProvider.user = const StaffUserModel(
        id: 'USR-BM',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.branchManager],
          ),
        ],
      );
      expect(evaluator.can(StaffPermissionEnum.viewConsultationNotes), isTrue);
    });
  });
}

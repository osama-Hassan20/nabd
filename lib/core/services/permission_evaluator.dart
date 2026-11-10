import '../enums/staff_permission_enum.dart';
import '../../features/users_management/data/models/role_definition_model.dart';
import '../../features/users_management/data/models/staff_user_model.dart';

abstract class CurrentUserProvider {
  StaffUserModel? get currentUser;
  String? get activeBranchId;
}

abstract class RolesProvider {
  List<RoleDefinitionModel> get currentRoles;
}

class PermissionEvaluator {
  final CurrentUserProvider userProvider;
  final RolesProvider rolesProvider;

  const PermissionEvaluator({
    required this.userProvider,
    required this.rolesProvider,
  });

  bool can(
    StaffPermissionEnum permission, {
    String? branchId,
    Set<String>? patientDoctorIds,
  }) {
    final user = userProvider.currentUser;

    // Fail-Closed: Unauthenticated or inactive users have zero access
    if (user == null || user.canAuthenticate == false) {
      return false;
    }

    final targetBranch = branchId ?? userProvider.activeBranchId ?? 'branch_1';

    // ─── 1. Owner Evaluation ──────────────────────────────────────────────────
    if (user.isOwner == true) {
      // Clinical write actions require valid linked doctor profile and patient assignment
      if (permission == StaffPermissionEnum.editMedicalDiagnosis ||
          permission == StaffPermissionEnum.issuePrescription ||
          permission == StaffPermissionEnum.startConsultation) {
        if (!user.isPracticingDoctor) {
          return false; // Non-practicing owner cannot write diagnosis or start consultation
        }
        if (patientDoctorIds != null &&
            !patientDoctorIds.contains(user.linkedDoctorId)) {
          return false; // Cannot start consultation or prescribe for a patient not assigned to them
        }
      }
      return true; // Owner has all other facility and view permissions
    }

    // ─── 2. Branch Assignment Check ───────────────────────────────────────────
    final assignment = user.branchAssignments
        ?.where((b) => b.branchId == targetBranch)
        .firstOrNull;

    if (assignment == null || assignment.branchId == null) {
      return false; // User has no role in the targeted branch
    }

    final userRoleIds = assignment.roleIds ?? [];
    if (userRoleIds.isEmpty) {
      return false;
    }

    // ─── 3. Collect Granted Permissions from Assigned Roles ───────────────────
    final allRoles = rolesProvider.currentRoles;
    final grantedPermissions = <StaffPermissionEnum>{};

    for (final roleId in userRoleIds) {
      final role = allRoles.firstWhere(
        (r) => r.id == roleId,
        orElse: () => const RoleDefinitionModel(),
      );
      if (role.permissions != null) {
        grantedPermissions.addAll(role.permissions!);
      }
    }

    if (!grantedPermissions.contains(permission)) {
      return false;
    }

    // ─── 4. Clinical Context & Fail-Closed Guard Rules ────────────────────────
    // 4.1 Diagnosis & Prescription Writing & Start Consultation: Strict requirement for practicing doctor assigned to patient
    if (permission == StaffPermissionEnum.editMedicalDiagnosis ||
        permission == StaffPermissionEnum.issuePrescription ||
        permission == StaffPermissionEnum.startConsultation) {
      if (!user.isPracticingDoctor) {
        return false;
      }
      if (patientDoctorIds != null &&
          !patientDoctorIds.contains(user.linkedDoctorId)) {
        return false;
      }
      return true;
    }

    // 4.2 Medical Diagnostics Viewing: Medical director / assigned doctor
    if (permission == StaffPermissionEnum.viewMedicalRecordDiagnostics) {
      // If user has viewAllDoctorsMedicalRecords permission, view is granted across all patients
      if (grantedPermissions.contains(StaffPermissionEnum.viewAllDoctorsMedicalRecords)) {
        return true;
      }

      // If user is a practicing doctor, they can only view diagnostics of their assigned patients
      if (user.isPracticingDoctor &&
          patientDoctorIds != null &&
          !patientDoctorIds.contains(user.linkedDoctorId)) {
        return false;
      }
    }

    return true;
  }
}


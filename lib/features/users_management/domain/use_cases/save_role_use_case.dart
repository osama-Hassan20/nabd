import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/role_definition_model.dart';
import '../../data/models/staff_user_model.dart';
import '../../data/repositories/staff_users_repo.dart';

class SaveRoleParams {
  final RoleDefinitionModel role;
  final String currentUserId;

  const SaveRoleParams({
    required this.role,
    required this.currentUserId,
  });
}

class SaveRoleUseCase implements UseCase<RoleDefinitionModel, SaveRoleParams> {
  final StaffUsersRepo staffUsersRepo;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  SaveRoleUseCase({
    required this.staffUsersRepo,
    this.currentUserProvider,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, RoleDefinitionModel>> call(
    SaveRoleParams params,
  ) async {
    // 1. Resolve actor
    final actorId =
        currentUserProvider?.currentUser?.id ?? params.currentUserId;
    final actorRes = await staffUsersRepo.getStaffUserById(actorId);
    StaffUserModel? actor;
    actorRes.fold((_) => null, (u) => actor = u);

    final isOwner = actor?.isOwner == true;

    // 2. Fetch existing roles to check for discount policy modifications
    final rolesRes = await staffUsersRepo.getRoles();
    List<RoleDefinitionModel> roles = [];
    rolesRes.fold((_) => null, (r) => roles = r);

    final existingIndex = roles.indexWhere((r) => r.id == params.role.id);
    final existingRole = existingIndex != -1 ? roles[existingIndex] : null;

    if (!isOwner) {
      final requestedMaxPct = params.role.maxDiscountPercent;
      final requestedCanFree = params.role.canGrantFreeConsultation;

      final existingMaxPct = existingRole?.maxDiscountPercent;
      final existingCanFree = existingRole?.canGrantFreeConsultation;

      final changedMaxPct = requestedMaxPct != existingMaxPct;
      final changedCanFree = requestedCanFree != existingCanFree;

      if (changedMaxPct || changedCanFree) {
        auditLogger?.log(
          eventType: 'privilege_escalation_attempt',
          performedByUserId: actorId,
          details:
              'Non-owner attempted to modify discount policy for role: ${params.role.nameAr}',
        );
        return const Left(
          PrivilegeEscalationFailure(
            errMessage: 'disc_policy_owner_only',
          ),
        );
      }
    }

    // 3. Save role via repo, strictly preserving protected fields if non-owner
    final roleToSave = isOwner
        ? params.role
        : params.role.copyWith(
            maxDiscountPercent: existingRole?.maxDiscountPercent,
            canGrantFreeConsultation: existingRole?.canGrantFreeConsultation,
          );

    final saveRes = await staffUsersRepo.saveRole(
      role: roleToSave,
      currentUserId: actorId,
    );

    return saveRes.fold(
      (failure) => Left(failure),
      (savedRole) => Right(savedRole),
    );
  }
}

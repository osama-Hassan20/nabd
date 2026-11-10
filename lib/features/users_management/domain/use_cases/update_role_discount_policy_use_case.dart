import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/role_definition_model.dart';
import '../../data/models/staff_user_model.dart';
import '../../data/repositories/staff_users_repo.dart';
import 'params/update_role_discount_policy_params.dart';

class UpdateRoleDiscountPolicyUseCase
    implements UseCase<Unit, UpdateRoleDiscountPolicyParams> {
  final StaffUsersRepo staffUsersRepo;
  final AuditLogger? auditLogger;

  UpdateRoleDiscountPolicyUseCase({
    required this.staffUsersRepo,
    this.auditLogger,
  });

  @override
  Future<Either<Failures, Unit>> call(
    UpdateRoleDiscountPolicyParams params,
  ) async {
    // 1. Verify that current user is an owner
    final userResult =
        await staffUsersRepo.getStaffUserById(params.currentUserId);
    StaffUserModel? actor;
    userResult.fold((_) => null, (u) => actor = u);

    if (actor == null || actor!.isOwner != true) {
      return const Left(ServerFailure(errMessage: 'disc_policy_owner_only'));
    }

    // 2. Fetch role
    final rolesResult = await staffUsersRepo.getRoles();
    RoleDefinitionModel? targetRole;
    rolesResult.fold(
      (_) => null,
      (roles) {
        final idx = roles.indexWhere((r) => r.id == params.roleId);
        if (idx != -1) targetRole = roles[idx];
      },
    );

    if (targetRole == null) {
      return const Left(ServerFailure(errMessage: 'role_not_found'));
    }

    final oldMaxPct = targetRole!.maxDiscountPercent;
    final oldCanFree = targetRole!.canGrantFreeConsultation;

    // 3. Update discount policy fields
    final updatedRole = targetRole!.copyWith(
      maxDiscountPercent: params.maxDiscountPercent,
      canGrantFreeConsultation: params.canGrantFreeConsultation,
    );

    final saveResult = await staffUsersRepo.saveRole(
      role: updatedRole,
      currentUserId: params.currentUserId,
    );

    return saveResult.fold(
      (failure) => Left(failure),
      (_) {
        auditLogger?.log(
          eventType: 'discount_policy_changed',
          performedByUserId: params.currentUserId,
          details:
              'Discount policy updated for role ${params.roleId}: maxPct $oldMaxPct -> ${params.maxDiscountPercent}, canFree $oldCanFree -> ${params.canGrantFreeConsultation}',
        );
        return const Right(unit);
      },
    );
  }
}

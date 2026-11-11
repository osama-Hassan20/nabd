import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../users_management/data/models/role_definition_model.dart';
import '../../../users_management/data/models/staff_user_model.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';

class ActorDiscountPolicy {
  final StaffUserModel? actor;
  final bool isOwner;
  final bool hasApplyPermission;
  final num? maxDiscountPercent;
  final bool? canGrantFreeConsultation;

  const ActorDiscountPolicy({
    this.actor,
    required this.isOwner,
    required this.hasApplyPermission,
    this.maxDiscountPercent,
    this.canGrantFreeConsultation,
  });
}

class BookingDiscountPolicyResolver {
  BookingDiscountPolicyResolver._();

  static Future<ActorDiscountPolicy> resolve({
    CurrentUserProvider? currentUserProvider,
    PermissionEvaluator? permissionEvaluator,
    StaffUsersRepo? staffUsersRepo,
    String? branchId,
    String? fallbackUserId,
  }) async {
    StaffUserModel? actor = currentUserProvider?.currentUser ??
        permissionEvaluator?.userProvider.currentUser;

    if (actor == null && fallbackUserId != null && staffUsersRepo != null) {
      final actorRes = await staffUsersRepo.getStaffUserById(fallbackUserId);
      actorRes.fold((_) => null, (u) => actor = u);
    }

    if (actor == null) {
      return const ActorDiscountPolicy(
        actor: null,
        isOwner: false,
        hasApplyPermission: false,
        maxDiscountPercent: 0,
        canGrantFreeConsultation: false,
      );
    }

    final isOwner = actor!.isOwner == true;
    if (isOwner) {
      return ActorDiscountPolicy(
        actor: actor,
        isOwner: true,
        hasApplyPermission: true,
        maxDiscountPercent: 100,
        canGrantFreeConsultation: true,
      );
    }

    bool hasApplyPermission = false;
    if (permissionEvaluator != null) {
      hasApplyPermission = permissionEvaluator.can(
        StaffPermissionEnum.applyBookingDiscount,
        branchId: branchId,
      );
    }

    num? maxDiscountPercent;
    bool? canGrantFreeConsultation;

    if (staffUsersRepo != null) {
      final rolesRes = await staffUsersRepo.getRoles();
      List<RoleDefinitionModel> allRoles = [];
      rolesRes.fold((_) => null, (r) => allRoles = r);

      final branchAssignment = actor!.branchAssignments
              ?.where((b) => b.branchId == branchId)
              .firstOrNull ??
          actor!.branchAssignments?.firstOrNull;

      final roleIds = branchAssignment?.roleIds ?? [];
      for (final rId in roleIds) {
        final roleDef = allRoles.where((r) => r.id == rId).firstOrNull;
        if (roleDef != null) {
          if (permissionEvaluator == null &&
              (roleDef.permissions
                      ?.contains(StaffPermissionEnum.applyBookingDiscount) ??
                  false)) {
            hasApplyPermission = true;
          }
          final p = roleDef.maxDiscountPercent;
          if (p != null) {
            maxDiscountPercent = maxDiscountPercent == null
                ? p
                : (p > maxDiscountPercent ? p : maxDiscountPercent);
          }
          if (roleDef.canGrantFreeConsultation == true) {
            canGrantFreeConsultation = true;
          }
        }
      }
    }

    return ActorDiscountPolicy(
      actor: actor,
      isOwner: false,
      hasApplyPermission: hasApplyPermission,
      maxDiscountPercent: maxDiscountPercent,
      canGrantFreeConsultation: canGrantFreeConsultation ?? false,
    );
  }
}


import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../users_management/data/repositories/staff_users_repo.dart';
import '../../data/models/cashier_shift_model.dart';
import '../repo/cashier_repo.dart';

class ApproveShortageUseCase {
  final CashierRepo cashierRepo;
  final StaffUsersRepo? staffUsersRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const ApproveShortageUseCase({
    required this.cashierRepo,
    this.staffUsersRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, CashierShiftModel>> call({
    required String shiftId,
    required String branchId,
    required String cashierUserId,
    required String reason,
    String? approvedByUserId,
  }) async {
    if (reason.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_reason_required'),
      );
    }

    final user = currentUserProvider?.currentUser;
    final effectiveApproverId = approvedByUserId ?? user?.id;

    if (effectiveApproverId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 1. Permission check: manageCashierShifts
    if (permissionEvaluator != null) {
      final canManage = permissionEvaluator!.can(
        StaffPermissionEnum.manageCashierShifts,
        branchId: branchId,
      );
      if (!canManage) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 2. Separation of duties check
    bool isOwnerSelfApproved = false;
    if (effectiveApproverId == cashierUserId) {
      final isOwner = user?.isOwner == true;
      if (!isOwner) {
        return const Left(
          ValidationFailure(errMessage: 'cashier_approver_same_as_cashier'),
        );
      }

      // Check single owner condition: no other active staff member in this branch possesses manageCashierShifts
      if (staffUsersRepo != null) {
        final staffRes = await staffUsersRepo!.getStaffUsers(
          branchId: branchId,
          isActive: true,
        );

        if (staffRes.isRight()) {
          final activeStaff = staffRes.getOrElse(() => []);
          final otherManagers = activeStaff.where((s) {
            if (s.id == user?.id) return false;
            if (s.isOwner == true) return true;
            return s.branchAssignments?.any(
                  (a) =>
                      a.branchId == branchId &&
                      (a.roleIds?.contains('role_branch_manager') == true ||
                          a.roleIds?.contains('branch_manager') == true),
                ) ??
                false;
          }).toList();

          if (otherManagers.isNotEmpty) {
            // Another qualified manager exists in this branch; owner cannot self-approve
            return const Left(
              ValidationFailure(errMessage: 'cashier_approver_same_as_cashier'),
            );
          }
        }
      }

      isOwnerSelfApproved = true;
    }

    // 3. Approve in repo
    final result = await cashierRepo.approveShortage(
      shiftId: shiftId,
      approvedByUserId: effectiveApproverId,
      reason: reason,
      isOwnerSelfApproved: isOwnerSelfApproved,
    );

    // 4. Audit on success
    result.fold(
      (failure) => null,
      (shift) {
        if (isOwnerSelfApproved) {
          auditLogger?.log(
            eventType: 'owner_self_approved',
            performedByUserId: effectiveApproverId,
            performedByUserName: user?.fullName ?? 'Unknown',
            branchId: branchId,
            details:
                'shiftId: $shiftId, differencePiastres: ${shift.cashDifferencePiastres ?? 0}, ownerUserId: $effectiveApproverId, reason: owner_self_approved_single_operator',
          );
        } else {
          auditLogger?.log(
            eventType: 'shortage_approved',
            performedByUserId: effectiveApproverId,
            performedByUserName: user?.fullName ?? 'Unknown',
            branchId: branchId,
            details:
                'shiftId: $shiftId, differencePiastres: ${shift.cashDifferencePiastres ?? 0}, approvedByUserId: $effectiveApproverId, reason: $reason',
          );
        }
      },
    );

    return result;
  }
}

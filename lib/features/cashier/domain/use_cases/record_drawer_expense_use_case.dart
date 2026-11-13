import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/cash_movement_model.dart';
import '../../data/models/enums/cash_movement_type_enum.dart';
import '../contracts/cashier_policy.dart';
import '../repo/cashier_repo.dart';

class RecordDrawerExpenseUseCase {
  final CashierRepo cashierRepo;
  final CashierPolicy policy;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const RecordDrawerExpenseUseCase({
    required this.cashierRepo,
    required this.policy,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, CashMovementModel>> call({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    String? performedByUserId,
  }) async {
    // 1. Validate positive amount
    if (amountPiastres <= 0) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_positive_amount'),
      );
    }

    // 2. Validate mandatory reason
    if (reason.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_reason_required'),
      );
    }

    // 3. Resolve actor
    final user = currentUserProvider?.currentUser;
    final effectiveUserId = performedByUserId ?? user?.id;

    if (effectiveUserId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 4. Check permissions against CashierPolicy
    if (permissionEvaluator != null) {
      final isPetty = movementType == CashMovementTypeEnum.pettyExpense.name;
      final isWithinPettyLimit = amountPiastres <= policy.maxPettyExpensePiastres;

      if (isPetty && isWithinPettyLimit) {
        final canCollect = permissionEvaluator!.can(
          StaffPermissionEnum.collectPayment,
          branchId: branchId,
        );
        if (!canCollect) {
          return const Left(ValidationFailure(errMessage: 'permission_denied'));
        }
      } else {
        // Exceeds petty expense threshold, or is capital injection/deposit/withdrawal
        final canManageDrawer = permissionEvaluator!.can(
          StaffPermissionEnum.manageDrawerMovements,
          branchId: branchId,
        );
        if (!canManageDrawer) {
          return const Left(ValidationFailure(errMessage: 'permission_denied'));
        }
      }
    }

    // 5. Record movement in repo
    final result = await cashierRepo.recordCashMovement(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      movementType: movementType,
      amountPiastres: amountPiastres,
      reason: reason,
      recipientName: recipientName,
      performedByUserId: effectiveUserId,
    );

    // 6. Audit on success
    result.fold(
      (failure) => null,
      (movement) {
        auditLogger?.log(
          eventType: 'cash_movement_recorded',
          performedByUserId: effectiveUserId,
          performedByUserName: user?.fullName ?? 'Unknown',
          branchId: branchId,
          details:
              'movementId: ${movement.id}, shiftId: $shiftId, movementType: $movementType, amountPiastres: $amountPiastres, reason: $reason',
        );
      },
    );

    return result;
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/cashier_shift_model.dart';
import '../repo/cashier_repo.dart';

class ForceCloseShiftUseCase {
  final CashierRepo cashierRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const ForceCloseShiftUseCase({
    required this.cashierRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, CashierShiftModel>> call({
    required String shiftId,
    required String branchId,
    required String reason,
    String? performedByUserId,
  }) async {
    if (reason.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_reason_required'),
      );
    }

    final user = currentUserProvider?.currentUser;
    final effectiveUserId = performedByUserId ?? user?.id;

    if (effectiveUserId == null) {
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

    // 2. Force close in repo
    final result = await cashierRepo.forceCloseShift(
      shiftId: shiftId,
      performedByUserId: effectiveUserId,
      reason: reason,
    );

    // 3. Audit on success
    result.fold(
      (failure) => null,
      (shift) {
        auditLogger?.log(
          eventType: 'shift_force_closed',
          performedByUserId: effectiveUserId,
          performedByUserName: user?.fullName ?? 'Unknown',
          branchId: branchId,
          details:
              'shiftId: $shiftId, performedByUserId: $effectiveUserId, reason: $reason',
        );
      },
    );

    return result;
  }
}

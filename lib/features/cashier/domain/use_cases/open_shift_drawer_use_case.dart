import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/cashier_shift_model.dart';
import '../repo/cashier_repo.dart';

class OpenShiftDrawerUseCase {
  final CashierRepo cashierRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const OpenShiftDrawerUseCase({
    required this.cashierRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, CashierShiftModel>> call({
    required String branchId,
    required int openingBalancePiastres,
    String? cashierUserId,
    String? cashierName,
    String? suggestedOpeningBalanceDiffReason,
  }) async {
    // 1. Validate non-negative opening balance
    if (openingBalancePiastres < 0) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_opening_balance_negative'),
      );
    }

    // 2. Resolve actor
    final user = currentUserProvider?.currentUser;
    final effectiveUserId = cashierUserId ?? user?.id;
    final effectiveName = cashierName ?? user?.fullName ?? 'Unknown';

    if (effectiveUserId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 3. Fail-Closed permission check
    if (permissionEvaluator != null) {
      final canOpen = permissionEvaluator!.can(
        StaffPermissionEnum.collectPayment,
        branchId: branchId,
      );
      if (!canOpen) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Open shift in repo
    final result = await cashierRepo.openShift(
      branchId: branchId,
      cashierUserId: effectiveUserId,
      cashierName: effectiveName,
      openingBalancePiastres: openingBalancePiastres,
      suggestedOpeningBalanceDiffReason: suggestedOpeningBalanceDiffReason,
    );

    // 5. Audit on success only (Strictly NO audit on failure)
    result.fold(
      (failure) => null,
      (shift) {
        auditLogger?.log(
          eventType: 'shift_opened',
          performedByUserId: effectiveUserId,
          performedByUserName: effectiveName,
          branchId: branchId,
          details:
              'shiftId: ${shift.id}, branchId: $branchId, openingBalancePiastres: $openingBalancePiastres',
        );
      },
    );

    return result;
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/cashier_shift_model.dart';
import '../contracts/cashier_policy.dart';
import '../helpers/cashier_shift_calculator.dart';
import '../repo/cashier_repo.dart';

class CloseShiftDrawerUseCase {
  final CashierRepo cashierRepo;
  final CashierPolicy policy;
  final CashierShiftCalculator calculator;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const CloseShiftDrawerUseCase({
    required this.cashierRepo,
    required this.policy,
    this.calculator = const CashierShiftCalculator(),
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, CashierShiftModel>> call({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  }) async {
    // 1. Validate non-negative cash count
    if (actualCashCountPiastres < 0) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_actual_cash_negative'),
      );
    }

    // 2. Fetch current shift
    final user = currentUserProvider?.currentUser;
    if (user == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    // 3. Fail-Closed permission check
    if (permissionEvaluator != null) {
      final canCollect = permissionEvaluator!.can(StaffPermissionEnum.collectPayment);
      if (!canCollect) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Close shift via repository
    final result = await cashierRepo.closeShift(
      shiftId: shiftId,
      actualCashCountPiastres: actualCashCountPiastres,
      closingNotes: closingNotes,
      shortageReason: shortageReason,
    );

    // 5. Audit on success
    result.fold(
      (failure) => null,
      (shift) {
        final expected = shift.expectedCashPiastres ?? 0;
        final diff = shift.cashDifferencePiastres ?? (actualCashCountPiastres - expected);
        auditLogger?.log(
          eventType: 'shift_closed',
          performedByUserId: user.id,
          performedByUserName: user.fullName ?? 'Unknown',
          branchId: shift.branchId,
          details:
              'shiftId: $shiftId, expectedCashPiastres: $expected, actualCashCountPiastres: $actualCashCountPiastres, differencePiastres: $diff',
        );
      },
    );

    return result;
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/cashier_shift_model.dart';
import '../repo/cashier_repo.dart';

class GetActiveShiftUseCase {
  final CashierRepo cashierRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GetActiveShiftUseCase({
    required this.cashierRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, CashierShiftModel?>> call({
    required String branchId,
    String? cashierUserId,
  }) async {
    final user = currentUserProvider?.currentUser;
    final effectiveUserId = cashierUserId ?? user?.id;

    if (effectiveUserId == null) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_user_required'),
      );
    }

    if (permissionEvaluator != null) {
      final canView = permissionEvaluator!.can(
            StaffPermissionEnum.viewCashierShift,
            branchId: branchId,
          ) ||
          permissionEvaluator!.can(
            StaffPermissionEnum.collectPayment,
            branchId: branchId,
          );

      if (!canView) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return cashierRepo.getCurrentShift(
      branchId: branchId,
      cashierUserId: effectiveUserId,
    );
  }
}

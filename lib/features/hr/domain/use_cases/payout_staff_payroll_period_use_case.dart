import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/enums/payroll_status_enum.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../repo/hr_repo.dart';

class PayoutStaffPayrollPeriodUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const PayoutStaffPayrollPeriodUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, StaffPayrollPeriodModel>> call({
    required String periodId,
  }) async {
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    // 1. Fetch period
    final existingRes = await hrRepo.getStaffPayrollPeriodById(periodId);
    if (existingRes.isLeft()) {
      return existingRes;
    }
    final existing = existingRes.getOrElse(() => throw StateError('unreachable'));

    // 2. Status validation: must be confirmed
    if (existing.status == PayrollStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'hr_payroll_period_not_confirmed_cannot_payout'));
    }
    if (existing.status == PayrollStatusEnum.paid) {
      return const Left(ValidationFailure(errMessage: 'hr_payroll_period_already_paid'));
    }

    // 3. Permission check: manageStaffPayroll
    if (permissionEvaluator != null) {
      final canPayout = permissionEvaluator!.can(
        StaffPermissionEnum.manageStaffPayroll,
        branchId: existing.primaryBranchId,
      );
      if (!canPayout) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Payout in repo
    final payoutRes = await hrRepo.payoutStaffPayrollPeriod(
      periodId: periodId,
      paidByUserId: user.id ?? 'unknown_user',
    );

    // 5. Audit logging on success ONLY
    payoutRes.fold(
      (failure) => null,
      (paid) {
        auditLogger?.log(
          eventType: 'staff_payroll_paid',
          performedByUserId: user.id,
          performedByUserName: user.fullName ?? 'Unknown',
          branchId: paid.primaryBranchId,
          details:
              'payrollId: ${paid.id}, totalAmountPiastres: ${paid.totalNetPayablePiastres}, '
              'paidByUserId: ${user.id}',
        );
      },
    );

    return payoutRes;
  }
}


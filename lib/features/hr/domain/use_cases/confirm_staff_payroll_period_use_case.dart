import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/enums/payroll_status_enum.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../repo/hr_repo.dart';

class ConfirmStaffPayrollPeriodUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const ConfirmStaffPayrollPeriodUseCase({
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

    // 2. Validate status: must be draft
    if (existing.status != PayrollStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'hr_payroll_period_already_confirmed_or_paid'));
    }

    // 3. Permission check: manageStaffPayroll
    if (permissionEvaluator != null) {
      final canManage = permissionEvaluator!.can(
        StaffPermissionEnum.manageStaffPayroll,
        branchId: existing.primaryBranchId,
      );
      if (!canManage) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Confirm in repo
    final confirmRes = await hrRepo.confirmStaffPayrollPeriod(
      periodId: periodId,
      confirmedByUserId: user.id ?? 'unknown_user',
    );

    // 5. Audit logging on success ONLY
    confirmRes.fold(
      (failure) => null,
      (confirmed) {
        auditLogger?.log(
          eventType: 'staff_payroll_confirmed',
          performedByUserId: user.id,
          performedByUserName: user.fullName ?? 'Unknown',
          branchId: confirmed.primaryBranchId,
          details:
              'payrollId: ${confirmed.id}, periodMonth: ${confirmed.month}, '
              'periodYear: ${confirmed.year}, employeesCount: ${confirmed.totalEmployeesCount}, '
              'totalNetPayablePiastres: ${confirmed.totalNetPayablePiastres}, '
              'confirmedByUserId: ${user.id}',
        );
      },
    );

    return confirmRes;
  }
}

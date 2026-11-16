import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../helpers/staff_payroll_calculator.dart';
import '../repo/hr_repo.dart';

class GenerateStaffPayrollPeriodUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const GenerateStaffPayrollPeriodUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, StaffPayrollPeriodModel>> call({
    required String primaryBranchId,
    required int month,
    required int year,
  }) async {
    // 1. Validation
    if (primaryBranchId.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_branch_id_required'));
    }
    if (month < 1 || month > 12) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_month'));
    }
    if (year < 2000) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_year'));
    }

    // 2. Permission check: manageStaffPayroll
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final canManage = permissionEvaluator!.can(
        StaffPermissionEnum.manageStaffPayroll,
        branchId: primaryBranchId,
      );
      if (!canManage) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 3. Duplicate check for same branch, month, and year
    final periodsRes = await hrRepo.getStaffPayrollPeriods(
      primaryBranchId: primaryBranchId,
      year: year,
    );
    if (periodsRes.isRight()) {
      final periods = periodsRes.getOrElse(() => []);
      final duplicate = periods.any((p) => p.month == month && p.year == year);
      if (duplicate) {
        return const Left(ValidationFailure(errMessage: 'hr_payroll_period_already_exists'));
      }
    }

    // 4. Fetch profiles
    final profilesRes = await hrRepo.getStaffPayrollProfiles(primaryBranchId: primaryBranchId);
    if (profilesRes.isLeft()) {
      return Left(profilesRes.fold((f) => f, (r) => const ValidationFailure(errMessage: 'profiles_error')));
    }
    final allProfiles = profilesRes.getOrElse(() => []);
    final activeProfiles = allProfiles.where((p) => p.isActive == true).toList();

    // 5. Fetch ledger entries for each active staff member
    final allLedgerEntries = <EmployeeLedgerEntryModel>[];
    for (final p in activeProfiles) {
      if (p.staffUserId != null && p.staffUserId!.isNotEmpty) {
        final entriesRes = await hrRepo.getEmployeeLedgerEntries(
          employeeId: p.staffUserId!,
          branchId: primaryBranchId,
        );
        if (entriesRes.isRight()) {
          allLedgerEntries.addAll(entriesRes.getOrElse(() => []));
        }
      }
    }

    // 6. Calculate period
    final period = StaffPayrollCalculator.calculatePeriod(
      primaryBranchId: primaryBranchId,
      month: month,
      year: year,
      activeProfiles: activeProfiles,
      ledgerEntries: allLedgerEntries,
    );

    // 7. Save period in repo
    return hrRepo.saveStaffPayrollPeriod(period);
  }
}


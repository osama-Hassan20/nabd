import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/staff_payroll_profile_model.dart';
import '../repo/hr_repo.dart';

class SaveStaffPayrollProfileUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;

  const SaveStaffPayrollProfileUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
  });

  Future<Either<Failures, StaffPayrollProfileModel>> call(
    StaffPayrollProfileModel profile,
  ) async {
    // 1. Validation of required identifiers
    if (profile.staffUserId == null || profile.staffUserId!.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_staff_user_id_required'));
    }
    if (profile.primaryBranchId == null || profile.primaryBranchId!.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_branch_id_required'));
    }

    // 2. Financial bounds validation: non-negative
    if (profile.baseSalaryPiastres == null || profile.baseSalaryPiastres! < 0) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_base_salary'));
    }
    if (profile.housingAllowancePiastres != null && profile.housingAllowancePiastres! < 0) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_allowance'));
    }
    if (profile.transportationAllowancePiastres != null &&
        profile.transportationAllowancePiastres! < 0) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_allowance'));
    }
    if (profile.insuranceDeductionPiastres != null &&
        profile.insuranceDeductionPiastres! < 0) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_deduction'));
    }
    if (profile.taxDeductionPiastres != null && profile.taxDeductionPiastres! < 0) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_deduction'));
    }

    // 3. Permission check: manageStaffPayroll
    final user = currentUserProvider?.currentUser;
    if (user == null || user.canAuthenticate == false) {
      return const Left(ValidationFailure(errMessage: 'permission_denied'));
    }

    if (permissionEvaluator != null) {
      final canManage = permissionEvaluator!.can(
        StaffPermissionEnum.manageStaffPayroll,
        branchId: profile.primaryBranchId,
      );
      if (!canManage) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    return hrRepo.saveStaffPayrollProfile(profile);
  }
}

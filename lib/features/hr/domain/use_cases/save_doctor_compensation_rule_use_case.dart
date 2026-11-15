import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../../data/models/enums/compensation_type_enum.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../repo/hr_repo.dart';

class SaveDoctorCompensationRuleUseCase {
  final HrRepo hrRepo;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const SaveDoctorCompensationRuleUseCase({
    required this.hrRepo,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, DoctorCompensationRuleModel>> call(
    DoctorCompensationRuleModel rule,
  ) async {
    // 1. Validation of required identifiers
    if (rule.doctorId == null || rule.doctorId!.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_doctor_id_required'));
    }
    if (rule.branchId == null || rule.branchId!.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_branch_id_required'));
    }
    if (rule.effectiveFrom == null) {
      return const Left(ValidationFailure(errMessage: 'hr_effective_from_required'));
    }
    if (rule.compensationType == null) {
      return const Left(ValidationFailure(errMessage: 'hr_compensation_type_required'));
    }

    // 2. Mathematical bounds validation
    switch (rule.compensationType!) {
      case CompensationTypeEnum.percentage:
        if (rule.commissionPercentage == null ||
            rule.commissionPercentage! < 0 ||
            rule.commissionPercentage! > 100) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_commission_percentage'));
        }
        break;
      case CompensationTypeEnum.fixedPerVisit:
        if (rule.fixedAmountPerVisitPiastres == null ||
            rule.fixedAmountPerVisitPiastres! < 0) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_fixed_amount'));
        }
        break;
      case CompensationTypeEnum.salaryOnly:
        if (rule.monthlyBaseSalaryPiastres == null ||
            rule.monthlyBaseSalaryPiastres! < 0) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_base_salary'));
        }
        break;
      case CompensationTypeEnum.salaryPlusPercentage:
        if (rule.monthlyBaseSalaryPiastres == null ||
            rule.monthlyBaseSalaryPiastres! < 0) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_base_salary'));
        }
        if (rule.commissionPercentage == null ||
            rule.commissionPercentage! < 0 ||
            rule.commissionPercentage! > 100) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_commission_percentage'));
        }
        break;
      case CompensationTypeEnum.salaryPlusFixed:
        if (rule.monthlyBaseSalaryPiastres == null ||
            rule.monthlyBaseSalaryPiastres! < 0) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_base_salary'));
        }
        if (rule.fixedAmountPerVisitPiastres == null ||
            rule.fixedAmountPerVisitPiastres! < 0) {
          return const Left(ValidationFailure(errMessage: 'hr_invalid_fixed_amount'));
        }
        break;
    }

    // 3. Permission check: fail-closed
    final user = currentUserProvider?.currentUser;
    if (permissionEvaluator != null) {
      final canManage = permissionEvaluator!.can(
        StaffPermissionEnum.manageCompensationRules,
        branchId: rule.branchId,
      );
      if (!canManage) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 4. Retroactivity check against confirmed/paid settlements
    final settlementsRes = await hrRepo.getDoctorSettlements(
      doctorId: rule.doctorId,
      branchId: rule.branchId,
    );
    if (settlementsRes.isRight()) {
      final settlements = settlementsRes.getOrElse(() => []);
      for (final s in settlements) {
        final isConfirmedOrPaid = s.status == SettlementStatusEnum.confirmed ||
            s.status == SettlementStatusEnum.paid;
        if (isConfirmedOrPaid && s.periodEnd != null) {
          if (rule.effectiveFrom!.isBefore(s.periodEnd!) ||
              rule.effectiveFrom!.isAtSameMomentAs(s.periodEnd!)) {
            return const Left(ValidationFailure(
              errMessage: 'hr_retroactive_rule_rejected_confirmed_period_exists',
            ));
          }
        }
      }
    }

    // 5. Save rule
    final result = await hrRepo.saveCompensationRule(rule);

    // 6. Security Audit logging on success ONLY (DEC-006: zero audit on failure, numeric/enum fields only)
    result.fold(
      (failure) => null,
      (savedRule) {
        auditLogger?.log(
          eventType: 'compensation_rule_saved',
          performedByUserId: user?.id,
          performedByUserName: user?.fullName ?? 'Unknown',
          branchId: savedRule.branchId,
          details:
              'ruleId: ${savedRule.id}, doctorId: ${savedRule.doctorId}, '
              'branchId: ${savedRule.branchId}, compensationType: ${savedRule.compensationType?.name}, '
              'percentage: ${savedRule.commissionPercentage}, fixedPiastres: ${savedRule.fixedAmountPerVisitPiastres}, '
              'baseSalaryPiastres: ${savedRule.monthlyBaseSalaryPiastres}',
        );
      },
    );

    return result;
  }
}


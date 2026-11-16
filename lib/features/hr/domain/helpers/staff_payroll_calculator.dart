import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/enums/ledger_entry_type_enum.dart';
import '../../data/models/enums/payroll_status_enum.dart';
import '../../data/models/staff_payroll_item_model.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../../data/models/staff_payroll_profile_model.dart';

class StaffPayrollCalculator {
  static StaffPayrollPeriodModel calculatePeriod({
    required String primaryBranchId,
    required int month,
    required int year,
    required List<StaffPayrollProfileModel> activeProfiles,
    required List<EmployeeLedgerEntryModel> ledgerEntries,
    List<String> alreadyConsumedAdvanceEntryIds = const [],
    DateTime? now,
  }) {
    final items = <StaffPayrollItemModel>[];
    final consumedAdvances = <String>[];

    int totalBase = 0;
    int totalAllowances = 0;
    int totalDeductions = 0;
    int totalNet = 0;

    // Filter profiles that are active and match primaryBranchId
    final eligibleProfiles = activeProfiles.where((p) {
      if (p.isActive != true) return false;
      if (p.primaryBranchId != null && p.primaryBranchId != primaryBranchId) return false;
      return true;
    }).toList();

    for (final profile in eligibleProfiles) {
      final staffId = profile.staffUserId ?? '';
      final baseSalary = profile.baseSalaryPiastres ?? 0;
      final housing = profile.housingAllowancePiastres ?? 0;
      final transportation = profile.transportationAllowancePiastres ?? 0;
      final allowances = housing + transportation;

      final insurance = profile.insuranceDeductionPiastres ?? 0;
      final tax = profile.taxDeductionPiastres ?? 0;
      final statutory = insurance + tax;

      // Filter ledger entries for this employee
      final empLedger = ledgerEntries.where((e) => e.employeeId == staffId).toList();

      // Ledger bonuses
      int bonuses = 0;
      for (final e in empLedger) {
        if (e.entryType == LedgerEntryTypeEnum.bonus && (e.amountPiastres ?? 0) > 0) {
          bonuses += e.amountPiastres!;
        }
      }

      // Ledger manual deductions
      int manualDeductions = 0;
      for (final e in empLedger) {
        if (e.entryType == LedgerEntryTypeEnum.deduction && (e.amountPiastres ?? 0) > 0) {
          manualDeductions += e.amountPiastres!;
        }
      }

      // Gross earnings before advances deduction
      final grossEarnings = baseSalary + allowances + bonuses - statutory - manualDeductions;

      // Calculate unconsumed outstanding advances
      final reversedIds = <String>{};
      for (final e in empLedger) {
        if (e.reversesEntryId != null) {
          reversedIds.add(e.reversesEntryId!);
        }
      }

      int availableAdvances = 0;
      final empConsumedAdvanceIds = <String>[];
      for (final e in empLedger) {
        if (e.entryType == LedgerEntryTypeEnum.advance) {
          if (e.id != null && !alreadyConsumedAdvanceEntryIds.contains(e.id)) {
            if (e.reversesEntryId == null && !reversedIds.contains(e.id)) {
              availableAdvances += (e.amountPiastres ?? 0);
              empConsumedAdvanceIds.add(e.id!);
            }
          }
        }
      }

      // Advances deduction capped at available earnings
      final maxDeductible = grossEarnings > 0 ? grossEarnings : 0;
      final advancesToDeduct = availableAdvances > maxDeductible ? maxDeductible : availableAdvances;
      if (advancesToDeduct > 0) {
        consumedAdvances.addAll(empConsumedAdvanceIds);
      }

      final totalEmpDeductions = statutory + manualDeductions + advancesToDeduct;
      final netSalary = grossEarnings - advancesToDeduct;

      final item = StaffPayrollItemModel(
        staffUserId: staffId,
        employeeName: profile.fullName,
        jobTitle: profile.jobTitle,
        primaryBranchId: primaryBranchId,
        baseSalaryPiastres: baseSalary,
        housingAllowancePiastres: housing,
        transportationAllowancePiastres: transportation,
        totalAllowancesPiastres: allowances,
        insuranceDeductionPiastres: insurance,
        taxDeductionPiastres: tax,
        ledgerDeductionsPiastres: manualDeductions,
        ledgerBonusesPiastres: bonuses,
        advancesDeductedPiastres: advancesToDeduct,
        totalDeductionsPiastres: totalEmpDeductions,
        netSalaryPiastres: netSalary > 0 ? netSalary : 0,
      );

      items.add(item);

      totalBase += baseSalary;
      totalAllowances += allowances;
      totalDeductions += totalEmpDeductions;
      totalNet += (netSalary > 0 ? netSalary : 0);
    }

    return StaffPayrollPeriodModel(
      primaryBranchId: primaryBranchId,
      month: month,
      year: year,
      status: PayrollStatusEnum.draft,
      totalEmployeesCount: items.length,
      totalBaseSalaryPiastres: totalBase,
      totalAllowancesPiastres: totalAllowances,
      totalDeductionsPiastres: totalDeductions,
      totalNetPayablePiastres: totalNet,
      items: items,
      createdAt: now,
    );
  }
}


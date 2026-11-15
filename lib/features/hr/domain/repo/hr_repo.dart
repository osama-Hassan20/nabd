import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../../data/models/staff_payroll_period_model.dart';
import '../../data/models/staff_payroll_profile_model.dart';

abstract class HrRepo {
  // ─── Doctor Compensation Rules ───────────────────────────────────────────
  Future<Either<Failures, List<DoctorCompensationRuleModel>>> getCompensationRules({
    String? doctorId,
    String? branchId,
  });

  Future<Either<Failures, DoctorCompensationRuleModel>> getCompensationRuleById(String ruleId);

  Future<Either<Failures, DoctorCompensationRuleModel>> getActiveRuleForDoctor({
    required String doctorId,
    required String branchId,
    DateTime? date,
  });

  Future<Either<Failures, DoctorCompensationRuleModel>> saveCompensationRule(
    DoctorCompensationRuleModel rule,
  );

  // ─── Doctor Settlements ──────────────────────────────────────────────────
  Future<Either<Failures, List<DoctorSettlementModel>>> getDoctorSettlements({
    String? doctorId,
    String? branchId,
    SettlementStatusEnum? status,
  });

  Future<Either<Failures, DoctorSettlementModel>> getDoctorSettlementById(String settlementId);

  Future<Either<Failures, DoctorSettlementModel>> saveDoctorSettlement(
    DoctorSettlementModel settlement,
  );

  Future<Either<Failures, DoctorSettlementModel>> confirmDoctorSettlement({
    required String settlementId,
    required String confirmedByUserId,
    bool isOwnerSelfConfirmed = false,
  });

  Future<Either<Failures, DoctorSettlementModel>> payoutDoctorSettlement({
    required String settlementId,
    required String paidByUserId,
    required PaymentMethod method,
    String? refNumber,
  });

  Future<bool> isPeriodOverlapping({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? excludeSettlementId,
  });

  // ─── Employee Ledger & Advances ──────────────────────────────────────────
  Future<Either<Failures, List<EmployeeLedgerEntryModel>>> getEmployeeLedgerEntries({
    required String employeeId,
    String? branchId,
  });

  Future<Either<Failures, EmployeeLedgerEntryModel>> addEmployeeLedgerEntry(
    EmployeeLedgerEntryModel entry,
  );

  Future<Either<Failures, EmployeeLedgerEntryModel>> reverseEmployeeLedgerEntry({
    required String entryId,
    required String reason,
    required String performedByUserId,
  });

  // ─── Staff Payroll ───────────────────────────────────────────────────────
  Future<Either<Failures, List<StaffPayrollProfileModel>>> getStaffPayrollProfiles({
    String? primaryBranchId,
  });

  Future<Either<Failures, StaffPayrollProfileModel>> saveStaffPayrollProfile(
    StaffPayrollProfileModel profile,
  );

  Future<Either<Failures, List<StaffPayrollPeriodModel>>> getStaffPayrollPeriods({
    String? primaryBranchId,
    int? year,
  });

  Future<Either<Failures, StaffPayrollPeriodModel>> getStaffPayrollPeriodById(String periodId);

  Future<Either<Failures, StaffPayrollPeriodModel>> saveStaffPayrollPeriod(
    StaffPayrollPeriodModel period,
  );

  Future<Either<Failures, StaffPayrollPeriodModel>> confirmStaffPayrollPeriod({
    required String periodId,
    required String confirmedByUserId,
  });

  Future<Either<Failures, StaffPayrollPeriodModel>> payoutStaffPayrollPeriod({
    required String periodId,
    required String paidByUserId,
  });
}


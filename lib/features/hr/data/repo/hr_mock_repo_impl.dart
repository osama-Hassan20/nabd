import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import '../../domain/repo/hr_repo.dart';
import '../models/doctor_compensation_rule_model.dart';
import '../models/doctor_settlement_model.dart';
import '../models/employee_ledger_entry_model.dart';
import '../models/enums/compensation_type_enum.dart';
import '../models/enums/employee_type_enum.dart';
import '../models/enums/ledger_entry_type_enum.dart';
import '../models/enums/payroll_status_enum.dart';
import '../models/enums/settlement_status_enum.dart';
import '../models/staff_payroll_period_model.dart';
import '../models/staff_payroll_profile_model.dart';

class HrMockRepoImpl implements HrRepo {
  final List<DoctorCompensationRuleModel> _rules = [];
  final List<DoctorSettlementModel> _settlements = [];
  final List<EmployeeLedgerEntryModel> _ledgerEntries = [];
  final List<StaffPayrollProfileModel> _payrollProfiles = [];
  final List<StaffPayrollPeriodModel> _payrollPeriods = [];

  int _ruleCounter = 100;
  int _settlementCounter = 100;
  int _ledgerCounter = 100;
  int _payrollProfileCounter = 100;
  int _payrollPeriodCounter = 100;

  HrMockRepoImpl({bool seedInitialData = true}) {
    if (seedInitialData) {
      _initSeedData();
    }
  }

  void _initSeedData() {
    final now = CairoTimeHelper.now();
    final effectiveBase = DateTime(now.year, 1, 1);

    // ─── Seed Compensation Rules (DOC-01 to DOC-06) ──────────────────────────
    _rules.addAll([
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-02',
        doctorId: 'DOC-02',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryPlusPercentage,
        monthlyBaseSalaryPiastres: 1000000, // 10,000 EGP
        commissionPercentage: 30,
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-03',
        doctorId: 'DOC-03',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000, // 100 EGP
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-04',
        doctorId: 'DOC-04',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 40,
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-05',
        doctorId: 'DOC-05',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: 1500000, // 15,000 EGP
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
      DoctorCompensationRuleModel(
        id: 'RULE-DOC-06',
        doctorId: 'DOC-06',
        branchId: 'branch_1',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 50,
        effectiveFrom: effectiveBase,
        createdAt: effectiveBase,
        isActive: true,
      ),
    ]);

    // ─── Seed Staff Payroll Profiles ─────────────────────────────────────────
    _payrollProfiles.addAll([
      const StaffPayrollProfileModel(
        id: 'PRF-001',
        staffUserId: 'usr_reception_1',
        fullName: 'سارة أحمد',
        jobTitle: 'موظف استقبال',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 600000, // 6,000 EGP
        housingAllowancePiastres: 50000,
        transportationAllowancePiastres: 50000,
        insuranceDeductionPiastres: 40000,
        taxDeductionPiastres: 20000,
        isActive: true,
      ),
      const StaffPayrollProfileModel(
        id: 'PRF-002',
        staffUserId: 'usr_nurse_1',
        fullName: 'مريم علي',
        jobTitle: 'تمريض أول',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 750000, // 7,500 EGP
        housingAllowancePiastres: 60000,
        transportationAllowancePiastres: 60000,
        insuranceDeductionPiastres: 50000,
        taxDeductionPiastres: 25000,
        isActive: true,
      ),
      const StaffPayrollProfileModel(
        id: 'PRF-003',
        staffUserId: 'usr_accountant_1',
        fullName: 'أحمد محمود',
        jobTitle: 'محاسب مالي',
        primaryBranchId: 'branch_1',
        baseSalaryPiastres: 900000, // 9,000 EGP
        housingAllowancePiastres: 80000,
        transportationAllowancePiastres: 80000,
        insuranceDeductionPiastres: 60000,
        taxDeductionPiastres: 35000,
        isActive: true,
      ),
    ]);

    // ─── Seed Historical Settlements (source = mockSeed) ──────────────────────
    final pastMonthStart = DateTime(now.year, now.month - 1, 1);
    final pastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    _settlements.add(
      DoctorSettlementModel(
        id: 'SET-SEED-001',
        settlementNumber: 'SET-DOC-${now.year}${(now.month - 1).toString().padLeft(2, '0')}-001',
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد خالد',
        branchId: 'branch_1',
        periodStart: pastMonthStart,
        periodEnd: pastMonthEnd,
        status: SettlementStatusEnum.paid,
        totalVisitsCount: 15,
        totalNetRevenuePiastres: 450000, // 4,500 EGP
        totalDoctorCommissionPiastres: 225000, // 2,250 EGP (50%)
        totalClinicSharePiastres: 225000,
        baseSalaryPiastres: 0,
        totalBonusesPiastres: 0,
        totalDeductionsPiastres: 0,
        totalAdvancesDeductedPiastres: 0,
        netPayablePiastres: 225000,
        confirmedByUserId: 'usr_owner_1',
        confirmedAt: pastMonthEnd.add(const Duration(days: 1)),
        paidAt: pastMonthEnd.add(const Duration(days: 2)),
        paymentMethod: PaymentMethod.bankTransfer,
        source: 'mockSeed',
        createdAt: pastMonthEnd,
      ),
    );
  }

  // ─── Doctor Compensation Rules ─────────────────────────────────────────────

  @override
  Future<Either<Failures, List<DoctorCompensationRuleModel>>> getCompensationRules({
    String? doctorId,
    String? branchId,
  }) async {
    var list = _rules.where((r) => r.isActive == true).toList();
    if (doctorId != null && doctorId.isNotEmpty) {
      list = list.where((r) => r.doctorId == doctorId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      list = list.where((r) => r.branchId == branchId).toList();
    }
    return Right(list);
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> getCompensationRuleById(String ruleId) async {
    final rule = _rules.cast<DoctorCompensationRuleModel?>().firstWhere(
          (r) => r?.id == ruleId,
          orElse: () => null,
        );
    if (rule == null) {
      return const Left(ValidationFailure(errMessage: 'rule_not_found'));
    }
    return Right(rule);
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> getActiveRuleForDoctor({
    required String doctorId,
    required String branchId,
    DateTime? date,
  }) async {
    final targetDate = date ?? CairoTimeHelper.now();

    final matching = _rules.where((r) {
      if (r.doctorId != doctorId) return false;
      if (r.branchId != branchId) return false;
      if (r.isActive != true) return false;
      if (r.effectiveFrom != null && r.effectiveFrom!.isAfter(targetDate)) return false;
      return true;
    }).toList();

    if (matching.isEmpty) {
      return const Left(ValidationFailure(errMessage: 'no_active_compensation_rule'));
    }

    // Sort by effectiveFrom descending to take the latest rule
    matching.sort((a, b) => (b.effectiveFrom ?? DateTime(1970)).compareTo(a.effectiveFrom ?? DateTime(1970)));
    return Right(matching.first);
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> saveCompensationRule(
    DoctorCompensationRuleModel rule,
  ) async {
    if (rule.doctorId == null || rule.doctorId!.isEmpty) {
      return const Left(ValidationFailure(errMessage: 'doctor_required'));
    }
    if (rule.branchId == null || rule.branchId!.isEmpty) {
      return const Left(ValidationFailure(errMessage: 'branch_required'));
    }

    final now = CairoTimeHelper.now();

    if (rule.id != null && rule.id!.isNotEmpty) {
      final index = _rules.indexWhere((r) => r.id == rule.id);
      if (index == -1) {
        return const Left(ValidationFailure(errMessage: 'rule_not_found'));
      }
      final updated = rule.copyWith();
      _rules[index] = updated;
      return Right(updated);
    } else {
      final newId = 'RULE-${(++_ruleCounter)}';
      final created = rule.copyWith(
        id: newId,
        createdAt: now,
        isActive: true,
      );
      _rules.add(created);
      return Right(created);
    }
  }

  // ─── Doctor Settlements ────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<DoctorSettlementModel>>> getDoctorSettlements({
    String? doctorId,
    String? branchId,
    SettlementStatusEnum? status,
  }) async {
    var list = _settlements.toList();
    if (doctorId != null && doctorId.isNotEmpty) {
      list = list.where((s) => s.doctorId == doctorId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      list = list.where((s) => s.branchId == branchId).toList();
    }
    if (status != null) {
      list = list.where((s) => s.status == status).toList();
    }
    // Sort by createdAt descending
    list.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    return Right(list);
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> getDoctorSettlementById(String settlementId) async {
    final s = _settlements.cast<DoctorSettlementModel?>().firstWhere(
          (e) => e?.id == settlementId,
          orElse: () => null,
        );
    if (s == null) {
      return const Left(ValidationFailure(errMessage: 'settlement_not_found'));
    }
    return Right(s);
  }

  @override
  Future<bool> isPeriodOverlapping({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? excludeSettlementId,
  }) async {
    for (final s in _settlements) {
      if (s.id == excludeSettlementId) continue;
      if (s.doctorId != doctorId || s.branchId != branchId) continue;
      if (s.status == SettlementStatusEnum.draft) continue; // Drafts do not block confirmed periods
      if (s.periodStart == null || s.periodEnd == null) continue;

      // Overlap condition: startA <= endB && endA >= startB
      final overlaps = !periodStart.isAfter(s.periodEnd!) && !periodEnd.isBefore(s.periodStart!);
      if (overlaps) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> saveDoctorSettlement(
    DoctorSettlementModel settlement,
  ) async {
    final now = CairoTimeHelper.now();

    if (settlement.id != null && settlement.id!.isNotEmpty) {
      final idx = _settlements.indexWhere((s) => s.id == settlement.id);
      if (idx != -1) {
        _settlements[idx] = settlement;
        return Right(settlement);
      }
    }

    final newId = settlement.id ?? 'SET-${(++_settlementCounter)}';
    final ym = '${settlement.periodStart?.year ?? now.year}${((settlement.periodStart?.month ?? now.month)).toString().padLeft(2, '0')}';
    final settlementNumber = settlement.settlementNumber ??
        'SET-DOC-$ym-${_settlementCounter.toString().padLeft(3, '0')}';

    final created = settlement.copyWith(
      id: newId,
      settlementNumber: settlementNumber,
      status: settlement.status ?? SettlementStatusEnum.draft,
      createdAt: settlement.createdAt ?? now,
    );
    _settlements.insert(0, created);
    return Right(created);
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> confirmDoctorSettlement({
    required String settlementId,
    required String confirmedByUserId,
    bool isOwnerSelfConfirmed = false,
  }) async {
    final idx = _settlements.indexWhere((s) => s.id == settlementId);
    if (idx == -1) {
      return const Left(ValidationFailure(errMessage: 'settlement_not_found'));
    }

    final existing = _settlements[idx];
    if (existing.status != SettlementStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'settlement_already_confirmed'));
    }

    final confirmed = existing.copyWith(
      status: SettlementStatusEnum.confirmed,
      confirmedByUserId: confirmedByUserId,
      confirmedAt: CairoTimeHelper.now(),
      isOwnerSelfConfirmed: isOwnerSelfConfirmed,
    );
    _settlements[idx] = confirmed;
    return Right(confirmed);
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> payoutDoctorSettlement({
    required String settlementId,
    required String paidByUserId,
    required PaymentMethod method,
    String? refNumber,
  }) async {
    final idx = _settlements.indexWhere((s) => s.id == settlementId);
    if (idx == -1) {
      return const Left(ValidationFailure(errMessage: 'settlement_not_found'));
    }

    final existing = _settlements[idx];
    if (existing.status != SettlementStatusEnum.confirmed) {
      return const Left(ValidationFailure(errMessage: 'settlement_not_confirmed'));
    }

    final now = CairoTimeHelper.now();
    final paid = existing.copyWith(
      status: SettlementStatusEnum.paid,
      paidAt: now,
      paymentMethod: method,
      paymentReferenceNumber: refNumber,
    );
    _settlements[idx] = paid;

    // Append ledger payout entry
    _ledgerEntries.add(
      EmployeeLedgerEntryModel(
        id: 'LED-${(++_ledgerCounter)}',
        employeeId: existing.doctorId,
        employeeType: EmployeeTypeEnum.doctor,
        branchId: existing.branchId,
        entryType: LedgerEntryTypeEnum.payout,
        amountPiastres: existing.netPayablePiastres,
        reason: 'صرف تسوية أتعاب ${existing.settlementNumber}',
        date: now,
        performedByUserId: paidByUserId,
        createdAt: now,
      ),
    );

    return Right(paid);
  }

  // ─── Employee Ledger & Advances ────────────────────────────────────────────

  @override
  Future<Either<Failures, List<EmployeeLedgerEntryModel>>> getEmployeeLedgerEntries({
    required String employeeId,
    String? branchId,
  }) async {
    var list = _ledgerEntries.where((e) => e.employeeId == employeeId).toList();
    if (branchId != null && branchId.isNotEmpty) {
      list = list.where((e) => e.branchId == branchId).toList();
    }
    list.sort((a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
    return Right(list);
  }

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>> addEmployeeLedgerEntry(
    EmployeeLedgerEntryModel entry,
  ) async {
    if (entry.amountPiastres == null || entry.amountPiastres! <= 0) {
      return const Left(ValidationFailure(errMessage: 'amount_must_be_positive'));
    }

    // Idempotency check with clientRequestId
    if (entry.clientRequestId != null && entry.clientRequestId!.isNotEmpty) {
      final existing = _ledgerEntries.cast<EmployeeLedgerEntryModel?>().firstWhere(
            (e) => e?.clientRequestId == entry.clientRequestId,
            orElse: () => null,
          );
      if (existing != null) {
        return Right(existing);
      }
    }

    final newId = 'LED-${(++_ledgerCounter)}';
    final created = entry.copyWith(
      id: newId,
      createdAt: CairoTimeHelper.now(),
    );
    _ledgerEntries.add(created);
    return Right(created);
  }

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>> reverseEmployeeLedgerEntry({
    required String entryId,
    required String reason,
    required String performedByUserId,
  }) async {
    final target = _ledgerEntries.cast<EmployeeLedgerEntryModel?>().firstWhere(
          (e) => e?.id == entryId,
          orElse: () => null,
        );
    if (target == null) {
      return const Left(ValidationFailure(errMessage: 'ledger_entry_not_found'));
    }

    if (reason.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'reversal_reason_required'));
    }

    if (target.reversesEntryId != null) {
      return const Left(ValidationFailure(errMessage: 'cannot_reverse_reversal_entry'));
    }

    if (target.entryType == LedgerEntryTypeEnum.payout) {
      return const Left(ValidationFailure(errMessage: 'cannot_reverse_payout_entry'));
    }

    // Check if already reversed
    final alreadyReversed = _ledgerEntries.any((e) => e.reversesEntryId == entryId);
    if (alreadyReversed) {
      return const Left(ValidationFailure(errMessage: 'ledger_entry_already_reversed'));
    }

    final now = CairoTimeHelper.now();
    final reverseId = 'LED-${(++_ledgerCounter)}';

    // Reverse entry: same amount, with reversesEntryId pointing to target
    final reverseEntry = EmployeeLedgerEntryModel(
      id: reverseId,
      employeeId: target.employeeId,
      employeeType: target.employeeType,
      branchId: target.branchId,
      entryType: target.entryType,
      amountPiastres: -(target.amountPiastres ?? 0),
      reason: reason,
      date: now,
      performedByUserId: performedByUserId,
      reversesEntryId: entryId,
      createdAt: now,
    );

    _ledgerEntries.add(reverseEntry);
    return Right(reverseEntry);
  }

  // ─── Staff Payroll ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<StaffPayrollProfileModel>>> getStaffPayrollProfiles({
    String? primaryBranchId,
  }) async {
    var list = _payrollProfiles.where((p) => p.isActive == true).toList();
    if (primaryBranchId != null && primaryBranchId.isNotEmpty) {
      list = list.where((p) => p.primaryBranchId == primaryBranchId).toList();
    }
    return Right(list);
  }

  @override
  Future<Either<Failures, StaffPayrollProfileModel>> saveStaffPayrollProfile(
    StaffPayrollProfileModel profile,
  ) async {
    final now = CairoTimeHelper.now();

    if (profile.id != null && profile.id!.isNotEmpty) {
      final idx = _payrollProfiles.indexWhere((p) => p.id == profile.id);
      if (idx == -1) {
        return const Left(ValidationFailure(errMessage: 'payroll_profile_not_found'));
      }
      final updated = profile.copyWith(updatedAt: now);
      _payrollProfiles[idx] = updated;
      return Right(updated);
    } else {
      final newId = 'PRF-${(++_payrollProfileCounter)}';
      final created = profile.copyWith(
        id: newId,
        isActive: true,
        updatedAt: now,
      );
      _payrollProfiles.add(created);
      return Right(created);
    }
  }

  @override
  Future<Either<Failures, List<StaffPayrollPeriodModel>>> getStaffPayrollPeriods({
    String? primaryBranchId,
    int? year,
  }) async {
    var list = _payrollPeriods.toList();
    if (primaryBranchId != null && primaryBranchId.isNotEmpty) {
      list = list.where((p) => p.primaryBranchId == primaryBranchId).toList();
    }
    if (year != null) {
      list = list.where((p) => p.year == year).toList();
    }
    list.sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    return Right(list);
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> saveStaffPayrollPeriod(
    StaffPayrollPeriodModel period,
  ) async {
    final now = CairoTimeHelper.now();

    if (period.id != null && period.id!.isNotEmpty) {
      final idx = _payrollPeriods.indexWhere((p) => p.id == period.id);
      if (idx == -1) {
        return const Left(ValidationFailure(errMessage: 'payroll_period_not_found'));
      }
      _payrollPeriods[idx] = period;
      return Right(period);
    } else {
      final newId = 'PAY-${(++_payrollPeriodCounter)}';
      final ym = '${period.year ?? now.year}${((period.month ?? now.month)).toString().padLeft(2, '0')}';
      final payrollNumber = 'PAY-$ym-${_payrollPeriodCounter.toString().padLeft(3, '0')}';

      final created = period.copyWith(
        id: newId,
        payrollNumber: payrollNumber,
        status: period.status ?? PayrollStatusEnum.draft,
        createdAt: now,
      );
      _payrollPeriods.insert(0, created);
      return Right(created);
    }
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> confirmStaffPayrollPeriod({
    required String periodId,
    required String confirmedByUserId,
  }) async {
    final idx = _payrollPeriods.indexWhere((p) => p.id == periodId);
    if (idx == -1) {
      return const Left(ValidationFailure(errMessage: 'payroll_period_not_found'));
    }

    final existing = _payrollPeriods[idx];
    if (existing.status != PayrollStatusEnum.draft) {
      return const Left(ValidationFailure(errMessage: 'payroll_period_already_confirmed'));
    }

    final confirmed = existing.copyWith(
      status: PayrollStatusEnum.confirmed,
      confirmedByUserId: confirmedByUserId,
      confirmedAt: CairoTimeHelper.now(),
    );
    _payrollPeriods[idx] = confirmed;
    return Right(confirmed);
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> payoutStaffPayrollPeriod({
    required String periodId,
    required String paidByUserId,
  }) async {
    final idx = _payrollPeriods.indexWhere((p) => p.id == periodId);
    if (idx == -1) {
      return const Left(ValidationFailure(errMessage: 'payroll_period_not_found'));
    }

    final existing = _payrollPeriods[idx];
    if (existing.status != PayrollStatusEnum.confirmed) {
      return const Left(ValidationFailure(errMessage: 'payroll_period_not_confirmed'));
    }

    final now = CairoTimeHelper.now();
    final paid = existing.copyWith(
      status: PayrollStatusEnum.paid,
      paidAt: now,
    );
    _payrollPeriods[idx] = paid;
    return Right(paid);
  }
}

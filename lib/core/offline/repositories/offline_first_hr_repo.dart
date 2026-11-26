import 'package:dartz/dartz.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../features/hr/data/models/doctor_compensation_rule_model.dart';
import '../../../features/hr/data/models/doctor_settlement_model.dart';
import '../../../features/hr/data/models/employee_ledger_entry_model.dart';
import '../../../features/hr/data/models/enums/settlement_status_enum.dart';
import '../../../features/hr/data/models/staff_payroll_period_model.dart';
import '../../../features/hr/data/models/staff_payroll_profile_model.dart';
import '../../../features/hr/domain/repo/hr_repo.dart';
import '../data_mode_service.dart';
import '../models/local_entity_record.dart';
import '../models/outbox_entry.dart';
import '../models/sync_status.dart';
import '../store/transactional_local_store.dart';

class OfflineFirstHrRepo implements HrRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final HrRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstHrRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, List<DoctorCompensationRuleModel>>> getCompensationRules({
    String? doctorId,
    String? branchId,
  }) async {
    final bId = branchId ?? getCurrentBranchId();
    final records = await localStore.getEntities(
      entityType: 'hr_compensation_rule',
      accountId: getCurrentAccountId(),
      branchId: bId,
    );

    final localRules = <String, DoctorCompensationRuleModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final rule = DoctorCompensationRuleModel.fromJson(rec.payload);
          if (rule.id != null && (doctorId == null || rule.doctorId == doctorId)) {
            localRules[rule.id!] = rule;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getCompensationRules(
      doctorId: doctorId,
      branchId: bId,
    );

    remoteRes.fold((_) {}, (rules) {
      for (final r in rules) {
        if (r.id != null && !localRules.containsKey(r.id!)) {
          localRules[r.id!] = r;
        }
      }
    });

    return Right(localRules.values.toList());
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> getCompensationRuleById(
    String ruleId,
  ) async {
    final localRec = await localStore.getEntity(
      localId: ruleId,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(DoctorCompensationRuleModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    return remoteRepo.getCompensationRuleById(ruleId);
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> getActiveRuleForDoctor({
    required String doctorId,
    required String branchId,
    DateTime? date,
  }) async {
    final records = await localStore.getEntities(
      entityType: 'hr_compensation_rule',
      accountId: getCurrentAccountId(),
      branchId: branchId,
    );

    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final rule = DoctorCompensationRuleModel.fromJson(rec.payload);
          if (rule.doctorId == doctorId && rule.branchId == branchId && rule.isActive == true) {
            return Right(rule);
          }
        } catch (_) {}
      }
    }

    return remoteRepo.getActiveRuleForDoctor(
      doctorId: doctorId,
      branchId: branchId,
      date: date,
    );
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> saveCompensationRule(
    DoctorCompensationRuleModel rule,
  ) async {
    final accountId = getCurrentAccountId();
    final branchId = rule.branchId ?? getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final ruleId = rule.id ?? 'RULE-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: ruleId,
          entityType: 'hr_compensation_rule',
          accountId: accountId,
          branchId: branchId,
          payload: rule.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: rule.effectiveFrom ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_rule_${ruleId}_${now.microsecondsSinceEpoch}',
          entityType: 'hr_compensation_rule',
          localId: ruleId,
          operation: OutboxOperationType.update,
          payload: rule.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.saveCompensationRule(rule);
    } catch (_) {}

    return Right(rule);
  }

  @override
  Future<Either<Failures, List<DoctorSettlementModel>>> getDoctorSettlements({
    String? doctorId,
    String? branchId,
    SettlementStatusEnum? status,
  }) async {
    final bId = branchId ?? getCurrentBranchId();
    final records = await localStore.getEntities(
      entityType: 'hr_doctor_settlement',
      accountId: getCurrentAccountId(),
      branchId: bId,
    );

    final localSettlements = <String, DoctorSettlementModel>{};
    for (final rec in records) {
      if (!rec.isTombstone) {
        try {
          final s = DoctorSettlementModel.fromJson(rec.payload);
          if (s.id != null && (doctorId == null || s.doctorId == doctorId) &&
              (status == null || s.status == status)) {
            localSettlements[s.id!] = s;
          }
        } catch (_) {}
      }
    }

    final remoteRes = await remoteRepo.getDoctorSettlements(
      doctorId: doctorId,
      branchId: bId,
      status: status,
    );

    remoteRes.fold((_) {}, (items) {
      for (final item in items) {
        if (item.id != null && !localSettlements.containsKey(item.id!)) {
          localSettlements[item.id!] = item;
        }
      }
    });

    return Right(localSettlements.values.toList());
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> getDoctorSettlementById(
    String settlementId,
  ) async {
    final localRec = await localStore.getEntity(
      localId: settlementId,
      accountId: getCurrentAccountId(),
      branchId: getCurrentBranchId(),
    );

    if (localRec != null && !localRec.isTombstone) {
      try {
        return Right(DoctorSettlementModel.fromJson(localRec.payload));
      } catch (_) {}
    }

    return remoteRepo.getDoctorSettlementById(settlementId);
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> saveDoctorSettlement(
    DoctorSettlementModel settlement,
  ) async {
    final res = await remoteRepo.saveDoctorSettlement(settlement);
    return res.fold((failure) => Left(failure), (saved) async {
      await _persistSettlementAtomic(saved);
      return Right(saved);
    });
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> confirmDoctorSettlement({
    required String settlementId,
    required String confirmedByUserId,
    bool isOwnerSelfConfirmed = false,
  }) async {
    final res = await remoteRepo.confirmDoctorSettlement(
      settlementId: settlementId,
      confirmedByUserId: confirmedByUserId,
      isOwnerSelfConfirmed: isOwnerSelfConfirmed,
    );
    return res.fold((failure) => Left(failure), (saved) async {
      await _persistSettlementAtomic(saved);
      return Right(saved);
    });
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> payoutDoctorSettlement({
    required String settlementId,
    required String paidByUserId,
    required PaymentMethod method,
    String? refNumber,
  }) async {
    final res = await remoteRepo.payoutDoctorSettlement(
      settlementId: settlementId,
      paidByUserId: paidByUserId,
      method: method,
      refNumber: refNumber,
    );
    return res.fold((failure) => Left(failure), (saved) async {
      await _persistSettlementAtomic(saved);
      return Right(saved);
    });
  }

  @override
  Future<bool> isPeriodOverlapping({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? excludeSettlementId,
  }) =>
      remoteRepo.isPeriodOverlapping(
        doctorId: doctorId,
        branchId: branchId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        excludeSettlementId: excludeSettlementId,
      );

  @override
  Future<Either<Failures, List<EmployeeLedgerEntryModel>>> getEmployeeLedgerEntries({
    required String employeeId,
    String? branchId,
  }) =>
      remoteRepo.getEmployeeLedgerEntries(
        employeeId: employeeId,
        branchId: branchId,
      );

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>> addEmployeeLedgerEntry(
    EmployeeLedgerEntryModel entry,
  ) =>
      remoteRepo.addEmployeeLedgerEntry(entry);

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>> reverseEmployeeLedgerEntry({
    required String entryId,
    required String reason,
    required String performedByUserId,
  }) =>
      remoteRepo.reverseEmployeeLedgerEntry(
        entryId: entryId,
        reason: reason,
        performedByUserId: performedByUserId,
      );

  @override
  Future<Either<Failures, List<StaffPayrollProfileModel>>> getStaffPayrollProfiles({
    String? primaryBranchId,
  }) =>
      remoteRepo.getStaffPayrollProfiles(primaryBranchId: primaryBranchId);

  @override
  Future<Either<Failures, StaffPayrollProfileModel>> saveStaffPayrollProfile(
    StaffPayrollProfileModel profile,
  ) =>
      remoteRepo.saveStaffPayrollProfile(profile);

  @override
  Future<Either<Failures, List<StaffPayrollPeriodModel>>> getStaffPayrollPeriods({
    String? primaryBranchId,
    int? year,
  }) =>
      remoteRepo.getStaffPayrollPeriods(
        primaryBranchId: primaryBranchId,
        year: year,
      );

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> getStaffPayrollPeriodById(
    String periodId,
  ) =>
      remoteRepo.getStaffPayrollPeriodById(periodId);

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> saveStaffPayrollPeriod(
    StaffPayrollPeriodModel period,
  ) =>
      remoteRepo.saveStaffPayrollPeriod(period);

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> confirmStaffPayrollPeriod({
    required String periodId,
    required String confirmedByUserId,
  }) =>
      remoteRepo.confirmStaffPayrollPeriod(
        periodId: periodId,
        confirmedByUserId: confirmedByUserId,
      );

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> payoutStaffPayrollPeriod({
    required String periodId,
    required String paidByUserId,
  }) =>
      remoteRepo.payoutStaffPayrollPeriod(
        periodId: periodId,
        paidByUserId: paidByUserId,
      );

  Future<void> _persistSettlementAtomic(DoctorSettlementModel settlement) async {
    final accountId = getCurrentAccountId();
    final branchId = settlement.branchId ?? getCurrentBranchId();
    final now = DateTime.now();
    final isProvisional = !dataModeService.isOnline;
    final settlementId = settlement.id ?? 'SETT-${now.millisecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: settlementId,
          entityType: 'hr_doctor_settlement',
          accountId: accountId,
          branchId: branchId,
          payload: settlement.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: settlement.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: 'op_settlement_${settlementId}_${now.microsecondsSinceEpoch}',
          entityType: 'hr_doctor_settlement',
          localId: settlementId,
          operation: OutboxOperationType.update,
          payload: settlement.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });
  }
}

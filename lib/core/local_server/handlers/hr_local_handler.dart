import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/employee_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/payroll_status_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_profile_model.dart';

class HrLocalHandler {
  HrLocalHandler._();

  static int _ruleCounter = 100;
  static int _settlementCounter = 100;
  static int _ledgerCounter = 100;
  static int _payrollProfileCounter = 100;
  static int _payrollPeriodCounter = 100;

  static void register(LocalServerRouter router) {
    // ─── Doctor Compensation Rules ─────────────────────────────────────────
    router.register('GET', 'hr/compensation-rules', (req) async {
      final doctorId = req.queryParameters['doctorId']?.toString();
      final branchId = req.queryParameters['branchId']?.toString();
      var list = router.db
          .collection('hrCompensationRules')
          .where((r) => r['isActive'] == true)
          .toList();
      if (doctorId != null && doctorId.isNotEmpty) {
        list = list.where((r) => r['doctorId'] == doctorId).toList();
      }
      if (branchId != null && branchId.isNotEmpty) {
        list = list.where((r) => r['branchId'] == branchId).toList();
      }
      return LocalServerRouter.ok(list);
    });

    router.register('GET', 'hr/compensation-rules/{id}', (req) async {
      final id = req.pathParams['id']!;
      final idx = router.db
          .collection('hrCompensationRules')
          .indexWhere((r) => r['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'rule_not_found');
      }
      return LocalServerRouter.ok(
          router.db.collection('hrCompensationRules')[idx]);
    });

    router.register('GET', 'doctors/{id}/compensation-rule/active',
        (req) async {
      final doctorId = req.pathParams['id']!;
      final branchId = req.queryParameters['branchId']?.toString() ?? '';
      final dateStr = req.queryParameters['date']?.toString();
      final targetDate =
          dateStr != null ? DateTime.tryParse(dateStr) ?? CairoTimeHelper.now() : CairoTimeHelper.now();

      final matching = router.db
          .collection('hrCompensationRules')
          .map((e) => DoctorCompensationRuleModel.fromJson(e))
          .where((r) {
        if (r.doctorId != doctorId) return false;
        if (r.branchId != branchId) return false;
        if (r.isActive != true) return false;
        if (r.effectiveFrom != null && r.effectiveFrom!.isAfter(targetDate)) {
          return false;
        }
        return true;
      }).toList();

      if (matching.isEmpty) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'no_active_compensation_rule',
        );
      }

      matching.sort((a, b) => (b.effectiveFrom ?? DateTime(1970))
          .compareTo(a.effectiveFrom ?? DateTime(1970)));
      return LocalServerRouter.ok(matching.first.toJson());
    });

    router.register('PUT', 'hr/compensation-rules/{id}', (req) async {
      final rule = DoctorCompensationRuleModel.fromJson(req.body);
      if (rule.doctorId == null || rule.doctorId!.isEmpty) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'doctor_required');
      }
      if (rule.branchId == null || rule.branchId!.isEmpty) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'branch_required');
      }

      final rules = router.db.collection('hrCompensationRules');
      final now = CairoTimeHelper.now();
      final paramId = req.pathParams['id']!;
      final effectiveId = (paramId == 'new' || paramId.isEmpty)
          ? (rule.id != null && rule.id!.isNotEmpty ? rule.id! : null)
          : paramId;

      if (effectiveId != null && effectiveId.isNotEmpty) {
        final idx = rules.indexWhere((r) => r['id'] == effectiveId);
        if (idx != -1) {
          final updated = rule.copyWith(
            id: effectiveId,
            isActive: rule.isActive ?? true,
          );
          final json = updated.toJson();
          rules[idx] = json;
          router.db.persist();
          return LocalServerRouter.ok(json);
        }
        final created = rule.copyWith(
          id: effectiveId,
          createdAt: rule.createdAt ?? now,
          isActive: rule.isActive ?? true,
        );
        final json = created.toJson();
        rules.add(json);
        router.db.persist();
        return LocalServerRouter.ok(json);
      }

      final newId = 'RULE-${(++_ruleCounter)}';
      final created = rule.copyWith(
        id: newId,
        createdAt: now,
        isActive: rule.isActive ?? true,
      );
      final json = created.toJson();
      rules.add(json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    // ─── Doctor Settlements ────────────────────────────────────────────────
    // Register static /overlap BEFORE parameterized /{id}
    router.register('GET', 'hr/settlements/overlap', (req) async {
      final doctorId = req.queryParameters['doctorId']?.toString() ?? '';
      final branchId = req.queryParameters['branchId']?.toString() ?? '';
      final startStr = req.queryParameters['periodStart']?.toString() ?? '';
      final endStr = req.queryParameters['periodEnd']?.toString() ?? '';
      final excludeId = req.queryParameters['excludeSettlementId']?.toString();
      final periodStart = DateTime.tryParse(startStr);
      final periodEnd = DateTime.tryParse(endStr);
      if (periodStart == null || periodEnd == null) {
        return LocalServerRouter.ok({'overlaps': false});
      }

      for (final raw in router.db.collection('hrSettlements')) {
        final s = DoctorSettlementModel.fromJson(raw);
        if (s.id == excludeId) continue;
        if (s.doctorId != doctorId || s.branchId != branchId) continue;
        if (s.status == SettlementStatusEnum.draft) continue;
        if (s.periodStart == null || s.periodEnd == null) continue;
        final overlaps = !periodStart.isAfter(s.periodEnd!) &&
            !periodEnd.isBefore(s.periodStart!);
        if (overlaps) {
          return LocalServerRouter.ok({'overlaps': true});
        }
      }
      return LocalServerRouter.ok({'overlaps': false});
    });

    router.register('GET', 'hr/settlements', (req) async {
      final doctorId = req.queryParameters['doctorId']?.toString();
      final branchId = req.queryParameters['branchId']?.toString();
      final statusStr = req.queryParameters['status']?.toString();

      var list = router.db
          .collection('hrSettlements')
          .map((e) => DoctorSettlementModel.fromJson(e))
          .toList();
      if (doctorId != null && doctorId.isNotEmpty) {
        list = list.where((s) => s.doctorId == doctorId).toList();
      }
      if (branchId != null && branchId.isNotEmpty) {
        list = list.where((s) => s.branchId == branchId).toList();
      }
      if (statusStr != null && statusStr.isNotEmpty) {
        final status = SettlementStatusEnum.fromJson(statusStr);
        list = list.where((s) => s.status == status).toList();
      }
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return LocalServerRouter.ok(list.map((e) => e.toJson()).toList());
    });

    router.register('GET', 'hr/settlements/{id}', (req) async {
      final id = req.pathParams['id']!;
      final idx = router.db
          .collection('hrSettlements')
          .indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'settlement_not_found');
      }
      return LocalServerRouter.ok(router.db.collection('hrSettlements')[idx]);
    });

    router.register('PUT', 'hr/settlements/{id}', (req) async {
      final settlement = DoctorSettlementModel.fromJson(req.body);
      final settlements = router.db.collection('hrSettlements');
      final now = CairoTimeHelper.now();
      final paramId = req.pathParams['id']!;
      final effectiveId = (paramId == 'new' || paramId.isEmpty)
          ? (settlement.id != null && settlement.id!.isNotEmpty
              ? settlement.id!
              : null)
          : paramId;

      if (effectiveId != null && effectiveId.isNotEmpty) {
        final idx = settlements.indexWhere((s) => s['id'] == effectiveId);
        if (idx != -1) {
          final json = settlement.copyWith(id: effectiveId).toJson();
          settlements[idx] = json;
          router.db.persist();
          return LocalServerRouter.ok(json);
        }
      }

      final newId = effectiveId ?? 'SET-${(++_settlementCounter)}';
      final ym =
          '${settlement.periodStart?.year ?? now.year}${(settlement.periodStart?.month ?? now.month).toString().padLeft(2, '0')}';
      final settlementNumber = settlement.settlementNumber ??
          'SET-DOC-$ym-${_settlementCounter.toString().padLeft(3, '0')}';

      final created = settlement.copyWith(
        id: newId,
        settlementNumber: settlementNumber,
        status: settlement.status ?? SettlementStatusEnum.draft,
        createdAt: settlement.createdAt ?? now,
      );
      final json = created.toJson();
      settlements.insert(0, json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'hr/settlements/{id}/confirm', (req) async {
      final id = req.pathParams['id']!;
      final settlements = router.db.collection('hrSettlements');
      final idx = settlements.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'settlement_not_found');
      }
      final existing = DoctorSettlementModel.fromJson(settlements[idx]);
      if (existing.status != SettlementStatusEnum.draft) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'settlement_already_confirmed');
      }
      final confirmed = existing.copyWith(
        status: SettlementStatusEnum.confirmed,
        confirmedByUserId: req.body['confirmedByUserId']?.toString(),
        confirmedAt: CairoTimeHelper.now(),
        isOwnerSelfConfirmed: req.body['isOwnerSelfConfirmed'] == true,
      );
      final json = confirmed.toJson();
      settlements[idx] = json;
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'hr/settlements/{id}/payout', (req) async {
      final id = req.pathParams['id']!;
      final settlements = router.db.collection('hrSettlements');
      final idx = settlements.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'settlement_not_found');
      }
      final existing = DoctorSettlementModel.fromJson(settlements[idx]);
      if (existing.status != SettlementStatusEnum.confirmed) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'settlement_not_confirmed');
      }

      final now = CairoTimeHelper.now();
      final method = PaymentMethod.fromValue(
          req.body['method']?.toString() ?? 'cash');
      final paid = existing.copyWith(
        status: SettlementStatusEnum.paid,
        paidAt: now,
        paymentMethod: method,
        paymentReferenceNumber: req.body['refNumber']?.toString(),
      );
      final paidJson = paid.toJson();
      settlements[idx] = paidJson;

      router.db.collection('hrLedgerEntries').add(
            EmployeeLedgerEntryModel(
              id: 'LED-${(++_ledgerCounter)}',
              employeeId: existing.doctorId,
              employeeType: EmployeeTypeEnum.doctor,
              branchId: existing.branchId,
              entryType: LedgerEntryTypeEnum.payout,
              amountPiastres: existing.netPayablePiastres,
              reason: 'صرف تسوية أتعاب ${existing.settlementNumber}',
              date: now,
              performedByUserId: req.body['paidByUserId']?.toString(),
              createdAt: now,
            ).toJson(),
          );

      router.db.persist();
      return LocalServerRouter.ok(paidJson);
    });

    // ─── Employee Ledger & Advances ────────────────────────────────────────
    router.register('GET', 'hr/ledger', (req) async {
      final employeeId = req.queryParameters['employeeId']?.toString() ?? '';
      final branchId = req.queryParameters['branchId']?.toString();
      var list = router.db
          .collection('hrLedgerEntries')
          .map((e) => EmployeeLedgerEntryModel.fromJson(e))
          .where((e) => e.employeeId == employeeId)
          .toList();
      if (branchId != null && branchId.isNotEmpty) {
        list = list.where((e) => e.branchId == branchId).toList();
      }
      list.sort((a, b) =>
          (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
      return LocalServerRouter.ok(list.map((e) => e.toJson()).toList());
    });

    router.register('POST', 'hr/ledger', (req) async {
      final entry = EmployeeLedgerEntryModel.fromJson(req.body);
      if (entry.amountPiastres == null || entry.amountPiastres! <= 0) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'amount_must_be_positive');
      }

      final ledger = router.db.collection('hrLedgerEntries');
      if (entry.clientRequestId != null && entry.clientRequestId!.isNotEmpty) {
        final idx = ledger
            .indexWhere((e) => e['clientRequestId'] == entry.clientRequestId);
        if (idx != -1) {
          return LocalServerRouter.ok(ledger[idx]);
        }
      }

      final newId = (entry.id != null && entry.id!.isNotEmpty)
          ? entry.id!
          : 'LED-${(++_ledgerCounter)}';
      final created = entry.copyWith(
        id: newId,
        createdAt: entry.createdAt ?? CairoTimeHelper.now(),
      );
      final json = created.toJson();
      ledger.add(json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'hr/ledger/{id}/reverse', (req) async {
      final entryId = req.pathParams['id']!;
      final reason = req.body['reason']?.toString() ?? '';
      final performedByUserId =
          req.body['performedByUserId']?.toString() ?? '';

      final ledger = router.db.collection('hrLedgerEntries');
      final targetIdx = ledger.indexWhere((e) => e['id'] == entryId);
      if (targetIdx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'ledger_entry_not_found');
      }
      if (reason.trim().isEmpty) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'reversal_reason_required');
      }
      final target = EmployeeLedgerEntryModel.fromJson(ledger[targetIdx]);
      if (target.reversesEntryId != null) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR',
            'cannot_reverse_reversal_entry');
      }
      if (target.entryType == LedgerEntryTypeEnum.payout) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'cannot_reverse_payout_entry');
      }
      final alreadyReversed =
          ledger.any((e) => e['reversesEntryId'] == entryId);
      if (alreadyReversed) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'ledger_entry_already_reversed');
      }

      final now = CairoTimeHelper.now();
      final reverseEntry = EmployeeLedgerEntryModel(
        id: 'LED-${(++_ledgerCounter)}',
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
      final json = reverseEntry.toJson();
      ledger.add(json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    // ─── Staff Payroll ─────────────────────────────────────────────────────
    router.register('GET', 'hr/payroll-profiles', (req) async {
      final primaryBranchId =
          req.queryParameters['primaryBranchId']?.toString();
      var list = router.db
          .collection('hrPayrollProfiles')
          .where((p) => p['isActive'] == true)
          .toList();
      if (primaryBranchId != null && primaryBranchId.isNotEmpty) {
        list = list
            .where((p) => p['primaryBranchId'] == primaryBranchId)
            .toList();
      }
      return LocalServerRouter.ok(list);
    });

    router.register('PUT', 'hr/payroll-profiles/{id}', (req) async {
      final profile = StaffPayrollProfileModel.fromJson(req.body);
      final profiles = router.db.collection('hrPayrollProfiles');
      final now = CairoTimeHelper.now();
      final paramId = req.pathParams['id']!;
      final effectiveId = (paramId == 'new' || paramId.isEmpty)
          ? (profile.id != null && profile.id!.isNotEmpty ? profile.id! : null)
          : paramId;

      if (effectiveId != null && effectiveId.isNotEmpty) {
        final idx = profiles.indexWhere((p) => p['id'] == effectiveId);
        if (idx != -1) {
          final updated = profile.copyWith(
            id: effectiveId,
            isActive: profile.isActive ?? true,
            updatedAt: now,
          );
          final json = updated.toJson();
          profiles[idx] = json;
          router.db.persist();
          return LocalServerRouter.ok(json);
        }
        final created = profile.copyWith(
          id: effectiveId,
          isActive: profile.isActive ?? true,
          updatedAt: now,
        );
        final json = created.toJson();
        profiles.add(json);
        router.db.persist();
        return LocalServerRouter.ok(json);
      }

      final newId = 'PRF-${(++_payrollProfileCounter)}';
      final created = profile.copyWith(
        id: newId,
        isActive: profile.isActive ?? true,
        updatedAt: now,
      );
      final json = created.toJson();
      profiles.add(json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('GET', 'hr/payroll-periods', (req) async {
      final primaryBranchId =
          req.queryParameters['primaryBranchId']?.toString();
      final yearStr = req.queryParameters['year']?.toString();
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      var list = router.db
          .collection('hrPayrollPeriods')
          .map((e) => StaffPayrollPeriodModel.fromJson(e))
          .toList();
      if (primaryBranchId != null && primaryBranchId.isNotEmpty) {
        list = list.where((p) => p.primaryBranchId == primaryBranchId).toList();
      }
      if (year != null) {
        list = list.where((p) => p.year == year).toList();
      }
      list.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return LocalServerRouter.ok(list.map((e) => e.toJson()).toList());
    });

    router.register('GET', 'hr/payroll-periods/{id}', (req) async {
      final id = req.pathParams['id']!;
      final idx = router.db
          .collection('hrPayrollPeriods')
          .indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'payroll_period_not_found');
      }
      return LocalServerRouter.ok(router.db.collection('hrPayrollPeriods')[idx]);
    });

    router.register('PUT', 'hr/payroll-periods/{id}', (req) async {
      final period = StaffPayrollPeriodModel.fromJson(req.body);
      final periods = router.db.collection('hrPayrollPeriods');
      final now = CairoTimeHelper.now();
      final paramId = req.pathParams['id']!;
      final effectiveId = (paramId == 'new' || paramId.isEmpty)
          ? (period.id != null && period.id!.isNotEmpty ? period.id! : null)
          : paramId;

      if (effectiveId != null && effectiveId.isNotEmpty) {
        final idx = periods.indexWhere((p) => p['id'] == effectiveId);
        if (idx != -1) {
          final json = period.copyWith(id: effectiveId).toJson();
          periods[idx] = json;
          router.db.persist();
          return LocalServerRouter.ok(json);
        }
        final json = period.copyWith(id: effectiveId).toJson();
        periods.insert(0, json);
        router.db.persist();
        return LocalServerRouter.ok(json);
      }

      final newId = 'PAY-${(++_payrollPeriodCounter)}';
      final ym =
          '${period.year ?? now.year}${(period.month ?? now.month).toString().padLeft(2, '0')}';
      final payrollNumber =
          'PAY-$ym-${_payrollPeriodCounter.toString().padLeft(3, '0')}';

      final created = period.copyWith(
        id: newId,
        payrollNumber: payrollNumber,
        status: period.status ?? PayrollStatusEnum.draft,
        createdAt: now,
      );
      final json = created.toJson();
      periods.insert(0, json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'hr/payroll-periods/{id}/confirm', (req) async {
      final id = req.pathParams['id']!;
      final periods = router.db.collection('hrPayrollPeriods');
      final idx = periods.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'payroll_period_not_found');
      }
      final existing = StaffPayrollPeriodModel.fromJson(periods[idx]);
      if (existing.status != PayrollStatusEnum.draft) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR',
            'payroll_period_already_confirmed');
      }
      final confirmed = existing.copyWith(
        status: PayrollStatusEnum.confirmed,
        confirmedByUserId: req.body['confirmedByUserId']?.toString(),
        confirmedAt: CairoTimeHelper.now(),
      );
      final json = confirmed.toJson();
      periods[idx] = json;
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'hr/payroll-periods/{id}/payout', (req) async {
      final id = req.pathParams['id']!;
      final periods = router.db.collection('hrPayrollPeriods');
      final idx = periods.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'payroll_period_not_found');
      }
      final existing = StaffPayrollPeriodModel.fromJson(periods[idx]);
      if (existing.status != PayrollStatusEnum.confirmed) {
        LocalServerRouter.throwHttpError(
            req.path, 422, 'VALIDATION_ERROR', 'payroll_period_not_confirmed');
      }

      final now = CairoTimeHelper.now();
      final paidByUserId = req.body['paidByUserId']?.toString() ?? '';
      final paid = existing.copyWith(
        status: PayrollStatusEnum.paid,
        paidAt: now,
      );
      final paidJson = paid.toJson();
      periods[idx] = paidJson;

      if (existing.items != null) {
        final ledger = router.db.collection('hrLedgerEntries');
        for (final item in existing.items!) {
          if (item.staffUserId != null && (item.netSalaryPiastres ?? 0) > 0) {
            ledger.add(
              EmployeeLedgerEntryModel(
                id: 'LED-${(++_ledgerCounter)}',
                employeeId: item.staffUserId,
                employeeType: EmployeeTypeEnum.staff,
                branchId: existing.primaryBranchId,
                entryType: LedgerEntryTypeEnum.payout,
                amountPiastres: item.netSalaryPiastres,
                reason:
                    'صرف مسير رواتب شهر ${existing.month}/${existing.year} - ${existing.payrollNumber}',
                date: now,
                performedByUserId: paidByUserId,
                createdAt: now,
              ).toJson(),
            );
          }
        }
      }

      router.db.persist();
      return LocalServerRouter.ok(paidJson);
    });
  }
}

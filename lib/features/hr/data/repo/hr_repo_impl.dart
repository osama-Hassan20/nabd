import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/local_server/local_server_db.dart';
import '../../domain/repo/hr_repo.dart';
import '../models/doctor_compensation_rule_model.dart';
import '../models/doctor_settlement_model.dart';
import '../models/employee_ledger_entry_model.dart';
import '../models/enums/settlement_status_enum.dart';
import '../models/staff_payroll_period_model.dart';
import '../models/staff_payroll_profile_model.dart';

class HrRepoImpl implements HrRepo {
  final ApiConsumer _api;

  HrRepoImpl({bool seedInitialData = true, ApiConsumer? apiConsumer})
      : _api = apiConsumer ??
            (seedInitialData
                ? (getIt.isRegistered<ApiConsumer>()
                    ? getIt<ApiConsumer>()
                    : LocalServerApiConsumer())
                : LocalServerApiConsumer(db: LocalServerDb()));

  // ─── Doctor Compensation Rules ─────────────────────────────────────────────

  @override
  Future<Either<Failures, List<DoctorCompensationRuleModel>>>
      getCompensationRules({
    String? doctorId,
    String? branchId,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/compensation-rules',
        queryParameters: {
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => DoctorCompensationRuleModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>>
      getCompensationRuleById(String ruleId) async {
    try {
      final res = await _api.get(path: 'hr/compensation-rules/$ruleId');
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorCompensationRuleModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>>
      getActiveRuleForDoctor({
    required String doctorId,
    required String branchId,
    DateTime? date,
  }) async {
    try {
      final res = await _api.get(
        path: 'doctors/$doctorId/compensation-rule/active',
        queryParameters: {
          'branchId': branchId,
          if (date != null) 'date': date.toIso8601String(),
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorCompensationRuleModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorCompensationRuleModel>> saveCompensationRule(
    DoctorCompensationRuleModel rule,
  ) async {
    try {
      final id = (rule.id != null && rule.id!.isNotEmpty) ? rule.id! : 'new';
      final res = await _api.put(
        path: 'hr/compensation-rules/$id',
        body: rule.toJson(),
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorCompensationRuleModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  // ─── Doctor Settlements ────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<DoctorSettlementModel>>> getDoctorSettlements({
    String? doctorId,
    String? branchId,
    SettlementStatusEnum? status,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/settlements',
        queryParameters: {
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
          if (status != null) 'status': status.name,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => DoctorSettlementModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> getDoctorSettlementById(
    String settlementId,
  ) async {
    try {
      final res = await _api.get(path: 'hr/settlements/$settlementId');
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorSettlementModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<bool> isPeriodOverlapping({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? excludeSettlementId,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/settlements/overlap',
        queryParameters: {
          'doctorId': doctorId,
          'branchId': branchId,
          'periodStart': periodStart.toIso8601String(),
          'periodEnd': periodEnd.toIso8601String(),
          if (excludeSettlementId != null)
            'excludeSettlementId': excludeSettlementId,
        },
      );
      final data = res is Map ? res['data'] : res;
      if (data is Map) return data['overlaps'] == true;
      return data == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> saveDoctorSettlement(
    DoctorSettlementModel settlement,
  ) async {
    try {
      final id = (settlement.id != null && settlement.id!.isNotEmpty)
          ? settlement.id!
          : 'new';
      final res = await _api.put(
        path: 'hr/settlements/$id',
        body: settlement.toJson(),
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorSettlementModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> confirmDoctorSettlement({
    required String settlementId,
    required String confirmedByUserId,
    bool isOwnerSelfConfirmed = false,
  }) async {
    try {
      final res = await _api.post(
        path: 'hr/settlements/$settlementId/confirm',
        body: {
          'confirmedByUserId': confirmedByUserId,
          'isOwnerSelfConfirmed': isOwnerSelfConfirmed,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorSettlementModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorSettlementModel>> payoutDoctorSettlement({
    required String settlementId,
    required String paidByUserId,
    required PaymentMethod method,
    String? refNumber,
  }) async {
    try {
      final res = await _api.post(
        path: 'hr/settlements/$settlementId/payout',
        body: {
          'paidByUserId': paidByUserId,
          'method': method.name,
          if (refNumber != null) 'refNumber': refNumber,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        DoctorSettlementModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  // ─── Employee Ledger & Advances ────────────────────────────────────────────

  @override
  Future<Either<Failures, List<EmployeeLedgerEntryModel>>>
      getEmployeeLedgerEntries({
    required String employeeId,
    String? branchId,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/ledger',
        queryParameters: {
          'employeeId': employeeId,
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => EmployeeLedgerEntryModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>> addEmployeeLedgerEntry(
    EmployeeLedgerEntryModel entry,
  ) async {
    try {
      final res = await _api.post(
        path: 'hr/ledger',
        body: entry.toJson(),
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        EmployeeLedgerEntryModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, EmployeeLedgerEntryModel>>
      reverseEmployeeLedgerEntry({
    required String entryId,
    required String reason,
    required String performedByUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'hr/ledger/$entryId/reverse',
        body: {
          'reason': reason,
          'performedByUserId': performedByUserId,
        },
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        EmployeeLedgerEntryModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  // ─── Staff Payroll ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<StaffPayrollProfileModel>>>
      getStaffPayrollProfiles({
    String? primaryBranchId,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/payroll-profiles',
        queryParameters: {
          if (primaryBranchId != null && primaryBranchId.isNotEmpty)
            'primaryBranchId': primaryBranchId,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => StaffPayrollProfileModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, StaffPayrollProfileModel>> saveStaffPayrollProfile(
    StaffPayrollProfileModel profile,
  ) async {
    try {
      final id =
          (profile.id != null && profile.id!.isNotEmpty) ? profile.id! : 'new';
      final res = await _api.put(
        path: 'hr/payroll-profiles/$id',
        body: profile.toJson(),
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        StaffPayrollProfileModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<StaffPayrollPeriodModel>>>
      getStaffPayrollPeriods({
    String? primaryBranchId,
    int? year,
  }) async {
    try {
      final res = await _api.get(
        path: 'hr/payroll-periods',
        queryParameters: {
          if (primaryBranchId != null && primaryBranchId.isNotEmpty)
            'primaryBranchId': primaryBranchId,
          if (year != null) 'year': year,
        },
      );
      final list = (res is Map ? res['data'] : res) as List? ?? const [];
      return Right(
        list
            .map((e) => StaffPayrollPeriodModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> getStaffPayrollPeriodById(
    String periodId,
  ) async {
    try {
      final res = await _api.get(path: 'hr/payroll-periods/$periodId');
      final data = res is Map ? res['data'] : res;
      return Right(
        StaffPayrollPeriodModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> saveStaffPayrollPeriod(
    StaffPayrollPeriodModel period,
  ) async {
    try {
      final id =
          (period.id != null && period.id!.isNotEmpty) ? period.id! : 'new';
      final res = await _api.put(
        path: 'hr/payroll-periods/$id',
        body: period.toJson(),
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        StaffPayrollPeriodModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> confirmStaffPayrollPeriod({
    required String periodId,
    required String confirmedByUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'hr/payroll-periods/$periodId/confirm',
        body: {'confirmedByUserId': confirmedByUserId},
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        StaffPayrollPeriodModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, StaffPayrollPeriodModel>> payoutStaffPayrollPeriod({
    required String periodId,
    required String paidByUserId,
  }) async {
    try {
      final res = await _api.post(
        path: 'hr/payroll-periods/$periodId/payout',
        body: {'paidByUserId': paidByUserId},
      );
      final data = res is Map ? res['data'] : res;
      return Right(
        StaffPayrollPeriodModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

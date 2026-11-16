import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../contracts/doctor_settlement_visits_lookup.dart';
import '../helpers/doctor_settlement_calculator.dart';
import '../repo/hr_repo.dart';

class CalculateDoctorSettlementDraftUseCase {
  final HrRepo hrRepo;
  final DoctorSettlementVisitsLookup? visitsLookup;
  final PermissionEvaluator? permissionEvaluator;
  final CurrentUserProvider? currentUserProvider;
  final AuditLogger? auditLogger;

  const CalculateDoctorSettlementDraftUseCase({
    required this.hrRepo,
    this.visitsLookup,
    this.permissionEvaluator,
    this.currentUserProvider,
    this.auditLogger,
  });

  Future<Either<Failures, DoctorSettlementModel>> call({
    required String doctorId,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    String? doctorName,
    List<SettlementVisitCandidate>? explicitCandidates,
  }) async {
    // 1. Validation of parameters
    if (doctorId.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_doctor_id_required'));
    }
    if (branchId.trim().isEmpty) {
      return const Left(ValidationFailure(errMessage: 'hr_branch_id_required'));
    }
    if (!periodStart.isBefore(periodEnd)) {
      return const Left(ValidationFailure(errMessage: 'hr_invalid_settlement_period'));
    }

    // 2. Permission check: calculateDoctorSettlement
    final user = currentUserProvider?.currentUser;
    if (permissionEvaluator != null) {
      final canCalculate = permissionEvaluator!.can(
        StaffPermissionEnum.calculateDoctorSettlement,
        branchId: branchId,
      );
      if (!canCalculate) {
        return const Left(ValidationFailure(errMessage: 'permission_denied'));
      }
    }

    // 3. Overlapping period check
    final isOverlapping = await hrRepo.isPeriodOverlapping(
      doctorId: doctorId,
      branchId: branchId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    if (isOverlapping) {
      return const Left(ValidationFailure(errMessage: 'hr_settlement_period_overlapping'));
    }

    // 4. Retrieve active compensation rule
    final ruleRes = await hrRepo.getActiveRuleForDoctor(
      doctorId: doctorId,
      branchId: branchId,
      date: periodEnd,
    );
    if (ruleRes.isLeft()) {
      return Left(ruleRes.fold((f) => f, (r) => const ValidationFailure(errMessage: 'no_active_compensation_rule')));
    }
    final activeRule = ruleRes.getOrElse(() => throw StateError('unreachable'));

    // 5. Retrieve past settlements to find consumed events and advances
    final consumedEvents = <String>{};
    final consumedAdvances = <String>{};
    final pastSettlementsRes = await hrRepo.getDoctorSettlements(
      doctorId: doctorId,
      branchId: branchId,
    );
    if (pastSettlementsRes.isRight()) {
      for (final s in pastSettlementsRes.getOrElse(() => [])) {
        if (s.status == SettlementStatusEnum.confirmed || s.status == SettlementStatusEnum.paid) {
          if (s.consumedEventIds != null) {
            consumedEvents.addAll(s.consumedEventIds!);
          }
          if (s.consumedAdvanceEntryIds != null) {
            consumedAdvances.addAll(s.consumedAdvanceEntryIds!);
          }
        }
      }
    }

    // 6. Retrieve candidate visits
    List<SettlementVisitCandidate> candidates = explicitCandidates ?? [];
    if (candidates.isEmpty && visitsLookup != null) {
      candidates = await visitsLookup!.getSettlementVisitCandidates(
        doctorId: doctorId,
        branchId: branchId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        excludedEventIds: consumedEvents.toList(),
      );
    }

    // 7. Retrieve ledger entries
    final ledgerRes = await hrRepo.getEmployeeLedgerEntries(
      employeeId: doctorId,
      branchId: branchId,
    );
    final ledgerEntries = ledgerRes.getOrElse(() => []);

    // 8. Calculate draft settlement
    final draft = DoctorSettlementCalculator.calculateSettlement(
      doctorId: doctorId,
      doctorName: doctorName ?? 'طبيب مستحق',
      branchId: branchId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      rule: activeRule,
      candidates: candidates,
      ledgerEntries: ledgerEntries,
      alreadyConsumedEventIds: consumedEvents.toList(),
      alreadyConsumedAdvanceEntryIds: consumedAdvances.toList(),
    );

    // 9. Save draft settlement in repository
    final saveRes = await hrRepo.saveDoctorSettlement(draft);

    // 10. Audit logging on success ONLY
    saveRes.fold(
      (failure) => null,
      (saved) {
        auditLogger?.log(
          eventType: 'doctor_settlement_drafted',
          performedByUserId: user?.id,
          performedByUserName: user?.fullName ?? 'Unknown',
          branchId: saved.branchId,
          details:
              'settlementId: ${saved.id}, doctorId: ${saved.doctorId}, '
              'branchId: ${saved.branchId}, periodStart: ${saved.periodStart?.toIso8601String()}, '
              'periodEnd: ${saved.periodEnd?.toIso8601String()}, visitsCount: ${saved.totalVisitsCount}, '
              'netRevenuePiastres: ${saved.totalNetRevenuePiastres}, commissionPiastres: ${saved.totalDoctorCommissionPiastres}',
        );
      },
    );

    return saveRes;
  }
}


import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import '../../data/models/doctor_compensation_rule_model.dart';
import '../../data/models/doctor_settlement_item_model.dart';
import '../../data/models/doctor_settlement_model.dart';
import '../../data/models/employee_ledger_entry_model.dart';
import '../../data/models/enums/compensation_type_enum.dart';
import '../../data/models/enums/ledger_entry_type_enum.dart';
import '../../data/models/enums/settlement_status_enum.dart';
import '../contracts/doctor_settlement_visits_lookup.dart';

class DoctorSettlementCalculator {
  /// Recognition date is max(transactionDate, visit.finalizedAt)
  static DateTime calculateRecognitionDate(DateTime transactionDate, DateTime visitFinalizedAt) {
    return transactionDate.isAfter(visitFinalizedAt) ? transactionDate : visitFinalizedAt;
  }

  /// Round half-up to nearest integer piastre
  static int roundHalfUp(num value) {
    if (value >= 0) {
      return (value + 0.5).floor();
    } else {
      return (value - 0.5).ceil();
    }
  }

  /// Calculates ledger balance for an employee.
  /// Advances balance: sum of active (unreversed) advances.
  static int calculateOutstandingAdvancesPiastres(List<EmployeeLedgerEntryModel> entries) {
    final reversedIds = <String>{};
    for (final e in entries) {
      if (e.reversesEntryId != null) {
        reversedIds.add(e.reversesEntryId!);
      }
    }

    int total = 0;
    for (final e in entries) {
      if (e.entryType == LedgerEntryTypeEnum.advance) {
        if (e.reversesEntryId == null && !reversedIds.contains(e.id)) {
          total += (e.amountPiastres ?? 0);
        }
      }
    }
    return total;
  }

  /// Calculates a draft doctor settlement according to the cash-collected basis.
  static DoctorSettlementModel calculateSettlement({
    required String doctorId,
    required String doctorName,
    required String branchId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DoctorCompensationRuleModel rule,
    required List<SettlementVisitCandidate> candidates,
    required List<EmployeeLedgerEntryModel> ledgerEntries,
    List<String> alreadyConsumedEventIds = const [],
    List<String> alreadyConsumedAdvanceEntryIds = const [],
    DateTime? now,
  }) {
    final items = <DoctorSettlementItemModel>[];
    final consumedEventIds = <String>[];

    int totalNetRevenuePiastres = 0;
    int totalDoctorCommissionPiastres = 0;
    int totalClinicSharePiastres = 0;

    final type = rule.compensationType ?? CompensationTypeEnum.percentage;
    final commissionPercent = rule.commissionPercentage ?? 0;
    final fixedFeePerVisit = rule.fixedAmountPerVisitPiastres ?? 0;
    final payForFreeVisits = rule.payForFreeVisits ?? false;

    for (final candidate in candidates) {
      // Free visit handling
      if (candidate.isFreeConsultation || candidate.netAmountPiastres == 0) {
        if (!payForFreeVisits) {
          continue;
        }
      }

      // Filter events recognized within period and not already consumed
      final candidateEvents = <SettlementPaymentEvent>[];
      int recognizedCollectedPiastres = 0;

      for (final ev in candidate.events) {
        if (alreadyConsumedEventIds.contains(ev.eventId)) {
          continue;
        }

        final recDate = calculateRecognitionDate(ev.date, candidate.finalizedAt);
        final inPeriod = (recDate.isAfter(periodStart) || recDate.isAtSameMomentAs(periodStart)) &&
            (recDate.isBefore(periodEnd) || recDate.isAtSameMomentAs(periodEnd));

        if (inPeriod) {
          candidateEvents.add(ev);
          if (ev.type == 'refund') {
            recognizedCollectedPiastres -= ev.amountPiastres;
          } else {
            recognizedCollectedPiastres += ev.amountPiastres;
          }
        }
      }

      if (candidateEvents.isEmpty && !payForFreeVisits) {
        continue;
      }

      // Calculate doctor earned for this visit based on rule type
      int doctorEarned = 0;

      if (candidate.isFreeConsultation || candidate.netAmountPiastres == 0) {
        // Free visit with payForFreeVisits = true
        if (type == CompensationTypeEnum.fixedPerVisit ||
            type == CompensationTypeEnum.salaryPlusFixed) {
          doctorEarned = fixedFeePerVisit;
        }
      } else {
        if (type == CompensationTypeEnum.percentage ||
            type == CompensationTypeEnum.salaryPlusPercentage) {
          // Commission percentage with round half-up per event
          for (final ev in candidateEvents) {
            final factor = ev.type == 'refund' ? -1 : 1;
            final eventDoctorEarned = roundHalfUp(ev.amountPiastres * (commissionPercent / 100.0));
            doctorEarned += (factor * eventDoctorEarned);
          }
        } else if (type == CompensationTypeEnum.fixedPerVisit ||
            type == CompensationTypeEnum.salaryPlusFixed) {
          // Fixed fee per visit: paid only when fully collected
          final isFullyCollected = recognizedCollectedPiastres >= candidate.netAmountPiastres;
          if (isFullyCollected) {
            doctorEarned = fixedFeePerVisit;
          } else if (recognizedCollectedPiastres < candidate.netAmountPiastres) {
            // If refund drops below net amount, reverse fixed fee
            doctorEarned = 0;
          }
        }
      }

      final clinicShare = recognizedCollectedPiastres - doctorEarned;

      final itemEventIds = candidateEvents.map((e) => e.eventId).toList();
      consumedEventIds.addAll(itemEventIds);

      final isFullyCollected = candidate.netAmountPiastres > 0 &&
          recognizedCollectedPiastres >= candidate.netAmountPiastres;

      final paymentStatus = candidate.netAmountPiastres == 0
          ? PaymentStatusEnum.paid
          : (recognizedCollectedPiastres >= candidate.netAmountPiastres
              ? PaymentStatusEnum.paid
              : (recognizedCollectedPiastres > 0
                  ? PaymentStatusEnum.partiallyPaid
                  : PaymentStatusEnum.unpaid));

      final item = DoctorSettlementItemModel(
        visitId: candidate.visitId,
        bookingId: candidate.bookingId,
        recognitionDate: candidateEvents.isNotEmpty
            ? calculateRecognitionDate(candidateEvents.first.date, candidate.finalizedAt)
            : candidate.finalizedAt,
        branchId: branchId,
        patientId: candidate.patientId,
        patientName: candidate.patientName,
        serviceName: candidate.serviceName,
        grossFeePiastres: candidate.grossFeePiastres,
        discountAmountPiastres: candidate.discountAmountPiastres,
        netAmountPiastres: candidate.netAmountPiastres,
        recognizedAmountPiastres: recognizedCollectedPiastres,
        commissionPercentageSnapshot: commissionPercent,
        fixedFeeSnapshotPiastres: fixedFeePerVisit,
        doctorEarnedPiastres: doctorEarned,
        clinicSharePiastres: clinicShare,
        paymentStatusSnapshot: paymentStatus,
        isFullyCollected: isFullyCollected,
        eventIds: itemEventIds,
      );

      items.add(item);
      totalNetRevenuePiastres += recognizedCollectedPiastres;
      totalDoctorCommissionPiastres += doctorEarned;
      totalClinicSharePiastres += clinicShare;
    }

    // Base salary from rule (for salaryOnly, salaryPlusPercentage, salaryPlusFixed)
    int baseSalary = 0;
    if (type == CompensationTypeEnum.salaryOnly ||
        type == CompensationTypeEnum.salaryPlusPercentage ||
        type == CompensationTypeEnum.salaryPlusFixed) {
      baseSalary = rule.monthlyBaseSalaryPiastres ?? 0;
    }

    // Process Ledger entries for bonuses and deductions within period
    final reversedEntryIds = <String>{};
    for (final e in ledgerEntries) {
      if (e.reversesEntryId != null) {
        reversedEntryIds.add(e.reversesEntryId!);
      }
    }

    int totalBonuses = 0;
    int totalDeductions = 0;
    final unconsumedAdvanceEntries = <EmployeeLedgerEntryModel>[];

    for (final e in ledgerEntries) {
      if (reversedEntryIds.contains(e.id)) continue;
      if (e.employeeId != doctorId) continue;

      if (e.entryType == LedgerEntryTypeEnum.bonus) {
        if (e.date != null &&
            (e.date!.isAfter(periodStart) || e.date!.isAtSameMomentAs(periodStart)) &&
            (e.date!.isBefore(periodEnd) || e.date!.isAtSameMomentAs(periodEnd))) {
          totalBonuses += (e.amountPiastres ?? 0);
        }
      } else if (e.entryType == LedgerEntryTypeEnum.deduction) {
        if (e.date != null &&
            (e.date!.isAfter(periodStart) || e.date!.isAtSameMomentAs(periodStart)) &&
            (e.date!.isBefore(periodEnd) || e.date!.isAtSameMomentAs(periodEnd))) {
          totalDeductions += (e.amountPiastres ?? 0);
        }
      } else if (e.entryType == LedgerEntryTypeEnum.advance) {
        if (!alreadyConsumedAdvanceEntryIds.contains(e.id)) {
          unconsumedAdvanceEntries.add(e);
        }
      }
    }

    // Earnings before advance deduction
    final earningsBeforeAdvances = baseSalary + totalDoctorCommissionPiastres + totalBonuses - totalDeductions;

    // Advances deduction: min(outstanding advances balance, earningsBeforeAdvances)
    int outstandingAdvances = 0;
    for (final adv in unconsumedAdvanceEntries) {
      outstandingAdvances += (adv.amountPiastres ?? 0);
    }

    final advancesDeducted = earningsBeforeAdvances > 0
        ? (outstandingAdvances <= earningsBeforeAdvances ? outstandingAdvances : earningsBeforeAdvances)
        : 0;

    final consumedAdvanceEntryIds = <String>[];
    if (advancesDeducted > 0) {
      int remainingToDeduct = advancesDeducted;
      for (final adv in unconsumedAdvanceEntries) {
        if (remainingToDeduct <= 0) break;
        consumedAdvanceEntryIds.add(adv.id!);
        remainingToDeduct -= (adv.amountPiastres ?? 0);
      }
    }

    final netPayable = (earningsBeforeAdvances - advancesDeducted) > 0
        ? (earningsBeforeAdvances - advancesDeducted)
        : 0;

    return DoctorSettlementModel(
      doctorId: doctorId,
      doctorName: doctorName,
      branchId: branchId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: SettlementStatusEnum.draft,
      totalVisitsCount: items.length,
      totalNetRevenuePiastres: totalNetRevenuePiastres,
      totalDoctorCommissionPiastres: totalDoctorCommissionPiastres,
      totalClinicSharePiastres: totalClinicSharePiastres,
      baseSalaryPiastres: baseSalary,
      totalBonusesPiastres: totalBonuses,
      totalDeductionsPiastres: totalDeductions,
      totalAdvancesDeductedPiastres: advancesDeducted,
      netPayablePiastres: netPayable,
      compensationRuleSnapshot: rule,
      items: items,
      consumedEventIds: consumedEventIds,
      consumedAdvanceEntryIds: consumedAdvanceEntryIds,
      createdAt: now,
    );
  }
}

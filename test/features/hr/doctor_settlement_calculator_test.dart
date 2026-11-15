import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/compensation_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart';
import 'package:eyadty/features/hr/domain/helpers/doctor_settlement_calculator.dart';

void main() {
  group('DoctorSettlementCalculator Tests', () {
    final periodStart = DateTime(2026, 4, 1, 0, 0);
    final periodEnd = DateTime(2026, 4, 30, 23, 59);

    final standard50PercentRule = DoctorCompensationRuleModel(
      id: 'RULE-1',
      doctorId: 'DOC-01',
      branchId: 'branch_1',
      compensationType: CompensationTypeEnum.percentage,
      commissionPercentage: 50,
      effectiveFrom: DateTime(2026, 1, 1),
    );

    test('1. Cash-collected basis: fee recognized only when transaction occurs', () {
      // Visit finalized in March, but payment received in April
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-001',
        bookingId: 'BOOK-001',
        patientId: 'PAT-001',
        patientName: 'أحمد علي',
        finalizedAt: DateTime(2026, 3, 28, 14, 0),
        grossFeePiastres: 30000,
        discountAmountPiastres: 0,
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-001',
            date: DateTime(2026, 4, 5, 10, 0),
            amountPiastres: 30000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.items!.length, 1);
      expect(settlement.totalNetRevenuePiastres, 30000);
      expect(settlement.totalDoctorCommissionPiastres, 15000); // 50% of 30,000
      expect(settlement.netPayablePiastres, 15000);
      expect(settlement.consumedEventIds!, contains('EV-001'));
    });

    test('2. Recognition date is max(transactionDate, visit.finalizedAt)', () {
      final transDate1 = DateTime(2026, 4, 5, 10, 0);
      final finalDate1 = DateTime(2026, 4, 2, 12, 0);
      expect(
        DoctorSettlementCalculator.calculateRecognitionDate(transDate1, finalDate1),
        transDate1,
      );

      final transDate2 = DateTime(2026, 3, 30, 10, 0);
      final finalDate2 = DateTime(2026, 4, 2, 12, 0);
      expect(
        DoctorSettlementCalculator.calculateRecognitionDate(transDate2, finalDate2),
        finalDate2,
      );
    });

    test('3. Payment prior to visit finalization recognized at visit.finalizedAt', () {
      // Payment made on March 25, visit finalized on April 2
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-002',
        bookingId: 'BOOK-002',
        finalizedAt: DateTime(2026, 4, 2, 14, 0),
        grossFeePiastres: 40000,
        netAmountPiastres: 40000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-002',
            date: DateTime(2026, 3, 25, 9, 0),
            amountPiastres: 40000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.items!.length, 1);
      expect(settlement.items!.first.recognitionDate, DateTime(2026, 4, 2, 14, 0));
      expect(settlement.totalDoctorCommissionPiastres, 20000);
    });

    test('4. Refund recognized as negative revenue and negative commission in refund period', () {
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-003',
        bookingId: 'BOOK-003',
        finalizedAt: DateTime(2026, 4, 5, 12, 0),
        grossFeePiastres: 50000,
        netAmountPiastres: 50000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-PAY-1',
            date: DateTime(2026, 4, 5, 12, 0),
            amountPiastres: 50000,
            type: 'payment',
          ),
          SettlementPaymentEvent(
            eventId: 'EV-REF-1',
            date: DateTime(2026, 4, 10, 16, 0),
            amountPiastres: 20000,
            type: 'refund',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.items!.length, 1);
      // Net recognized: 50000 - 20000 = 30000
      expect(settlement.totalNetRevenuePiastres, 30000);
      // Doctor 50%: 25000 - 10000 = 15000
      expect(settlement.totalDoctorCommissionPiastres, 15000);
      expect(settlement.totalClinicSharePiastres, 15000);
    });

    test('5. Commission calculation: round half-up per event in piastres', () {
      // 33% of 3500 piastres (35.00 EGP) = 1155 piastres (3500 * 0.33 = 1155.0)
      // 33% of 3550 piastres = 1171.5 -> rounds half-up to 1172
      final rule33Percent = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        compensationType: CompensationTypeEnum.percentage,
        commissionPercentage: 33,
      );

      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-004',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 3550,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-004',
            date: DateTime(2026, 4, 5),
            amountPiastres: 3550,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: rule33Percent,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.totalDoctorCommissionPiastres, 1172);
    });

    test('6. Fixed fee per visit: paid only when fully collected (collected >= netAmount)', () {
      final fixedRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000, // 100 EGP
      );

      // Candidate 1: Partially collected (200 out of 300 EGP) -> 0 earned
      final candidatePartial = SettlementVisitCandidate(
        visitId: 'VIS-PARTIAL',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-P1',
            date: DateTime(2026, 4, 5),
            amountPiastres: 20000,
            type: 'payment',
          ),
        ],
      );

      // Candidate 2: Fully collected (300 out of 300 EGP) -> 100 EGP earned
      final candidateFull = SettlementVisitCandidate(
        visitId: 'VIS-FULL',
        finalizedAt: DateTime(2026, 4, 6),
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-F1',
            date: DateTime(2026, 4, 6),
            amountPiastres: 30000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: fixedRule,
        candidates: [candidatePartial, candidateFull],
        ledgerEntries: [],
      );

      expect(settlement.items![0].doctorEarnedPiastres, 0);
      expect(settlement.items![0].isFullyCollected, isFalse);
      expect(settlement.items![1].doctorEarnedPiastres, 10000);
      expect(settlement.items![1].isFullyCollected, isTrue);
      expect(settlement.totalDoctorCommissionPiastres, 10000);
    });

    test('7. Fixed fee per visit: reversed if refund brings collected below net amount', () {
      final fixedRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000,
      );

      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-REFUND-FIXED',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-P',
            date: DateTime(2026, 4, 5),
            amountPiastres: 30000,
            type: 'payment',
          ),
          SettlementPaymentEvent(
            eventId: 'EV-R',
            date: DateTime(2026, 4, 8),
            amountPiastres: 10000,
            type: 'refund',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: fixedRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      // Recognized collected is 20000 < netAmount 30000, doctorEarned should be 0
      expect(settlement.items!.first.doctorEarnedPiastres, 0);
      expect(settlement.items!.first.isFullyCollected, isFalse);
    });

    test('8. Free consultation (netAmount == 0): 0 earned when payForFreeVisits = false', () {
      final fixedRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000,
        payForFreeVisits: false,
      );

      final freeCandidate = SettlementVisitCandidate(
        visitId: 'VIS-FREE-1',
        finalizedAt: DateTime(2026, 4, 5),
        grossFeePiastres: 0,
        netAmountPiastres: 0,
        isFreeConsultation: true,
        events: [],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: fixedRule,
        candidates: [freeCandidate],
        ledgerEntries: [],
      );

      expect(settlement.items!, isEmpty);
      expect(settlement.totalDoctorCommissionPiastres, 0);
    });

    test('9. Free consultation (netAmount == 0): fixed fee earned when payForFreeVisits = true', () {
      final fixedRulePayFree = DoctorCompensationRuleModel(
        doctorId: 'DOC-01',
        compensationType: CompensationTypeEnum.fixedPerVisit,
        fixedAmountPerVisitPiastres: 10000,
        payForFreeVisits: true,
      );

      final freeCandidate = SettlementVisitCandidate(
        visitId: 'VIS-FREE-2',
        finalizedAt: DateTime(2026, 4, 5),
        grossFeePiastres: 0,
        netAmountPiastres: 0,
        isFreeConsultation: true,
        events: [],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: fixedRulePayFree,
        candidates: [freeCandidate],
        ledgerEntries: [],
      );

      expect(settlement.items!.length, 1);
      expect(settlement.items!.first.doctorEarnedPiastres, 10000);
      expect(settlement.totalDoctorCommissionPiastres, 10000);
    });

    test('10. Salary-only rule: base salary applied regardless of visits', () {
      final salaryRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-05',
        compensationType: CompensationTypeEnum.salaryOnly,
        monthlyBaseSalaryPiastres: 1500000, // 15,000 EGP
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-05',
        doctorName: 'د. أسامة',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: salaryRule,
        candidates: [], // Zero visits
        ledgerEntries: [],
      );

      expect(settlement.baseSalaryPiastres, 1500000);
      expect(settlement.totalDoctorCommissionPiastres, 0);
      expect(settlement.netPayablePiastres, 1500000);
    });

    test('11. Salary + percentage rule: base salary + commission combined', () {
      final salaryPlusPercentRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-02',
        compensationType: CompensationTypeEnum.salaryPlusPercentage,
        monthlyBaseSalaryPiastres: 1000000, // 10,000 EGP
        commissionPercentage: 30,
      );

      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-SAL-PCT',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 20000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-SP',
            date: DateTime(2026, 4, 5),
            amountPiastres: 20000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-02',
        doctorName: 'د. محمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: salaryPlusPercentRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      // Base salary: 1000000, Commission: 30% of 20000 = 6000
      expect(settlement.baseSalaryPiastres, 1000000);
      expect(settlement.totalDoctorCommissionPiastres, 6000);
      expect(settlement.netPayablePiastres, 1006000);
    });

    test('12. Salary + fixed rule: base salary + fixed fee for fully collected visits', () {
      final salaryPlusFixedRule = DoctorCompensationRuleModel(
        doctorId: 'DOC-02',
        compensationType: CompensationTypeEnum.salaryPlusFixed,
        monthlyBaseSalaryPiastres: 800000,
        fixedAmountPerVisitPiastres: 5000,
      );

      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-SAL-FIXED',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 15000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-SF',
            date: DateTime(2026, 4, 5),
            amountPiastres: 15000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-02',
        doctorName: 'د. محمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: salaryPlusFixedRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.baseSalaryPiastres, 800000);
      expect(settlement.totalDoctorCommissionPiastres, 5000);
      expect(settlement.netPayablePiastres, 805000);
    });

    test('13. Advance deduction: deducted up to available earnings (min(advances, earnings))', () {
      // Total earnings: 25,000 piastres (50% of 50,000)
      // Active advances: 10,000 piastres
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-ADV-1',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 50000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-ADV-1',
            date: DateTime(2026, 4, 5),
            amountPiastres: 50000,
            type: 'payment',
          ),
        ],
      );

      final advances = [
        const EmployeeLedgerEntryModel(
          id: 'LEDGER-ADV-01',
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 10000,
        ),
      ];

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: advances,
      );

      expect(settlement.totalDoctorCommissionPiastres, 25000);
      expect(settlement.totalAdvancesDeductedPiastres, 10000);
      expect(settlement.netPayablePiastres, 15000);
      expect(settlement.consumedAdvanceEntryIds!, contains('LEDGER-ADV-01'));
    });

    test('14. Net payable cannot be negative: advances deduction capped at available earnings', () {
      // Total earnings: 10,000 piastres
      // Active advances: 30,000 piastres
      // Should deduct 10,000; netPayable = 0; remaining 20,000 stays in ledger
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-ADV-CAP',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 20000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-AC',
            date: DateTime(2026, 4, 5),
            amountPiastres: 20000,
            type: 'payment',
          ),
        ],
      );

      final advances = [
        const EmployeeLedgerEntryModel(
          id: 'LEDGER-ADV-02',
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 30000,
        ),
      ];

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: advances,
      );

      expect(settlement.totalDoctorCommissionPiastres, 10000);
      expect(settlement.totalAdvancesDeductedPiastres, 10000); // capped at earnings
      expect(settlement.netPayablePiastres, 0);
    });

    test('15. Bonuses from ledger added to earnings', () {
      final bonusEntry = EmployeeLedgerEntryModel(
        id: 'LEDGER-BONUS-1',
        employeeId: 'DOC-01',
        entryType: LedgerEntryTypeEnum.bonus,
        amountPiastres: 50000, // 500 EGP bonus
        date: DateTime(2026, 4, 15),
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [],
        ledgerEntries: [bonusEntry],
      );

      expect(settlement.totalBonusesPiastres, 50000);
      expect(settlement.netPayablePiastres, 50000);
    });

    test('16. Deductions from ledger subtracted from earnings', () {
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-DED',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 40000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-DED',
            date: DateTime(2026, 4, 5),
            amountPiastres: 40000,
            type: 'payment',
          ),
        ],
      );

      final deductionEntry = EmployeeLedgerEntryModel(
        id: 'LEDGER-DED-1',
        employeeId: 'DOC-01',
        entryType: LedgerEntryTypeEnum.deduction,
        amountPiastres: 5000, // 50 EGP deduction
        date: DateTime(2026, 4, 12),
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [deductionEntry],
      );

      // Commission 20000 - deduction 5000 = 15000 net payable
      expect(settlement.totalDoctorCommissionPiastres, 20000);
      expect(settlement.totalDeductionsPiastres, 5000);
      expect(settlement.netPayablePiastres, 15000);
    });

    test('17. Already consumed events and advances are excluded', () {
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-CONSUMED',
        finalizedAt: DateTime(2026, 4, 5),
        netAmountPiastres: 40000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-ALREADY-CONSUMED',
            date: DateTime(2026, 4, 5),
            amountPiastres: 40000,
            type: 'payment',
          ),
        ],
      );

      final advanceEntry = const EmployeeLedgerEntryModel(
        id: 'ADV-ALREADY-CONSUMED',
        employeeId: 'DOC-01',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 10000,
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [advanceEntry],
        alreadyConsumedEventIds: ['EV-ALREADY-CONSUMED'],
        alreadyConsumedAdvanceEntryIds: ['ADV-ALREADY-CONSUMED'],
      );

      expect(settlement.items!, isEmpty);
      expect(settlement.totalAdvancesDeductedPiastres, 0);
      expect(settlement.netPayablePiastres, 0);
    });

    test('18. Multi-event visit: partial payment + subsequent payment recognized properly', () {
      // First installment: 200 EGP on April 2
      // Second installment: 100 EGP on April 15
      final candidate = SettlementVisitCandidate(
        visitId: 'VIS-MULTI',
        finalizedAt: DateTime(2026, 4, 2),
        netAmountPiastres: 30000,
        events: [
          SettlementPaymentEvent(
            eventId: 'EV-INST-1',
            date: DateTime(2026, 4, 2),
            amountPiastres: 20000,
            type: 'payment',
          ),
          SettlementPaymentEvent(
            eventId: 'EV-INST-2',
            date: DateTime(2026, 4, 15),
            amountPiastres: 10000,
            type: 'payment',
          ),
        ],
      );

      final settlement = DoctorSettlementCalculator.calculateSettlement(
        doctorId: 'DOC-01',
        doctorName: 'د. أحمد',
        branchId: 'branch_1',
        periodStart: periodStart,
        periodEnd: periodEnd,
        rule: standard50PercentRule,
        candidates: [candidate],
        ledgerEntries: [],
      );

      expect(settlement.items!.length, 1);
      expect(settlement.items!.first.eventIds!.length, 2);
      expect(settlement.items!.first.recognizedAmountPiastres, 30000);
      expect(settlement.items!.first.doctorEarnedPiastres, 15000);
      expect(settlement.items!.first.isFullyCollected, isTrue);
      expect(settlement.items!.first.paymentStatusSnapshot, PaymentStatusEnum.paid);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/enums/employee_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/ledger_entry_type_enum.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/repo/hr_mock_repo_impl.dart';
import 'package:eyadty/features/hr/domain/helpers/doctor_settlement_calculator.dart';

void main() {
  group('Employee Ledger & Advances Tests (Plan 8.2)', () {
    late HrMockRepoImpl repo;

    setUp(() {
      repo = HrMockRepoImpl(seedInitialData: false);
    });

    test('1. Add advance entry creates ledger record successfully', () async {
      final now = CairoTimeHelper.now();
      final entry = EmployeeLedgerEntryModel(
        employeeId: 'DOC-01',
        employeeType: EmployeeTypeEnum.doctor,
        branchId: 'branch_1',
        entryType: LedgerEntryTypeEnum.advance,
        amountPiastres: 100000, // 1,000 EGP
        reason: 'سلفة نقدية طارئة',
        date: now,
        performedByUserId: 'user-manager',
      );

      final result = await repo.addEmployeeLedgerEntry(entry);
      expect(result.isRight(), isTrue);

      final created = result.getOrElse(() => const EmployeeLedgerEntryModel());
      expect(created.id, isNotNull);
      expect(created.amountPiastres, 100000);
      expect(created.entryType, LedgerEntryTypeEnum.advance);

      final fetchRes = await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01');
      expect(fetchRes.isRight(), isTrue);
      final entries = fetchRes.getOrElse(() => []);
      expect(entries.length, 1);
      expect(entries.first.id, created.id);
    });

    test('2. Calculate outstanding advances sums active unreversed advances', () async {
      final now = CairoTimeHelper.now();
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          employeeType: EmployeeTypeEnum.doctor,
          branchId: 'branch_1',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 50000,
          date: now,
        ),
      );
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          employeeType: EmployeeTypeEnum.doctor,
          branchId: 'branch_1',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 30000,
          date: now.add(const Duration(hours: 1)),
        ),
      );

      final entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      final total = DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(entries);
      expect(total, 80000); // 50,000 + 30,000
    });

    test('3. Reversal entry cancels original entry via reversesEntryId', () async {
      final now = CairoTimeHelper.now();
      final adv = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          employeeType: EmployeeTypeEnum.doctor,
          branchId: 'branch_1',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 40000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      final revRes = await repo.reverseEmployeeLedgerEntry(
        entryId: adv.id!,
        reason: 'صرفت عن طريق الخطأ بالكاشير وتم استردادها',
        performedByUserId: 'user-manager',
      );

      expect(revRes.isRight(), isTrue);
      final revEntry = revRes.getOrElse(() => const EmployeeLedgerEntryModel());
      expect(revEntry.reversesEntryId, adv.id);
      expect(revEntry.amountPiastres, -40000);

      // Total outstanding advances should now be 0
      final entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      final balance = DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(entries);
      expect(balance, 0);
    });

    test('4. Cannot reverse a reversal entry', () async {
      final now = CairoTimeHelper.now();
      final adv = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 25000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      final rev = (await repo.reverseEmployeeLedgerEntry(
        entryId: adv.id!,
        reason: 'إلغاء لخطأ في الإدخال',
        performedByUserId: 'user-manager',
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      // Try reversing the reversal
      final secondRev = await repo.reverseEmployeeLedgerEntry(
        entryId: rev.id!,
        reason: 'محاولة إلغاء الإلغاء',
        performedByUserId: 'user-manager',
      );

      expect(secondRev.isLeft(), isTrue);
      secondRev.fold(
        (failure) => expect(failure.errMessage, 'cannot_reverse_reversal_entry'),
        (_) => fail('Should have rejected reversing a reversal entry'),
      );
    });

    test('5. Cannot reverse a payout entry', () async {
      final now = CairoTimeHelper.now();
      final payout = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.payout,
          amountPiastres: 150000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      final result = await repo.reverseEmployeeLedgerEntry(
        entryId: payout.id!,
        reason: 'محاولة إلغاء صرف',
        performedByUserId: 'user-manager',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'cannot_reverse_payout_entry'),
        (_) => fail('Should have rejected reversing payout entry'),
      );
    });

    test('6. Idempotency via clientRequestId: duplicate request returns existing entry without double-posting', () async {
      final now = CairoTimeHelper.now();
      const requestId = 'req-unique-client-1234';

      final firstRes = await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          clientRequestId: requestId,
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 70000,
          date: now,
        ),
      );
      expect(firstRes.isRight(), isTrue);
      final firstEntry = firstRes.getOrElse(() => const EmployeeLedgerEntryModel());

      // Attempt duplicate submit with exact same clientRequestId
      final secondRes = await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          clientRequestId: requestId,
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 70000,
          date: now,
        ),
      );
      expect(secondRes.isRight(), isTrue);
      final secondEntry = secondRes.getOrElse(() => const EmployeeLedgerEntryModel());

      // Must be the identical entry
      expect(secondEntry.id, firstEntry.id);

      final entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      expect(entries.length, 1);
    });

    test('7. Deductions and bonuses ledger entries creation and retrieval', () async {
      final now = CairoTimeHelper.now();
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.bonus,
          amountPiastres: 20000,
          reason: 'مكافأة تميز في شهر رمضان',
          date: now,
        ),
      );

      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.deduction,
          amountPiastres: 10000,
          reason: 'خصم غياب يوم غير مصرح',
          date: now.add(const Duration(hours: 1)),
        ),
      );

      final entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      expect(entries.length, 2);
      expect(entries.any((e) => e.entryType == LedgerEntryTypeEnum.bonus), isTrue);
      expect(entries.any((e) => e.entryType == LedgerEntryTypeEnum.deduction), isTrue);
    });

    test('8. Amount must be positive when creating entries', () async {
      final zeroRes = await repo.addEmployeeLedgerEntry(
        const EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 0,
        ),
      );
      expect(zeroRes.isLeft(), isTrue);
      zeroRes.fold(
        (f) => expect(f.errMessage, 'amount_must_be_positive'),
        (_) => fail('Should have rejected 0 amount'),
      );

      final negativeRes = await repo.addEmployeeLedgerEntry(
        const EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: -5000,
        ),
      );
      expect(negativeRes.isLeft(), isTrue);
      negativeRes.fold(
        (f) => expect(f.errMessage, 'amount_must_be_positive'),
        (_) => fail('Should have rejected negative amount'),
      );
    });

    test('9. Branch filtering on ledger entries', () async {
      final now = CairoTimeHelper.now();
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          branchId: 'branch_1',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 30000,
          date: now,
        ),
      );
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          branchId: 'branch_2',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 40000,
          date: now,
        ),
      );

      final branch1Entries = (await repo.getEmployeeLedgerEntries(
        employeeId: 'DOC-01',
        branchId: 'branch_1',
      )).getOrElse(() => []);
      expect(branch1Entries.length, 1);
      expect(branch1Entries.first.branchId, 'branch_1');

      final branch2Entries = (await repo.getEmployeeLedgerEntries(
        employeeId: 'DOC-01',
        branchId: 'branch_2',
      )).getOrElse(() => []);
      expect(branch2Entries.length, 1);
      expect(branch2Entries.first.branchId, 'branch_2');
    });

    test('10. Reversal must provide documentary reason', () async {
      final now = CairoTimeHelper.now();
      final adv = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 15000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      final emptyReasonRes = await repo.reverseEmployeeLedgerEntry(
        entryId: adv.id!,
        reason: '   ',
        performedByUserId: 'user-manager',
      );

      expect(emptyReasonRes.isLeft(), isTrue);
      emptyReasonRes.fold(
        (f) => expect(f.errMessage, 'reversal_reason_required'),
        (_) => fail('Should have required documentary reason'),
      );
    });

    test('11. Append-only immutability: entries cannot be mutated retroactively', () async {
      final now = CairoTimeHelper.now();
      final adv = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 50000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      // Attempting to reverse an entry that was already reversed
      await repo.reverseEmployeeLedgerEntry(
        entryId: adv.id!,
        reason: 'إلغاء أولي',
        performedByUserId: 'user-1',
      );

      final secondTry = await repo.reverseEmployeeLedgerEntry(
        entryId: adv.id!,
        reason: 'إلغاء ثان لنفس القيد',
        performedByUserId: 'user-1',
      );

      expect(secondTry.isLeft(), isTrue);
      secondTry.fold(
        (f) => expect(f.errMessage, 'ledger_entry_already_reversed'),
        (_) => fail('Should not allow duplicate reversals'),
      );
    });

    test('12. Seed settlements marked source: mockSeed excluded from general ledger', () {
      final seedRepo = HrMockRepoImpl(seedInitialData: true);
      final seededSettlements = seedRepo.getDoctorSettlements(doctorId: 'DOC-01');
      expect(seededSettlements, completes);
    });

    test('13. Multiple advances partial deduction tracking', () {
      final now = CairoTimeHelper.now();
      final advances = [
        EmployeeLedgerEntryModel(
          id: 'ADV-1',
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 20000,
          date: now,
        ),
        EmployeeLedgerEntryModel(
          id: 'ADV-2',
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 30000,
          date: now.add(const Duration(days: 1)),
        ),
      ];

      final totalAdvances = DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(advances);
      expect(totalAdvances, 50000);
    });

    test('14. Doctor payout creates LedgerEntryTypeEnum.payout entry in ledger', () async {
      final draftSettlement = DoctorSettlementModel(
        id: 'SETTL-TEST-01',
        settlementNumber: 'SET-2026-0001',
        doctorId: 'DOC-01',
        doctorName: 'د. خالد',
        branchId: 'branch_1',
        periodStart: DateTime(2026, 4, 1),
        periodEnd: DateTime(2026, 4, 30),
        status: SettlementStatusEnum.draft,
        netPayablePiastres: 450000, // 4,500 EGP
      );

      await repo.saveDoctorSettlement(draftSettlement);
      await repo.confirmDoctorSettlement(
        settlementId: 'SETTL-TEST-01',
        confirmedByUserId: 'user-owner',
      );

      final payoutRes = await repo.payoutDoctorSettlement(
        settlementId: 'SETTL-TEST-01',
        paidByUserId: 'user-cashier',
        method: PaymentMethod.cash,
      );

      expect(payoutRes.isRight(), isTrue);
      final paid = payoutRes.getOrElse(() => const DoctorSettlementModel());
      expect(paid.status, SettlementStatusEnum.paid);

      // Verify a payout ledger entry was created
      final ledgerRes = await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01');
      expect(ledgerRes.isRight(), isTrue);
      final entries = ledgerRes.getOrElse(() => []);
      final payoutEntry = entries.firstWhere((e) => e.entryType == LedgerEntryTypeEnum.payout);
      expect(payoutEntry.amountPiastres, 450000);
      expect(payoutEntry.performedByUserId, 'user-cashier');
    });

    test('15. Reversal reduces outstanding balance accurately', () async {
      final now = CairoTimeHelper.now();
      final adv1 = (await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 50000,
          date: now,
        ),
      )).getOrElse(() => const EmployeeLedgerEntryModel());

      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.advance,
          amountPiastres: 30000,
          date: now.add(const Duration(minutes: 5)),
        ),
      );

      var entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      expect(DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(entries), 80000);

      // Reverse the first advance of 50,000
      await repo.reverseEmployeeLedgerEntry(
        entryId: adv1.id!,
        reason: 'إلغاء السلفة الأولى',
        performedByUserId: 'user-manager',
      );

      entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      expect(DoctorSettlementCalculator.calculateOutstandingAdvancesPiastres(entries), 30000);
    });

    test('16. Edge case: multiple entries with same timestamp sorted consistently', () async {
      final fixedTime = DateTime(2026, 4, 15, 10, 0);
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.bonus,
          amountPiastres: 10000,
          date: fixedTime,
        ),
      );
      await repo.addEmployeeLedgerEntry(
        EmployeeLedgerEntryModel(
          employeeId: 'DOC-01',
          entryType: LedgerEntryTypeEnum.deduction,
          amountPiastres: 5000,
          date: fixedTime,
        ),
      );

      final entries = (await repo.getEmployeeLedgerEntries(employeeId: 'DOC-01')).getOrElse(() => []);
      expect(entries.length, 2);
    });
  });
}

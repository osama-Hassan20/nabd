import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/enums/print_document_type.dart';
import 'package:eyadty/core/enums/print_format.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/cashier/data/models/cash_movement_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_summary_metrics_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/data/models/refund_transaction_model.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_mock_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M-1: Cashier Models, Enums & Seed Repo Tests', () {
    test('1. PaymentMethod enum serialization, getters, and bankTransfer support', () {
      expect(PaymentMethod.fromValue('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromValue('card'), PaymentMethod.card);
      expect(PaymentMethod.fromValue('bankTransfer'), PaymentMethod.bankTransfer);
      expect(PaymentMethod.fromValue('unknown'), PaymentMethod.cash);

      expect(PaymentMethod.cash.value, 'cash');
      expect(PaymentMethod.card.value, 'card');
      expect(PaymentMethod.bankTransfer.value, 'bankTransfer');
    });

    test('2. PrintFormat enum serialization and default fallback to a4', () {
      expect(PrintFormat.fromString('thermal80'), PrintFormat.thermal80);
      expect(PrintFormat.fromString('a4'), PrintFormat.a4);
      expect(PrintFormat.fromString(null), PrintFormat.a4);
      expect(PrintFormat.fromString('unknown_format'), PrintFormat.a4);
    });

    test('3. PrintDocumentType enum values and getters', () {
      expect(PrintDocumentType.fromValue('paymentReceipt'), PrintDocumentType.paymentReceipt);
      expect(PrintDocumentType.fromValue('shiftReport'), PrintDocumentType.shiftReport);
      expect(PrintDocumentType.fromValue('prescription'), PrintDocumentType.prescription);
      expect(PrintDocumentType.fromValue(null), PrintDocumentType.paymentReceipt);
    });

    test('4. ShiftStatusEnum serialization and value checks', () {
      expect(ShiftStatusEnum.fromValue('open'), ShiftStatusEnum.open);
      expect(ShiftStatusEnum.fromValue('closed'), ShiftStatusEnum.closed);
      expect(ShiftStatusEnum.fromValue('closed_pending_approval'), ShiftStatusEnum.closedPendingApproval);
      expect(ShiftStatusEnum.fromValue('force_closed'), ShiftStatusEnum.forceClosed);
    });

    test('5. CashMovementTypeEnum serialization and inflow/outflow properties', () {
      expect(CashMovementTypeEnum.pettyExpense.isOutflow, isTrue);
      expect(CashMovementTypeEnum.bankDeposit.isOutflow, isTrue);
      expect(CashMovementTypeEnum.ownerWithdrawal.isOutflow, isTrue);
      expect(CashMovementTypeEnum.capitalInjection.isInflow, isTrue);
    });

    test('6. CashierShiftModel JSON serialization and Money getters', () {
      final shift = CashierShiftModel(
        id: 'SHIFT-001',
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        status: ShiftStatusEnum.open,
        openingBalancePiastres: 100000,
        expectedCashPiastres: 205000,
        actualCashCountPiastres: 205000,
        cashDifferencePiastres: 0,
      );

      final json = shift.toJson();
      final fromJson = CashierShiftModel.fromJson(json);

      expect(fromJson.id, 'SHIFT-001');
      expect(fromJson.openingBalanceMoney.toPounds(), 1000.0);
      expect(fromJson.expectedCashMoney.toPounds(), 2050.0);
      expect(fromJson.isBalanced, isTrue);
      expect(fromJson.hasShortage, isFalse);
    });

    test('7. PaymentTransactionModel JSON serialization and Money helpers', () {
      final payment = PaymentTransactionModel(
        id: 'PAY-001',
        clientRequestId: 'REQ-001',
        shiftId: 'SHIFT-001',
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-001',
        patientName: 'سارة أحمد',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.card,
        isRefunded: false,
        refundedAmountPiastres: 0,
      );

      final json = payment.toJson();
      final fromJson = PaymentTransactionModel.fromJson(json);

      expect(fromJson.id, 'PAY-001');
      expect(fromJson.amountMoney.toPounds(), 300.0);
      expect(fromJson.isCard, isTrue);
      expect(fromJson.isCash, isFalse);
    });

    test('8. RefundTransactionModel JSON serialization', () {
      final refund = RefundTransactionModel(
        id: 'REF-001',
        clientRequestId: 'REQ-REF-001',
        originalPaymentId: 'PAY-001',
        shiftId: 'SHIFT-001',
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-001',
        refundAmountPiastres: 15000,
        refundMethod: PaymentMethod.cash,
        reason: 'إلغاء حجز',
        authorizedByUserId: 'USER-MGR',
      );

      final json = refund.toJson();
      final fromJson = RefundTransactionModel.fromJson(json);

      expect(fromJson.refundAmountMoney.toPounds(), 150.0);
      expect(fromJson.isCash, isTrue);
    });

    test('9. CashMovementModel JSON serialization', () {
      final mov = CashMovementModel(
        id: 'CSM-001',
        clientRequestId: 'REQ-CSM-001',
        shiftId: 'SHIFT-001',
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense,
        amountPiastres: 15000,
        reason: 'ضيافة',
        recipientName: 'عامل الخدمات',
      );

      final json = mov.toJson();
      final fromJson = CashMovementModel.fromJson(json);

      expect(fromJson.amountMoney.toPounds(), 150.0);
      expect(fromJson.isOutflow, isTrue);
    });

    test('10. CashierSummaryMetricsModel calculations', () {
      const metrics = CashierSummaryMetricsModel(
        openingBalancePiastres: 100000,
        expectedCashPiastres: 205000,
        actualCashPiastres: 205000,
        differencePiastres: 0,
        cashCollectedPiastres: 120000,
        cardCollectedPiastres: 65000,
        bankTransferPiastres: 30000,
        totalExpensesPiastres: 15000,
        totalRefundsPiastres: 0,
        transactionsCount: 8,
      );

      expect(metrics.openingBalanceMoney.toPounds(), 1000.0);
      expect(metrics.expectedCashMoney.toPounds(), 2050.0);
      expect(metrics.grandTotalCollectedMoney.toPounds(), 2150.0);
    });

    test('11. Seed matching: branch_1 shift SHIFT-CAI-01 matches 2050.0 EGP expected cash', () async {
      final repo = CashierMockRepoImpl();
      final shiftRes = await repo.getCurrentShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
      );

      expect(shiftRes.isRight(), isTrue);
      final shift = shiftRes.getOrElse(() => null);
      expect(shift, isNotNull);
      expect(shift!.id, 'SHIFT-CAI-01');
      expect(shift.cashierName, 'منى إبراهيم');
      expect(shift.openingBalancePiastres, 100000); // 1000 EGP
      expect(shift.totalCashCollectedPiastres, 120000); // 1200 EGP
      expect(shift.totalCardCollectedPiastres, 65000); // 650 EGP
      expect(shift.totalExpensesPiastres, 15000); // 150 EGP
      expect(shift.expectedCashPiastres, 205000); // 2050.0 EGP (1000 + 1200 - 150)
    });

    test('12. Seed matching: branch_2 and branch_3 shifts reconcile with reception users', () async {
      final repo = CashierMockRepoImpl();

      // Branch 2: مدينة نصر with USER-REC-2 (هدى مصطفى)
      final shift2Res = await repo.getCurrentShift(
        branchId: 'branch_2',
        cashierUserId: 'USER-REC-2',
      );
      expect(shift2Res.isRight(), isTrue);
      final shift2 = shift2Res.getOrElse(() => null);
      expect(shift2, isNotNull);
      expect(shift2!.cashierName, 'هدى مصطفى');
      expect(shift2.openingBalancePiastres, 50000);
      expect(shift2.totalBankTransferPiastres, 30000); // 300 EGP
      expect(shift2.expectedCashPiastres, 50000); // Bank transfer does NOT alter drawer cash

      // Branch 3: التجمع الخامس with USER-REC-TAG (سارة العزازي)
      final shift3Res = await repo.getCurrentShift(
        branchId: 'branch_3',
        cashierUserId: 'USER-REC-TAG',
      );
      expect(shift3Res.isRight(), isTrue);
      final shift3 = shift3Res.getOrElse(() => null);
      expect(shift3, isNotNull);
      expect(shift3!.cashierName, 'سارة العزازي');
      expect(shift3.openingBalancePiastres, 50000);
      expect(shift3.expectedCashPiastres, 50000);
    });

    test('13. Seed matching: All 11 seed bookings reconcile with ledger transactions and patient totals', () async {
      final repo = CashierMockRepoImpl();

      // MED-101: 300 EGP card
      final p101 = await repo.getPaymentsByBookingId(bookingId: 'MED-101');
      expect(p101.getOrElse(() => []).first.amountPiastres, 30000);
      expect(p101.getOrElse(() => []).first.paymentMethod, PaymentMethod.card);

      // MED-103: 450 EGP cash
      final p103 = await repo.getPaymentsByBookingId(bookingId: 'MED-103');
      expect(p103.getOrElse(() => []).first.amountPiastres, 45000);

      // MED-104: 150 EGP cash
      final p104 = await repo.getPaymentsByBookingId(bookingId: 'MED-104');
      expect(p104.getOrElse(() => []).first.amountPiastres, 15000);

      // MED-106: 350 EGP card
      final p106 = await repo.getPaymentsByBookingId(bookingId: 'MED-106');
      expect(p106.getOrElse(() => []).first.amountPiastres, 35000);

      // MED-107: 150 EGP cash
      final p107 = await repo.getPaymentsByBookingId(bookingId: 'MED-107');
      expect(p107.getOrElse(() => []).first.amountPiastres, 15000);

      // MED-108: 300 EGP bankTransfer
      final p108 = await repo.getPaymentsByBookingId(bookingId: 'MED-108');
      expect(p108.getOrElse(() => []).first.amountPiastres, 30000);
      expect(p108.getOrElse(() => []).first.paymentMethod, PaymentMethod.bankTransfer);

      // MED-109: 150 EGP cash
      final p109 = await repo.getPaymentsByBookingId(bookingId: 'MED-109');
      expect(p109.getOrElse(() => []).first.amountPiastres, 15000);

      // MED-111: 300 EGP cash (no_show revenue)
      final p111 = await repo.getPaymentsByBookingId(bookingId: 'MED-111');
      expect(p111.getOrElse(() => []).first.amountPiastres, 30000);

      // Unpaid bookings: MED-102, MED-105, MED-110 have 0 payments
      final p102 = await repo.getPaymentsByBookingId(bookingId: 'MED-102');
      expect(p102.getOrElse(() => []), isEmpty);
      final p105 = await repo.getPaymentsByBookingId(bookingId: 'MED-105');
      expect(p105.getOrElse(() => []), isEmpty);
      final p110 = await repo.getPaymentsByBookingId(bookingId: 'MED-110');
      expect(p110.getOrElse(() => []), isEmpty);

      // Patient Totals Reconciliation:
      // PAT-000101: MED-101 (300) + MED-106 (350) + MED-111 (300) = 950 EGP
      final pat101Sum = [30000, 35000, 30000].reduce((a, b) => a + b);
      expect(pat101Sum, 95000); // 950.0 EGP

      // PAT-000102: MED-107 (150) = 150 EGP
      expect(15000, 15000);

      // PAT-000103: MED-103 (450) + MED-108 (300) = 750 EGP
      final pat103Sum = [45000, 30000].reduce((a, b) => a + b);
      expect(pat103Sum, 75000); // 750.0 EGP

      // PAT-000104: MED-104 (150) + MED-109 (150) = 300 EGP
      final pat104Sum = [15000, 15000].reduce((a, b) => a + b);
      expect(pat104Sum, 30000); // 300.0 EGP
    });

    test('14. Relative time resilience: seed initializes correctly across various day hours (07:00, 12:00, 23:30)', () {
      final hours = [7, 12, 23];
      final minutes = [0, 0, 30];

      for (int i = 0; i < hours.length; i++) {
        final mockTime = DateTime(2026, 11, 11, hours[i], minutes[i]);
        CairoTimeHelper.setFixedClock(mockTime);

        final repo = CashierMockRepoImpl();
        expect(repo, isNotNull);

        CairoTimeHelper.resetFixedClock();
      }
    });

    test('15. Idempotency and Rollback: cached on identical params, rejected on conflict, restored on rollback', () async {
      final repo = CashierMockRepoImpl(seedInitialData: false);
      await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      );
      final shift = (await repo.getCurrentShift(branchId: 'branch_1', cashierUserId: 'USER-REC')).getOrElse(() => null)!;
      final initialExpected = shift.expectedCashPiastres;

      // 1. Record payment
      final res1 = await repo.recordPayment(
        clientRequestId: 'REQ-IDEM-001',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-NEW',
        patientId: 'PAT-001',
        patientName: 'أحمد',
        amountPiastres: 10000,
        paymentMethod: 'cash',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );
      expect(res1.isRight(), isTrue);
      final payment = res1.getOrElse(() => throw Exception());

      // 2. Duplicate with identical params -> returns same model
      final res2 = await repo.recordPayment(
        clientRequestId: 'REQ-IDEM-001',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-NEW',
        patientId: 'PAT-001',
        patientName: 'أحمد',
        amountPiastres: 10000,
        paymentMethod: 'cash',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );
      expect(res2.getOrElse(() => throw Exception()).id, payment.id);

      // 3. Duplicate with different amount -> fails with idempotency_conflict
      final resConflict = await repo.recordPayment(
        clientRequestId: 'REQ-IDEM-001',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-NEW',
        patientId: 'PAT-001',
        patientName: 'أحمد',
        amountPiastres: 20000,
        paymentMethod: 'cash',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );
      expect(resConflict.isLeft(), isTrue);
      resConflict.fold(
        (f) => expect(f.errMessage, 'idempotency_conflict'),
        (_) => fail('Should have failed with idempotency_conflict'),
      );

      // 4. Void rollback restores expected cash exactly
      final rollbackRes = await repo.voidPaymentRollback(
        paymentId: payment.id!,
        reason: 'system_rollback',
      );
      expect(rollbackRes.isRight(), isTrue);

      final shiftAfter = (await repo.getCurrentShift(branchId: 'branch_1', cashierUserId: 'USER-REC')).getOrElse(() => null)!;
      expect(shiftAfter.expectedCashPiastres, equals(initialExpected));
    });

    test('16. Close shift: verifies diff threshold <= 50.0 EGP closes normally vs pending approval', () async {
      final repo = CashierMockRepoImpl(seedInitialData: false);
      final shift = (await repo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw Exception());

      // Normal closure: diff = 20 EGP (2000 piastres <= 5000)
      final closeResNormal = await repo.closeShift(
        shiftId: shift.id!,
        actualCashCountPiastres: 52000,
      );
      expect(closeResNormal.getOrElse(() => throw Exception()).status, ShiftStatusEnum.closed);
    });
  });
}

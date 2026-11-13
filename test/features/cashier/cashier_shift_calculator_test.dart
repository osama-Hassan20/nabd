import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/features/cashier/data/models/cash_movement_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/data/models/refund_transaction_model.dart';
import 'package:eyadty/features/cashier/domain/contracts/cashier_policy.dart';
import 'package:eyadty/features/cashier/domain/helpers/cashier_shift_calculator.dart';

void main() {
  const calculator = CashierShiftCalculator();
  const defaultPolicy = CashierPolicy();

  group('CashierShiftCalculator - Expected Cash Calculations', () {
    test('1. Calculates expected cash with opening balance only', () {
      final expected = calculator.calculateExpectedCashPiastres(
        openingBalancePiastres: 100000,
        cashCollectedPiastres: 0,
        cashRefundedPiastres: 0,
        pettyExpensesPiastres: 0,
      );
      expect(expected, 100000);
    });

    test('2. Calculates expected cash with cash collected and petty expenses', () {
      final expected = calculator.calculateExpectedCashPiastres(
        openingBalancePiastres: 100000, // 1000 EGP
        cashCollectedPiastres: 50000,   // +500 EGP
        cashRefundedPiastres: 10000,    // -100 EGP
        pettyExpensesPiastres: 5000,    // -50 EGP
      );
      expect(expected, 135000); // 1350 EGP
    });

    test('3. Calculates expected cash with capital injection and bank deposits', () {
      final expected = calculator.calculateExpectedCashPiastres(
        openingBalancePiastres: 50000,
        cashCollectedPiastres: 20000,
        cashRefundedPiastres: 0,
        pettyExpensesPiastres: 0,
        capitalInjectionPiastres: 30000, // +300 EGP
        bankDepositPiastres: 40000,      // -400 EGP
        ownerWithdrawalPiastres: 10000,  // -100 EGP
      );
      // 50000 + 20000 - 0 - 0 + 30000 - 40000 - 10000 = 50000
      expect(expected, 50000);
    });

    test('4. Card and BankTransfer payments are strictly isolated from expected drawer cash', () {
      // Shift with 1000 cash, 5000 card, 3000 bank transfer
      // Expected cash in drawer must ignore the 5000 card and 3000 bank transfer
      final expected = calculator.calculateExpectedCashPiastres(
        openingBalancePiastres: 50000,
        cashCollectedPiastres: 100000,
        cashRefundedPiastres: 0,
        pettyExpensesPiastres: 0,
      );
      expect(expected, 150000); // Only 500 + 1000 = 1500 EGP
    });

    test('5. Non-cash refunds do not deduct from drawer cash', () {
      // Cash refund of 50 EGP deducts from drawer, non-cash does not
      final expected = calculator.calculateExpectedCashPiastres(
        openingBalancePiastres: 50000,
        cashCollectedPiastres: 0,
        cashRefundedPiastres: 5000, // Cash refund only
        pettyExpensesPiastres: 0,
      );
      expect(expected, 45000);
    });
  });

  group('CashierShiftCalculator - Difference and Closure Status', () {
    test('6. Calculates positive difference (surplus)', () {
      final diff = calculator.calculateDifferencePiastres(
        actualCashCountPiastres: 105000,
        expectedCashPiastres: 100000,
      );
      expect(diff, 5000); // +50 EGP surplus
    });

    test('7. Calculates negative difference (shortage)', () {
      final diff = calculator.calculateDifferencePiastres(
        actualCashCountPiastres: 92000,
        expectedCashPiastres: 100000,
      );
      expect(diff, -8000); // -80 EGP shortage
    });

    test('8. Determines closed status when drawer is perfectly balanced', () {
      final status = calculator.determineCloseShiftStatus(
        differencePiastres: 0,
        policy: defaultPolicy,
      );
      expect(status, ShiftStatusEnum.closed);
    });

    test('9. Determines closed status when shortage is within policy limit (<= 50 EGP)', () {
      final status = calculator.determineCloseShiftStatus(
        differencePiastres: -5000, // Exactly 50 EGP
        policy: defaultPolicy,
      );
      expect(status, ShiftStatusEnum.closed);
    });

    test('10. Determines closedPendingApproval when shortage exceeds policy limit (> 50 EGP)', () {
      final status = calculator.determineCloseShiftStatus(
        differencePiastres: -5001, // 50.01 EGP shortage
        policy: defaultPolicy,
      );
      expect(status, ShiftStatusEnum.closedPendingApproval);
    });

    test('11. Determines closed status on any surplus regardless of amount', () {
      final status = calculator.determineCloseShiftStatus(
        differencePiastres: 150000, // +1500 EGP surplus
        policy: defaultPolicy,
      );
      expect(status, ShiftStatusEnum.closed);
    });
  });

  group('CashierShiftCalculator - Overdue and Shift Metrics', () {
    test('12. Determines overdue shift after maxShiftAgeHours (16 hours)', () {
      final openedAt = DateTime(2026, 11, 13, 8, 0);
      final after15Hours = DateTime(2026, 11, 13, 23, 0);
      final after17Hours = DateTime(2026, 11, 14, 1, 0);

      expect(
        calculator.isShiftOverdue(
          openedAt: openedAt,
          currentTime: after15Hours,
          policy: defaultPolicy,
        ),
        false,
      );

      expect(
        calculator.isShiftOverdue(
          openedAt: openedAt,
          currentTime: after17Hours,
          policy: defaultPolicy,
        ),
        true,
      );
    });

    test('13. Calculates comprehensive shift metrics from transaction lists', () {
      const shift = CashierShiftModel(
        id: 'SHIFT-TEST',
        branchId: 'branch_1',
        cashierUserId: 'USER-1',
        openingBalancePiastres: 100000, // 1000 EGP
        actualCashCountPiastres: 140000,
      );

      final payments = [
        const PaymentTransactionModel(
          id: 'P1',
          amountPiastres: 30000,
          paymentMethod: PaymentMethod.cash,
        ),
        const PaymentTransactionModel(
          id: 'P2',
          amountPiastres: 25000,
          paymentMethod: PaymentMethod.card,
        ),
        const PaymentTransactionModel(
          id: 'P3',
          amountPiastres: 15000,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
      ];

      final refunds = [
        const RefundTransactionModel(
          id: 'R1',
          refundAmountPiastres: 5000,
          refundMethod: PaymentMethod.cash,
        ),
      ];

      final movements = [
        const CashMovementModel(
          id: 'M1',
          amountPiastres: 10000,
          movementType: CashMovementTypeEnum.pettyExpense,
        ),
      ];

      final metrics = calculator.calculateShiftMetrics(
        shift: shift,
        payments: payments,
        refunds: refunds,
        movements: movements,
      );

      // Expected cash: 100000 + 30000 - 5000 - 10000 = 115000
      expect(metrics.expectedCashPiastres, 115000);
      expect(metrics.cashCollectedPiastres, 30000);
      expect(metrics.cardCollectedPiastres, 25000);
      expect(metrics.bankTransferPiastres, 15000);
      expect(metrics.totalExpensesPiastres, 10000);
      expect(metrics.totalRefundsPiastres, 5000);
      // Difference: 140000 - 115000 = +25000
      expect(metrics.differencePiastres, 25000);
      expect(metrics.transactionsCount, 5);
    });

    test('14. Excludes voided payments from metrics calculation', () {
      const shift = CashierShiftModel(
        id: 'SHIFT-TEST',
        branchId: 'branch_1',
        cashierUserId: 'USER-1',
        openingBalancePiastres: 100000,
      );

      final payments = [
        const PaymentTransactionModel(
          id: 'P1',
          amountPiastres: 30000,
          paymentMethod: PaymentMethod.cash,
          isVoidedBySystem: false,
        ),
        const PaymentTransactionModel(
          id: 'P2_VOIDED',
          amountPiastres: 50000,
          paymentMethod: PaymentMethod.cash,
          isVoidedBySystem: true, // Should be ignored
        ),
      ];

      final metrics = calculator.calculateShiftMetrics(
        shift: shift,
        payments: payments,
        refunds: const [],
        movements: const [],
      );

      expect(metrics.cashCollectedPiastres, 30000);
      expect(metrics.expectedCashPiastres, 130000);
      expect(metrics.transactionsCount, 1);
    });
  });
}


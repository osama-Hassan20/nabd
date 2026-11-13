import '../../data/models/cash_movement_model.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/cashier_summary_metrics_model.dart';
import '../../data/models/enums/cash_movement_type_enum.dart';
import '../../data/models/enums/shift_status_enum.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/refund_transaction_model.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../contracts/cashier_policy.dart';

class CashierShiftCalculator {
  const CashierShiftCalculator();

  /// Calculates the expected cash in drawer based on cash-only movements.
  /// Non-cash transactions (card, bank transfer) MUST NOT affect this value.
  int calculateExpectedCashPiastres({
    required int openingBalancePiastres,
    required int cashCollectedPiastres,
    required int cashRefundedPiastres,
    required int pettyExpensesPiastres,
    int capitalInjectionPiastres = 0,
    int bankDepositPiastres = 0,
    int ownerWithdrawalPiastres = 0,
  }) {
    return openingBalancePiastres +
        cashCollectedPiastres -
        cashRefundedPiastres -
        pettyExpensesPiastres +
        capitalInjectionPiastres -
        bankDepositPiastres -
        ownerWithdrawalPiastres;
  }

  /// Calculates the difference between actual cash count and expected cash in piastres.
  /// Negative result indicates a shortage; positive indicates a surplus.
  int calculateDifferencePiastres({
    required int actualCashCountPiastres,
    required int expectedCashPiastres,
  }) {
    return actualCashCountPiastres - expectedCashPiastres;
  }

  /// Determines the shift status upon closure.
  /// If shortage exceeds [CashierPolicy.maxUnapprovedShortagePiastres], the shift
  /// requires manager approval ([ShiftStatusEnum.closedPendingApproval]).
  ShiftStatusEnum determineCloseShiftStatus({
    required int differencePiastres,
    required CashierPolicy policy,
  }) {
    if (differencePiastres < 0 &&
        differencePiastres.abs() > policy.maxUnapprovedShortagePiastres) {
      return ShiftStatusEnum.closedPendingApproval;
    }
    return ShiftStatusEnum.closed;
  }

  /// Checks if a shift has exceeded the maximum age policy (default 16 hours).
  bool isShiftOverdue({
    required DateTime openedAt,
    DateTime? currentTime,
    required CashierPolicy policy,
  }) {
    final now = currentTime ?? CairoTimeHelper.now();
    final elapsed = now.difference(openedAt);
    return elapsed.inHours >= policy.maxShiftAgeHours;
  }

  /// Calculates comprehensive metrics for a shift from its transaction lists.
  CashierSummaryMetricsModel calculateShiftMetrics({
    required CashierShiftModel shift,
    required List<PaymentTransactionModel> payments,
    required List<RefundTransactionModel> refunds,
    required List<CashMovementModel> movements,
  }) {
    int cashCollected = 0;
    int cardCollected = 0;
    int bankTransferCollected = 0;
    int cashRefunded = 0;
    int nonCashRefunded = 0;
    int pettyExpenses = 0;
    int capitalInjections = 0;
    int bankDeposits = 0;
    int ownerWithdrawals = 0;

    // Filter out voided payments
    for (final p in payments) {
      if (p.isVoidedBySystem == true) continue;
      final amount = p.amountPiastres ?? 0;
      final method = p.paymentMethod;
      if (method == PaymentMethod.cash) {
        cashCollected += amount;
      } else if (method == PaymentMethod.card) {
        cardCollected += amount;
      } else if (method == PaymentMethod.bankTransfer) {
        bankTransferCollected += amount;
      }
    }

    // Process refunds
    for (final r in refunds) {
      final amount = r.refundAmountPiastres ?? 0;
      final method = r.refundMethod;
      if (method == PaymentMethod.cash) {
        cashRefunded += amount;
      } else {
        nonCashRefunded += amount;
      }
    }

    // Process cash drawer movements
    for (final m in movements) {
      final amount = m.amountPiastres ?? 0;
      final type = m.movementType;
      if (type == CashMovementTypeEnum.pettyExpense) {
        pettyExpenses += amount;
      } else if (type == CashMovementTypeEnum.capitalInjection) {
        capitalInjections += amount;
      } else if (type == CashMovementTypeEnum.bankDeposit) {
        bankDeposits += amount;
      } else if (type == CashMovementTypeEnum.ownerWithdrawal) {
        ownerWithdrawals += amount;
      }
    }

    final opening = shift.openingBalancePiastres ?? 0;
    final expectedCash = calculateExpectedCashPiastres(
      openingBalancePiastres: opening,
      cashCollectedPiastres: cashCollected,
      cashRefundedPiastres: cashRefunded,
      pettyExpensesPiastres: pettyExpenses,
      capitalInjectionPiastres: capitalInjections,
      bankDepositPiastres: bankDeposits,
      ownerWithdrawalPiastres: ownerWithdrawals,
    );

    return CashierSummaryMetricsModel(
      openingBalancePiastres: opening,
      expectedCashPiastres: expectedCash,
      actualCashPiastres: shift.actualCashCountPiastres,
      differencePiastres: shift.actualCashCountPiastres != null
          ? calculateDifferencePiastres(
              actualCashCountPiastres: shift.actualCashCountPiastres!,
              expectedCashPiastres: expectedCash,
            )
          : null,
      cashCollectedPiastres: cashCollected,
      cardCollectedPiastres: cardCollected,
      bankTransferPiastres: bankTransferCollected,
      totalExpensesPiastres: pettyExpenses,
      totalRefundsPiastres: cashRefunded + nonCashRefunded,
      transactionsCount: payments.where((p) => p.isVoidedBySystem != true).length +
          refunds.length +
          movements.length,
    );
  }
}

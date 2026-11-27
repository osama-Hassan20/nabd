import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/cashier/data/models/cash_movement_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_summary_metrics_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/data/models/refund_transaction_model.dart';

class CashierLocalHandler {
  CashierLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'cashier/shifts/current', (req) async {
      final branchId = req.queryParameters['branchId']?.toString();
      final cashierUserId = req.queryParameters['cashierUserId']?.toString();
      final matches = router.db
          .collection('cashierShifts')
          .map((e) => CashierShiftModel.fromJson(e))
          .where((s) =>
              (branchId == null || s.branchId == branchId) &&
              (cashierUserId == null || s.cashierUserId == cashierUserId) &&
              s.status == ShiftStatusEnum.open)
          .toList();
      if (matches.isEmpty) return LocalServerRouter.ok(null);
      return LocalServerRouter.ok(matches.last.toJson());
    });

    router.register('GET', 'cashier/shifts', (req) async {
      final branchId = req.queryParameters['branchId']?.toString();
      final cashierUserId = req.queryParameters['cashierUserId']?.toString();
      final list = router.db.collection('cashierShifts').where((s) {
        if (branchId != null && s['branchId'] != branchId) return false;
        if (cashierUserId != null && s['cashierUserId'] != cashierUserId) {
          return false;
        }
        return true;
      }).toList();
      return LocalServerRouter.ok(list.reversed.toList());
    });

    router.register('POST', 'cashier/shifts/open', (req) async {
      final branchId = req.body['branchId']?.toString() ?? '';
      final cashierUserId = req.body['cashierUserId']?.toString() ?? '';
      final cashierName = req.body['cashierName']?.toString() ?? '';
      final openingBalancePiastres =
          (req.body['openingBalancePiastres'] as num?)?.toInt() ?? 0;

      final shifts = router.db.collection('cashierShifts');
      final existing = shifts.map((e) => CashierShiftModel.fromJson(e)).any(
            (s) =>
                s.branchId == branchId &&
                s.cashierUserId == cashierUserId &&
                s.status == ShiftStatusEnum.open,
          );
      if (existing) {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'SHIFT_ALREADY_OPEN',
          'cashier_validation_shift_already_open',
        );
      }

      final now = CairoTimeHelper.now();
      final today = DateTime(now.year, now.month, now.day);
      final shift = CashierShiftModel(
        id: 'SHIFT-${branchId.replaceAll('branch_', '')}-${now.millisecondsSinceEpoch}',
        branchId: branchId,
        cashierUserId: cashierUserId,
        cashierName: cashierName,
        status: ShiftStatusEnum.open,
        openedAt: now,
        businessDate: today,
        openingBalancePiastres: openingBalancePiastres,
        expectedCashPiastres: openingBalancePiastres,
        totalCashCollectedPiastres: 0,
        totalCardCollectedPiastres: 0,
        totalBankTransferPiastres: 0,
        totalExpensesPiastres: 0,
        totalRefundsPiastres: 0,
        totalCapitalInjectionsPiastres: 0,
        totalBankDepositsPiastres: 0,
        totalOwnerWithdrawalsPiastres: 0,
        transactionCount: 0,
      );
      final json = shift.toJson();
      shifts.add(json);
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'cashier/shifts/{id}/close', (req) async {
      final id = req.pathParams['id']!;
      final shifts = router.db.collection('cashierShifts');
      final idx = shifts.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'shift_not_found');
      }
      final current = CashierShiftModel.fromJson(shifts[idx]);
      final actualCashCountPiastres =
          (req.body['actualCashCountPiastres'] as num?)?.toInt() ?? 0;
      final closingNotes = req.body['closingNotes']?.toString();
      final shortageReason = req.body['shortageReason']?.toString();
      final expected = current.expectedCashPiastres ?? 0;
      final diff = actualCashCountPiastres - expected;
      final isPending = diff.abs() > 5000;

      final updated = current.copyWith(
        status: isPending
            ? ShiftStatusEnum.closedPendingApproval
            : ShiftStatusEnum.closed,
        closedAt: CairoTimeHelper.now(),
        actualCashCountPiastres: actualCashCountPiastres,
        cashDifferencePiastres: diff,
        closingNotes: closingNotes,
        shortageReason: shortageReason,
        isShortageApproved: !isPending,
      );
      final json = updated.toJson();
      shifts[idx] = json;
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'cashier/shifts/{id}/force-close', (req) async {
      final id = req.pathParams['id']!;
      final shifts = router.db.collection('cashierShifts');
      final idx = shifts.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'shift_not_found');
      }
      final current = CashierShiftModel.fromJson(shifts[idx]);
      final updated = current.copyWith(
        status: ShiftStatusEnum.forceClosed,
        closedAt: CairoTimeHelper.now(),
        forceClosedByUserId: req.body['performedByUserId']?.toString(),
        forceCloseReason: req.body['reason']?.toString(),
      );
      final json = updated.toJson();
      shifts[idx] = json;
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'cashier/shifts/{id}/approve-shortage',
        (req) async {
      final id = req.pathParams['id']!;
      final shifts = router.db.collection('cashierShifts');
      final idx = shifts.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'shift_not_found');
      }
      final current = CashierShiftModel.fromJson(shifts[idx]);
      final updated = current.copyWith(
        status: ShiftStatusEnum.closed,
        isShortageApproved: true,
        isOwnerSelfApproved: req.body['isOwnerSelfApproved'] == true,
        shortageApprovedByUserId: req.body['approvedByUserId']?.toString(),
        shortageApprovedAt: CairoTimeHelper.now(),
        shortageReason: req.body['reason']?.toString(),
      );
      final json = updated.toJson();
      shifts[idx] = json;
      router.db.persist();
      return LocalServerRouter.ok(json);
    });

    router.register('POST', 'cashier/payments', (req) async {
      final clientRequestId = req.body['clientRequestId']?.toString() ?? '';
      final shiftId = req.body['shiftId']?.toString() ?? '';
      final branchId = req.body['branchId']?.toString() ?? '';
      final bookingId = req.body['bookingId']?.toString() ?? '';
      final patientId = req.body['patientId']?.toString() ?? '';
      final patientName = req.body['patientName']?.toString() ?? '';
      final amountPiastres = (req.body['amountPiastres'] as num?)?.toInt() ?? 0;
      final paymentMethodStr = req.body['paymentMethod']?.toString() ?? 'cash';
      final referenceNumber = req.body['referenceNumber']?.toString();
      final cashierUserId = req.body['cashierUserId']?.toString() ?? '';
      final cashierName = req.body['cashierName']?.toString() ?? '';
      final notes = req.body['notes']?.toString();

      final idemp = router.db.collection('cashierIdempotency');
      final existingIdx =
          idemp.indexWhere((e) => e['clientRequestId'] == clientRequestId);
      if (existingIdx != -1) {
        final cached = idemp[existingIdx];
        if (cached['amountPiastres'] == amountPiastres &&
            cached['bookingId'] == bookingId &&
            cached['paymentMethod'] == paymentMethodStr) {
          return LocalServerRouter.ok(cached['payment']);
        }
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'IDEMPOTENCY_CONFLICT',
          'idempotency_conflict',
        );
      }

      final shifts = router.db.collection('cashierShifts');
      final shiftIdx = shifts.indexWhere((s) => s['id'] == shiftId);
      if (shiftIdx == -1) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'cashier_validation_shift_required',
        );
      }

      final method = PaymentMethod.fromValue(paymentMethodStr);
      final payment = PaymentTransactionModel(
        id: 'PAY-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        clientRequestId: clientRequestId,
        shiftId: shiftId,
        branchId: branchId,
        bookingId: bookingId,
        patientId: patientId,
        patientName: patientName,
        amountPiastres: amountPiastres,
        paymentMethod: method,
        referenceNumber: referenceNumber,
        cashierUserId: cashierUserId,
        cashierName: cashierName,
        createdAt: CairoTimeHelper.now(),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
        notes: notes,
      );
      final paymentJson = payment.toJson();
      router.db.collection('cashierPayments').add(paymentJson);

      final shift = CashierShiftModel.fromJson(shifts[shiftIdx]);
      final isCash = method == PaymentMethod.cash;
      final isCard = method == PaymentMethod.card;
      final isBank = method == PaymentMethod.bankTransfer;
      shifts[shiftIdx] = shift
          .copyWith(
            expectedCashPiastres: (shift.expectedCashPiastres ?? 0) +
                (isCash ? amountPiastres : 0),
            totalCashCollectedPiastres:
                (shift.totalCashCollectedPiastres ?? 0) +
                    (isCash ? amountPiastres : 0),
            totalCardCollectedPiastres:
                (shift.totalCardCollectedPiastres ?? 0) +
                    (isCard ? amountPiastres : 0),
            totalBankTransferPiastres:
                (shift.totalBankTransferPiastres ?? 0) +
                    (isBank ? amountPiastres : 0),
            transactionCount: (shift.transactionCount ?? 0) + 1,
          )
          .toJson();

      idemp.add({
        'clientRequestId': clientRequestId,
        'amountPiastres': amountPiastres,
        'bookingId': bookingId,
        'paymentMethod': paymentMethodStr,
        'payment': paymentJson,
      });

      router.db.persist();
      return LocalServerRouter.ok(paymentJson);
    });

    router.register('POST', 'cashier/payments/{id}/refund', (req) async {
      final originalPaymentId = req.pathParams['id']!;
      final payments = router.db.collection('cashierPayments');
      final payIdx = payments.indexWhere((p) => p['id'] == originalPaymentId);
      if (payIdx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'payment_not_found');
      }

      final origPayment = PaymentTransactionModel.fromJson(payments[payIdx]);
      final refundAmountPiastres =
          (req.body['refundAmountPiastres'] as num?)?.toInt() ?? 0;
      final currentRefunded = origPayment.refundedAmountPiastres ?? 0;
      final maxAvailable = (origPayment.amountPiastres ?? 0) - currentRefunded;
      if (refundAmountPiastres > maxAvailable) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'refund_exceeds_available_amount',
        );
      }

      final shiftId = req.body['shiftId']?.toString() ?? '';
      final method = PaymentMethod.fromValue(
          req.body['refundMethod']?.toString() ?? 'cash');
      final refund = RefundTransactionModel(
        id: 'REF-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        clientRequestId: req.body['clientRequestId']?.toString() ?? '',
        originalPaymentId: originalPaymentId,
        shiftId: shiftId,
        branchId: req.body['branchId']?.toString() ?? '',
        bookingId: req.body['bookingId']?.toString() ?? '',
        patientId: req.body['patientId']?.toString() ?? '',
        refundAmountPiastres: refundAmountPiastres,
        refundMethod: method,
        reason: req.body['reason']?.toString() ?? '',
        authorizedByUserId: req.body['authorizedByUserId']?.toString() ?? '',
        authorizedByName: req.body['authorizedByName']?.toString() ?? '',
        createdAt: CairoTimeHelper.now(),
      );
      final refundJson = refund.toJson();
      router.db.collection('cashierRefunds').add(refundJson);

      payments[payIdx] = origPayment
          .copyWith(
            isRefunded: true,
            refundedAmountPiastres: currentRefunded + refundAmountPiastres,
          )
          .toJson();

      final shifts = router.db.collection('cashierShifts');
      final shiftIdx = shifts.indexWhere((s) => s['id'] == shiftId);
      if (shiftIdx != -1) {
        final shift = CashierShiftModel.fromJson(shifts[shiftIdx]);
        final isCash = method == PaymentMethod.cash;
        shifts[shiftIdx] = shift
            .copyWith(
              expectedCashPiastres: (shift.expectedCashPiastres ?? 0) -
                  (isCash ? refundAmountPiastres : 0),
              totalRefundsPiastres: (shift.totalRefundsPiastres ?? 0) +
                  (isCash ? refundAmountPiastres : 0),
              transactionCount: (shift.transactionCount ?? 0) + 1,
            )
            .toJson();
      }

      router.db.persist();
      return LocalServerRouter.ok(refundJson);
    });

    router.register('POST', 'cashier/movements', (req) async {
      final shiftId = req.body['shiftId']?.toString() ?? '';
      final shifts = router.db.collection('cashierShifts');
      final shiftIdx = shifts.indexWhere((s) => s['id'] == shiftId);
      if (shiftIdx == -1) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'cashier_validation_shift_required',
        );
      }

      final amountPiastres = (req.body['amountPiastres'] as num?)?.toInt() ?? 0;
      final type = CashMovementTypeEnum.fromValue(
          req.body['movementType']?.toString() ?? 'petty_expense');
      final movement = CashMovementModel(
        id: 'CSM-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        clientRequestId: req.body['clientRequestId']?.toString() ?? '',
        shiftId: shiftId,
        branchId: req.body['branchId']?.toString() ?? '',
        movementType: type,
        amountPiastres: amountPiastres,
        reason: req.body['reason']?.toString() ?? '',
        recipientName: req.body['recipientName']?.toString(),
        performedByUserId: req.body['performedByUserId']?.toString() ?? '',
        createdAt: CairoTimeHelper.now(),
      );
      final movementJson = movement.toJson();
      router.db.collection('cashierMovements').add(movementJson);

      final shift = CashierShiftModel.fromJson(shifts[shiftIdx]);
      int expected = shift.expectedCashPiastres ?? 0;
      int expenses = shift.totalExpensesPiastres ?? 0;
      int capital = shift.totalCapitalInjectionsPiastres ?? 0;
      int deposits = shift.totalBankDepositsPiastres ?? 0;
      int withdrawals = shift.totalOwnerWithdrawalsPiastres ?? 0;

      switch (type) {
        case CashMovementTypeEnum.pettyExpense:
          expected -= amountPiastres;
          expenses += amountPiastres;
          break;
        case CashMovementTypeEnum.capitalInjection:
          expected += amountPiastres;
          capital += amountPiastres;
          break;
        case CashMovementTypeEnum.bankDeposit:
          expected -= amountPiastres;
          deposits += amountPiastres;
          break;
        case CashMovementTypeEnum.ownerWithdrawal:
          expected -= amountPiastres;
          withdrawals += amountPiastres;
          break;
      }

      shifts[shiftIdx] = shift
          .copyWith(
            expectedCashPiastres: expected,
            totalExpensesPiastres: expenses,
            totalCapitalInjectionsPiastres: capital,
            totalBankDepositsPiastres: deposits,
            totalOwnerWithdrawalsPiastres: withdrawals,
            transactionCount: (shift.transactionCount ?? 0) + 1,
          )
          .toJson();

      router.db.persist();
      return LocalServerRouter.ok(movementJson);
    });

    router.register('GET', 'cashier/shifts/{id}/metrics', (req) async {
      final id = req.pathParams['id']!;
      final shifts = router.db.collection('cashierShifts');
      final idx = shifts.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'shift_not_found');
      }
      final shift = CashierShiftModel.fromJson(shifts[idx]);
      final metrics = CashierSummaryMetricsModel(
        openingBalancePiastres: shift.openingBalancePiastres,
        expectedCashPiastres: shift.expectedCashPiastres,
        actualCashPiastres: shift.actualCashCountPiastres,
        differencePiastres: shift.cashDifferencePiastres,
        cashCollectedPiastres: shift.totalCashCollectedPiastres,
        cardCollectedPiastres: shift.totalCardCollectedPiastres,
        bankTransferPiastres: shift.totalBankTransferPiastres,
        totalExpensesPiastres: shift.totalExpensesPiastres,
        totalRefundsPiastres: shift.totalRefundsPiastres,
        transactionsCount: shift.transactionCount,
      );
      return LocalServerRouter.ok(metrics.toJson());
    });

    router.register('GET', 'cashier/shifts/{id}/payments', (req) async {
      final shiftId = req.pathParams['id']!;
      final includeVoided =
          req.queryParameters['includeVoided'] == true ||
          req.queryParameters['includeVoided'] == 'true';
      final list = router.db.collection('cashierPayments').where((p) {
        if (p['shiftId'] != shiftId) return false;
        if (!includeVoided && p['isVoidedBySystem'] == true) return false;
        return true;
      }).toList();
      return LocalServerRouter.ok(list.reversed.toList());
    });

    router.register('GET', 'bookings/{id}/payments', (req) async {
      final bookingId = req.pathParams['id']!;
      final list = router.db
          .collection('cashierPayments')
          .where((p) =>
              p['bookingId'] == bookingId && p['isVoidedBySystem'] != true)
          .toList();
      return LocalServerRouter.ok(list);
    });

    router.register('GET', 'patients/{id}/payments', (req) async {
      final patientId = req.pathParams['id']!;
      final list = router.db
          .collection('cashierPayments')
          .where((p) =>
              p['patientId'] == patientId && p['isVoidedBySystem'] != true)
          .toList();
      return LocalServerRouter.ok(list);
    });

    router.register('POST', 'cashier/payments/{id}/void', (req) async {
      final paymentId = req.pathParams['id']!;
      final payments = router.db.collection('cashierPayments');
      final idx = payments.indexWhere((p) => p['id'] == paymentId);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(
            req.path, 404, 'NOT_FOUND', 'payment_not_found');
      }
      final payment = PaymentTransactionModel.fromJson(payments[idx]);
      payments[idx] = payment.copyWith(isVoidedBySystem: true).toJson();

      final shifts = router.db.collection('cashierShifts');
      final shiftIdx = shifts.indexWhere((s) => s['id'] == payment.shiftId);
      if (shiftIdx != -1) {
        final shift = CashierShiftModel.fromJson(shifts[shiftIdx]);
        final amount = payment.amountPiastres ?? 0;
        final isCash = payment.paymentMethod == PaymentMethod.cash;
        final isCard = payment.paymentMethod == PaymentMethod.card;
        final isBank = payment.paymentMethod == PaymentMethod.bankTransfer;
        shifts[shiftIdx] = shift
            .copyWith(
              expectedCashPiastres:
                  (shift.expectedCashPiastres ?? 0) - (isCash ? amount : 0),
              totalCashCollectedPiastres:
                  (shift.totalCashCollectedPiastres ?? 0) -
                      (isCash ? amount : 0),
              totalCardCollectedPiastres:
                  (shift.totalCardCollectedPiastres ?? 0) -
                      (isCard ? amount : 0),
              totalBankTransferPiastres:
                  (shift.totalBankTransferPiastres ?? 0) -
                      (isBank ? amount : 0),
              transactionCount:
                  ((shift.transactionCount ?? 1) - 1).clamp(0, 999999),
            )
            .toJson();
      }
      router.db.persist();
      return LocalServerRouter.ok({'voided': true});
    });
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/enums/payment_method.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../domain/repo/cashier_repo.dart';
import '../models/cash_movement_model.dart';
import '../models/cashier_shift_model.dart';
import '../models/cashier_summary_metrics_model.dart';
import '../models/enums/cash_movement_type_enum.dart';
import '../models/enums/shift_status_enum.dart';
import '../models/payment_transaction_model.dart';
import '../models/refund_transaction_model.dart';

class CashierRepoImpl implements CashierRepo {
  CashierRepoImpl({bool seedInitialData = true}) {
    if (seedInitialData) {
      _initSeedData();
    }
  }

  final List<CashierShiftModel> _shifts = [];
  final List<PaymentTransactionModel> _payments = [];
  final List<RefundTransactionModel> _refunds = [];
  final List<CashMovementModel> _movements = [];

  // Idempotency cache: clientRequestId -> Map with params & result
  final Map<String, Map<String, dynamic>> _idempotencyStore = {};

  void _initSeedData() {
    final now = CairoTimeHelper.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Shift for branch_1 (فرع المعادي)
    final shiftCairo = CashierShiftModel(
      id: 'SHIFT-CAI-01',
      branchId: 'branch_1',
      cashierUserId: 'USER-REC',
      cashierName: 'منى إبراهيم',
      status: ShiftStatusEnum.open,
      openedAt: now.subtract(const Duration(hours: 4)),
      businessDate: today,
      openingBalancePiastres: 100000, // 1000 EGP
      expectedCashPiastres: 205000,   // 1000 + 1200 - 150 = 2050 EGP
      actualCashCountPiastres: null,
      cashDifferencePiastres: null,
      totalCashCollectedPiastres: 120000, // 1200 EGP
      totalCardCollectedPiastres: 65000,  // 650 EGP
      totalBankTransferPiastres: 0,
      totalExpensesPiastres: 15000,       // 150 EGP
      totalRefundsPiastres: 0,
      totalCapitalInjectionsPiastres: 0,
      totalBankDepositsPiastres: 0,
      totalOwnerWithdrawalsPiastres: 0,
      transactionCount: 8,
    );
    _shifts.add(shiftCairo);

    // 2. Payments for shiftCairo
    _payments.addAll([
      // MED-101: 300 EGP card POS
      PaymentTransactionModel(
        id: 'PAY-CAI-01',
        clientRequestId: 'REQ-SEED-101',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-101',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.card,
        referenceNumber: 'POS-89214',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 50)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-103: 450 EGP cash
      PaymentTransactionModel(
        id: 'PAY-CAI-02',
        clientRequestId: 'REQ-SEED-103',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-103',
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        amountPiastres: 45000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-104: 150 EGP cash
      PaymentTransactionModel(
        id: 'PAY-CAI-03',
        clientRequestId: 'REQ-SEED-104',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-104',
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-106: 350 EGP card POS
      PaymentTransactionModel(
        id: 'PAY-CAI-04',
        clientRequestId: 'REQ-SEED-106',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-106',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 35000,
        paymentMethod: PaymentMethod.card,
        referenceNumber: 'POS-89222',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-107: 150 EGP cash (partially paid, 150 remaining)
      PaymentTransactionModel(
        id: 'PAY-CAI-05',
        clientRequestId: 'REQ-SEED-107',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-107',
        patientId: 'PAT-000102',
        patientName: 'يوسف إبراهيم المنصوري',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-109: 150 EGP cash
      PaymentTransactionModel(
        id: 'PAY-CAI-06',
        clientRequestId: 'REQ-SEED-109',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-109',
        patientId: 'PAT-000104',
        patientName: 'طارق عبد الرحمن علي',
        amountPiastres: 15000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
      // MED-111: 300 EGP cash (no-show advance)
      PaymentTransactionModel(
        id: 'PAY-CAI-07',
        clientRequestId: 'REQ-SEED-111',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        bookingId: 'MED-111',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد عبد الله',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
    ]);

    // 3. Petty expense for shiftCairo
    _movements.add(
      CashMovementModel(
        id: 'CSM-CAI-01',
        clientRequestId: 'REQ-SEED-CSM-01',
        shiftId: 'SHIFT-CAI-01',
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense,
        amountPiastres: 15000, // 150 EGP
        reason: 'شراء مستلزمات ضيافة ومياه للعيادة',
        recipientName: 'عامل الخدمات',
        performedByUserId: 'USER-REC',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 45)),
      ),
    );

    // 4. Shift for branch_2 (فرع مدينة نصر)
    final shiftNasr = CashierShiftModel(
      id: 'SHIFT-NASR-01',
      branchId: 'branch_2',
      cashierUserId: 'USER-REC-2',
      cashierName: 'هدى مصطفى',
      status: ShiftStatusEnum.open,
      openedAt: now.subtract(const Duration(hours: 3)),
      businessDate: today,
      openingBalancePiastres: 50000, // 500 EGP
      expectedCashPiastres: 50000,   // Bank transfer does not affect drawer
      actualCashCountPiastres: null,
      cashDifferencePiastres: null,
      totalCashCollectedPiastres: 0,
      totalCardCollectedPiastres: 0,
      totalBankTransferPiastres: 30000, // 300 EGP
      totalExpensesPiastres: 0,
      totalRefundsPiastres: 0,
      totalCapitalInjectionsPiastres: 0,
      totalBankDepositsPiastres: 0,
      totalOwnerWithdrawalsPiastres: 0,
      transactionCount: 1,
    );
    _shifts.add(shiftNasr);

    // MED-108: 300 EGP bankTransfer
    _payments.add(
      PaymentTransactionModel(
        id: 'PAY-NASR-01',
        clientRequestId: 'REQ-SEED-108',
        shiftId: 'SHIFT-NASR-01',
        branchId: 'branch_2',
        bookingId: 'MED-108',
        patientId: 'PAT-000103',
        patientName: 'مريم محمود حسن',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.bankTransfer,
        referenceNumber: 'INSTA-99120',
        cashierUserId: 'USER-REC-2',
        cashierName: 'هدى مصطفى',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRefunded: false,
        refundedAmountPiastres: 0,
        isVoidedBySystem: false,
      ),
    );

    // 5. Shift for branch_3 (فرع التجمع الخامس)
    final shiftTag = CashierShiftModel(
      id: 'SHIFT-TAG-01',
      branchId: 'branch_3',
      cashierUserId: 'USER-REC-TAG',
      cashierName: 'سارة العزازي',
      status: ShiftStatusEnum.open,
      openedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
      businessDate: today,
      openingBalancePiastres: 50000, // 500 EGP
      expectedCashPiastres: 50000,   // 500 EGP
      actualCashCountPiastres: null,
      cashDifferencePiastres: null,
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
    _shifts.add(shiftTag);
  }

  @override
  Future<Either<Failures, CashierShiftModel?>> getCurrentShift({
    required String branchId,
    required String cashierUserId,
  }) async {
    try {
      final matches = _shifts.where(
        (s) =>
            s.branchId == branchId &&
            s.cashierUserId == cashierUserId &&
            s.status == ShiftStatusEnum.open,
      );
      if (matches.isEmpty) return const Right(null);
      return Right(matches.last);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<CashierShiftModel>>> getShiftHistory({
    required String branchId,
    String? cashierUserId,
  }) async {
    try {
      final list = _shifts.where((s) {
        if (s.branchId != branchId) return false;
        if (cashierUserId != null && s.cashierUserId != cashierUserId) {
          return false;
        }
        return true;
      }).toList();
      return Right(list.reversed.toList());
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> openShift({
    required String branchId,
    required String cashierUserId,
    required String cashierName,
    required int openingBalancePiastres,
    String? suggestedOpeningBalanceDiffReason,
  }) async {
    try {
      final existing = _shifts.any(
        (s) =>
            s.branchId == branchId &&
            s.cashierUserId == cashierUserId &&
            s.status == ShiftStatusEnum.open,
      );
      if (existing) {
        return const Left(
          ServerFailure(errMessage: 'cashier_validation_shift_already_open'),
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

      _shifts.add(shift);
      return Right(shift);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> closeShift({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  }) async {
    try {
      final idx = _shifts.indexWhere((s) => s.id == shiftId);
      if (idx == -1) {
        return const Left(ServerFailure(errMessage: 'shift_not_found'));
      }

      final current = _shifts[idx];
      final expected = current.expectedCashPiastres ?? 0;
      final diff = actualCashCountPiastres - expected;
      final isPending = diff.abs() > 5000; // maxUnapprovedShortagePiastres = 50 EGP

      final updated = current.copyWith(
        status: isPending
            ? ShiftStatusEnum.closedPendingApproval
            : ShiftStatusEnum.closed,
        closedAt: CairoTimeHelper.now(),
        actualCashCountPiastres: actualCashCountPiastres,
        cashDifferencePiastres: diff,
        closingNotes: closingNotes,
        shortageReason: shortageReason,
        isShortageApproved: isPending ? false : true,
      );

      _shifts[idx] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> forceCloseShift({
    required String shiftId,
    required String performedByUserId,
    required String reason,
  }) async {
    try {
      final idx = _shifts.indexWhere((s) => s.id == shiftId);
      if (idx == -1) {
        return const Left(ServerFailure(errMessage: 'shift_not_found'));
      }

      final current = _shifts[idx];
      final updated = current.copyWith(
        status: ShiftStatusEnum.forceClosed,
        closedAt: CairoTimeHelper.now(),
        forceClosedByUserId: performedByUserId,
        forceCloseReason: reason,
      );

      _shifts[idx] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashierShiftModel>> approveShortage({
    required String shiftId,
    required String approvedByUserId,
    required String reason,
    bool isOwnerSelfApproved = false,
  }) async {
    try {
      final idx = _shifts.indexWhere((s) => s.id == shiftId);
      if (idx == -1) {
        return const Left(ServerFailure(errMessage: 'shift_not_found'));
      }

      final current = _shifts[idx];
      final updated = current.copyWith(
        status: ShiftStatusEnum.closed,
        isShortageApproved: true,
        isOwnerSelfApproved: isOwnerSelfApproved,
        shortageApprovedByUserId: approvedByUserId,
        shortageApprovedAt: CairoTimeHelper.now(),
        shortageReason: reason,
      );

      _shifts[idx] = updated;
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, PaymentTransactionModel>> recordPayment({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    String? referenceNumber,
    required String cashierUserId,
    required String cashierName,
    String? notes,
  }) async {
    try {
      // Idempotency check
      if (_idempotencyStore.containsKey(clientRequestId)) {
        final cached = _idempotencyStore[clientRequestId]!;
        if (cached['amountPiastres'] == amountPiastres &&
            cached['bookingId'] == bookingId &&
            cached['paymentMethod'] == paymentMethod) {
          return Right(cached['model'] as PaymentTransactionModel);
        } else {
          return const Left(
            ServerFailure(errMessage: 'idempotency_conflict'),
          );
        }
      }

      final shiftIdx = _shifts.indexWhere((s) => s.id == shiftId);
      if (shiftIdx == -1) {
        return const Left(
          ServerFailure(errMessage: 'cashier_validation_shift_required'),
        );
      }

      final method = PaymentMethod.fromValue(paymentMethod);
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

      _payments.add(payment);

      // Update shift totals
      final shift = _shifts[shiftIdx];
      final isCash = method == PaymentMethod.cash;
      final isCard = method == PaymentMethod.card;
      final isBank = method == PaymentMethod.bankTransfer;

      _shifts[shiftIdx] = shift.copyWith(
        expectedCashPiastres:
            (shift.expectedCashPiastres ?? 0) + (isCash ? amountPiastres : 0),
        totalCashCollectedPiastres:
            (shift.totalCashCollectedPiastres ?? 0) + (isCash ? amountPiastres : 0),
        totalCardCollectedPiastres:
            (shift.totalCardCollectedPiastres ?? 0) + (isCard ? amountPiastres : 0),
        totalBankTransferPiastres:
            (shift.totalBankTransferPiastres ?? 0) + (isBank ? amountPiastres : 0),
        transactionCount: (shift.transactionCount ?? 0) + 1,
      );

      // Save to idempotency store
      _idempotencyStore[clientRequestId] = {
        'amountPiastres': amountPiastres,
        'bookingId': bookingId,
        'paymentMethod': paymentMethod,
        'model': payment,
      };

      return Right(payment);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, RefundTransactionModel>> refundPayment({
    required String clientRequestId,
    required String originalPaymentId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required int refundAmountPiastres,
    required String refundMethod,
    required String reason,
    required String authorizedByUserId,
    required String authorizedByName,
  }) async {
    try {
      final payIdx = _payments.indexWhere((p) => p.id == originalPaymentId);
      if (payIdx == -1) {
        return const Left(ServerFailure(errMessage: 'payment_not_found'));
      }

      final origPayment = _payments[payIdx];
      final currentRefunded = origPayment.refundedAmountPiastres ?? 0;
      final maxAvailable = (origPayment.amountPiastres ?? 0) - currentRefunded;
      if (refundAmountPiastres > maxAvailable) {
        return const Left(
          ServerFailure(errMessage: 'refund_exceeds_available_amount'),
        );
      }

      final method = PaymentMethod.fromValue(refundMethod);
      final refund = RefundTransactionModel(
        id: 'REF-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        clientRequestId: clientRequestId,
        originalPaymentId: originalPaymentId,
        shiftId: shiftId,
        branchId: branchId,
        bookingId: bookingId,
        patientId: patientId,
        refundAmountPiastres: refundAmountPiastres,
        refundMethod: method,
        reason: reason,
        authorizedByUserId: authorizedByUserId,
        authorizedByName: authorizedByName,
        createdAt: CairoTimeHelper.now(),
      );

      _refunds.add(refund);

      // Mark payment as refunded
      final newRefundedTotal = currentRefunded + refundAmountPiastres;
      _payments[payIdx] = origPayment.copyWith(
        isRefunded: true,
        refundedAmountPiastres: newRefundedTotal,
      );

      // Adjust shift if cash
      final shiftIdx = _shifts.indexWhere((s) => s.id == shiftId);
      if (shiftIdx != -1) {
        final shift = _shifts[shiftIdx];
        final isCash = method == PaymentMethod.cash;
        _shifts[shiftIdx] = shift.copyWith(
          expectedCashPiastres:
              (shift.expectedCashPiastres ?? 0) - (isCash ? refundAmountPiastres : 0),
          totalRefundsPiastres:
              (shift.totalRefundsPiastres ?? 0) + (isCash ? refundAmountPiastres : 0),
          transactionCount: (shift.transactionCount ?? 0) + 1,
        );
      }

      return Right(refund);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashMovementModel>> recordCashMovement({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    required String performedByUserId,
  }) async {
    try {
      final shiftIdx = _shifts.indexWhere((s) => s.id == shiftId);
      if (shiftIdx == -1) {
        return const Left(
          ServerFailure(errMessage: 'cashier_validation_shift_required'),
        );
      }

      final type = CashMovementTypeEnum.fromValue(movementType);
      final movement = CashMovementModel(
        id: 'CSM-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        clientRequestId: clientRequestId,
        shiftId: shiftId,
        branchId: branchId,
        movementType: type,
        amountPiastres: amountPiastres,
        reason: reason,
        recipientName: recipientName,
        performedByUserId: performedByUserId,
        createdAt: CairoTimeHelper.now(),
      );

      _movements.add(movement);

      // Adjust shift drawer cash
      final shift = _shifts[shiftIdx];
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

      _shifts[shiftIdx] = shift.copyWith(
        expectedCashPiastres: expected,
        totalExpensesPiastres: expenses,
        totalCapitalInjectionsPiastres: capital,
        totalBankDepositsPiastres: deposits,
        totalOwnerWithdrawalsPiastres: withdrawals,
        transactionCount: (shift.transactionCount ?? 0) + 1,
      );

      return Right(movement);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, CashierSummaryMetricsModel>> getShiftMetrics({
    required String shiftId,
  }) async {
    try {
      final shift = _shifts.firstWhere(
        (s) => s.id == shiftId,
        orElse: () => const CashierShiftModel(),
      );
      if (shift.id == null) {
        return const Left(ServerFailure(errMessage: 'shift_not_found'));
      }

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

      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsForShift({
    required String shiftId,
    bool includeVoided = false,
  }) async {
    try {
      final list = _payments.where((p) {
        if (p.shiftId != shiftId) return false;
        if (!includeVoided && (p.isVoidedBySystem ?? false)) return false;
        return true;
      }).toList();
      return Right(list.reversed.toList());
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByBookingId({
    required String bookingId,
  }) async {
    try {
      final list = _payments
          .where((p) => p.bookingId == bookingId && !(p.isVoidedBySystem ?? false))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByPatientId({
    required String patientId,
  }) async {
    try {
      final list = _payments
          .where((p) => p.patientId == patientId && !(p.isVoidedBySystem ?? false))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> voidPaymentRollback({
    required String paymentId,
    required String reason,
  }) async {
    try {
      final idx = _payments.indexWhere((p) => p.id == paymentId);
      if (idx == -1) {
        return const Left(ServerFailure(errMessage: 'payment_not_found'));
      }

      final payment = _payments[idx];
      _payments[idx] = payment.copyWith(isVoidedBySystem: true);

      // Rollback shift totals
      final shiftIdx = _shifts.indexWhere((s) => s.id == payment.shiftId);
      if (shiftIdx != -1) {
        final shift = _shifts[shiftIdx];
        final amount = payment.amountPiastres ?? 0;
        final isCash = payment.paymentMethod == PaymentMethod.cash;
        final isCard = payment.paymentMethod == PaymentMethod.card;
        final isBank = payment.paymentMethod == PaymentMethod.bankTransfer;

        _shifts[shiftIdx] = shift.copyWith(
          expectedCashPiastres:
              (shift.expectedCashPiastres ?? 0) - (isCash ? amount : 0),
          totalCashCollectedPiastres:
              (shift.totalCashCollectedPiastres ?? 0) - (isCash ? amount : 0),
          totalCardCollectedPiastres:
              (shift.totalCardCollectedPiastres ?? 0) - (isCard ? amount : 0),
          totalBankTransferPiastres:
              (shift.totalBankTransferPiastres ?? 0) - (isBank ? amount : 0),
          transactionCount:
              ((shift.transactionCount ?? 1) - 1).clamp(0, 999999),
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}

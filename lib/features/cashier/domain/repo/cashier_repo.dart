import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/cash_movement_model.dart';
import '../../data/models/cashier_shift_model.dart';
import '../../data/models/cashier_summary_metrics_model.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/refund_transaction_model.dart';

abstract class CashierRepo {
  Future<Either<Failures, CashierShiftModel?>> getCurrentShift({
    required String branchId,
    required String cashierUserId,
  });

  Future<Either<Failures, List<CashierShiftModel>>> getShiftHistory({
    required String branchId,
    String? cashierUserId,
  });

  Future<Either<Failures, CashierShiftModel>> openShift({
    required String branchId,
    required String cashierUserId,
    required String cashierName,
    required int openingBalancePiastres,
    String? suggestedOpeningBalanceDiffReason,
  });

  Future<Either<Failures, CashierShiftModel>> closeShift({
    required String shiftId,
    required int actualCashCountPiastres,
    String? closingNotes,
    String? shortageReason,
  });

  Future<Either<Failures, CashierShiftModel>> forceCloseShift({
    required String shiftId,
    required String performedByUserId,
    required String reason,
  });

  Future<Either<Failures, CashierShiftModel>> approveShortage({
    required String shiftId,
    required String approvedByUserId,
    required String reason,
    bool isOwnerSelfApproved = false,
  });

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
  });

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
  });

  Future<Either<Failures, CashMovementModel>> recordCashMovement({
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String movementType,
    required int amountPiastres,
    required String reason,
    String? recipientName,
    required String performedByUserId,
  });

  Future<Either<Failures, CashierSummaryMetricsModel>> getShiftMetrics({
    required String shiftId,
  });

  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsForShift({
    required String shiftId,
  });

  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByBookingId({
    required String bookingId,
  });

  Future<Either<Failures, List<PaymentTransactionModel>>> getPaymentsByPatientId({
    required String patientId,
  });

  Future<Either<Failures, void>> voidPaymentRollback({
    required String paymentId,
    required String reason,
  });
}

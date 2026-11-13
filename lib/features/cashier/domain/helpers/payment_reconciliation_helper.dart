import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../bookings/data/models/enums/payment_status_enum.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../data/models/payment_transaction_model.dart';
import '../../data/models/refund_transaction_model.dart';
import '../repo/cashier_repo.dart';

class PaymentReconciliationHelper {
  const PaymentReconciliationHelper();

  /// Executes payment collection with a 2-step atomic saga and compensating rollback.
  /// Step 1: Ledger entry in CashierRepo.
  /// Step 2: Booking balance and status update in BookingsRepo.
  /// If Step 2 fails, Step 1 is rolled back via [CashierRepo.voidPaymentRollback].
  Future<Either<Failures, PaymentTransactionModel>> collectPaymentWithSaga({
    required CashierRepo cashierRepo,
    required BookingsRepo bookingsRepo,
    required String clientRequestId,
    required String shiftId,
    required String branchId,
    required String bookingId,
    required String patientId,
    required String patientName,
    required int amountPiastres,
    required String paymentMethod,
    required String cashierUserId,
    required String cashierName,
    String? referenceNumber,
    String? notes,
    AuditLogger? auditLogger,
  }) async {
    // 1. Validate positive amount
    if (amountPiastres <= 0) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_positive_amount'),
      );
    }

    // 2. Fetch booking to check remaining balance
    final bookingRes = await bookingsRepo.getBookingById(bookingId);
    if (bookingRes.isLeft()) {
      return Left(
        bookingRes.fold((f) => f, (_) => const ServerFailure(errMessage: 'booking_not_found')),
      );
    }
    final booking = bookingRes.getOrElse(() => throw StateError(''));

    final totalPricePounds = booking.netAmount > 0
        ? booking.netAmount
        : (booking.consultationFee ?? booking.totalPrice ?? 0);
    final currentPaidPounds = booking.paidAmount ?? 0;
    final remainingPounds = totalPricePounds - currentPaidPounds;
    final remainingPiastres = (remainingPounds * 100).round();

    if (amountPiastres > remainingPiastres) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_exceeds_remaining'),
      );
    }

    // 3. Step 1 of Saga: Record payment transaction in cashier ledger
    final paymentRes = await cashierRepo.recordPayment(
      clientRequestId: clientRequestId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      patientName: patientName,
      amountPiastres: amountPiastres,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      cashierUserId: cashierUserId,
      cashierName: cashierName,
      notes: notes,
    );

    if (paymentRes.isLeft()) {
      return paymentRes;
    }

    final payment = paymentRes.getOrElse(() => throw StateError(''));

    // 4. Step 2 of Saga: Update booking paid amount and payment status
    final newPaidPounds = currentPaidPounds + (amountPiastres / 100.0);
    final isFullyPaid = (newPaidPounds * 100).round() >= (totalPricePounds * 100).round();
    final newStatus = isFullyPaid
        ? PaymentStatusEnum.paid
        : PaymentStatusEnum.partiallyPaid;

    final updatedBooking = booking.copyWith(
      paidAmount: newPaidPounds,
      paymentStatus: newStatus,
    );

    final updateRes = await bookingsRepo.updateBooking(updatedBooking);

    // If updating booking fails, execute compensating rollback on cashier ledger
    if (updateRes.isLeft()) {
      await cashierRepo.voidPaymentRollback(
        paymentId: payment.id ?? '',
        reason: 'system_rollback',
      );

      // Audit the rollback event with numeric IDs and amounts only
      auditLogger?.log(
        eventType: 'payment_voided_by_system',
        performedByUserId: 'system',
        branchId: branchId,
        details:
            'paymentId: ${payment.id}, bookingId: $bookingId, amountPiastres: $amountPiastres, reason: system_rollback',
      );

      return Left(
        updateRes.fold(
          (f) => f,
          (_) => const ServerFailure(errMessage: 'booking_update_failed_rolled_back'),
        ),
      );
    }

    // 5. Successful completion: Audit payment collected
    auditLogger?.log(
      eventType: 'payment_collected',
      performedByUserId: cashierUserId,
      performedByUserName: cashierName,
      branchId: branchId,
      details:
          'paymentId: ${payment.id}, bookingId: $bookingId, amountPiastres: $amountPiastres, method: $paymentMethod, shiftId: $shiftId, clientRequestId: $clientRequestId',
    );

    return Right(payment);
  }

  /// Executes payment refund with booking balance reversal and audit.
  Future<Either<Failures, RefundTransactionModel>> refundPaymentWithSaga({
    required CashierRepo cashierRepo,
    required BookingsRepo bookingsRepo,
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
    AuditLogger? auditLogger,
  }) async {
    if (reason.trim().isEmpty) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_reason_required'),
      );
    }

    if (refundAmountPiastres <= 0) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_positive_amount'),
      );
    }

    // Fetch booking
    final bookingRes = await bookingsRepo.getBookingById(bookingId);
    if (bookingRes.isLeft()) {
      return Left(
        bookingRes.fold((f) => f, (_) => const ServerFailure(errMessage: 'booking_not_found')),
      );
    }
    final booking = bookingRes.getOrElse(() => throw StateError(''));

    final currentPaidPounds = booking.paidAmount ?? 0;
    final currentPaidPiastres = (currentPaidPounds * 100).round();

    if (refundAmountPiastres > currentPaidPiastres) {
      return const Left(
        ValidationFailure(errMessage: 'cashier_validation_exceeds_paid'),
      );
    }

    // Record refund in cashier ledger
    final refundRes = await cashierRepo.refundPayment(
      clientRequestId: clientRequestId,
      originalPaymentId: originalPaymentId,
      shiftId: shiftId,
      branchId: branchId,
      bookingId: bookingId,
      patientId: patientId,
      refundAmountPiastres: refundAmountPiastres,
      refundMethod: refundMethod,
      reason: reason,
      authorizedByUserId: authorizedByUserId,
      authorizedByName: authorizedByName,
    );

    if (refundRes.isLeft()) {
      return refundRes;
    }

    final refund = refundRes.getOrElse(() => throw StateError(''));

    // Update booking paid amount
    final newPaidPounds = (currentPaidPiastres - refundAmountPiastres) / 100.0;
    final totalPricePounds = booking.netAmount > 0
        ? booking.netAmount
        : (booking.consultationFee ?? booking.totalPrice ?? 0);

    PaymentStatusEnum newStatus;
    if (newPaidPounds <= 0) {
      newStatus = PaymentStatusEnum.unpaid;
    } else if (newPaidPounds < totalPricePounds) {
      newStatus = PaymentStatusEnum.partiallyPaid;
    } else {
      newStatus = PaymentStatusEnum.paid;
    }

    final updatedBooking = booking.copyWith(
      paidAmount: newPaidPounds.clamp(0.0, double.infinity),
      paymentStatus: newStatus,
    );

    await bookingsRepo.updateBooking(updatedBooking);

    // Audit refund event
    auditLogger?.log(
      eventType: 'payment_refunded',
      performedByUserId: authorizedByUserId,
      performedByUserName: authorizedByName,
      branchId: branchId,
      details:
          'refundId: ${refund.id}, originalPaymentId: $originalPaymentId, amountPiastres: $refundAmountPiastres, reason: $reason, authorizedByUserId: $authorizedByUserId',
    );

    return Right(refund);
  }
}

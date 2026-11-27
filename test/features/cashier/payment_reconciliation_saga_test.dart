import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_repo_impl.dart';
import 'package:eyadty/features/cashier/domain/helpers/payment_reconciliation_helper.dart';

class FakeFailingBookingsRepo implements BookingsRepo {
  final Map<String, BookingModel> bookings = {};
  bool failOnUpdate = false;

  FakeFailingBookingsRepo();

  void addBooking(BookingModel booking) {
    bookings[booking.id!] = booking;
  }

  @override
  Future<Either<Failures, BookingModel>> getBookingById(String id) async {
    final b = bookings[id];
    if (b == null) return const Left(ServerFailure(errMessage: 'booking_not_found'));
    return Right(b);
  }

  @override
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    if (failOnUpdate) {
      return const Left(ServerFailure(errMessage: 'database_unavailable_during_booking_update'));
    }
    bookings[booking.id!] = booking;
    return Right(booking);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CashierRepoImpl cashierRepo;
  late FakeFailingBookingsRepo bookingsRepo;
  late InMemoryAuditLogger auditLogger;
  const saga = PaymentReconciliationHelper();

  setUp(() {
    cashierRepo = CashierRepoImpl(seedInitialData: false);
    bookingsRepo = FakeFailingBookingsRepo();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
  });

  group('Payment Reconciliation Saga - Collection & Balance Updates', () {
    test('1. Full payment updates booking paidAmount and sets paymentStatus to paid', () async {
      // 1. Setup shift
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000, // 1000 EGP
      )).getOrElse(() => throw StateError(''));

      // 2. Setup booking (total price = 300 EGP, currently unpaid)
      const booking = BookingModel(
        id: 'MED-SAGA-01',
        totalPrice: 300,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // 3. Execute saga for 300 EGP cash
      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-01',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      expect(result.isRight(), true);
      final payment = result.getOrElse(() => throw StateError(''));
      expect(payment.amountPiastres, 30000);

      // Check updated booking
      final updatedBooking = bookingsRepo.bookings['MED-SAGA-01']!;
      expect(updatedBooking.paidAmount, 300.0);
      expect(updatedBooking.paymentStatus, PaymentStatusEnum.paid);

      // Check drawer cash
      final updatedShift = (await cashierRepo.getCurrentShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
      )).getOrElse(() => null);
      expect(updatedShift?.expectedCashPiastres, 130000); // 1000 + 300 = 1300 EGP
      expect(updatedShift?.totalCashCollectedPiastres, 30000);

      // Check audit
      final logs = auditLogger.getLogs(eventType: 'payment_collected');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('bookingId: MED-SAGA-01'), true);
    });

    test('2. Partial payment updates booking paidAmount and sets paymentStatus to partiallyPaid', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-02',
        totalPrice: 400,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-2',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-02',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 15000, // 150 EGP partial
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      expect(result.isRight(), true);
      final updatedBooking = bookingsRepo.bookings['MED-SAGA-02']!;
      expect(updatedBooking.paidAmount, 150.0);
      expect(updatedBooking.paymentStatus, PaymentStatusEnum.partiallyPaid);
    });

    test('3. Rejects payment exceeding remaining balance on booking', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-03',
        totalPrice: 300,
        paidAmount: 200, // 100 EGP remaining
        paymentStatus: PaymentStatusEnum.partiallyPaid,
      );
      bookingsRepo.addBooking(booking);

      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-3',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-03',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 15000, // 150 EGP > 100 EGP remaining
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_validation_exceeds_remaining'),
        (_) => fail('Should reject overpayment'),
      );
    });

    test('4. Rejects payment with zero or negative amount', () async {
      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-4',
        shiftId: 'SHIFT-1',
        branchId: 'branch_1',
        bookingId: 'MED-1',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 0,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.errMessage, 'cashier_validation_positive_amount'),
        (_) => fail('Should reject non-positive amount'),
      );
    });
  });

  group('Payment Reconciliation Saga - Compensating Rollback Verification', () {
    test('5. When BookingsRepo update fails, compensating rollback voids payment in ledger', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-05',
        totalPrice: 300,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // Simulate BookingsRepo failure during update
      bookingsRepo.failOnUpdate = true;

      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-FAIL',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-05',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      // Expect failure returned to caller
      expect(result.isLeft(), true);

      // Verify booking was NOT modified
      expect(bookingsRepo.bookings['MED-SAGA-05']?.paidAmount, 0);
      expect(bookingsRepo.bookings['MED-SAGA-05']?.paymentStatus, PaymentStatusEnum.unpaid);

      // Verify payment was marked as voided by system in ledger
      final payments = (await cashierRepo.getPaymentsForShift(
        shiftId: shift.id!,
        includeVoided: true,
      )).getOrElse(() => []);
      expect(payments.length, 1);
      expect(payments.first.isVoidedBySystem, true);
    });

    test('6. After rollback, expected cash in drawer and shift metrics return to 100% initial state', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000, // 1000 EGP
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-06',
        totalPrice: 500,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);
      bookingsRepo.failOnUpdate = true;

      await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-SAGA-ROLLBACK',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-06',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 50000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      final currentShift = (await cashierRepo.getCurrentShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
      )).getOrElse(() => null);

      // Expected cash returned to 1000 EGP (100000 piastres)
      expect(currentShift?.expectedCashPiastres, 100000);
      expect(currentShift?.totalCashCollectedPiastres, 0);
      expect(currentShift?.transactionCount, 0);
    });

    test('7. Emits payment_voided_by_system audit event on rollback with numeric IDs only', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 50000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-07',
        totalPrice: 200,
        paidAmount: 0,
      );
      bookingsRepo.addBooking(booking);
      bookingsRepo.failOnUpdate = true;

      await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-ROLLBACK-AUDIT',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-07',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 20000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      final rollbackLogs = auditLogger.getLogs(eventType: 'payment_voided_by_system');
      expect(rollbackLogs.length, 1);
      expect(rollbackLogs.first.performedByUserId, 'system');
      expect(rollbackLogs.first.details?.contains('bookingId: MED-SAGA-07'), true);
      expect(rollbackLogs.first.details?.contains('amountPiastres: 20000'), true);
      expect(rollbackLogs.first.details?.contains('reason: system_rollback'), true);
    });

    test('8. Non-cash payments (card, bank transfer) update booking without modifying expected drawer cash', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-08',
        totalPrice: 350,
        paidAmount: 0,
      );
      bookingsRepo.addBooking(booking);

      final result = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-CARD-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-08',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 35000,
        paymentMethod: PaymentMethod.card.name,
        referenceNumber: 'POS-12345',
        cashierUserId: 'USER-REC',
        cashierName: 'منى إبراهيم',
        auditLogger: auditLogger,
      );

      expect(result.isRight(), true);
      expect(bookingsRepo.bookings['MED-SAGA-08']?.paidAmount, 350.0);
      expect(bookingsRepo.bookings['MED-SAGA-08']?.paymentStatus, PaymentStatusEnum.paid);

      // Expected drawer cash MUST NOT increase for card payment
      final currentShift = (await cashierRepo.getCurrentShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-REC',
      )).getOrElse(() => null);
      expect(currentShift?.expectedCashPiastres, 100000); // Unchanged!
      expect(currentShift?.totalCardCollectedPiastres, 35000); // Recorded in card metrics
    });
  });

  group('Payment Reconciliation Saga - Refund Flow', () {
    test('9. Full refund sets booking paidAmount to 0 and paymentStatus to unpaid', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-REFUND-1',
        totalPrice: 300,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // First pay the booking in ledger
      final payRes = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-PAY-BEFORE-REFUND-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-1',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
      );
      final paymentId = payRes.getOrElse(() => throw StateError('')).id!;

      final refundResult = await saga.refundPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-REFUND-1',
        originalPaymentId: paymentId,
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-1',
        patientId: 'PAT-1',
        refundAmountPiastres: 30000, // 300 EGP full refund
        refundMethod: PaymentMethod.cash.name,
        reason: 'إلغاء الموعد بناء على طلب المريض',
        authorizedByUserId: 'USER-MGR',
        authorizedByName: 'م. أحمد مهران',
        auditLogger: auditLogger,
      );

      expect(refundResult.isRight(), true);
      final updatedBooking = bookingsRepo.bookings['MED-SAGA-REFUND-1']!;
      expect(updatedBooking.paidAmount, 0.0);
      expect(updatedBooking.paymentStatus, PaymentStatusEnum.unpaid);

      final logs = auditLogger.getLogs(eventType: 'payment_refunded');
      expect(logs.length, 1);
      expect(logs.first.details?.contains('amountPiastres: 30000'), true);
    });

    test('10. Partial refund updates booking paidAmount and sets paymentStatus to partiallyPaid', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-REFUND-2',
        totalPrice: 400,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // First pay 400 EGP
      final payRes = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-PAY-BEFORE-REFUND-2',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-2',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 40000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
      );
      final paymentId = payRes.getOrElse(() => throw StateError('')).id!;

      final refundResult = await saga.refundPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-REFUND-2',
        originalPaymentId: paymentId,
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-2',
        patientId: 'PAT-1',
        refundAmountPiastres: 15000, // 150 EGP partial refund (250 remaining)
        refundMethod: PaymentMethod.cash.name,
        reason: 'تعديل الخدمة واسترداد الفارق',
        authorizedByUserId: 'USER-MGR',
        authorizedByName: 'م. أحمد مهران',
        auditLogger: auditLogger,
      );

      expect(refundResult.isRight(), true);
      final updatedBooking = bookingsRepo.bookings['MED-SAGA-REFUND-2']!;
      expect(updatedBooking.paidAmount, 250.0);
      expect(updatedBooking.paymentStatus, PaymentStatusEnum.partiallyPaid);
    });

    test('11. Rejects refund exceeding total paid amount on booking', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-REFUND-3',
        totalPrice: 300,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // Pay 150 EGP
      final payRes = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-PAY-BEFORE-REFUND-3',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-3',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 15000, // 150 EGP
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
      );
      final paymentId = payRes.getOrElse(() => throw StateError('')).id!;

      final refundResult = await saga.refundPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-REFUND-3',
        originalPaymentId: paymentId,
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-REFUND-3',
        patientId: 'PAT-1',
        refundAmountPiastres: 20000, // 200 EGP > 150 EGP paid
        refundMethod: PaymentMethod.cash.name,
        reason: 'استرداد يتجاوز المدفوع',
        authorizedByUserId: 'USER-MGR',
        authorizedByName: 'م. أحمد مهران',
      );

      expect(refundResult.isLeft(), true);
      refundResult.fold(
        (f) => expect(f.errMessage, 'cashier_validation_exceeds_paid'),
        (_) => fail('Should reject refund exceeding paid amount'),
      );
    });

    test('12. End-to-end reconciliation: completes payment and then full refund sequentially', () async {
      final shift = (await cashierRepo.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
        openingBalancePiastres: 100000,
      )).getOrElse(() => throw StateError(''));

      const booking = BookingModel(
        id: 'MED-SAGA-E2E',
        totalPrice: 200,
        paidAmount: 0,
        paymentStatus: PaymentStatusEnum.unpaid,
      );
      bookingsRepo.addBooking(booking);

      // 1. Pay 200 EGP
      final payRes = await saga.collectPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-E2E-PAY',
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-E2E',
        patientId: 'PAT-1',
        patientName: 'مريض تجريبي',
        amountPiastres: 20000,
        paymentMethod: PaymentMethod.cash.name,
        cashierUserId: 'USER-MGR',
        cashierName: 'م. أحمد مهران',
      );
      expect(payRes.isRight(), true);
      expect(bookingsRepo.bookings['MED-SAGA-E2E']?.paidAmount, 200.0);
      expect(bookingsRepo.bookings['MED-SAGA-E2E']?.paymentStatus, PaymentStatusEnum.paid);

      // 2. Refund 200 EGP
      final refundRes = await saga.refundPaymentWithSaga(
        cashierRepo: cashierRepo,
        bookingsRepo: bookingsRepo,
        clientRequestId: 'REQ-E2E-REFUND',
        originalPaymentId: payRes.getOrElse(() => throw StateError('')).id!,
        shiftId: shift.id!,
        branchId: 'branch_1',
        bookingId: 'MED-SAGA-E2E',
        patientId: 'PAT-1',
        refundAmountPiastres: 20000,
        refundMethod: PaymentMethod.cash.name,
        reason: 'إلغاء واسترداد كامل',
        authorizedByUserId: 'USER-MGR',
        authorizedByName: 'م. أحمد مهران',
      );
      expect(refundRes.isRight(), true);
      expect(bookingsRepo.bookings['MED-SAGA-E2E']?.paidAmount, 0.0);
      expect(bookingsRepo.bookings['MED-SAGA-E2E']?.paymentStatus, PaymentStatusEnum.unpaid);
    });
  });
}

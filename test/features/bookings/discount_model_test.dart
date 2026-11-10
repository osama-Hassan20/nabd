import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B-DISC M-1: DiscountModel & Computed Getters Tests', () {
    test('T1: DiscountTypeEnum.fromValue("free") = DiscountTypeEnum.free', () {
      expect(DiscountTypeEnum.fromValue('free'), DiscountTypeEnum.free);
      expect(DiscountTypeEnum.fromValue('percentage'),
          DiscountTypeEnum.percentage);
      expect(DiscountTypeEnum.fromValue('fixed_amount'),
          DiscountTypeEnum.fixedAmount);
    });

    test('T2: DiscountTypeEnum.fromValue(null) = DiscountTypeEnum.none', () {
      expect(DiscountTypeEnum.fromValue(null), DiscountTypeEnum.none);
      expect(DiscountTypeEnum.fromValue('invalid'), DiscountTypeEnum.none);
    });

    test('T3: BookingModel.netAmount = consultationFee if discountType = none',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.none,
      );
      expect(booking.discountAmount, 0);
      expect(booking.netAmount, 300);
    });

    test('T4: BookingModel.netAmount = 0 if discountType = free', () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.free,
      );
      expect(booking.discountAmount, 300);
      expect(booking.netAmount, 0);
    });

    test(
        'T5: BookingModel.netAmount = consultationFee * (1 - 20/100) for 20% discount',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
      );
      expect(booking.discountAmount, 60);
      expect(booking.netAmount, 240);
    });

    test('T6: BookingModel.netAmount = consultationFee - fixedAmount for fixed discount',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.fixedAmount,
        discountValue: 50,
      );
      expect(booking.discountAmount, 50);
      expect(booking.netAmount, 250);
    });

    test('T7: BookingModel.discountAmount does not exceed consultationFee (clamp)',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.fixedAmount,
        discountValue: 500, // exceeds 300
      );
      expect(booking.discountAmount, 300);
      expect(booking.netAmount, 0);
    });

    test('T8: BookingModel.isFreeConsultation = true if discountType = free', () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.free,
      );
      expect(booking.isFreeConsultation, isTrue);
    });

    test('T9: BookingModel.isFreeConsultation = true if percentage >= 100', () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 100,
      );
      expect(booking.isFreeConsultation, isTrue);
    });

    test('T10: BookingModel.isFreeConsultation = true if fixedAmount >= consultationFee',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        discountType: DiscountTypeEnum.fixedAmount,
        discountValue: 300,
      );
      expect(booking.isFreeConsultation, isTrue);
    });

    test('T11: BookingModel.effectivePaymentStatus = paid if isFreeConsultation',
        () {
      const booking = BookingModel(
        consultationFee: 300,
        paymentStatus: PaymentStatusEnum.unpaid,
        discountType: DiscountTypeEnum.free,
      );
      expect(booking.isFreeConsultation, isTrue);
      expect(booking.netAmount, 0);
      expect(booking.effectivePaymentStatus, PaymentStatusEnum.paid);
      // Original stored status remains unpaid
      expect(booking.paymentStatus, PaymentStatusEnum.unpaid);
    });

    test(
        'T12: BookingModel.effectivePaymentStatus = unpaid after discount removed',
        () {
      final freeBooking = const BookingModel(
        consultationFee: 300,
        paymentStatus: PaymentStatusEnum.unpaid,
        discountType: DiscountTypeEnum.free,
      );
      expect(freeBooking.effectivePaymentStatus, PaymentStatusEnum.paid);

      final removedBooking = freeBooking.copyWith(
        discountType: DiscountTypeEnum.none,
        discountValue: 0,
        discountRemovedReason: 'Cancelled by patient',
      );
      expect(removedBooking.isFreeConsultation, isFalse);
      expect(removedBooking.effectivePaymentStatus, PaymentStatusEnum.unpaid);
    });

    test('T13: BookingModel.copyWith() preserves discount fields when unspecified',
        () {
      final now = DateTime(2026, 11, 10, 12, 0);
      final booking = BookingModel(
        id: 'B-100',
        consultationFee: 300,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        discountReason: 'Loyalty discount',
        discountApprovedByUserId: 'usr_owner_01',
        discountApprovedAt: now,
      );

      final updated = booking.copyWith(notes: 'Updated notes');
      expect(updated.id, 'B-100');
      expect(updated.notes, 'Updated notes');
      expect(updated.discountType, DiscountTypeEnum.percentage);
      expect(updated.discountValue, 20);
      expect(updated.discountReason, 'Loyalty discount');
      expect(updated.discountApprovedByUserId, 'usr_owner_01');
      expect(updated.discountApprovedAt, now);
    });
  });
}


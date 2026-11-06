import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';

void main() {
  final testToday = DateTime(2026, 11, 6);
  final currentTime = DateTime(2026, 11, 6, 14, 0); // 2:00 PM in Cairo

  group('BookingStatisticsCalculator Unit Tests', () {
    test('1. Past appointment time without arrival -> No-show', () {
      final booking = BookingModel(
        id: 'BK-1',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 6, 10, 0), // 10:00 AM (passed)
        arrivalTime: null,
        status: BookingStatusEnum.waiting,
      );

      final isNoShow = BookingStatisticsCalculator.isNoShow(
        booking,
        testToday,
        now: currentTime,
      );

      expect(isNoShow, isTrue);

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: [booking],
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      expect(summary.noShow, equals(1));
      expect(summary.inWaiting, equals(0)); // Should not be in waiting
    });

    test('2. Future appointment time -> NOT No-show (remains in waiting)', () {
      final booking = BookingModel(
        id: 'BK-2',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 6, 16, 0), // 4:00 PM (future)
        arrivalTime: null,
        status: BookingStatusEnum.waiting,
      );

      final isNoShow = BookingStatisticsCalculator.isNoShow(
        booking,
        testToday,
        now: currentTime,
      );

      expect(isNoShow, isFalse);

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: [booking],
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      expect(summary.noShow, equals(0));
      expect(summary.inWaiting, equals(1));
    });

    test('3. Past appointment time but patient arrived -> NOT No-show', () {
      final booking = BookingModel(
        id: 'BK-3',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 6, 11, 0),
        arrivalTime: DateTime(2026, 11, 6, 10, 50), // Arrived!
        status: BookingStatusEnum.waiting,
      );

      final isNoShow = BookingStatisticsCalculator.isNoShow(
        booking,
        testToday,
        now: currentTime,
      );

      expect(isNoShow, isFalse);

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: [booking],
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      expect(summary.noShow, equals(0));
      expect(summary.inWaiting, equals(1));
    });

    test('4. Cancelled today vs cancelled on another day', () {
      final cancelledToday = BookingModel(
        id: 'BK-4A',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 6, 12, 0),
        status: BookingStatusEnum.cancelled,
        cancelledAt: DateTime(2026, 11, 6, 9, 30),
      );

      final cancelledOtherDay = BookingModel(
        id: 'BK-4B',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 10, 12, 0),
        status: BookingStatusEnum.cancelled,
        cancelledAt: DateTime(2026, 11, 5, 10, 0),
      );

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: [cancelledToday, cancelledOtherDay],
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      expect(summary.cancelledToday, equals(1));
    });

    test(
        '5. Postponed to another date vs postponed to same day at later time',
        () {
      // Postponed to another day
      final postponedToOtherDate = BookingModel(
        id: 'BK-5A',
        branchId: 'branch_1',
        originalAppointmentTime: DateTime(2026, 11, 6, 10, 0),
        appointmentTime: DateTime(2026, 11, 6, 10, 0),
        rescheduledTo: DateTime(2026, 11, 8, 14, 0), // Different date!
        status: BookingStatusEnum.postponed,
        postponedAt: DateTime(2026, 11, 6, 9, 0),
      );

      // Postponed to the same day at a later hour
      final postponedSameDay = BookingModel(
        id: 'BK-5B',
        branchId: 'branch_1',
        originalAppointmentTime: DateTime(2026, 11, 6, 10, 0),
        appointmentTime: DateTime(2026, 11, 6, 10, 0),
        rescheduledTo: DateTime(2026, 11, 6, 17, 0), // Same date!
        status: BookingStatusEnum.postponed,
        postponedAt: DateTime(2026, 11, 6, 9, 15),
      );

      expect(
        BookingStatisticsCalculator.isPostponedToAnotherDate(
            postponedToOtherDate, testToday),
        isTrue,
      );
      expect(
        BookingStatisticsCalculator.isPostponedToAnotherDate(
            postponedSameDay, testToday),
        isFalse,
      );

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: [postponedToOtherDate, postponedSameDay],
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      expect(summary.postponedToOther, equals(1));
    });

    test('6. Changing selected date and changing branch filters correctly', () {
      final branch1Today = BookingModel(
        id: 'BK-6A',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 6, 11, 0),
        status: BookingStatusEnum.completed,
      );

      final branch2Today = BookingModel(
        id: 'BK-6B',
        branchId: 'branch_2',
        appointmentTime: DateTime(2026, 11, 6, 11, 0),
        status: BookingStatusEnum.completed,
      );

      final branch1Tomorrow = BookingModel(
        id: 'BK-6C',
        branchId: 'branch_1',
        appointmentTime: DateTime(2026, 11, 7, 11, 0),
        status: BookingStatusEnum.completed,
      );

      final allBookings = [branch1Today, branch2Today, branch1Tomorrow];

      // Branch 1 Today
      final sumBranch1Today = BookingStatisticsCalculator.calculateSummary(
        bookings: allBookings,
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );
      expect(sumBranch1Today.completedToday, equals(1));
      expect(sumBranch1Today.visitsToday, equals(1));

      // Branch 2 Today
      final sumBranch2Today = BookingStatisticsCalculator.calculateSummary(
        bookings: allBookings,
        selectedDate: testToday,
        branchId: 'branch_2',
        currentTime: currentTime,
      );
      expect(sumBranch2Today.completedToday, equals(1));

      // Branch 1 Tomorrow
      final sumBranch1Tomorrow = BookingStatisticsCalculator.calculateSummary(
        bookings: allBookings,
        selectedDate: DateTime(2026, 11, 7),
        branchId: 'branch_1',
        currentTime: currentTime,
      );
      expect(sumBranch1Tomorrow.completedToday, equals(1));
    });

    test('7. Filter matching synchronization with card numbers', () {
      final bookings = [
        BookingModel(
          id: '1',
          branchId: 'branch_1',
          appointmentTime: DateTime(2026, 11, 6, 9, 0), // passed
          status: BookingStatusEnum.waiting, // No arrival -> No-show
        ),
        BookingModel(
          id: '2',
          branchId: 'branch_1',
          appointmentTime: DateTime(2026, 11, 6, 16, 0), // future
          status: BookingStatusEnum.waiting,
        ),
        BookingModel(
          id: '3',
          branchId: 'branch_1',
          appointmentTime: DateTime(2026, 11, 6, 12, 0),
          status: BookingStatusEnum.inConsultation,
        ),
        BookingModel(
          id: '4',
          branchId: 'branch_1',
          appointmentTime: DateTime(2026, 11, 6, 10, 0),
          status: BookingStatusEnum.completed,
        ),
        BookingModel(
          id: '5',
          branchId: 'branch_1',
          appointmentTime: DateTime(2026, 11, 6, 11, 0),
          status: BookingStatusEnum.cancelled,
          cancelledAt: DateTime(2026, 11, 6, 8, 0),
        ),
        BookingModel(
          id: '6',
          branchId: 'branch_1',
          originalAppointmentTime: DateTime(2026, 11, 6, 13, 0),
          rescheduledTo: DateTime(2026, 11, 12, 10, 0),
          status: BookingStatusEnum.postponed,
        ),
      ];

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: testToday,
        branchId: 'branch_1',
        currentTime: currentTime,
      );

      // Verify each status matches exactly the filtered list length
      final noShowRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.noShow,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(noShowRows, equals(summary.noShow));

      final waitingRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.waiting,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(waitingRows, equals(summary.inWaiting));

      final consultRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.inConsultation,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(consultRows, equals(summary.inConsultation));

      final completedRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.completed,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(completedRows, equals(summary.completedToday));

      final cancelledRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.cancelled,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(cancelledRows, equals(summary.cancelledToday));

      final postponedRows = bookings
          .where((b) => BookingStatisticsCalculator.matchesStatusFilter(
                b,
                BookingStatusEnum.postponed,
                selectedDate: testToday,
                branchId: 'branch_1',
                currentTime: currentTime,
              ))
          .length;
      expect(postponedRows, equals(summary.postponedToOther));
    });
  });
}


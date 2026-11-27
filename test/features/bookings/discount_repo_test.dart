import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/contracts/active_visit_lookup.dart';
import 'package:eyadty/features/bookings/domain/helpers/booking_statistics_calculator.dart';
import 'package:eyadty/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_by_id_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_booking_summary_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/apply_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/remove_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCurrentUserProvider implements CurrentUserProvider {
  StaffUserModel? user;
  @override
  StaffUserModel? get currentUser => user;
  @override
  String? get activeBranchId => 'branch_1';
}

void main() {
  late BookingsRepoImpl repo;

  setUp(() {
    repo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
  });

  group('B-DISC M-2: Repository, Calculator & Discount Operations Tests', () {
    test(
        'T1: applyDiscount updates discountType, discountValue, discountReason, and discountApprovedAt',
        () async {
      const params = ApplyDiscountParams(
        bookingId: 'MED-101',
        discountType: DiscountTypeEnum.percentage,
        discountValue: 25,
        reason: 'Special holiday promotion',
        approvedByUserId: 'USER-OWNER',
      );

      final result = await repo.applyDiscount(params);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.discountType, DiscountTypeEnum.percentage);
          expect(booking.discountValue, 25);
          expect(booking.discountReason, 'Special holiday promotion');
          expect(booking.discountApprovedByUserId, 'USER-OWNER');
          expect(booking.discountApprovedAt, isNotNull);
          expect(booking.discountAmount, 75); // 25% of 300
          expect(booking.netAmount, 225);
        },
      );
    });

    test(
        'T2: removeDiscount resets discountType -> none and records discountRemovedReason',
        () async {
      // First apply discount
      await repo.applyDiscount(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 50,
          reason: 'Initial discount',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      // Now remove it
      const removeParams = RemoveDiscountParams(
        bookingId: 'MED-101',
        reason: 'Removed by manager request',
        removedByUserId: 'USER-MGR',
      );

      final result = await repo.removeDiscount(removeParams);
      expect(result.isRight(), isTrue);

      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.discountType, DiscountTypeEnum.none);
          expect(booking.discountValue, 0);
          expect(booking.discountReason, isNull);
          expect(booking.discountRemovedReason, 'Removed by manager request');
          expect(booking.discountAmount, 0);
          expect(booking.netAmount, 300);
        },
      );
    });

    test(
        'T3: removeDiscount for a free booking resets effectivePaymentStatus back to unpaid',
        () async {
      // Create an unpaid booking
      await repo.createBooking(
        const BookingModel(
          id: 'BOOK-FREE-TO-UNPAID',
          consultationFee: 300,
          paidAmount: 0,
          paymentStatus: PaymentStatusEnum.unpaid,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // Apply free consultation
      final appliedRes = await repo.applyDiscount(
        const ApplyDiscountParams(
          bookingId: 'BOOK-FREE-TO-UNPAID',
          discountType: DiscountTypeEnum.free,
          reason: 'Free consultation granted',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      appliedRes.fold(
        (_) => fail('Apply free failed'),
        (b) {
          expect(b.isFreeConsultation, isTrue);
          expect(b.effectivePaymentStatus, PaymentStatusEnum.paid);
          expect(b.paymentStatus, PaymentStatusEnum.unpaid); // raw stored
        },
      );

      // Remove discount
      final removeRes = await repo.removeDiscount(
        const RemoveDiscountParams(
          bookingId: 'BOOK-FREE-TO-UNPAID',
          reason: 'Cancelled free voucher',
          removedByUserId: 'USER-OWNER',
        ),
      );

      removeRes.fold(
        (_) => fail('Remove discount failed'),
        (b) {
          expect(b.isFreeConsultation, isFalse);
          expect(b.effectivePaymentStatus, PaymentStatusEnum.unpaid);
        },
      );
    });

    test('T4: BookingStatisticsCalculator uses netAmount instead of consultationFee',
        () {
      final now = CairoTimeHelper.now();
      final today = DateTime(now.year, now.month, now.day);

      final bookings = [
        BookingModel(
          id: 'B1',
          consultationFee: 300,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20, // Discount: 60, Net: 240
          appointmentTime: today.add(const Duration(hours: 10)),
          status: BookingStatusEnum.waiting,
        ),
        BookingModel(
          id: 'B2',
          consultationFee: 200,
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 50, // Discount: 50, Net: 150
          appointmentTime: today.add(const Duration(hours: 11)),
          status: BookingStatusEnum.waiting,
        ),
      ];

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: today,
        currentTime: today.add(const Duration(hours: 9)),
      );

      // Total Net: 240 + 150 = 390 (not 300 + 200 = 500)
      expect(summary.totalNetRevenue, 390);
      expect(summary.netRevenue, 390);
    });

    test('T5: freeConsultationsCount excludes cancelled bookings', () {
      final now = CairoTimeHelper.now();
      final today = DateTime(now.year, now.month, now.day);

      final bookings = [
        BookingModel(
          id: 'B-FREE-ACTIVE',
          consultationFee: 300,
          discountType: DiscountTypeEnum.free,
          appointmentTime: today.add(const Duration(hours: 10)),
          status: BookingStatusEnum.waiting,
        ),
        BookingModel(
          id: 'B-FREE-CANCELLED',
          consultationFee: 300,
          discountType: DiscountTypeEnum.free,
          appointmentTime: today.add(const Duration(hours: 11)),
          cancelledAt: today.add(const Duration(hours: 9)),
          status: BookingStatusEnum.cancelled,
        ),
      ];

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: today,
        currentTime: today.add(const Duration(hours: 8)),
      );

      // Only the active waiting one is counted in freeConsultationsCount
      expect(summary.freeConsultationsCount, 1);
      expect(summary.freeConsultations, 1);
      expect(summary.cancelledBookings, 1);
    });

    test(
        'T6: totalDiscountsGiven = sum of discountAmount for non-cancelled bookings',
        () {
      final now = CairoTimeHelper.now();
      final today = DateTime(now.year, now.month, now.day);

      final bookings = [
        BookingModel(
          id: 'B1',
          consultationFee: 300,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20, // discount 60
          appointmentTime: today.add(const Duration(hours: 10)),
          status: BookingStatusEnum.waiting,
        ),
        BookingModel(
          id: 'B2',
          consultationFee: 400,
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 100, // discount 100
          appointmentTime: today.add(const Duration(hours: 11)),
          status: BookingStatusEnum.completed,
        ),
        BookingModel(
          id: 'B3-CANCELLED',
          consultationFee: 500,
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 250, // discount 250 (cancelled, should be excluded)
          appointmentTime: today.add(const Duration(hours: 12)),
          cancelledAt: today.add(const Duration(hours: 9)),
          status: BookingStatusEnum.cancelled,
        ),
      ];

      final summary = BookingStatisticsCalculator.calculateSummary(
        bookings: bookings,
        selectedDate: today,
        currentTime: today.add(const Duration(hours: 8)),
      );

      // Total discounts: 60 + 100 = 160 (excludes cancelled 250)
      expect(summary.totalDiscountsGiven, 160);
      expect(summary.discountsGiven, 160);
    });

    test(
        'T7: Changing consultationFee on discounted booking revalidates and resets discount if invalid',
        () async {
      final auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
      final staffRepo = StaffUsersRepoImpl(apiConsumer: LocalServerApiConsumer(), auditLogger: auditLogger);
      final userProvider = _FakeCurrentUserProvider();
      final ownerRes = await staffRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final updateUseCase = UpdateBookingUseCase(
        repo: repo,
        staffUsersRepo: staffRepo,
        currentUserProvider: userProvider,
        auditLogger: auditLogger,
      );

      // 1. Create a discounted booking: Fee 300, fixed discount 200 (Net 100)
      await repo.createBooking(
        const BookingModel(
          id: 'BOOK-FEE-CHANGE',
          consultationFee: 300,
          paidAmount: 0,
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 200,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // 2. Doctor reduces fee from 300 to 150 -> fixed discount 200 is now > fee (150)
      const updateParams = BookingModel(
        id: 'BOOK-FEE-CHANGE',
        consultationFee: 150,
        paidAmount: 0,
        discountType: DiscountTypeEnum.fixedAmount,
        discountValue: 200,
        status: BookingStatusEnum.waiting,
        branchId: 'branch_1',
      );

      final updateRes = await updateUseCase(updateParams);
      expect(updateRes.isRight(), isTrue);

      updateRes.fold(
        (_) => fail('Update should succeed'),
        (res) {
          expect(res.discountResetKey, 'disc_removed_due_to_fee_change');
          expect(res.booking.consultationFee, 150);
          // Discount is automatically reset because 200 > 150
          expect(res.booking.discountType, DiscountTypeEnum.none);
          expect(res.booking.discountValue, 0);
          expect(res.booking.discountRemovedReason, 'fee_changed');
        },
      );
    });

    test('T8: BookingsCubit applyDiscount and removeDiscount integration',
        () async {
      final auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
      final staffRepo = StaffUsersRepoImpl(apiConsumer: LocalServerApiConsumer(), auditLogger: auditLogger);

      final applyUseCase = ApplyBookingDiscountUseCase(
        bookingsRepo: repo,
        staffUsersRepo: staffRepo,
        auditLogger: auditLogger,
      );
      final removeUseCase = RemoveBookingDiscountUseCase(
        bookingsRepo: repo,
        staffUsersRepo: staffRepo,
        auditLogger: auditLogger,
      );

      final cubit = BookingsCubit(
        getBookingSummaryUseCase: GetBookingSummaryUseCase(repo: repo),
        getBookingsUseCase: GetBookingsUseCase(repo: repo),
        getBookingByIdUseCase: GetBookingByIdUseCase(repo: repo),
        createBookingUseCase: CreateBookingUseCase(repo: repo),
        updateBookingUseCase: UpdateBookingUseCase(repo: repo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(
          repo: repo,
          activeVisitLookup: const _FakeActiveVisitLookup(),
        ),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(
          repo: repo,
          activeVisitLookup: const _FakeActiveVisitLookup(),
        ),
        deleteBookingUseCase: DeleteBookingUseCase(
          repo: repo,
          activeVisitLookup: const _FakeActiveVisitLookup(),
        ),
        applyBookingDiscountUseCase: applyUseCase,
        removeBookingDiscountUseCase: removeUseCase,
      );

      // Create an unpaid booking for Cubit test
      await repo.createBooking(
        const BookingModel(
          id: 'BOOK-CUBIT-TEST',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // Apply discount via Cubit
      final applyOk = await cubit.applyDiscount(
        const ApplyDiscountParams(
          bookingId: 'BOOK-CUBIT-TEST',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Cubit test discount',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(applyOk, isTrue);

      // Remove discount via Cubit
      final removeOk = await cubit.removeDiscount(
        const RemoveDiscountParams(
          bookingId: 'BOOK-CUBIT-TEST',
          reason: 'Cubit test remove',
          removedByUserId: 'USER-OWNER',
        ),
      );

      expect(removeOk, isTrue);
      await cubit.close();
    });
  });
}

class _FakeActiveVisitLookup implements ActiveVisitLookup {
  const _FakeActiveVisitLookup();

  @override
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId) async =>
      null;
}

import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/data/services/booking_patient_balance_lookup_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_actions_menu.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/patients/data/repo/patients_repo_impl.dart';

class _FakeUserProvider implements CurrentUserProvider {
  @override
  StaffUserModel? get currentUser => const StaffUserModel(
        id: 'user_owner',
        fullName: 'المالك',
        isOwner: true,
      );

  @override
  String? get activeBranchId => 'branch_1';
}

Widget _buildTestWidget(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    CairoTimeHelper.setFixedClock(DateTime.utc(2026, 11, 14, 10, 0));
  });

  tearDownAll(() {
    CairoTimeHelper.resetFixedClock();
  });

  group('Cashier & Bookings Integration - M-5 Tests', () {
    late BookingsRepoImpl bookingsRepo;
    late CreateBookingUseCase createBookingUseCase;
    late UpdateBookingUseCase updateBookingUseCase;
    late DeleteBookingUseCase deleteBookingUseCase;

    setUp(() async {
      bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
      await bookingsRepo.getBookings(PaginationParams(page: 1, limit: 100));
      createBookingUseCase = CreateBookingUseCase(
        repo: bookingsRepo,
        currentUserProvider: _FakeUserProvider(),
      );
      updateBookingUseCase = UpdateBookingUseCase(repo: bookingsRepo);
      deleteBookingUseCase = DeleteBookingUseCase(repo: bookingsRepo);
    });

    test('1. CreateBookingUseCase locks paidAmount to 0 and paymentStatus to unpaid', () async {
      final input = BookingModel(
        branchId: 'branch_1',
        patientId: 'PAT-000101',
        patientName: 'سارة أحمد',
        consultationFee: 300,
        paidAmount: 300, // Attempted direct manual payment
        paymentStatus: PaymentStatusEnum.paid,
      );

      final result = await createBookingUseCase(input);
      expect(result.isRight(), isTrue);

      final created = result.getOrElse(() => throw StateError(''));
      expect(created.paidAmount, 0);
      expect(created.paymentStatus, PaymentStatusEnum.unpaid);
    });

    test('2. CreateBookingUseCase sets paid for free consultation with 0 paidAmount', () async {
      final input = BookingModel(
        branchId: 'branch_1',
        patientId: 'PAT-000101',
        consultationFee: 300,
        discountType: DiscountTypeEnum.free,
        discountValue: 100,
        discountReason: 'إعفاء حالة إنسانية',
        paidAmount: 50,
      );

      final result = await createBookingUseCase(input);
      expect(result.isRight(), isTrue);

      final created = result.getOrElse(() => throw StateError(''));
      expect(created.paidAmount, 0);
      expect(created.paymentStatus, PaymentStatusEnum.paid);
      expect(created.isFreeConsultation, isTrue);
    });

    test('3. UpdateBookingUseCase prevents direct tampering of paidAmount', () async {
      final initial = await bookingsRepo.getBookingById('MED-101');
      final original = initial.getOrElse(() => throw StateError(''));
      expect(original.paidAmount, 300);

      // Attempt to tamper paidAmount to 50 directly in update
      final tampered = original.copyWith(paidAmount: 50);
      final updateRes = await updateBookingUseCase(tampered);
      expect(updateRes.isRight(), isTrue);

      final updated = updateRes.getOrElse(() => throw StateError('')).booking;
      // Must preserve the original 300
      expect(updated.paidAmount, 300);
    });

    test('4. UpdateBookingUseCase prevents direct tampering of paymentStatus', () async {
      final initial = await bookingsRepo.getBookingById('MED-102');
      final original = initial.getOrElse(() => throw StateError(''));
      expect(original.paymentStatus, PaymentStatusEnum.unpaid);

      // Attempt to set paymentStatus to paid directly without payment saga
      final tampered = original.copyWith(paymentStatus: PaymentStatusEnum.paid);
      final updateRes = await updateBookingUseCase(tampered);
      expect(updateRes.isRight(), isTrue);

      final updated = updateRes.getOrElse(() => throw StateError('')).booking;
      // Must preserve original unpaid
      expect(updated.paymentStatus, PaymentStatusEnum.unpaid);
    });

    test('5. DeleteBookingUseCase blocks deletion when paidAmount > 0', () async {
      // MED-101 has paidAmount = 300
      final res = await deleteBookingUseCase('MED-101');
      expect(res.isLeft(), isTrue);

      res.fold(
        (failure) => expect(failure.errMessage, 'booking_cannot_delete_has_payments'),
        (_) => fail('Should have failed'),
      );
    });

    test('6. DeleteBookingUseCase succeeds when paidAmount == 0', () async {
      // MED-102 has paidAmount = 0
      final res = await deleteBookingUseCase('MED-102');
      expect(res.isRight(), isTrue);

      final check = await bookingsRepo.getBookingById('MED-102');
      expect(check.isRight(), isTrue);
      expect(check.getOrElse(() => throw StateError('')).status, BookingStatusEnum.cancelled);
    });

    testWidgets('7. BookingActionsMenu renders collect payment menu item when callback provided', (tester) async {
      bool collected = false;

      await tester.pumpWidget(
        _buildTestWidget(
          BookingActionsMenu(
            onCollectPayment: () => collected = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();

      expect(collected, isTrue);
    });

    testWidgets('8. BookingActionsMenu renders refund payment menu item when callback provided', (tester) async {
      bool refunded = false;

      await tester.pumpWidget(
        _buildTestWidget(
          BookingActionsMenu(
            onRefundPayment: () => refunded = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.assignment_return_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.assignment_return_outlined));
      await tester.pumpAndSettle();

      expect(refunded, isTrue);
    });

    testWidgets('9. BookingsTable displays needs refund badge when cancelled and paidAmount > 0', (tester) async {
      final cancelledPaidBooking = BookingModel(
        id: 'B-TEST-CANCELLED-PAID',
        queueNumber: 1,
        patientName: 'مريض تجريبي',
        status: BookingStatusEnum.cancelled,
        consultationFee: 300,
        paidAmount: 300,
        startTime: '10:00',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          BookingsTable(
            bookings: [cancelledPaidBooking],
            onEdit: (_) {},
            onChangeStatus: (_) {},
            onReassignTechnician: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_needs_refund'.tr()), findsOneWidget);
    });

    testWidgets('10. BookingsTable does NOT display needs refund badge when cancelled and paidAmount == 0', (tester) async {
      final cancelledUnpaidBooking = BookingModel(
        id: 'B-TEST-CANCELLED-UNPAID',
        queueNumber: 2,
        patientName: 'مريض غير مسدد',
        status: BookingStatusEnum.cancelled,
        consultationFee: 300,
        paidAmount: 0,
        startTime: '10:30',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          BookingsTable(
            bookings: [cancelledUnpaidBooking],
            onEdit: (_) {},
            onChangeStatus: (_) {},
            onReassignTechnician: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cashier_needs_refund'.tr()), findsNothing);
    });

    testWidgets('11. BookingsTable does NOT display needs refund badge for noShow, even if paidAmount > 0', (tester) async {
      final noShowPaidBooking = BookingModel(
        id: 'B-TEST-NOSHOW-PAID',
        queueNumber: 3,
        patientName: 'مريض لم يحضر',
        status: BookingStatusEnum.noShow,
        consultationFee: 300,
        paidAmount: 300,
        paymentStatus: PaymentStatusEnum.paid,
        startTime: '11:00',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          BookingsTable(
            bookings: [noShowPaidBooking],
            onEdit: (_) {},
            onChangeStatus: (_) {},
            onReassignTechnician: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT show "يحتاج استرداد"
      expect(find.text('cashier_needs_refund'.tr()), findsNothing);
    });

    test('12. BookingPatientBalanceLookupImpl computes debt strictly from completed bookings', () {
      final lookup = BookingPatientBalanceLookupImpl(bookingsRepo);

      // PAT-000102 has:
      // - MED-102 (confirmed, fee: 150, paid: 0) -> NOT completed, ignored
      // - MED-107 (completed, fee: 300, paid: 150) -> completed, debt = 150
      final debt = lookup.calculateOutstandingBalance(patientId: 'PAT-000102');
      expect(debt, 150);

      final totalPaid = lookup.calculateTotalPaid(patientId: 'PAT-000102');
      expect(totalPaid, 150);
    });

    test('13. PatientsRepoImpl with lookup computes PAT-000102 debt as 150 EGP', () async {
      final lookup = BookingPatientBalanceLookupImpl(bookingsRepo);
      final patientsRepo = PatientsRepoImpl(apiConsumer: LocalServerApiConsumer(), 
        bookingsRepo: bookingsRepo,
        balanceLookup: lookup,
      );

      final res = await patientsRepo.getPatientById(id: 'PAT-000102');
      expect(res.isRight(), isTrue);

      final patient = res.getOrElse(() => throw StateError(''));
      expect(patient.outstandingBalance, 150);
      expect(patient.totalPaidAmount, 150);
    });

    test('14. PatientsRepoImpl with lookup computes PAT-000105 debt as 0 EGP', () async {
      final lookup = BookingPatientBalanceLookupImpl(bookingsRepo);
      final patientsRepo = PatientsRepoImpl(apiConsumer: LocalServerApiConsumer(), 
        bookingsRepo: bookingsRepo,
        balanceLookup: lookup,
      );

      final res = await patientsRepo.getPatientById(id: 'PAT-000105');
      expect(res.isRight(), isTrue);

      final patient = res.getOrElse(() => throw StateError(''));
      // MED-105 is postponed / not completed, so confirmed overdue debt is 0
      expect(patient.outstandingBalance, 0);
      expect(patient.totalPaidAmount, 0);
    });
  });
}

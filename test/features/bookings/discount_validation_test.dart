import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/apply_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCurrentUserProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch ?? 'branch_1';
}

class FakeRolesProvider implements RolesProvider {
  List<RoleDefinitionModel> roles = RoleDefinitionModel.defaultSystemRoles();

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  late BookingsMockRepoImpl bookingsRepo;
  late StaffUsersMockRepoImpl staffUsersRepo;
  late InMemoryAuditLogger auditLogger;
  late FakeCurrentUserProvider userProvider;
  late FakeRolesProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late ApplyBookingDiscountUseCase applyDiscountUseCase;
  late UpdateBookingUseCase updateBookingUseCase;

  setUp(() async {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    staffUsersRepo = StaffUsersMockRepoImpl(auditLogger: auditLogger);
    bookingsRepo = BookingsMockRepoImpl();
    userProvider = FakeCurrentUserProvider();
    rolesProvider = FakeRolesProvider();
    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );
    applyDiscountUseCase = ApplyBookingDiscountUseCase(
      bookingsRepo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    updateBookingUseCase = UpdateBookingUseCase(
      repo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
    );
  });

  group('B-DISC M-1: Discount Validation Tests', () {
    test('T1: Percentage 101% -> Left(Failure: disc_validation_pct_range)',
        () async {
      // Set user to owner
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 101,
          reason: 'Valid reason',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_pct_range'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T2: Fixed amount greater than consultationFee -> Left(Failure: disc_validation_fixed_range)',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101', // Fee: 300
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 350,
          reason: 'Valid reason',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_fixed_range'),
        (_) => fail('Should fail'),
      );
    });

    test('T3: Discount without reason -> Left(Failure: disc_validation_reason_required)',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20,
          reason: '', // Empty reason
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_reason_required'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T4: Free consultation without reason -> Left(Failure: disc_validation_free_reason_required)',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.free,
          reason: '   ', // Whitespace
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_free_reason_required'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T5: Discount on cancelled booking -> Left(Failure: disc_validation_cancelled_booking)',
        () async {
      // Create a cancelled booking
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-CANCELLED',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.cancelled,
          branchId: 'branch_1',
        ),
      );

      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-CANCELLED',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Valid reason',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_cancelled_booking'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T6: Discount percentage 30% when role max is 20% -> Left(Failure: disc_validation_max_exceeded)',
        () async {
      // USER-REC has role_reception which has maxDiscountPercent = 20
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      // Create booking with 0 paid
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-REC-1',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-REC-1',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 30, // 30% > 20%
          reason: 'Reception discount',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_max_exceeded'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T7: Fixed amount 150 of 300 (= 50%) when role max is 20% -> Left(Failure: disc_validation_max_exceeded)',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-REC-2',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-REC-2',
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 150, // 150/300 = 50% > 20%
          reason: 'Reception fixed discount',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_max_exceeded'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T8: 100% or amount = fee when role lacks canGrantFreeConsultation -> Left(Failure: disc_validation_free_required)',
        () async {
      // USER-REC has canGrantFreeConsultation = false
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-REC-3',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // Try free type
      final resultFree = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-REC-3',
          discountType: DiscountTypeEnum.free,
          reason: 'Attempt free consultation',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(resultFree.isLeft(), isTrue);
      resultFree.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_free_required'),
        (_) => fail('Should fail'),
      );

      // Try 100% percentage
      final result100 = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-REC-3',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 100,
          reason: 'Attempt 100% discount',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(result100.isLeft(), isTrue);
      result100.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_free_required'),
        (_) => fail('Should fail'),
      );
    });

    test('T9: 100% discount with canGrantFreeConsultation = true -> Right(success)',
        () async {
      // USER-MGR (branchManager) has canGrantFreeConsultation = true and maxDiscountPercent = 100
      final mgrRes = await staffUsersRepo.getStaffUserById('USER-MGR');
      userProvider.user = mgrRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-MGR-FREE',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-MGR-FREE',
          discountType: DiscountTypeEnum.free,
          reason: 'Humanitarian case approved by manager',
          approvedByUserId: 'USER-MGR',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.isFreeConsultation, isTrue);
          expect(booking.discountAmount, 300);
          expect(booking.netAmount, 0);
        },
      );
    });

    test(
        'T10: Discount makes netAmount < paidAmount -> Left(Failure: disc_validation_below_paid)',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      // Fee: 300, already paid: 200. Discount 150 leaves net 150 (< 200 paid)
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-PAID-200',
          consultationFee: 300,
          paidAmount: 200,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-PAID-200',
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 150,
          reason: 'Fixed discount',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_below_paid'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T11: Reception with maxDiscount=20 applies 15% discount -> Right(success)',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-REC-VALID',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-REC-VALID',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 15, // <= 20%
          reason: 'Family discount',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.discountAmount, 45); // 15% of 300
          expect(booking.netAmount, 255);
        },
      );
    });

    test(
        'T12: Owner (isOwner) has no percentage limit -> Right(success) for 80%',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-OWNER-VALID',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-OWNER-VALID',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 80,
          reason: 'Owner VIP courtesy discount',
          approvedByUserId: 'USER-OWNER',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.discountAmount, 240);
          expect(booking.netAmount, 60);
        },
      );
    });

    test(
        'T13: Modifying discountType in UpdateBookingUseCase without applyBookingDiscount -> Left(Failure: disc_validation_no_permission)',
        () async {
      // USER-MED-DIR (Medical Director) does NOT have applyBookingDiscount permission
      final medDirRes =
          await staffUsersRepo.getStaffUserById('USER-MED-DIR');
      userProvider.user = medDirRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-UPDATE-PERM',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.none,
          branchId: 'branch_1',
        ),
      );

      // Attempt to modify discountType to percentage
      const updatedBooking = BookingModel(
        id: 'BOOK-UPDATE-PERM',
        consultationFee: 300,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        branchId: 'branch_1',
      );

      final result = await updateBookingUseCase(updatedBooking);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_no_permission'),
        (_) => fail('Should fail'),
      );
    });
  });
}

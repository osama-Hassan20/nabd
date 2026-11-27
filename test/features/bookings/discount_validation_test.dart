import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/create_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/apply_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/remove_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/update_booking_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';
import 'package:eyadty/features/users_management/domain/use_cases/params/update_role_discount_policy_params.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
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
  late BookingsRepoImpl bookingsRepo;
  late StaffUsersRepoImpl staffUsersRepo;
  late InMemoryAuditLogger auditLogger;
  late FakeCurrentUserProvider userProvider;
  late FakeRolesProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late ApplyBookingDiscountUseCase applyDiscountUseCase;
  late RemoveBookingDiscountUseCase removeDiscountUseCase;
  late CreateBookingUseCase createBookingUseCase;
  late UpdateBookingUseCase updateBookingUseCase;

  setUp(() async {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    staffUsersRepo = StaffUsersRepoImpl(apiConsumer: LocalServerApiConsumer(), auditLogger: auditLogger);
    bookingsRepo = BookingsRepoImpl(apiConsumer: LocalServerApiConsumer());
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
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );
    removeDiscountUseCase = RemoveBookingDiscountUseCase(
      bookingsRepo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );
    createBookingUseCase = CreateBookingUseCase(
      repo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );
    updateBookingUseCase = UpdateBookingUseCase(
      repo: bookingsRepo,
      staffUsersRepo: staffUsersRepo,
      permissionEvaluator: permissionEvaluator,
      currentUserProvider: userProvider,
      auditLogger: auditLogger,
    );
  });

  group('B-DISC M-1 & M-2: Discount Validation Tests', () {
    test('T1: Percentage 101% -> Left(Failure: disc_validation_pct_range)',
        () async {
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

    test(
        'T3: Discount without reason -> Left(Failure: disc_validation_reason_required)',
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
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

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

    test(
        'T9: 100% discount with canGrantFreeConsultation = true -> Right(success)',
        () async {
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

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-PAID-TEST',
          consultationFee: 300,
          paidAmount: 250, // Paid 250
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // Attempt 100 fixed discount -> net 200 < paid 250
      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-PAID-TEST',
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 100,
          reason: 'Partial courtesy discount',
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
        'T11: Receptionist applies 15% discount (below 20% limit) -> Right(success)',
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
          discountValue: 15,
          reason: 'Family discount',
          approvedByUserId: 'USER-REC',
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          expect(booking.discountAmount, 45);
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

    test(
        'T14: Session-derived approver: passing another user ID in approvedByUserId does NOT change recorded approver or audit actor',
        () async {
      // Session user is USER-REC
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-SPOOF-TEST',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // Caller maliciously passes USER-OWNER as approvedByUserId
      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-SPOOF-TEST',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Valid reason',
          approvedByUserId: 'USER-OWNER', // Attempted spoof
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (booking) {
          // Strictly bound to session actor: USER-REC
          expect(booking.discountApprovedByUserId, 'USER-REC');
        },
      );

      final applyLogs = auditLogger.getLogs(eventType: 'booking_discount_applied');
      expect(applyLogs, isNotEmpty);
      expect(applyLogs.last.performedByUserId, 'USER-REC');
    });

    test(
        'T15: Session-derived remover: passing another user ID in removedByUserId does NOT change remover in audit log',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      // Create booking with active discount
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-REMOVE-SPOOF',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          discountReason: 'Initial',
          discountApprovedByUserId: 'USER-REC',
          branchId: 'branch_1',
        ),
      );

      final result = await removeDiscountUseCase(
        const RemoveDiscountParams(
          bookingId: 'BOOK-REMOVE-SPOOF',
          reason: 'Customer requested full price receipt',
          removedByUserId: 'USER-OWNER', // Attempted spoof
        ),
      );

      expect(result.isRight(), isTrue);
      final removeLogs = auditLogger.getLogs(eventType: 'booking_discount_removed');
      expect(removeLogs, isNotEmpty);
      expect(removeLogs.last.performedByUserId, 'USER-REC');
    });

    test(
        'T16: Custom role with null discount policy fields fails closed -> Left(Failure: disc_validation_max_exceeded)',
        () async {
      // Create user with custom role having null discount fields
      final customRole = const RoleDefinitionModel(
        id: 'role_custom_trainee',
        nameAr: 'متدرب مخصص',
        permissions: [StaffPermissionEnum.applyBookingDiscount],
        maxDiscountPercent: null, // Null!
        canGrantFreeConsultation: null, // Null!
      );
      rolesProvider.roles = [...rolesProvider.roles, customRole];
      await staffUsersRepo.saveRole(role: customRole, currentUserId: 'USER-OWNER');

      final traineeUser = const StaffUserModel(
        id: 'USER-TRAINEE',
        fullName: 'متدرب تجريبي',
        isActive: true,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['role_custom_trainee'],
          ),
        ],
      );
      await staffUsersRepo.createStaffUser(
        user: traineeUser,
        temporaryPassword: 'Password123',
        currentUserId: 'USER-OWNER',
      );

      userProvider.user = traineeUser;

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-TRAINEE-TEST',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-TRAINEE-TEST',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Attempt discount by custom trainee',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_max_exceeded'),
        (_) => fail('Should fail closed'),
      );
    });

    test(
        'T17: User whose role definition does not exist fails closed -> Left(Failure: disc_validation_no_permission)',
        () async {
      final phantomUser = const StaffUserModel(
        id: 'USER-PHANTOM',
        fullName: 'مستخدم بلا دور',
        isActive: true,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['role_non_existent'],
          ),
        ],
      );
      userProvider.user = phantomUser;

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-PHANTOM-TEST',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-PHANTOM-TEST',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Test',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_no_permission'),
        (_) => fail('Should fail closed'),
      );
    });

    test(
        'T18: Unauthenticated user (null session user) fails closed -> Left(Failure: staff_user_not_found)',
        () async {
      userProvider.user = null;

      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          reason: 'Test',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'staff_user_not_found'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T19: Failed apply discount logs ZERO booking_discount_applied audit events',
        () async {
      final beforeCount =
          auditLogger.getLogs(eventType: 'booking_discount_applied').length;

      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      // Attempt 50% discount when limit is 20%
      final result = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'MED-101',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 50,
          reason: 'Test failure',
        ),
      );

      expect(result.isLeft(), isTrue);
      final afterCount =
          auditLogger.getLogs(eventType: 'booking_discount_applied').length;
      expect(afterCount, beforeCount);
    });

    test(
        'T20: Failed remove discount logs ZERO booking_discount_removed audit events',
        () async {
      final beforeCount =
          auditLogger.getLogs(eventType: 'booking_discount_removed').length;

      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      // Missing reason
      final result = await removeDiscountUseCase(
        const RemoveDiscountParams(
          bookingId: 'MED-101',
          reason: '',
        ),
      );

      expect(result.isLeft(), isTrue);
      final afterCount =
          auditLogger.getLogs(eventType: 'booking_discount_removed').length;
      expect(afterCount, beforeCount);
    });

    test(
        'T21: F-04a booking lock (visit in_progress) does NOT prevent applying or removing discount',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-IN-PROGRESS-LOCK',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.inConsultation, // Locked by consultation
          branchId: 'branch_1',
        ),
      );

      // 1. Apply discount succeeds
      final applyResult = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-IN-PROGRESS-LOCK',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20,
          reason: 'Doctor approved mid-consultation courtesy discount',
        ),
      );
      expect(applyResult.isRight(), isTrue);

      // 2. Remove discount succeeds
      final removeResult = await removeDiscountUseCase(
        const RemoveDiscountParams(
          bookingId: 'BOOK-IN-PROGRESS-LOCK',
          reason: 'Doctor decided standard procedure price applies',
        ),
      );
      expect(removeResult.isRight(), isTrue);
    });

    test(
        'T22: Changing consultationFee on a booking with active discount without applyBookingDiscount is rejected',
        () async {
      final medDirRes =
          await staffUsersRepo.getStaffUserById('USER-MED-DIR');
      userProvider.user = medDirRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-FEE-CHANGE-NOPERM',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20,
          discountReason: 'Existing discount',
          branchId: 'branch_1',
        ),
      );

      // Change fee from 300 to 400
      const updated = BookingModel(
        id: 'BOOK-FEE-CHANGE-NOPERM',
        consultationFee: 400,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        discountReason: 'Existing discount',
        branchId: 'branch_1',
      );

      final result = await updateBookingUseCase(updated);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.errMessage, 'disc_validation_no_permission'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T23: Changing consultationFee on a booking with discount where new fee makes discount invalid resets discount and logs audit',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      // Booking had fee 300, fixed discount 200 (net 100), paid 100
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-FEE-CHANGE-RESET',
          consultationFee: 300,
          paidAmount: 100,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.fixedAmount,
          discountValue: 200,
          discountReason: 'Initial discount',
          branchId: 'branch_1',
        ),
      );

      // Fee is reduced to 150 -> fixed discount 200 is now > fee (150) and net (-50) < paid (100) -> Invalid!
      const updated = BookingModel(
        id: 'BOOK-FEE-CHANGE-RESET',
        consultationFee: 150,
        paidAmount: 100,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.fixedAmount,
        discountValue: 200,
        discountReason: 'Initial discount',
        branchId: 'branch_1',
      );

      final result = await updateBookingUseCase(updated);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed with reset'),
        (res) {
          expect(res.discountResetKey, 'disc_removed_due_to_fee_change');
          expect(res.booking.discountType, DiscountTypeEnum.none);
          expect(res.booking.discountValue, 0);
          expect(res.booking.discountRemovedReason, 'fee_changed');
        },
      );

      final removeLogs = auditLogger
          .getLogs(eventType: 'booking_discount_removed')
          .where((l) => l.details?.contains('fee_changed') ?? false)
          .toList();
      expect(removeLogs, isNotEmpty);
    });

    test(
        'T27: Changing consultationFee from 300 to 400 where 10% discount remains valid preserves discount with discountResetKey == null',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-FEE-VALID-PRESERVED',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 10,
          discountReason: 'Loyalty discount',
          branchId: 'branch_1',
        ),
      );

      const updated = BookingModel(
        id: 'BOOK-FEE-VALID-PRESERVED',
        consultationFee: 400,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 10,
        discountReason: 'Loyalty discount',
        branchId: 'branch_1',
      );

      final result = await updateBookingUseCase(updated);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed without reset'),
        (res) {
          expect(res.discountResetKey, isNull);
          expect(res.booking.discountType, DiscountTypeEnum.percentage);
          expect(res.booking.discountValue, 10);
          expect(res.booking.discountAmount, 40); // 10% of 400
          expect(res.booking.netAmount, 360);
        },
      );
    });

    test(
        'T28: Changing consultationFee makes netAmount < paidAmount -> resets discount with discountResetKey and logs audit',
        () async {
      final ownerRes = await staffUsersRepo.getStaffUserById('USER-OWNER');
      userProvider.user = ownerRes.getOrElse(() => const StaffUserModel());

      // Booking had fee 300, 20% discount (net 240), paid 100
      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-FEE-NET-BELOW-PAID',
          consultationFee: 300,
          paidAmount: 100,
          status: BookingStatusEnum.waiting,
          discountType: DiscountTypeEnum.percentage,
          discountValue: 20,
          discountReason: 'Initial discount',
          branchId: 'branch_1',
        ),
      );

      // Fee reduced to 120 -> 20% of 120 = 24, net is 96, but paid is 100! (net < paid)
      const updated = BookingModel(
        id: 'BOOK-FEE-NET-BELOW-PAID',
        consultationFee: 120,
        paidAmount: 100,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 20,
        discountReason: 'Initial discount',
        branchId: 'branch_1',
      );

      final result = await updateBookingUseCase(updated);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed with reset'),
        (res) {
          expect(res.discountResetKey, 'disc_removed_due_to_fee_change');
          expect(res.booking.discountType, DiscountTypeEnum.none);
          expect(res.booking.discountValue, 0);
          expect(res.booking.discountRemovedReason, 'fee_changed');
        },
      );

      final removeLogs = auditLogger
          .getLogs(eventType: 'booking_discount_removed')
          .where((l) => l.details?.contains('fee_changed') ?? false)
          .toList();
      expect(removeLogs, isNotEmpty);
    });

    test(
        'T29: Custom role with 35% discount policy: applies 30% successfully, rejects 40% with disc_validation_max_exceeded',
        () async {
      const customRole = RoleDefinitionModel(
        id: 'role_custom_senior_coord',
        nameAr: 'منسق أول مخصص',
        permissions: [StaffPermissionEnum.applyBookingDiscount],
        maxDiscountPercent: 35,
        canGrantFreeConsultation: false,
      );
      rolesProvider.roles = [...rolesProvider.roles, customRole];
      await staffUsersRepo.saveRole(role: customRole, currentUserId: 'USER-OWNER');

      final seniorUser = const StaffUserModel(
        id: 'USER-SENIOR-COORD',
        fullName: 'منسق أول',
        isActive: true,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: ['role_custom_senior_coord'],
          ),
        ],
      );
      await staffUsersRepo.createStaffUser(
        user: seniorUser,
        temporaryPassword: 'Password123',
        currentUserId: 'USER-OWNER',
      );

      userProvider.user = seniorUser;

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-CUSTOM-35PCT',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // 1. Applying 30% <= 35% succeeds
      final res30 = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-CUSTOM-35PCT',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 30,
          reason: '30% within 35% policy',
        ),
      );
      expect(res30.isRight(), isTrue);

      // 2. Applying 40% > 35% is rejected
      final res40 = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-CUSTOM-35PCT',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 40,
          reason: '40% exceeds 35% policy',
        ),
      );
      expect(res40.isLeft(), isTrue);
      res40.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_max_exceeded'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T30: Owner updating receptionist role policy immediately changes receptionist discount behavior in subsequent calls',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      final recUser = recRes.getOrElse(() => const StaffUserModel());
      userProvider.user = recUser;

      await bookingsRepo.createBooking(
        const BookingModel(
          id: 'BOOK-DYNAMIC-POLICY',
          consultationFee: 300,
          paidAmount: 0,
          status: BookingStatusEnum.waiting,
          branchId: 'branch_1',
        ),
      );

      // 1. Receptionist applying 30% fails initially because default limit is 20%
      final failAttempt = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-DYNAMIC-POLICY',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 30,
          reason: 'Early attempt before policy change',
        ),
      );
      expect(failAttempt.isLeft(), isTrue);

      // 2. Owner updates reception role policy to 35%
      final updatePolicy = UpdateRoleDiscountPolicyUseCase(
        staffUsersRepo: staffUsersRepo,
        auditLogger: auditLogger,
      );
      await updatePolicy(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.reception,
          maxDiscountPercent: 35,
          canGrantFreeConsultation: false,
          currentUserId: 'USER-OWNER',
        ),
      );

      // 3. Receptionist immediately attempts 30% again without app restart -> succeeds!
      userProvider.user = recUser;
      final successAttempt = await applyDiscountUseCase(
        const ApplyDiscountParams(
          bookingId: 'BOOK-DYNAMIC-POLICY',
          discountType: DiscountTypeEnum.percentage,
          discountValue: 30,
          reason: 'Attempt after owner raised limit to 35%',
        ),
      );
      expect(successAttempt.isRight(), isTrue);
      successAttempt.fold(
        (_) => fail('Should succeed now'),
        (b) {
          expect(b.discountValue, 30);
          expect(b.discountAmount, 90);
          expect(b.netAmount, 210);
        },
      );
    });

    test(
        'T24: Receptionist creating booking with 30% discount (limit 20%) -> Left(Failure: disc_validation_max_exceeded)',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      const newBooking = BookingModel(
        id: 'BOOK-CREATE-30PCT',
        consultationFee: 300,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 30, // Exceeds 20%
        discountReason: 'Attempted creation with high discount',
        branchId: 'branch_1',
      );

      final result = await createBookingUseCase(newBooking);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_max_exceeded'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T25: Receptionist creating free booking without canGrantFreeConsultation -> Left(Failure: disc_validation_free_required)',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      const newBooking = BookingModel(
        id: 'BOOK-CREATE-FREE',
        consultationFee: 300,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.free,
        discountReason: 'Attempted free creation',
        branchId: 'branch_1',
      );

      final result = await createBookingUseCase(newBooking);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_validation_free_required'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T26: Receptionist creating booking with 15% discount succeeds and logs booking_discount_applied audit event',
        () async {
      final recRes = await staffUsersRepo.getStaffUserById('USER-REC');
      userProvider.user = recRes.getOrElse(() => const StaffUserModel());

      const newBooking = BookingModel(
        id: 'BOOK-CREATE-15PCT',
        consultationFee: 300,
        paidAmount: 0,
        status: BookingStatusEnum.waiting,
        discountType: DiscountTypeEnum.percentage,
        discountValue: 15,
        discountReason: 'Valid family discount',
        branchId: 'branch_1',
      );

      final result = await createBookingUseCase(newBooking);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should succeed'),
        (saved) {
          expect(saved.discountAmount, 45);
          expect(saved.netAmount, 255);
          expect(saved.discountApprovedByUserId, 'USER-REC');
        },
      );

      final applyLogs = auditLogger
          .getLogs(eventType: 'booking_discount_applied')
          .where((l) => l.performedByUserId == 'USER-REC')
          .toList();
      expect(applyLogs, isNotEmpty);
    });
  });
}

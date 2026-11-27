import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/providers/active_bookings_count_provider.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';

class FakeActiveBookingsProvider implements ActiveBookingsCountProvider {
  final Map<String, int> counts;
  FakeActiveBookingsProvider(this.counts);

  @override
  Future<int> countActiveFutureBookingsForDoctor(String doctorId) async {
    return counts[doctorId] ?? 0;
  }

  @override
  Future<int> countActiveFutureBookingsForBranch(String branchId) async {
    return counts[branchId] ?? 0;
  }
}

void main() {
  late InMemoryAuditLogger auditLogger;
  late StaffUsersRepoImpl repo;

  setUp(() {
    auditLogger = InMemoryAuditLogger();
    repo = StaffUsersRepoImpl(
      auditLogger: auditLogger,
      activeBookingsProvider: FakeActiveBookingsProvider({'DOC-01': 3}),
    );
  });

  group('Staff Models & Seed Data (Rule 9: Seeded Data)', () {
    test('100% nullable model constructors with no defaults', () {
      const user = StaffUserModel();
      expect(user.id, isNull);
      expect(user.fullName, isNull);
      expect(user.isOwner, isNull);
      expect(user.linkedDoctorId, isNull);
      expect(user.branchAssignments, isNull);

      const branchAssignment = BranchAssignmentModel();
      expect(branchAssignment.branchId, isNull);
      expect(branchAssignment.roleIds, isNull);

      const role = RoleDefinitionModel();
      expect(role.id, isNull);
      expect(role.permissions, isNull);
    });

    test('Seeded mock users count and exact role mapping', () async {
      final res = await repo.getStaffUsers();
      final users = res.getOrElse(() => []);

      expect(users.length, greaterThanOrEqualTo(13)); // owner + medDir + mgr + rec + nurse + acc + hr + 6 docs

      // Owner exists and has isOwner: true
      final owner = users.firstWhere((u) => u.id == 'USER-OWNER');
      expect(owner.isOwner, isTrue);
      expect(owner.linkedDoctorId, isNull);

      // Medical Director exists and is administrative by default
      final medDir = users.firstWhere((u) => u.id == 'USER-MED-DIR');
      expect(medDir.isOwner, isFalse);
      expect(medDir.linkedDoctorId, isNull);

      // Doctors mapped DOC-01 through DOC-06
      for (int i = 1; i <= 6; i++) {
        final docId = 'DOC-0$i';
        final docUser = users.firstWhere((u) => u.linkedDoctorId == docId);
        expect(docUser.id, equals('USER-$docId'));
        expect(docUser.isPracticingDoctor, isTrue);
      }
    });

    test('7 system roles seeded properly matching Seed Matrix', () async {
      final res = await repo.getRoles();
      final roles = res.getOrElse(() => []);
      expect(roles.length, equals(7));

      final roleIds = roles.map((r) => r.id).toSet();
      expect(
        roleIds,
        containsAll([
          RoleIds.branchManager,
          RoleIds.medicalDirector,
          RoleIds.doctor,
          RoleIds.nurse,
          RoleIds.reception,
          RoleIds.accountant,
          RoleIds.hr,
        ]),
      );
    });
  });

  group('Security Rules Implementation', () {
    test('Rule 1: Last Active Owner cannot be demoted, deactivated or deleted', () async {
      // 1. Demoting last active owner
      final ownerRes = await repo.getStaffUserById('USER-OWNER');
      final owner = ownerRes.getOrElse(() => const StaffUserModel());
      final demoteAttempt = await repo.updateStaffUser(
        user: owner.copyWith(isOwner: false),
        currentUserId: 'USER-OWNER',
      );
      expect(demoteAttempt.isLeft(), isTrue);
      demoteAttempt.fold(
        (failure) => expect(failure, isA<LastActiveOwnerFailure>()),
        (_) => fail('Should not allow demoting last active owner'),
      );

      // 2. Deactivating last active owner
      final deactivateAttempt = await repo.toggleStaffUserStatus(
        userId: 'USER-OWNER',
        isActive: false,
        currentUserId: 'USER-MGR', // Another user trying to deactivate
      );
      expect(deactivateAttempt.isLeft(), isTrue);
      deactivateAttempt.fold(
        (failure) => expect(failure, isA<LastActiveOwnerFailure>()),
        (_) => fail('Should not allow deactivating last active owner'),
      );

      // 3. Deleting last active owner
      final deleteAttempt = await repo.deleteStaffUser(
        userId: 'USER-OWNER',
        currentUserId: 'USER-MGR',
      );
      expect(deleteAttempt.isLeft(), isTrue);
      deleteAttempt.fold(
        (failure) => expect(failure, isA<LastActiveOwnerFailure>()),
        (_) => fail('Should not allow deleting last active owner'),
      );
    });

    test('Rule 2: Privilege Escalation Prevention (Non-owner cannot assign critical permissions)', () async {
      // HR user (non-owner) trying to create a user with manageRolesAndPermissions
      const newUser = StaffUserModel(
        fullName: 'هاكر متسلل',
        email: 'hacker@eyadty.com',
        phone: '01099999999',
        jobTitle: 'مشرف نظام مصعد',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.branchManager], // branchManager contains critical permissions or owner
          ),
        ],
      );

      // Let's create a custom role with manageRolesAndPermissions and test HR assigning it
      final customRole = RoleDefinitionModel(
        id: 'role_super_admin',
        nameAr: 'سوبر أدمن',
        permissions: const [StaffPermissionEnum.manageRolesAndPermissions],
      );
      await repo.saveRole(role: customRole, currentUserId: 'USER-OWNER');

      final hackUser = newUser.copyWith(
        branchAssignments: const [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: ['role_super_admin']),
        ],
      );

      final attempt = await repo.createStaffUser(
        user: hackUser,
        temporaryPassword: 'Password123!',
        currentUserId: 'USER-HR', // Non-owner
      );

      expect(attempt.isLeft(), isTrue);
      attempt.fold(
        (failure) => expect(failure, isA<PrivilegeEscalationFailure>()),
        (_) => fail('Should block non-owner from assigning critical permissions'),
      );
    });

    test('Rule 3: Self-Deactivation Prevention', () async {
      final attempt = await repo.toggleStaffUserStatus(
        userId: 'USER-REC',
        isActive: false,
        currentUserId: 'USER-REC',
      );
      expect(attempt.isLeft(), isTrue);
      attempt.fold(
        (failure) => expect(failure, isA<SelfDeactivationFailure>()),
        (_) => fail('Should block self-deactivation'),
      );
    });

    test('Rule 4: Self-Deletion Prevention', () async {
      final attempt = await repo.deleteStaffUser(
        userId: 'USER-REC',
        currentUserId: 'USER-REC',
      );
      expect(attempt.isLeft(), isTrue);
      attempt.fold(
        (failure) => expect(failure, isA<SelfDeletionFailure>()),
        (_) => fail('Should block self-deletion'),
      );
    });

    test('Rule 5: Doctor Profile Linking Requirement', () async {
      // Creating a user marked as doctor without linkedDoctorId
      const unlinkedDoc = StaffUserModel(
        fullName: 'طبيب بدون بروفايل',
        email: 'doc_unlinked@eyadty.com',
        phone: '01088888888',
        jobTitle: 'طبيب ممارس',
        linkedDoctorId: '', // Empty or null
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
        ],
      );

      // Note: isPracticingDoctor checks linkedDoctorId != null && linkedDoctorId.isNotEmpty
      expect(unlinkedDoc.isPracticingDoctor, isFalse);
    });

    test('Rule 6: Active Bookings Warning on Deletion', () async {
      // DOC-01 has 3 active bookings configured in mock
      final attempt = await repo.deleteStaffUser(
        userId: 'USER-DOC-01',
        currentUserId: 'USER-OWNER',
        forceWithActiveBookings: false,
      );

      expect(attempt.isLeft(), isTrue);
      attempt.fold(
        (failure) {
          expect(failure, isA<ActiveBookingsWarningFailure>());
          final warning = failure as ActiveBookingsWarningFailure;
          expect(warning.activeBookingsCount, equals(3));
        },
        (_) => fail('Should warn about active bookings'),
      );

      // Deleting with forceWithActiveBookings: true succeeds
      final forceAttempt = await repo.deleteStaffUser(
        userId: 'USER-DOC-01',
        currentUserId: 'USER-OWNER',
        forceWithActiveBookings: true,
      );
      expect(forceAttempt.isRight(), isTrue);
    });

    test('Rule 7: Audit Logger Sanitization (Redacting Passwords & Tokens)', () {
      auditLogger.log(
        eventType: 'test_event',
        details: 'Attempt login with password: secret_password_123, and token: eyJhbGciOi...',
      );

      final logs = auditLogger.getLogs(eventType: 'test_event');
      expect(logs.isNotEmpty, isTrue);
      final log = logs.first;
      expect(log.details, contains('password=[REDACTED]'));
      expect(log.details, contains('token=[REDACTED]'));
      expect(log.details, isNot(contains('secret_password_123')));
    });

    test('Rule 8: mustChangePassword Flow', () async {
      // 1. Create a new user with temporary password
      const newStaff = StaffUserModel(
        fullName: 'موظف استقبال جديد',
        email: 'new_rec@eyadty.com',
        phone: '01012341234',
        jobTitle: 'استقبال مسائي',
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.reception]),
        ],
      );

      final createRes = await repo.createStaffUser(
        user: newStaff,
        temporaryPassword: 'TempPassword123',
        currentUserId: 'USER-OWNER',
      );
      final createdUser = createRes.getOrElse(() => const StaffUserModel());
      expect(createdUser.mustChangePassword, isTrue);

      // 2. Authenticating with temporary password fails with MustChangePasswordFailure
      final loginAttempt = await repo.authenticate(
        identifier: createdUser.email!,
        password: 'TempPassword123',
      );
      expect(loginAttempt.isLeft(), isTrue);
      loginAttempt.fold(
        (failure) => expect(failure, isA<MustChangePasswordFailure>()),
        (_) => fail('Must require password change'),
      );

      // 3. User changes password
      final changeRes = await repo.changePasswordOnFirstLogin(
        userId: createdUser.id!,
        currentPassword: 'TempPassword123',
        newPassword: 'MyNewPermanentPassword!',
      );
      expect(changeRes.isRight(), isTrue);

      // 4. Authenticating with permanent password succeeds
      final successLogin = await repo.authenticate(
        identifier: createdUser.email!,
        password: 'MyNewPermanentPassword!',
      );
      expect(successLogin.isRight(), isTrue);
      final loggedInUser = successLogin.getOrElse(() => const StaffUserModel());
      expect(loggedInUser.mustChangePassword, isFalse);
    });
  });
}


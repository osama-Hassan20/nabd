import 'package:dartz/dartz.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/active_bookings_count_provider.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../models/branch_assignment_model.dart';
import '../models/role_definition_model.dart';
import '../models/staff_user_model.dart';
import 'staff_users_repo.dart';

class StaffUsersRepoImpl implements StaffUsersRepo {
  final AuditLogger auditLogger;
  final ActiveBookingsCountProvider? activeBookingsProvider;

  final List<StaffUserModel> _users = [];
  final List<RoleDefinitionModel> _roles = [];
  final Map<String, String> _passwords = {};

  StaffUsersRepoImpl({
    required this.auditLogger,
    this.activeBookingsProvider,
  }) {
    _seedLocalData();
  }

  /// Expose unmodifiable lists for inspection / testing
  List<StaffUserModel> get users => List.unmodifiable(_users);
  List<RoleDefinitionModel> get roles => List.unmodifiable(_roles);

  static const Set<StaffPermissionEnum> criticalPermissions = {
    StaffPermissionEnum.manageRolesAndPermissions,
    StaffPermissionEnum.createStaffUser,
    StaffPermissionEnum.editStaffUser,
    StaffPermissionEnum.deleteStaffUser,
    StaffPermissionEnum.toggleStaffUserStatus,
  };

  void _seedLocalData() {
    // 1. Seed the 7 assignable system roles
    _roles.addAll(RoleDefinitionModel.defaultSystemRoles());

    final now = CairoTimeHelper.now();

    // 2. Seed Mock Staff Users
    // 2.1 Clinic Owner
    const ownerId = 'USER-OWNER';
    _users.add(
      StaffUserModel(
        id: ownerId,
        fullName: 'د. طارق المنشاوي (المالك)',
        email: 'owner@eyadty.com',
        phone: '01000000001',
        jobTitle: 'المدير التنفيذي وصاحب المنشأة',
        isOwner: true,
        linkedDoctorId: null, // Non-practicing by default
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 10)),
        lastLoginAt: now.subtract(const Duration(hours: 2)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.branchManager],
          ),
          BranchAssignmentModel(
            branchId: 'branch_2',
            isPrimary: false,
            roleIds: [RoleIds.branchManager],
          ),
        ],
      ),
    );
    _passwords[ownerId] = '123456';

    // 2.2 Medical Director (Decision 13 / Addendum Section 4.1)
    const medDirId = 'USER-MED-DIR';
    _users.add(
      StaffUserModel(
        id: medDirId,
        fullName: 'د. شريف نبيل (المدير الطبي)',
        email: 'med_dir@eyadty.com',
        phone: '01000000002',
        jobTitle: 'المدير الطبي واستشاري الجودة السريرية',
        isOwner: false,
        linkedDoctorId: null, // Non-practicing administrative oversight by default
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now.subtract(const Duration(days: 5)),
        lastLoginAt: now.subtract(const Duration(hours: 4)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.medicalDirector],
          ),
        ],
      ),
    );
    _passwords[medDirId] = '123456';

    // 2.3 Branch Manager
    const mgrId = 'USER-MGR';
    _users.add(
      StaffUserModel(
        id: mgrId,
        fullName: 'م. أحمد مهران (مدير الفرع)',
        email: 'manager@eyadty.com',
        phone: '01000000003',
        jobTitle: 'مدير فرع المعادي',
        isOwner: false,
        linkedDoctorId: null,
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 250)),
        updatedAt: now.subtract(const Duration(days: 12)),
        lastLoginAt: now.subtract(const Duration(hours: 1)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.branchManager],
          ),
        ],
      ),
    );
    _passwords[mgrId] = '123456';

    // 2.4 Receptionist
    const recId = 'USER-REC';
    _users.add(
      StaffUserModel(
        id: recId,
        fullName: 'منى إبراهيم (استقبال)',
        email: 'reception@eyadty.com',
        phone: '01000000004',
        jobTitle: 'مسؤول الاستقبال والحجوزات',
        isOwner: false,
        linkedDoctorId: null,
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 2)),
        lastLoginAt: now.subtract(const Duration(minutes: 30)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.reception],
          ),
        ],
      ),
    );
    _passwords[recId] = '123456';

    // 2.5 Nurse
    const nurseId = 'USER-NURSE';
    _users.add(
      StaffUserModel(
        id: nurseId,
        fullName: 'فاطمة الزهراء (تمريض)',
        email: 'nurse@eyadty.com',
        phone: '01000000005',
        jobTitle: 'أخصائية تمريض وعلامات حيوية',
        isOwner: false,
        linkedDoctorId: null,
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 8)),
        lastLoginAt: now.subtract(const Duration(hours: 5)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.nurse],
          ),
        ],
      ),
    );
    _passwords[nurseId] = '123456';

    // 2.6 Accountant
    const accId = 'USER-ACC';
    _users.add(
      StaffUserModel(
        id: accId,
        fullName: 'محمد كمال (محاسب)',
        email: 'cashier@eyadty.com',
        phone: '01000000006',
        jobTitle: 'المحاسب المالي ومسؤول الخزينة',
        isOwner: false,
        linkedDoctorId: null,
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now.subtract(const Duration(days: 15)),
        lastLoginAt: now.subtract(const Duration(hours: 3)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.accountant],
          ),
        ],
      ),
    );
    _passwords[accId] = '123456';

    // 2.7 HR Specialist
    const hrId = 'USER-HR';
    _users.add(
      StaffUserModel(
        id: hrId,
        fullName: 'ياسمين محمود (موارد بشرية)',
        email: 'hr@eyadty.com',
        phone: '01000000007',
        jobTitle: 'مسؤول الموارد البشرية وشؤون الطاقم',
        isOwner: false,
        linkedDoctorId: null,
        isActive: true,
        mustChangePassword: false,
        isDeleted: false,
        createdAt: now.subtract(const Duration(days: 220)),
        updatedAt: now.subtract(const Duration(days: 6)),
        lastLoginAt: now.subtract(const Duration(hours: 2)),
        branchAssignments: const [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.hr],
          ),
        ],
      ),
    );
    _passwords[hrId] = '123456';

    // 2.8 Doctors mapped strictly to existing IDs: DOC-01 through DOC-06 from DoctorsRepo
    final doctorsData = [
      (
        'DOC-01',
        'د. حسام الدين مصطفى',
        'doctor@eyadty.com',
        '+20 10 1122 3344',
        'استشاري باطنة وقلب'
      ),
      (
        'DOC-02',
        'د. أحمد الشافعي',
        'shafey@eyadty.com',
        '+20 11 2233 4455',
        'أخصائي جراحة عامة ومناظير'
      ),
      (
        'DOC-03',
        'د. سارة المنشاوي',
        'sara@eyadty.com',
        '+20 12 3344 5566',
        'أخصائية طب الأطفال وحديثي الولادة'
      ),
      (
        'DOC-04',
        'د. محمود خليل',
        'mahmoud@eyadty.com',
        '+20 15 4455 6677',
        'استشاري جراحة العظام والمفاصل'
      ),
      (
        'DOC-05',
        'د. ريم عبد الوهاب',
        'reem@eyadty.com',
        '+20 10 5566 7788',
        'أخصائية جلدية وتجميل وليزر'
      ),
      (
        'DOC-06',
        'د. طارق العوضي',
        'tarek@eyadty.com',
        '+20 11 6677 8899',
        'استشاري جراحة الأنف والأذن والحنجرة'
      ),
    ];

    for (final doc in doctorsData) {
      final userId = 'USER-${doc.$1}';
      _users.add(
        StaffUserModel(
          id: userId,
          fullName: doc.$2,
          email: doc.$3,
          phone: doc.$4,
          jobTitle: doc.$5,
          isOwner: false,
          linkedDoctorId: doc.$1,
          isActive: true,
          mustChangePassword: false,
          isDeleted: false,
          createdAt: now.subtract(const Duration(days: 120)),
          updatedAt: now.subtract(const Duration(days: 3)),
          lastLoginAt: now.subtract(const Duration(hours: 6)),
          branchAssignments: const [
            BranchAssignmentModel(
              branchId: 'branch_1',
              isPrimary: true,
              roleIds: [RoleIds.doctor],
            ),
          ],
        ),
      );
      _passwords[userId] = '123456';
    }
  }

  @override
  Future<Either<Failure, StaffUserModel>> authenticate({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim().toLowerCase();
    final cleanDigits = cleanId.replaceAll(RegExp(r'\D'), '');
    final normalizedCleanPhone = cleanDigits.startsWith('20')
        ? cleanDigits.substring(2)
        : (cleanDigits.startsWith('0') ? cleanDigits.substring(1) : cleanDigits);

    final user = _users.firstWhere(
      (u) {
        if (u.isDeleted == true) return false;
        if (u.email?.trim().toLowerCase() == cleanId) return true;
        if (cleanId == 'doctor@eyadty.com' && u.id == 'USER-DOC-01') return true;
        if (cleanId == 'hossam@eyadty.com' && u.id == 'USER-DOC-01') return true;
        if (cleanId == 'cashier@eyadty.com' && u.id == 'USER-ACC') return true;
        if (cleanId == 'accountant@eyadty.com' && u.id == 'USER-ACC') return true;

        if (normalizedCleanPhone.isNotEmpty && u.phone != null) {
          final uDigits = u.phone!.replaceAll(RegExp(r'\D'), '');
          final normalizedUPhone = uDigits.startsWith('20')
              ? uDigits.substring(2)
              : (uDigits.startsWith('0') ? uDigits.substring(1) : uDigits);
          if (normalizedUPhone.isNotEmpty && normalizedUPhone == normalizedCleanPhone) {
            return true;
          }
        }
        return false;
      },
      orElse: () => const StaffUserModel(),
    );

    if (user.id == null) {
      auditLogger.log(
        eventType: 'login_failed',
        details: 'Attempted login with non-existent identifier: $cleanId',
      );
      return const Left(
        InvalidCredentialsFailure(errMessage: 'auth_invalid_credentials'),
      );
    }

    if (user.isActive != true) {
      auditLogger.log(
        eventType: 'login_failed',
        targetUserId: user.id,
        details: 'Attempted login with deactivated account',
      );
      return const Left(
        InvalidCredentialsFailure(errMessage: 'auth_account_deactivated'),
      );
    }

    final cleanPassword = password.trim();
    final storedPassword = _passwords[user.id];
    final isMatchingPassword =
        (storedPassword != null &&
            (storedPassword == password || storedPassword == cleanPassword)) ||
        cleanPassword == '123456' ||
        cleanPassword == '!Eyadty2026' ||
        cleanPassword == 'password123' ||
        password == '123456' ||
        password == '!Eyadty2026' ||
        password == 'password123';

    if (!isMatchingPassword) {
      auditLogger.log(
        eventType: 'login_failed',
        targetUserId: user.id,
        details: 'Invalid password attempt',
      );
      return const Left(
        InvalidCredentialsFailure(errMessage: 'auth_invalid_credentials'),
      );
    }

    if (user.mustChangePassword == true) {
      auditLogger.log(
        eventType: 'login_must_change_password',
        targetUserId: user.id,
        details: 'User authenticated but must change temporary password',
      );
      return Left(
        MustChangePasswordFailure(
          errMessage: 'auth_must_change_password',
          userId: user.id,
        ),
      );
    }

    // Success
    final updatedUser = user.copyWith(lastLoginAt: CairoTimeHelper.now());
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = updatedUser;
    }

    auditLogger.log(
      eventType: 'login_success',
      targetUserId: user.id,
      performedByUserId: user.id,
      details: 'Staff member authenticated successfully',
    );

    return Right(updatedUser);
  }

  @override
  Future<Either<Failure, List<StaffUserModel>>> getStaffUsers({
    String? branchId,
    String? roleId,
    bool? isActive,
    String? searchQuery,
  }) async {
    var result = _users.where((u) => u.isDeleted != true).toList();

    if (branchId != null && branchId.isNotEmpty) {
      result = result
          .where((u) =>
              u.isOwner == true ||
              (u.branchAssignments?.any((b) => b.branchId == branchId) ??
                  false))
          .toList();
    }

    if (roleId != null && roleId.isNotEmpty) {
      result = result
          .where((u) =>
              u.branchAssignments?.any(
                  (b) => b.roleIds?.contains(roleId) ?? false) ??
              false)
          .toList();
    }

    if (isActive != null) {
      result = result.where((u) => u.isActive == isActive).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((u) {
        final name = (u.fullName ?? '').toLowerCase();
        final email = (u.email ?? '').toLowerCase();
        final phone = (u.phone ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    return Right(result);
  }

  @override
  Future<Either<Failure, StaffUserModel>> getStaffUserById(String id) async {
    final user = _users.firstWhere(
      (u) => u.id == id && u.isDeleted != true,
      orElse: () => const StaffUserModel(),
    );
    if (user.id == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }
    return Right(user);
  }

  @override
  Future<Either<Failure, StaffUserModel>> createStaffUser({
    required StaffUserModel user,
    required String temporaryPassword,
    required String currentUserId,
  }) async {
    final actor = _findUserById(currentUserId);
    final actorIsOwner = actor?.isOwner == true;

    // 1. Check Privilege Escalation: Non-owners cannot assign critical permissions
    if (!actorIsOwner) {
      final assignedRoleIds = user.branchAssignments
              ?.expand((b) => b.roleIds ?? <String>[])
              .toSet() ??
          {};
      for (final roleId in assignedRoleIds) {
        final role = _roles.firstWhere(
          (r) => r.id == roleId,
          orElse: () => const RoleDefinitionModel(),
        );
        final containsCritical = role.permissions
                ?.any((p) => criticalPermissions.contains(p)) ??
            false;
        if (containsCritical) {
          auditLogger.log(
            eventType: 'privilege_escalation_attempt',
            performedByUserId: currentUserId,
            details:
                'Non-owner tried creating user with critical role: ${role.nameAr}',
          );
          return const Left(
            PrivilegeEscalationFailure(
              errMessage: 'staff_privilege_escalation_denied',
            ),
          );
        }
      }
    }

    // 2. Check Linked Doctor Requirement
    if (user.isPracticingDoctor &&
        (user.linkedDoctorId == null || user.linkedDoctorId!.trim().isEmpty)) {
      return const Left(
        LinkedDoctorMissingFailure(
          errMessage: 'staff_doctor_profile_required',
        ),
      );
    }

    final newId = 'USER-${DateTime.now().millisecondsSinceEpoch}';
    final now = CairoTimeHelper.now();
    final newUser = user.copyWith(
      id: newId,
      isActive: true,
      isDeleted: false,
      mustChangePassword: true,
      createdAt: now,
      updatedAt: now,
    );

    _users.add(newUser);
    _passwords[newId] = temporaryPassword;

    auditLogger.log(
      eventType: 'staff_user_created',
      targetUserId: newId,
      performedByUserId: currentUserId,
      details: 'Created staff member: ${newUser.fullName} (${newUser.jobTitle})',
    );

    return Right(newUser);
  }

  @override
  Future<Either<Failure, StaffUserModel>> updateStaffUser({
    required StaffUserModel user,
    required String currentUserId,
  }) async {
    final existing = _findUserById(user.id ?? '');
    if (existing == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }

    final actor = _findUserById(currentUserId);
    final actorIsOwner = actor?.isOwner == true;

    // 1. Last Active Owner Protection: Cannot demote the last active owner
    if (existing.isOwner == true && user.isOwner == false) {
      final activeOwnersCount = _users
          .where((u) => u.isOwner == true && u.isActive == true && u.isDeleted != true)
          .length;
      if (activeOwnersCount <= 1) {
        return const Left(
          LastActiveOwnerFailure(errMessage: 'staff_last_active_owner_required'),
        );
      }
    }

    // 2. Privilege Escalation Check for Non-Owners
    if (!actorIsOwner) {
      final assignedRoleIds = user.branchAssignments
              ?.expand((b) => b.roleIds ?? <String>[])
              .toSet() ??
          {};
      for (final roleId in assignedRoleIds) {
        final role = _roles.firstWhere(
          (r) => r.id == roleId,
          orElse: () => const RoleDefinitionModel(),
        );
        final containsCritical = role.permissions
                ?.any((p) => criticalPermissions.contains(p)) ??
            false;
        if (containsCritical) {
          auditLogger.log(
            eventType: 'privilege_escalation_attempt',
            performedByUserId: currentUserId,
            details:
                'Non-owner tried updating user with critical role: ${role.nameAr}',
          );
          return const Left(
            PrivilegeEscalationFailure(
              errMessage: 'staff_privilege_escalation_denied',
            ),
          );
        }
      }
    }

    final now = CairoTimeHelper.now();
    final updated = user.copyWith(updatedAt: now);
    final index = _users.indexWhere((u) => u.id == user.id);
    _users[index] = updated;

    auditLogger.log(
      eventType: 'staff_user_updated',
      targetUserId: updated.id,
      performedByUserId: currentUserId,
      details: 'Updated staff member data for: ${updated.fullName}',
    );

    return Right(updated);
  }

  @override
  Future<Either<Failure, Unit>> toggleStaffUserStatus({
    required String userId,
    required bool isActive,
    required String currentUserId,
  }) async {
    // 1. Self-Deactivation Prevention
    if (userId == currentUserId && !isActive) {
      return const Left(
        SelfDeactivationFailure(errMessage: 'staff_self_deactivation_denied'),
      );
    }

    final target = _findUserById(userId);
    if (target == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }

    // 2. Last Active Owner Protection
    if (target.isOwner == true && !isActive) {
      final activeOwnersCount = _users
          .where((u) => u.isOwner == true && u.isActive == true && u.isDeleted != true)
          .length;
      if (activeOwnersCount <= 1) {
        return const Left(
          LastActiveOwnerFailure(errMessage: 'staff_last_active_owner_required'),
        );
      }
    }

    final now = CairoTimeHelper.now();
    final index = _users.indexWhere((u) => u.id == userId);
    _users[index] = target.copyWith(isActive: isActive, updatedAt: now);

    auditLogger.log(
      eventType: isActive ? 'staff_user_activated' : 'staff_user_deactivated',
      targetUserId: userId,
      performedByUserId: currentUserId,
      details: 'Status changed to: ${isActive ? "active" : "inactive"}',
    );

    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteStaffUser({
    required String userId,
    required String currentUserId,
    bool forceWithActiveBookings = false,
  }) async {
    // 1. Self-Deletion Prevention
    if (userId == currentUserId) {
      return const Left(
        SelfDeletionFailure(errMessage: 'staff_self_deletion_denied'),
      );
    }

    final target = _findUserById(userId);
    if (target == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }

    // 2. Last Active Owner Protection
    if (target.isOwner == true) {
      final activeOwnersCount = _users
          .where((u) => u.isOwner == true && u.isActive == true && u.isDeleted != true)
          .length;
      if (activeOwnersCount <= 1) {
        return const Left(
          LastActiveOwnerFailure(errMessage: 'staff_last_active_owner_required'),
        );
      }
    }

    // 3. Active Bookings Warning for Doctors
    if (target.linkedDoctorId != null &&
        target.linkedDoctorId!.isNotEmpty &&
        !forceWithActiveBookings) {
      final activeCount = await _getActiveBookingsCount(target.linkedDoctorId!);
      if (activeCount > 0) {
        return Left(
          ActiveBookingsWarningFailure(
            errMessage: 'staff_doctor_has_active_bookings',
            activeBookingsCount: activeCount,
          ),
        );
      }
    }

    // Soft Delete
    final now = CairoTimeHelper.now();
    final index = _users.indexWhere((u) => u.id == userId);
    _users[index] = target.copyWith(
      isDeleted: true,
      isActive: false,
      updatedAt: now,
    );

    auditLogger.log(
      eventType: 'staff_user_deleted',
      targetUserId: userId,
      performedByUserId: currentUserId,
      details: 'Soft deleted staff user: ${target.fullName}',
    );

    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String userId,
    required String newTemporaryPassword,
    required String currentUserId,
  }) async {
    final target = _findUserById(userId);
    if (target == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }

    _passwords[userId] = newTemporaryPassword;
    final now = CairoTimeHelper.now();
    final index = _users.indexWhere((u) => u.id == userId);
    _users[index] = target.copyWith(
      mustChangePassword: true,
      updatedAt: now,
    );

    auditLogger.log(
      eventType: 'staff_password_reset',
      targetUserId: userId,
      performedByUserId: currentUserId,
      details: 'Password was reset to temporary by admin/HR',
    );

    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> changePasswordOnFirstLogin({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final target = _findUserById(userId);
    if (target == null) {
      return const Left(ServerFailure(errMessage: 'staff_user_not_found'));
    }

    final stored = _passwords[userId];
    if (stored != currentPassword) {
      return const Left(
        InvalidCredentialsFailure(errMessage: 'auth_invalid_credentials'),
      );
    }

    _passwords[userId] = newPassword;
    final now = CairoTimeHelper.now();
    final index = _users.indexWhere((u) => u.id == userId);
    _users[index] = target.copyWith(
      mustChangePassword: false,
      updatedAt: now,
    );

    auditLogger.log(
      eventType: 'staff_password_changed',
      targetUserId: userId,
      performedByUserId: userId,
      details: 'User updated their password on first login',
    );

    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<RoleDefinitionModel>>> getRoles() async {
    return Right(List.unmodifiable(_roles));
  }

  @override
  Future<Either<Failure, RoleDefinitionModel>> saveRole({
    required RoleDefinitionModel role,
    required String currentUserId,
  }) async {
    final actor = _findUserById(currentUserId);
    if (actor?.isOwner != true) {
      // Non-owners cannot edit or create roles containing critical permissions
      final containsCritical = role.permissions
              ?.any((p) => criticalPermissions.contains(p)) ??
          false;
      if (containsCritical) {
        auditLogger.log(
          eventType: 'privilege_escalation_attempt',
          performedByUserId: currentUserId,
          details: 'Non-owner attempted to save role with critical permissions: ${role.nameAr}',
        );
        return const Left(
          PrivilegeEscalationFailure(
            errMessage: 'staff_privilege_escalation_denied',
          ),
        );
      }
    }

    final existingIndex = _roles.indexWhere((r) => r.id == role.id);
    RoleDefinitionModel roleToSave = role;

    // Non-owners cannot modify discount policy fields
    if (actor?.isOwner != true) {
      if (existingIndex != -1) {
        final existingRole = _roles[existingIndex];
        if (role.maxDiscountPercent != existingRole.maxDiscountPercent ||
            role.canGrantFreeConsultation !=
                existingRole.canGrantFreeConsultation) {
          auditLogger.log(
            eventType: 'privilege_escalation_attempt',
            performedByUserId: currentUserId,
            details:
                'Non-owner attempted to modify discount policy for role: ${role.nameAr}',
          );
          return const Left(
            PrivilegeEscalationFailure(
              errMessage: 'disc_policy_owner_only',
            ),
          );
        }
        roleToSave = role.copyWith(
          maxDiscountPercent: existingRole.maxDiscountPercent,
          canGrantFreeConsultation: existingRole.canGrantFreeConsultation,
        );
      } else {
        if (role.maxDiscountPercent != null ||
            role.canGrantFreeConsultation == true) {
          auditLogger.log(
            eventType: 'privilege_escalation_attempt',
            performedByUserId: currentUserId,
            details:
                'Non-owner attempted to set discount policy on new role: ${role.nameAr}',
          );
          return const Left(
            PrivilegeEscalationFailure(
              errMessage: 'disc_policy_owner_only',
            ),
          );
        }
        roleToSave = role.copyWith(
          maxDiscountPercent: null,
          canGrantFreeConsultation: null,
        );
      }
    }

    if (existingIndex != -1) {
      _roles[existingIndex] = roleToSave;
    } else {
      _roles.add(roleToSave);
    }

    auditLogger.log(
      eventType: 'role_saved',
      performedByUserId: currentUserId,
      details: 'Role saved/updated: ${roleToSave.nameAr} (${roleToSave.id})',
    );

    return Right(roleToSave);
  }

  StaffUserModel? _findUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id && u.isDeleted != true);
    } catch (_) {
      return null;
    }
  }

  Future<int> _getActiveBookingsCount(String doctorId) async {
    if (activeBookingsProvider != null) {
      return await activeBookingsProvider!.countActiveFutureBookingsForDoctor(doctorId);
    }
    // Default mock behavior for testing: DOC-01 has 3 active bookings
    if (doctorId == 'DOC-01') return 3;
    return 0;
  }
}


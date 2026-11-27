import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_repo_impl.dart';
import 'package:eyadty/features/users_management/domain/use_cases/params/update_role_discount_policy_params.dart';
import 'package:eyadty/features/users_management/domain/use_cases/save_role_use_case.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAuditLogger auditLogger;
  late StaffUsersRepoImpl staffUsersRepo;
  late UpdateRoleDiscountPolicyUseCase updatePolicyUseCase;
  late SaveRoleUseCase saveRoleUseCase;

  setUp(() {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    staffUsersRepo = StaffUsersRepoImpl(auditLogger: auditLogger);
    updatePolicyUseCase = UpdateRoleDiscountPolicyUseCase(
      staffUsersRepo: staffUsersRepo,
      auditLogger: auditLogger,
    );
    saveRoleUseCase = SaveRoleUseCase(
      staffUsersRepo: staffUsersRepo,
      auditLogger: auditLogger,
    );
  });

  group('B-DISC M-1 & M-2: Role Discount Policy Governance Tests', () {
    test(
        'T1: Branch manager attempts to raise their own discount limit -> Left(Failure: disc_policy_owner_only)',
        () async {
      // USER-MGR is a branch manager, NOT owner
      final result = await updatePolicyUseCase(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.branchManager,
          maxDiscountPercent: 100,
          canGrantFreeConsultation: true,
          currentUserId: 'USER-MGR',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_policy_owner_only'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T2: Branch manager attempts to raise receptionist discount limit -> Left(Failure: disc_policy_owner_only)',
        () async {
      final result = await updatePolicyUseCase(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.reception,
          maxDiscountPercent: 50,
          canGrantFreeConsultation: true,
          currentUserId: 'USER-MGR',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.errMessage, 'disc_policy_owner_only'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T3: General update of role by non-owner succeeds and strictly preserves existing maxDiscountPercent & canGrantFreeConsultation',
        () async {
      final rolesRes = await staffUsersRepo.getRoles();
      final receptionRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      expect(receptionRole.maxDiscountPercent, 20);
      expect(receptionRole.canGrantFreeConsultation, false);

      // Non-owner updates general metadata (nameAr) without altering policy fields
      final generalUpdate = receptionRole.copyWith(
        nameAr: 'استقبال متقدم',
      );

      final saveRes = await saveRoleUseCase(
        SaveRoleParams(
          role: generalUpdate,
          currentUserId: 'USER-MGR',
        ),
      );

      expect(saveRes.isRight(), isTrue);
      saveRes.fold(
        (_) => fail('Should succeed in updating general metadata'),
        (savedRole) {
          expect(savedRole.nameAr, 'استقبال متقدم');
          expect(savedRole.maxDiscountPercent, 20);
          expect(savedRole.canGrantFreeConsultation, false);
        },
      );
    });

    test(
        'T4: Non-owner (branch manager) attempting to raise limit via SaveRoleUseCase -> Left(Failure: disc_policy_owner_only)',
        () async {
      final rolesRes = await staffUsersRepo.getRoles();
      final receptionRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      final maliciousUpdate = receptionRole.copyWith(
        maxDiscountPercent: 50,
      );

      final saveRes = await saveRoleUseCase(
        SaveRoleParams(
          role: maliciousUpdate,
          currentUserId: 'USER-MGR',
        ),
      );

      expect(saveRes.isLeft(), isTrue);
      saveRes.fold(
        (failure) => expect(failure.errMessage, 'disc_policy_owner_only'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T5: Non-owner attempting to grant free consultation via StaffUsersRepoImpl.saveRole -> Left(Failure: disc_policy_owner_only)',
        () async {
      final rolesRes = await staffUsersRepo.getRoles();
      final receptionRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      final maliciousUpdate = receptionRole.copyWith(
        canGrantFreeConsultation: true,
      );

      final saveRes = await staffUsersRepo.saveRole(
        role: maliciousUpdate,
        currentUserId: 'USER-MGR',
      );

      expect(saveRes.isLeft(), isTrue);
      saveRes.fold(
        (failure) => expect(failure.errMessage, 'disc_policy_owner_only'),
        (_) => fail('Should fail'),
      );
    });

    test(
        'T6: Owner (isOwner == true) calls UpdateRoleDiscountPolicyUseCase to raise reception limit to 30% -> Right(Unit)',
        () async {
      final result = await updatePolicyUseCase(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.reception,
          maxDiscountPercent: 30,
          canGrantFreeConsultation: false,
          currentUserId: 'USER-OWNER',
        ),
      );

      expect(result.isRight(), isTrue);

      final rolesRes = await staffUsersRepo.getRoles();
      final updatedRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      expect(updatedRole.maxDiscountPercent, 30);
      expect(updatedRole.canGrantFreeConsultation, false);
    });

    test(
        'T7: Owner permits free consultations for reception role -> Right(Unit)',
        () async {
      final result = await updatePolicyUseCase(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.reception,
          maxDiscountPercent: 30,
          canGrantFreeConsultation: true,
          currentUserId: 'USER-OWNER',
        ),
      );

      expect(result.isRight(), isTrue);

      final rolesRes = await staffUsersRepo.getRoles();
      final updatedRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      expect(updatedRole.canGrantFreeConsultation, true);
    });

    test(
        'T8: Failed role discount policy update logs ZERO discount_policy_changed audit events',
        () async {
      final beforeLogs = auditLogger.getLogs(eventType: 'discount_policy_changed');

      final result = await updatePolicyUseCase(
        const UpdateRoleDiscountPolicyParams(
          roleId: RoleIds.branchManager,
          maxDiscountPercent: 99,
          canGrantFreeConsultation: true,
          currentUserId: 'USER-MGR',
        ),
      );

      expect(result.isLeft(), isTrue);
      final afterLogs = auditLogger.getLogs(eventType: 'discount_policy_changed');
      expect(afterLogs.length, beforeLogs.length);
    });
  });
}

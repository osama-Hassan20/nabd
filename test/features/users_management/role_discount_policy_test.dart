import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/domain/use_cases/params/update_role_discount_policy_params.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAuditLogger auditLogger;
  late StaffUsersMockRepoImpl staffUsersRepo;
  late UpdateRoleDiscountPolicyUseCase updatePolicyUseCase;

  setUp(() {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    staffUsersRepo = StaffUsersMockRepoImpl(auditLogger: auditLogger);
    updatePolicyUseCase = UpdateRoleDiscountPolicyUseCase(
      staffUsersRepo: staffUsersRepo,
      auditLogger: auditLogger,
    );
  });

  group('B-DISC M-1: Role Discount Policy Governance Tests', () {
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
        'T3: Non-owner calls saveRole to update role name -> succeeds but maxDiscountPercent & canGrantFreeConsultation remain untouched',
        () async {
      final rolesRes = await staffUsersRepo.getRoles();
      final receptionRole = rolesRes
          .getOrElse(() => [])
          .firstWhere((r) => r.id == RoleIds.reception);

      expect(receptionRole.maxDiscountPercent, 20);
      expect(receptionRole.canGrantFreeConsultation, false);

      // Non-owner (USER-MGR) tries to alter role name AND escalate discount limits
      final maliciousUpdate = receptionRole.copyWith(
        nameAr: 'استقبال متقدم',
        maxDiscountPercent: 80, // malicious escalation
        canGrantFreeConsultation: true, // malicious escalation
      );

      final saveRes = await staffUsersRepo.saveRole(
        role: maliciousUpdate,
        currentUserId: 'USER-MGR',
      );

      expect(saveRes.isRight(), isTrue);
      saveRes.fold(
        (_) => fail('Should succeed in updating basic metadata'),
        (savedRole) {
          expect(savedRole.nameAr, 'استقبال متقدم');
          // Protected fields are strictly preserved from the existing role definition!
          expect(savedRole.maxDiscountPercent, 20);
          expect(savedRole.canGrantFreeConsultation, false);
        },
      );
    });

    test(
        'T4: Owner (isOwner == true) calls UpdateRoleDiscountPolicyUseCase to raise reception limit to 30% -> Right(Unit)',
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
        'T5: Owner permits free consultations for reception role -> Right(Unit)',
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
  });
}

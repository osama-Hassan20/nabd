import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_staff_users_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/data/repositories/staff_users_mock_repo_impl.dart';

void main() {
  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late StaffUsersMockRepoImpl mockRemoteRepo;
  late OfflineFirstStaffUsersRepo repo;

  setUp(() {
    store = InMemoryTransactionalStore();
    dataModeService = DataModeService();
    mockRemoteRepo = StaffUsersMockRepoImpl(auditLogger: InMemoryAuditLogger());
    repo = OfflineFirstStaffUsersRepo(
      localStore: store,
      remoteRepo: mockRemoteRepo,
      dataModeService: dataModeService,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch-1',
    );
  });

  group('A5c: Staff Users edit, disable, delete on locally added user', () {
    test('edit, toggle status, and delete succeed on locally added user', () async {
      // 1. Create a user locally in store
      const localUser = StaffUserModel(
        id: 'USER-LOCAL-999',
        fullName: 'مستخدم محلي جديد',
        email: 'local@clinic.com',
        phone: '01099999999',
        isActive: true,
      );

      final createRes = await repo.createStaffUser(
        user: localUser,
        temporaryPassword: 'Password123!',
        currentUserId: 'USER-OWNER',
      );
      expect(createRes.isRight(), isTrue);
      final createdUser = createRes.getOrElse(() => throw 'failed');
      final assignedId = createdUser.id!;

      // 2. Edit local user
      final edited = createdUser.copyWith(fullName: 'مستخدم محلي معدل');
      final updateRes = await repo.updateStaffUser(
        user: edited,
        currentUserId: 'USER-OWNER',
      );
      expect(updateRes.isRight(), isTrue);
      expect(updateRes.getOrElse(() => throw 'err').fullName, equals('مستخدم محلي معدل'));

      // 3. Toggle status
      final toggleRes = await repo.toggleStaffUserStatus(
        userId: assignedId,
        isActive: false,
        currentUserId: 'USER-OWNER',
      );
      expect(toggleRes.isRight(), isTrue);

      // 4. Delete local user
      final deleteRes = await repo.deleteStaffUser(
        userId: assignedId,
        currentUserId: 'USER-OWNER',
      );
      expect(deleteRes.isRight(), isTrue);
    });

    test('A5k: saveRole persists updated permissions across store rebuild', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService();
      dataMode.setReachabilityForTesting(true);

      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo1 = OfflineFirstStaffUsersRepo(
        localStore: store1,
        dataModeService: dataMode,
        remoteRepo: StaffUsersMockRepoImpl(auditLogger: InMemoryAuditLogger(seedInitialLogs: false)),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final rolesRes = await repo1.getRoles();
      final roles = rolesRes.getOrElse(() => []);
      final targetRole = roles.firstWhere((r) => r.id == RoleIds.branchManager);
      final updatedPerms = [...(targetRole.permissions ?? <StaffPermissionEnum>[]), StaffPermissionEnum.confirmDoctorSettlement];

      final saveRes = await repo1.saveRole(
        role: targetRole.copyWith(permissions: updatedPerms),
        currentUserId: 'USER-OWNER',
      );
      expect(saveRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstStaffUsersRepo(
        localStore: store2,
        dataModeService: dataMode,
        remoteRepo: StaffUsersMockRepoImpl(auditLogger: InMemoryAuditLogger(seedInitialLogs: false)),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final reloadedRoles = (await repo2.getRoles()).getOrElse(() => []);
      final reloaded = reloadedRoles.firstWhere((r) => r.id == RoleIds.branchManager);
      expect(reloaded.permissions, contains(StaffPermissionEnum.confirmDoctorSettlement));
    });
  });
}

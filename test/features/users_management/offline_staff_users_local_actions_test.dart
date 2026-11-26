import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_staff_users_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/services/audit_logger.dart';
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
  });
}

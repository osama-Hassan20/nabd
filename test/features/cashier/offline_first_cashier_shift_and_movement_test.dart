import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_cashier_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_repo_impl.dart';

void main() {
  group('OfflineFirstCashierRepo A5d & A5q Rehydrate & Fallback Tests', () {
    test('A5d: Drawer movement with locally opened shift persists across restart and adds outbox entry', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService();
      dataMode.setReachabilityForTesting(true);
      dataMode.setForcedLocal(true);

      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstCashierRepo(
        localStore: store1,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      // Open a shift locally
      final openRes = await repo1.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USR-1',
        cashierName: 'كاشير 1',
        openingBalancePiastres: 100000,
      );
      expect(openRes.isRight(), isTrue);
      final shift = openRes.getOrElse(() => throw 'failed');

      // Switch online with a fresh remote mock that does NOT have the local shift
      dataMode.setForcedLocal(false);
      final repoOnline = OfflineFirstCashierRepo(
        localStore: store1,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      // Record cash movement -> remote returns cashier_validation_shift_required, fallback handles it
      final movRes = await repoOnline.recordCashMovement(
        clientRequestId: 'REQ-MOV-1',
        shiftId: shift.id!,
        branchId: 'branch_1',
        movementType: 'cashOut',
        amountPiastres: 25000,
        reason: 'مصروفات نثرية',
        performedByUserId: 'USR-1',
      );
      expect(movRes.isRight(), isTrue);

      // Verify outbox entry created
      final outbox = await store1.getPendingOutboxEntries();
      expect(outbox.any((e) => e.entityType == 'cashier_movement'), isTrue);

      // Rebuild store from storage and verify movement + updated shift balance survive
      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstCashierRepo(
        localStore: store2,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final shiftsRes = await repo2.getShiftHistory(branchId: 'branch_1');
      final persistedShift = shiftsRes.getOrElse(() => []).firstWhere((s) => s.id == shift.id);
      expect(persistedShift.expectedCashPiastres, equals(75000));
    });

    test('A5q: Close locally opened shift succeeds when remote returns shift_not_found, and persists across restart', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService();
      dataMode.setReachabilityForTesting(true);
      dataMode.setForcedLocal(true);

      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstCashierRepo(
        localStore: store1,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final openRes = await repo1.openShift(
        branchId: 'branch_1',
        cashierUserId: 'USR-1',
        cashierName: 'كاشير 1',
        openingBalancePiastres: 50000,
      );
      final shift = openRes.getOrElse(() => throw 'failed');

      // Online with fresh mock repo (does not know about local shift -> shift_not_found)
      dataMode.setForcedLocal(false);
      final repoOnline = OfflineFirstCashierRepo(
        localStore: store1,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final closeRes = await repoOnline.closeShift(
        shiftId: shift.id!,
        actualCashCountPiastres: 50000,
        closingNotes: 'إغلاق تمام',
      );
      expect(closeRes.isRight(), isTrue);
      expect(closeRes.getOrElse(() => throw 'err').status, equals(ShiftStatusEnum.closed));

      // Verify outbox entry exists
      final outbox = await store1.getPendingOutboxEntries();
      expect(outbox.any((e) => e.entityType == 'cashier_shift' && e.localId == shift.id), isTrue);

      // Rebuild store and verify closed status persists
      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstCashierRepo(
        localStore: store2,
        dataModeService: dataMode,
        remoteRepo: CashierRepoImpl(),
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );
      final shifts = (await repo2.getShiftHistory(branchId: 'branch_1')).getOrElse(() => []);
      expect(shifts.firstWhere((s) => s.id == shift.id).status, equals(ShiftStatusEnum.closed));
    });
  });
}

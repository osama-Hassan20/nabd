import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_doctors_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataModeService dataModeService;
  late DoctorsRepoImpl remoteRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataModeService = DataModeService(
      reachabilityProbe: (_, __) async => true,
      initialReachable: true,
    );
    remoteRepo = DoctorsRepoImpl();
  });

  tearDown(() {
    dataModeService.dispose();
  });

  group('OfflineFirstDoctorsRepo Leaves Rehydrate Tests (A5g)', () {
    test('1. Doctor add leave survives store rebuild from storage', () async {
      final sharedStorage = <String, String>{};
      final store1 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo1 = OfflineFirstDoctorsRepo(
        localStore: store1,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final leave = DoctorLeaveModel(
        id: 'LV-QA-101',
        doctorId: 'DOC-001',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 5),
        reason: 'QA vacation',
        createdAt: DateTime.now(),
      );

      final addRes = await repo1.addDoctorLeave(leave: leave);
      expect(addRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );

      final repo2 = OfflineFirstDoctorsRepo(
        localStore: store2,
        dataModeService: dataModeService,
        remoteRepo: remoteRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );

      final leavesRes = await repo2.getDoctorLeaves(doctorId: 'DOC-001');
      expect(leavesRes.isRight(), isTrue);
      final leaves = leavesRes.getOrElse(() => []);
      expect(leaves.any((l) => l.id == 'LV-QA-101' && l.reason == 'QA vacation'), isTrue);

      // Verify outbox entry exists
      final outbox = await store2.getAllOutboxEntries();
      expect(outbox.any((o) => o.entityType == 'doctor_leave' && o.localId == 'LV-QA-101'), isTrue);
    });
  });
}

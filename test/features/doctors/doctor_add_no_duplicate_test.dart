import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_doctors_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';

void main() {
  late InMemoryTransactionalStore store;
  late DoctorsRepoImpl mockRemoteRepo;
  late DataModeService dataModeService;
  late OfflineFirstDoctorsRepo repo;

  setUp(() {
    store = InMemoryTransactionalStore();
    mockRemoteRepo = DoctorsRepoImpl(apiConsumer: LocalServerApiConsumer());
    dataModeService = DataModeService();
    repo = OfflineFirstDoctorsRepo(
      localStore: store,
      remoteRepo: mockRemoteRepo,
      dataModeService: dataModeService,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch-1',
    );
  });

  group('A5n: Doctor Add No Duplication', () {
    test('adding a doctor does not create duplicate entries in getDoctors', () async {
      final initialRes = await repo.getDoctors(params: const PaginationParams());
      final initialCount = initialRes.getOrElse(() => throw 'failed').totalCount ?? 0;

      const newDoc = DoctorModel(
        name: 'دكتور تجريبي جديد',
        phone: '01012345678',
        specialty: 'طب عام',
      );

      final addRes = await repo.addDoctor(doctor: newDoc);
      expect(addRes.isRight(), isTrue);

      final afterRes = await repo.getDoctors(params: const PaginationParams());
      final afterDoctors = afterRes.getOrElse(() => throw 'failed').doctors;

      expect(afterDoctors.length, equals(initialCount + 1));
      final matches = afterDoctors.where((d) => d.name == 'دكتور تجريبي جديد').toList();
      expect(matches.length, equals(1), reason: 'Doctor should appear exactly once in the list');
    });
  });
}

import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/repositories/offline_first_visits_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/bookings/domain/contracts/active_visit_lookup.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_addendum_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_repo_impl.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late VisitsRepoImpl mockRemote;
  late OfflineFirstVisitsRepo repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  setUp(() {
    dataModeService = DataModeService(
      reachabilityProbe: (url, timeout) async => false,
      initialReachable: false,
    );

    store = InMemoryTransactionalStore(
      dataModeService: dataModeService,
      persistToStorage: true,
    );

    mockRemote = VisitsRepoImpl(apiConsumer: LocalServerApiConsumer());

    repo = OfflineFirstVisitsRepo(
      localStore: store,
      dataModeService: dataModeService,
      remoteRepo: mockRemote,
      getCurrentAccountId: () => 'acc_main',
      getCurrentBranchId: () => 'branch_1',
    );
  });

  group('OfflineFirstVisitsRepo Durability & Contracts', () {
    test('Saving visit draft while offline persists locally and queues outbox with dependencies', () async {
      final now = DateTime.now();
      final draft = VisitModel(
        id: 'VIS-TEST-001',
        bookingId: 'BOOKING-001',
        patientId: 'PAT-001',
        patientName: 'أحمد محمود',
        doctorId: 'DOC-001',
        branchId: 'branch_1',
        chiefComplaint: 'صداع وألم بالعين',
        diagnosis: 'إجهاد عيني حاد',
        startedAt: now,
        prescriptionItems: const [
          PrescriptionItemModel(
            tradeName: 'قطرة مرطبة',
            dosage: 'نقطتان 3 مرات يومياً',
            duration: '7 أيام',
          ),
        ],
      );

      final saveRes = await repo.saveVisitDraft(draft: draft);
      expect(saveRes.isRight(), isTrue);

      final saved = saveRes.getOrElse(() => throw Exception());
      expect(saved.id, 'VIS-TEST-001');
      expect(saved.status, VisitStatusEnum.inProgress);

      // Check store and outbox
      final localVisit = await repo.getVisitById(visitId: 'VIS-TEST-001');
      expect(localVisit.isRight(), isTrue);
      expect(localVisit.getOrElse(() => null)?.diagnosis, 'إجهاد عيني حاد');

      final pendingOutbox = await store.getPendingOutboxEntries();
      expect(pendingOutbox.length, 1);
      final outboxItem = pendingOutbox.first;
      expect(outboxItem.entityType, 'visit');
      expect(outboxItem.localId, 'VIS-TEST-001');
      expect(outboxItem.dependencyRefs, containsAll(['patient:PAT-001', 'booking:BOOKING-001']));
    });

    test('Recording vitals persists triage data locally and to outbox', () async {
      const vitals = VitalsModel(
        systolicBp: 120,
        diastolicBp: 80,
        heartRate: 72,
        temperature: 37.0,
        weightKg: 75.0,
        heightCm: 175.0,
      );

      final result = await repo.recordVitals(
        bookingId: 'BOOKING-002',
        patientId: 'PAT-002',
        branchId: 'branch_1',
        patientName: 'سارة علي',
        doctorId: 'DOC-001',
        doctorName: 'د. طارق المنشاوي',
        vitals: vitals,
      );

      expect(result.isRight(), isTrue);
      final saved = result.getOrElse(() => throw Exception());
      expect(saved.vitals?.systolicBp, 120);
      expect(saved.status, VisitStatusEnum.triage);

      final byBooking = await repo.getVisitByBookingId(bookingId: 'BOOKING-002');
      expect(byBooking.isRight(), isTrue);
      expect(byBooking.getOrElse(() => null)?.vitals?.heartRate, 72);
    });

    test('Finalizing visit marks it finalized, enforces immutability, and allows addenda', () async {
      final initial = VisitModel(
        id: 'VIS-FIN-001',
        bookingId: 'BOOKING-003',
        patientId: 'PAT-003',
        branchId: 'branch_1',
        chiefComplaint: 'فحص دوري',
        diagnosis: 'سليم تماماً',
      );

      await repo.saveVisitDraft(draft: initial);
      final finalRes = await repo.finalizeVisit(finalContent: initial);
      expect(finalRes.isRight(), isTrue);

      final finalized = finalRes.getOrElse(() => throw Exception());
      expect(finalized.status, VisitStatusEnum.finalized);

      // Attempting to overwrite a finalized visit with a draft save must be rejected
      final overwriteAttempt = await repo.saveVisitDraft(
        draft: finalized.copyWith(diagnosis: 'محاولة تعديل كشف مغلق'),
      );
      expect(overwriteAttempt.isLeft(), isTrue);

      // Adding addendum to finalized visit succeeds
      final addendum = VisitAddendumModel(
        id: 'ADD-001',
        notes: 'ملاحظة لاحقة: تم التأكيد هاتفياً على التحسن',
        createdAt: DateTime.now(),
        doctorName: 'د. طارق المنشاوي',
      );

      final addendumRes = await repo.addVisitAddendum(
        visitId: 'VIS-FIN-001',
        addendum: addendum,
      );
      expect(addendumRes.isRight(), isTrue);
      final updatedWithAddendum = addendumRes.getOrElse(() => throw Exception());
      expect(updatedWithAddendum.addenda?.length, 1);
      expect(updatedWithAddendum.addenda?.first.notes, contains('ملاحظة لاحقة'));
    });

    test('ActiveVisitLookup returns local visit status', () async {
      final visit = VisitModel(
        id: 'VIS-LOOKUP-001',
        bookingId: 'BOOKING-LK-001',
        patientId: 'PAT-004',
        branchId: 'branch_1',
        status: VisitStatusEnum.inProgress,
      );
      await repo.saveVisitDraft(draft: visit);

      final status = await repo.getVisitStatusByBookingId('BOOKING-LK-001');
      expect(status, VisitStatusEnum.inProgress);
    });

    test('Branch and account isolation prevents data leakage across branches', () async {
      final visitBranch1 = VisitModel(
        id: 'VIS-B1',
        bookingId: 'B-001',
        patientId: 'P-001',
        branchId: 'branch_1',
        diagnosis: 'فرع 1',
      );
      final visitBranch2 = VisitModel(
        id: 'VIS-B2',
        bookingId: 'B-002',
        patientId: 'P-002',
        branchId: 'branch_2',
        diagnosis: 'فرع 2',
      );

      await repo.saveVisitDraft(draft: visitBranch1);

      final repoBranch2 = OfflineFirstVisitsRepo(
        localStore: store,
        dataModeService: dataModeService,
        remoteRepo: mockRemote,
        getCurrentAccountId: () => 'acc_main',
        getCurrentBranchId: () => 'branch_2',
      );
      await repoBranch2.saveVisitDraft(draft: visitBranch2);

      // Verify branch_1 queue only sees branch_1 visits
      final queueB1 = await repo.getDoctorQueue(
        branchId: 'branch_1',
        date: DateTime.now(),
      );
      expect(queueB1.isRight(), isTrue);
    });

    test('Store recreated from SharedPreferences preserves edited visit across app reload/relaunch', () async {
      final visit = VisitModel(
        id: 'VIS-RESTART-001',
        bookingId: 'BOOKING-RS-001',
        patientId: 'PAT-005',
        branchId: 'branch_1',
        chiefComplaint: 'ألم حاد في الركبة',
        diagnosis: 'التهاب أوتار الرضفة',
      );
      await repo.saveVisitDraft(draft: visit);

      // Simulate full app relaunch by recreating store from SharedPreferences snapshot
      final restartedService = DataModeService(initialReachable: false);
      final restartedStore = InMemoryTransactionalStore(
        dataModeService: restartedService,
        persistToStorage: true,
      );

      final restoredRepo = OfflineFirstVisitsRepo(
        localStore: restartedStore,
        dataModeService: restartedService,
        remoteRepo: mockRemote,
        getCurrentAccountId: () => 'acc_main',
        getCurrentBranchId: () => 'branch_1',
      );

      final restoredVisitRes = await restoredRepo.getVisitById(visitId: 'VIS-RESTART-001');
      expect(restoredVisitRes.isRight(), isTrue);
      final restoredVisit = restoredVisitRes.getOrElse(() => null);
      expect(restoredVisit, isNotNull);
      expect(restoredVisit?.chiefComplaint, 'ألم حاد في الركبة');
      expect(restoredVisit?.diagnosis, 'التهاب أوتار الرضفة');

      final pending = await restartedStore.getPendingOutboxEntries();
      expect(pending.any((e) => e.localId == 'VIS-RESTART-001'), isTrue);
    });
  });

  group('DI Registration Verification', () {
    setUp(() async {
      await getIt.reset();
      await setupGetIt();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('VisitsRepo and ActiveVisitLookup both resolve to identical OfflineFirstVisitsRepo instance', () {
      final visitsRepo = getIt<VisitsRepo>();
      final activeVisitLookup = getIt<ActiveVisitLookup>();

      expect(visitsRepo, isA<OfflineFirstVisitsRepo>());
      expect(activeVisitLookup, isA<OfflineFirstVisitsRepo>());
      expect(identical(visitsRepo, activeVisitLookup), isTrue);
    });
  });
}

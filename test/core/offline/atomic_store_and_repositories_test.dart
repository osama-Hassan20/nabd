import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/policies/entity_mutation_policy.dart';
import 'package:eyadty/core/offline/repositories/offline_first_bookings_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  late InMemoryTransactionalStore store;
  late DataModeService dataModeService;
  late OfflineFirstPatientsRepo patientsRepo;
  late OfflineFirstBookingsRepo bookingsRepo;

  String currentAccountId = 'ACC-01';
  String currentBranchId = 'branch_1';

  setUp(() {
    store = InMemoryTransactionalStore();
    dataModeService = DataModeService(
      reachabilityProbe: (url, timeout) async => true,
      initialReachable: true,
    );

    patientsRepo = OfflineFirstPatientsRepo(
      localStore: store,
      dataModeService: dataModeService,
      getCurrentAccountId: () => currentAccountId,
      getCurrentBranchId: () => currentBranchId,
    );

    bookingsRepo = OfflineFirstBookingsRepo(
      localStore: store,
      dataModeService: dataModeService,
      getCurrentAccountId: () => currentAccountId,
      getCurrentBranchId: () => currentBranchId,
    );
  });

  group('Atomic Transaction & Outbox Isolation Tests', () {
    test('1. Atomic Write: addPatient persists both entity row and outbox entry', () async {
      final patient = PatientModel(
        id: 'PAT-001',
        name: 'أحمد محمود',
        phone: '01011223344',
      );

      final result = await patientsRepo.addPatient(patient: patient);
      expect(result.isRight(), isTrue);

      // Verify entity row in store
      final entity = await store.getEntity(
        localId: 'PAT-001',
        accountId: currentAccountId,
        branchId: currentBranchId,
      );
      expect(entity, isNotNull);
      expect(entity!.payload['name'], 'أحمد محمود');

      // Verify outbox entry in store
      final pendingOutbox = await store.getPendingOutboxEntries();
      expect(pendingOutbox.length, 1);
      expect(pendingOutbox.first.localId, 'PAT-001');
      expect(pendingOutbox.first.operation, OutboxOperationType.create);
    });

    test('2. Mid-transaction failure leaves NEITHER entity row nor outbox entry (Rollback)', () async {
      expect(
        () => store.runInTransaction((txn) async {
          txn.upsertEntity(
            LocalEntityRecord(
              localId: 'PAT-DOOMED',
              entityType: 'patient',
              accountId: currentAccountId,
              branchId: currentBranchId,
              payload: const {'name': 'Doomed Record'},
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          txn.insertOutbox(
            OutboxEntry(
              operationId: 'OP-DOOMED',
              entityType: 'patient',
              localId: 'PAT-DOOMED',
              operation: OutboxOperationType.create,
              payload: const {'name': 'Doomed Record'},
              baseRevision: 1,
              createdAt: DateTime.now(),
            ),
          );

          // Simulated crash mid-transaction
          throw Exception('Simulated fatal disk or validation failure mid-transaction');
        }),
        throwsA(isA<Exception>()),
      );

      // Verify rollback: NEITHER entity nor outbox was committed
      final entity = await store.getEntity(
        localId: 'PAT-DOOMED',
        accountId: currentAccountId,
        branchId: currentBranchId,
      );
      expect(entity, isNull);

      final outbox = await store.getPendingOutboxEntries();
      expect(outbox.where((o) => o.operationId == 'OP-DOOMED'), isEmpty);
    });

    test('3. Account and branch isolation: records from other accounts/branches are never exposed', () async {
      await patientsRepo.addPatient(
        patient: PatientModel(id: 'PAT-BRANCH-1', name: 'مريض فرع 1'),
      );

      // Query with different branch
      currentBranchId = 'branch_2';
      final branch2Result = await patientsRepo.getPatients(
        params: const PaginationParams(page: 1),
      );
      branch2Result.fold(
        (f) => fail('Should return empty list'),
        (res) => expect(res.items, isEmpty),
      );

      // Query with different account
      currentBranchId = 'branch_1';
      currentAccountId = 'ACC-OTHER';
      final otherAccountResult = await patientsRepo.getPatients(
        params: const PaginationParams(page: 1),
      );
      otherAccountResult.fold(
        (f) => fail('Should return empty list'),
        (res) => expect(res.items, isEmpty),
      );
    });

    test('4. Provisional flag: offline or forced-local mutations are marked provisional', () async {
      await dataModeService.setForcedLocal(true);

      final result = await bookingsRepo.createBooking(
        BookingModel(
          id: 'BOOK-OFFLINE-1',
          patientId: 'PAT-001',
          patientName: 'مريض تجريبي',
          status: BookingStatusEnum.waiting,
        ),
      );
      expect(result.isRight(), isTrue);

      final entity = await store.getEntity(
        localId: 'BOOK-OFFLINE-1',
        accountId: currentAccountId,
        branchId: currentBranchId,
      );
      expect(entity, isNotNull);
      expect(entity!.isProvisional, isTrue);
      expect(entity.syncStatus, SyncStatus.pending);

      // Summary calculated offline
      final summaryRes = await bookingsRepo.getBookingSummary();
      summaryRes.fold(
        (f) => fail('Summary failed'),
        (s) => expect(s.totalBookings, 1),
      );
    });

    test('5. Mutation policies: finalized clinical notes and financial entries cannot be overwritten', () {
      const clinicalPolicy = ClinicalRecordMutationPolicy();
      const financialPolicy = FinancialEntryPolicy();

      // Finalized clinical record rejects in-place overwrite
      expect(
        clinicalPolicy.canOverwriteInPlace({'isFinalized': true}, {'notes': 'new'}),
        isFalse,
      );
      expect(
        clinicalPolicy.canOverwriteInPlace({'isFinalized': false}, {'notes': 'new'}),
        isTrue,
      );

      // Financial payments reject both in-place overwrite and delete
      expect(
        financialPolicy.canOverwriteInPlace({'amount': 500}, {'amount': 600}),
        isFalse,
      );
      expect(
        financialPolicy.canDelete({'amount': 500}),
        isFalse,
      );
      expect(
        financialPolicy.deleteOperationType,
        OutboxOperationType.reverseFinancial,
      );
    });
  });
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/api/dio_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/http_remote_sync_api.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/data/repo/patients_repo_impl.dart';

import '../tools/stub_backend_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubBackendServer server;
  late Dio dio;
  late DioConsumer dioConsumer;
  late PatientsRepoImpl remotePatientsRepo;

  setUpAll(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    server = StubBackendServer();
    await server.start();
    AppConfig.setBackendModeForTesting(BackendMode.remote);
    dio = Dio(
      BaseOptions(
        baseUrl: server.apiBaseUrl,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        headers: {
          'Authorization': 'Bearer initial-access-value',
          'Accept-Language': 'ar',
        },
      ),
    );
    dioConsumer = DioConsumer(dio: dio);
    remotePatientsRepo = PatientsRepoImpl(apiConsumer: dioConsumer);
  });

  tearDown(() async {
    AppConfig.setBackendModeForTesting(null);
    await server.stop();
  });

  group('Step 4 Remote Mode Integration Tests (against StubBackendServer)', () {
    test('4.2 Sends Bearer Authorization, Accept-Language, and supports pagination on patients', () async {
      final res = await remotePatientsRepo.getPatients(
        params: PaginationParams(page: 2, limit: 2),
      );
      expect(res.isRight(), isTrue);
      final data = res.getOrElse(() => throw StateError(''));
      expect(data.items?.length, 2);
      expect(data.items?.first.id, 'PAT-STUB-3');
      expect(data.totalCount, 5);
      expect(server.observedAuthHeaders, contains('Bearer initial-access-value'));
      expect(server.observedAcceptLanguages, contains('ar'));
    });

    test('4.2 Sends Idempotency-Key and deduplicates repeated POST mutations', () async {
      final options = IdempotencyHelper.options('idem-key-101');
      final r1 = await dioConsumer.post(
        path: 'patients',
        options: options,
        body: {'name': 'مريض جديد', 'phone': '01011112222'},
      );
      final r2 = await dioConsumer.post(
        path: 'patients',
        options: options,
        body: {'name': 'مريض جديد', 'phone': '01011112222'},
      );
      expect(r1['data']['id'], r2['data']['id']);
      expect(server.patients.length, 6);
      expect(server.observedIdempotencyKeys, contains('idem-key-101'));
    });

    test('4.3 Maps 422 validation error with field errors', () async {
      try {
        await dioConsumer.post(
          path: 'patients',
          body: {'name': '', 'phone': '01000000000'},
        );
        fail('Expected 422 DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 422);
        final err = e.response?.data['error'] as Map;
        expect((err['fields'] as Map)['name'], 'patient_name_required');
        expect(HttpFailureMapper.fromError(e), isA<ValidationFailure>());
      }
    });

    test('4.3 Maps 403 to PermissionDeniedFailure and 409 to ConflictFailure with serverVersion', () async {
      try {
        await dioConsumer.get(path: 'forbidden');
        fail('Expected 403');
      } catch (e) {
        expect(HttpFailureMapper.fromError(e), isA<PermissionDeniedFailure>());
      }

      await dioConsumer.put(
        path: 'patients/PAT-STUB-1',
        body: {'name': 'Updated on Server'},
      );
      try {
        await dioConsumer.put(
          path: 'patients/PAT-STUB-1',
          body: {'name': 'Stale Client', 'baseRevision': 1},
        );
        fail('Expected 409 DioException');
      } catch (e) {
        final failure = HttpFailureMapper.fromError(e);
        expect(failure, isA<ConflictFailure>());
        expect((failure as ConflictFailure).serverVersion?['name'], 'Updated on Server');
      }
    });

    test('4.3 Handles 401 token refresh once and fails on second 401 (expired refresh)', () async {
      try {
        await dioConsumer.get(path: 'protected');
        fail('Expected 401 on expired token');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
        final refreshRes = await dioConsumer.post(
          path: 'admin/auth/refresh',
          body: {'refreshToken': 'initial-refresh-value'},
        );
        final newToken = refreshRes['data']['accessToken'] as String;
        dio.options.headers['Authorization'] = 'Bearer $newToken';
        final retryRes = await dioConsumer.get(path: 'protected');
        expect(retryRes['data']['ok'], isTrue);
      }

      // Expired refresh returns 401 -> caller triggers logout
      try {
        await dioConsumer.post(
          path: 'admin/auth/refresh',
          body: {'refreshToken': 'expired-refresh-value'},
        );
        fail('Expected 401 on expired refresh token');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
    });

    test('4.4 Pagination and filters on bookings and audit-logs via stub server', () async {
      final bookings = await dioConsumer.get(
        path: 'bookings',
        queryParameters: {'page': 1, 'limit': 3},
      );
      expect((bookings['data'] as List).length, 3);
      expect((bookings['meta'] as Map)['total'], greaterThanOrEqualTo(3));

      final audits = await dioConsumer.get(
        path: 'audit-logs',
        queryParameters: {'page': 1, 'limit': 5},
      );
      expect(audits['data'], isA<List>());
      expect(audits['meta'], isA<Map>());
    });

    test('4.5 Sync pushes in dependency order, replays operationId idempotently, and pulls tombstones', () async {
      final syncApi = HttpRemoteSyncApi(apiConsumer: dioConsumer);
      final store = InMemoryTransactionalStore(persistToStorage: false);
      final dataMode = DataModeService(
        reachabilityProbe: (_, __) async => true,
        initialReachable: true,
      );
      final engine = SyncEngine(
        localStore: store,
        dataModeService: dataMode,
        remoteApi: syncApi,
      );

      final patOp = OutboxEntry(
        operationId: 'stub_op_pat_1',
        entityType: 'patient',
        localId: 'PAT-DEP-1',
        operation: OutboxOperationType.create,
        payload: {'id': 'PAT-DEP-1', 'name': 'Dependent Parent'},
        baseRevision: 1,
        createdAt: DateTime(2026, 11, 28, 1, 0),
      );
      final bookOp = OutboxEntry(
        operationId: 'stub_op_bok_1',
        entityType: 'booking',
        localId: 'BOK-DEP-1',
        operation: OutboxOperationType.create,
        payload: {'id': 'BOK-DEP-1', 'patientId': 'PAT-DEP-1'},
        baseRevision: 1,
        dependencyRefs: ['patient:PAT-DEP-1'],
        createdAt: DateTime(2026, 11, 28, 1, 1),
      );

      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'PAT-DEP-1',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: patOp.payload,
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(patOp);
        txn.upsertEntity(LocalEntityRecord(
          localId: 'BOK-DEP-1',
          entityType: 'booking',
          accountId: 'default',
          branchId: 'branch_1',
          payload: bookOp.payload,
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(bookOp);
      });

      final report = await engine.syncNow();
      expect(report.operationsAcknowledged, 2);

      // Idempotent replay of same operationId returns stored result
      final replay = await syncApi.pushBatch([patOp]);
      expect(replay.getResultFor('stub_op_pat_1')?.success, isTrue);

      // Pull tombstones
      final p1 = await syncApi.pullChanges(entityType: 'patient');
      await syncApi.pushBatch([
        OutboxEntry(
          operationId: 'stub_op_pat_del',
          entityType: 'patient',
          localId: 'PAT-DEP-1',
          operation: OutboxOperationType.delete,
          payload: {'id': 'PAT-DEP-1'},
          baseRevision: 2,
          createdAt: DateTime(2026, 11, 28, 1, 2),
        ),
      ]);
      final p2 = await syncApi.pullChanges(entityType: 'patient', cursor: p1.newCursor);
      expect(p2.changes.any((c) => c.localId == 'PAT-DEP-1' && c.isDeleted), isTrue);

      engine.dispose();
      dataMode.dispose();
    });

    test('4.6 Airplane mode queues offline mutations when stub is stopped and pushes when stub returns', () async {
      final stoppedPort = server.port;
      await server.stop();

      final store = InMemoryTransactionalStore(persistToStorage: false);
      bool online = false;
      final dataMode = DataModeService(
        reachabilityProbe: (_, __) async => online,
        initialReachable: false,
      );
      expect(dataMode.currentMode, DataMode.offline);

      final offlineRepo = OfflineFirstPatientsRepo(
        localStore: store,
        dataModeService: dataMode,
        remoteRepo: remotePatientsRepo,
        getCurrentAccountId: () => 'default',
        getCurrentBranchId: () => 'branch_1',
      );
      final syncApi = HttpRemoteSyncApi(apiConsumer: dioConsumer);
      final engine = SyncEngine(
        localStore: store,
        dataModeService: dataMode,
        remoteApi: syncApi,
      );

      final offlineRes = await offlineRepo.addPatient(
        patient: const PatientModel(id: 'PAT-AIR-1', name: 'مريض وضع الطيران', phone: '01099998888'),
      );
      expect(offlineRes.isRight(), isTrue);
      expect((await store.getPendingOutboxEntries()).length, 1);

      // Stub returns on the same port
      await server.start(bindPort: stoppedPort);
      online = true;
      await dataMode.checkReachability();
      expect(dataMode.currentMode, DataMode.online);

      final report = await engine.syncNow();
      expect(report.operationsAcknowledged, 1);
      expect((await store.getPendingOutboxEntries()).length, 0);

      engine.dispose();
      dataMode.dispose();
    });
  });
}

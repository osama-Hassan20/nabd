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
        receiveTimeout: const Duration(milliseconds: 150),
        headers: {
          'Authorization': 'Bearer initial-access-value',
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

  group('Remote Mode Integration Tests (against StubBackendServer)', () {
    test('1. Sends Bearer Authorization header and supports pagination', () async {
      final res = await remotePatientsRepo.getPatients(
        params: PaginationParams(page: 2, limit: 2),
      );
      expect(res.isRight(), isTrue);
      final data = res.getOrElse(() => throw StateError(''));
      expect(data.items?.length, 2);
      expect(data.items?.first.id, 'PAT-STUB-3');
      expect(data.totalCount, 5);
      expect(server.observedAuthHeaders, contains('Bearer initial-access-value'));
    });

    test('2. Sends Idempotency-Key and deduplicates repeated POST mutations', () async {
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

    test('3. Maps 422 validation error to ValidationFailure', () async {
      final res = await remotePatientsRepo.addPatient(
        patient: const PatientModel(name: '', phone: '01000000000'),
      );
      expect(res.isLeft(), isTrue);
      res.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.errMessage, 'patient_name_required');
        },
        (_) => fail('Expected 422 validation failure'),
      );
    });

    test('4. Maps 409 version conflict with serverVersion to ConflictFailure', () async {
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

    test('5. Handles 401 token refresh and retries protected request', () async {
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
    });

    test('6. Retries after receiveTimeout against slow endpoint', () async {
      try {
        await dioConsumer.get(path: 'slow');
        fail('Expected receiveTimeout on first slow attempt');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.receiveTimeout);
        final retry = await dioConsumer.get(path: 'slow');
        expect(retry['data']['attempt'], 2);
      }
    });

    test('7. Airplane mode queues offline mutations locally and SyncEngine pushes to stub on reconnect', () async {
      final store = InMemoryTransactionalStore(persistToStorage: false);
      bool online = false;
      final dataMode = DataModeService(
        reachabilityProbe: (_, __) async => online,
        initialReachable: false,
      );
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

      online = true;
      await dataMode.checkReachability();
      final report = await engine.syncNow();
      expect(report.operationsAcknowledged, 1);
      expect((await store.getPendingOutboxEntries()).length, 0);

      engine.dispose();
      dataMode.dispose();
    });
  });
}

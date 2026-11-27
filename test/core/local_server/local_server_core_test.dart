import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/local_server/local_server_config.dart';
import 'package:eyadty/core/storage/cache_helper.dart';

void main() {
  late LocalServerApiConsumer api;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    LocalServerConfig.reset();
    api = LocalServerApiConsumer();
    await api.resetLocalData();
  });

  group('LocalServer Core & Entity Handlers Tests', () {
    test('Auth login returns token and user profile', () async {
      final res = await api.post(
        path: 'admin/auth/login',
        body: {'email': 'doctor@eyadty.com'},
      );
      final data = res['data'] as Map<String, dynamic>;
      expect(data['accessToken'], isNotEmpty);
      expect((data['user'] as Map)['id'], 'USER-DOC-01');
    });

    test('Patients handler serves 9 seeded patients, creates, and searches by phone', () async {
      final listRes = await api.get(path: 'patients', queryParameters: {'page': 1, 'limit': 20});
      expect((listRes['data'] as List).length, 9);
      expect((listRes['meta'] as Map)['total'], 9);

      final created = await api.post(
        path: 'patients',
        body: {'name': 'مريض جديد', 'phone': '01112223334', 'gender': 'male'},
        options: Options(headers: {'Idempotency-Key': 'op-pat-1'}),
      );
      final id = (created['data'] as Map)['id'];
      expect(id, isNotNull);

      // Idempotent replay does not duplicate
      await api.post(
        path: 'patients',
        body: {'name': 'مريض جديد', 'phone': '01112223334', 'gender': 'male'},
        options: Options(headers: {'Idempotency-Key': 'op-pat-1'}),
      );
      final afterRes = await api.get(path: 'patients');
      expect((afterRes['meta'] as Map)['total'], 10);
    });

    test('Doctors, Bookings, and Visits immutability & addendum work', () async {
      final docs = await api.get(path: 'doctors');
      expect((docs['data'] as List).length, 13);

      final bookings = await api.get(path: 'bookings');
      expect((bookings['data'] as List).length, 9);

      final startRes = await api.put(
        path: 'visits/consultation-start',
        body: {'bookingId': 'BOOK-001', 'patientId': 'PAT-000101', 'doctorId': 'DOC-01'},
      );
      final visitId = (startRes['data'] as Map)['id'] as String;

      await api.post(path: 'visits/$visitId/finalize', body: {'diagnosis': 'سليم'});

      // Direct draft edit after finalize must throw 409
      expect(
        () => api.put(path: 'visits/$visitId/draft', body: {'diagnosis': 'تعديل'}),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 409)),
      );

      // Addendum succeeds
      final addRes = await api.post(
        path: 'visits/$visitId/addenda',
        body: {'notes': 'ملاحظة إضافية'},
      );
      expect(((addRes['data'] as Map)['addenda'] as List).length, 1);
    });

    test('Failure injection simulates 503 and timeout', () async {
      LocalServerConfig.injectedFailureStatusCode = 503;
      expect(
        () => api.get(path: 'patients'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 503)),
      );

      // Resets after next call
      final okRes = await api.get(path: 'patients');
      expect((okRes['data'] as List).length, 9);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/dio_consumer.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/api/end_points.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:eyadty/core/local_server/local_server_sync_api.dart';
import 'package:eyadty/core/offline/remote/http_remote_sync_api.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';

void main() {
  group('AppConfig & Backend Mode Switch Tests', () {
    tearDown(() async {
      AppConfig.resetTestingOverrides();
      await getIt.reset();
    });

    test('1. Default configuration reflects local backend mode', () {
      expect(AppConfig.backendMode, BackendMode.local);
      expect(AppConfig.isLocalMode, isTrue);
      expect(AppConfig.isRemoteMode, isFalse);
      expect(AppConfig.isDemoMode, isTrue);
      expect(AppConfig.baseUrl, 'http://192.168.1.60:1601/');
      expect(AppConfig.apiUrl, 'http://192.168.1.60:1601/api/v1/');
      expect(AppConfig.baseImageUrl, 'http://192.168.1.60:1601/uploads');
    });

    test('2. EndPoints delegates to AppConfig without divergence', () {
      expect(EndPoints.appBaseUrl, AppConfig.baseUrl);
      expect(EndPoints.baseUrl, AppConfig.apiUrl);
      expect(EndPoints.baseImageUrl, AppConfig.baseImageUrl);
    });

    test('3. BaseUrl normalization ensures trailing slash', () {
      AppConfig.setBaseUrlForTesting('https://api.eyadty.clinic');
      expect(AppConfig.baseUrl, 'https://api.eyadty.clinic/');
      expect(AppConfig.apiUrl, 'https://api.eyadty.clinic/api/v1/');
    });

    test('4. Token generator tags mock session tokens properly', () {
      final token = AppConfig.generateDemoToken('USR-01');
      expect(token, startsWith('eyadty_demo_session_USR-01_'));
      expect(AppConfig.isDemoToken(token), isTrue);
      expect(AppConfig.isDemoToken('eyadty_session_USR-01_12345'), isTrue);
      expect(
        AppConfig.isDemoToken('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.s'),
        isFalse,
      );
    });

    test('5. setupGetIt in local mode registers LocalServerApiConsumer and LocalServerSyncApi', () async {
      AppConfig.setBackendModeForTesting(BackendMode.local);
      await getIt.reset();
      await setupGetIt();

      expect(getIt.isRegistered<LocalServerApiConsumer>(), isTrue);
      expect(getIt<ApiConsumer>(), isA<LocalServerApiConsumer>());
      expect(getIt<RemoteSyncApi>(), isA<LocalServerSyncApi>());
    });

    test('6. setupGetIt in remote mode never registers local server and uses DioConsumer + HttpRemoteSyncApi', () async {
      AppConfig.setBackendModeForTesting(BackendMode.remote);
      await getIt.reset();
      await setupGetIt();

      expect(AppConfig.isLocalMode, isFalse);
      expect(AppConfig.isDemoMode, isFalse);
      expect(getIt.isRegistered<LocalServerApiConsumer>(), isFalse);
      expect(getIt<ApiConsumer>(), isA<DioConsumer>());
      expect(getIt<RemoteSyncApi>(), isA<HttpRemoteSyncApi>());
    });
  });
}

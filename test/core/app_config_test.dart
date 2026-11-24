import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/config/app_config.dart';
import 'package:eyadty/core/api/end_points.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';

void main() {
  group('AppConfig & Demo Mode Safety Tests', () {
    tearDown(() {
      AppConfig.resetTestingOverrides();
    });

    test('1. Default configuration reflects mock stage', () {
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

    test('5. assertDemoModeAllowed succeeds in demo mode and throws in non-demo mode', () {
      AppConfig.setDemoModeForTesting(true);
      expect(() => AppConfig.assertDemoModeAllowed('TestRepo'), returnsNormally);

      AppConfig.setDemoModeForTesting(false);
      expect(
        () => AppConfig.assertDemoModeAllowed('TestRepo'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('TestRepo'),
          ),
        ),
      );
    });

    test('6. setupGetIt fails loudly if DEMO_MODE is false', () async {
      AppConfig.setDemoModeForTesting(false);
      expect(
        () => setupGetIt(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('setupGetIt'),
          ),
        ),
      );
    });
  });
}

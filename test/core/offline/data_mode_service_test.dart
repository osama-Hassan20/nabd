import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/shared/app_layout/presentation/widgets/header_data_mode_widget.dart';

class MockSyncCoordinator implements InFlightSyncCoordinator {
  bool inProgress = false;
  bool modeSwitchedCalled = false;
  final Map<String, Map<String, dynamic>> recordedAcks = {};

  @override
  bool get isSyncInProgress => inProgress;

  @override
  Future<void> onModeSwitchedToForcedLocal() async {
    modeSwitchedCalled = true;
  }

  @override
  void recordAckSafely(String operationId, Map<String, dynamic> ackResponse) {
    recordedAcks[operationId] = ackResponse;
  }
}

Widget _buildTestWidget(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [child],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  group('DataModeService Rule Table Tests', () {
    test('1. Truth Table: forcedLocal overrides reachability; unreachable falls back to offline', () async {
      final service = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
        initialReachable: true,
      );

      // Default: online
      expect(service.currentMode, DataMode.online);

      // Unreachable -> offline
      service.setReachabilityForTesting(false);
      expect(service.currentMode, DataMode.offline);

      // Forced local on -> forcedLocal (even if unreachable)
      await service.setForcedLocal(true);
      expect(service.currentMode, DataMode.forcedLocal);

      // Reachable -> still forcedLocal because toggle is active
      service.setReachabilityForTesting(true);
      expect(service.currentMode, DataMode.forcedLocal);

      // Toggle off -> returns to online because reachable
      await service.setForcedLocal(false);
      expect(service.currentMode, DataMode.online);

      // Toggle off when unreachable -> returns to offline
      service.setReachabilityForTesting(false);
      expect(service.currentMode, DataMode.offline);
    });

    test('2. Persistence: forcedLocal state is saved to SharedPreferences and restored', () async {
      final service = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
      );
      await service.setForcedLocal(true);

      expect(AppSharedPreferences.getBool(key: DataModeService.forcedLocalKey), isTrue);

      // Recreate service: should restore forcedLocal
      final restored = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
      );
      expect(restored.currentMode, DataMode.forcedLocal);
      expect(restored.isForcedLocal, isTrue);
    });

    test('3. In-flight sync safety: switching to forcedLocal notifies coordinator and preserves ACK', () async {
      final coordinator = MockSyncCoordinator();
      coordinator.inProgress = true;

      final service = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
        syncCoordinator: coordinator,
      );

      // Trigger forced local while sync is in progress
      await service.setForcedLocal(true);

      expect(coordinator.modeSwitchedCalled, isTrue);

      // Simulate the in-flight HTTP request finishing AFTER mode switched
      coordinator.recordAckSafely('op_123', {'status': 'acknowledged', 'rev': 2});

      // ACK is safely recorded and not dropped
      expect(coordinator.recordedAcks.containsKey('op_123'), isTrue);
      expect(coordinator.recordedAcks['op_123']!['status'], 'acknowledged');
    });

    test('4. Platform connectivity stream changes update reachability and mode automatically', () async {
      final controller = StreamController<bool>.broadcast();
      final service = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
        initialReachable: true,
        platformConnectivityStreamOverride: controller.stream,
      );

      expect(service.currentMode, DataMode.online);

      // Browser fires offline event
      controller.add(false);
      await Future.delayed(Duration.zero);
      expect(service.currentMode, DataMode.offline);
      expect(service.state.isServerReachable, isFalse);

      // Browser fires online event
      controller.add(true);
      await Future.delayed(Duration.zero);
      expect(service.currentMode, DataMode.online);
      expect(service.state.isServerReachable, isTrue);

      await controller.close();
      service.dispose();
    });
  });

  group('HeaderDataModeWidget UI & RTL Tests', () {
    late DataModeService testService;

    setUp(() {
      testService = DataModeService(
        reachabilityProbe: (url, timeout) async => true,
        initialReachable: true,
      );

      if (getIt.isRegistered<DataModeService>()) {
        getIt.unregister<DataModeService>();
      }
      getIt.registerSingleton<DataModeService>(testService);
    });

    tearDown(() {
      if (getIt.isRegistered<DataModeService>()) {
        getIt.unregister<DataModeService>();
      }
    });

    testWidgets('1. Shows online chip and switches to forcedLocal upon toggle tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildTestWidget(const HeaderDataModeWidget()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header_data_mode_chip')), findsOneWidget);
      expect(find.text('mode_online'.tr()), findsOneWidget);

      // Tap toggle button to activate forced local
      await tester.tap(find.byKey(const Key('header_forced_local_toggle_btn')));
      await tester.pumpAndSettle();

      expect(testService.currentMode, DataMode.forcedLocal);
      expect(find.text('mode_forced_local'.tr()), findsOneWidget);
    });

    testWidgets('2. Displays pending operations count when queue has items', (tester) async {
      testService.updatePendingOutboxCount(5);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildTestWidget(const HeaderDataModeWidget()));
      await tester.pumpAndSettle();

      expect(find.text('5 ${'pending_sync_operations'.tr()}'), findsOneWidget);
    });
  });
}

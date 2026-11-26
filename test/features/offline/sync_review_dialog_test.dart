import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/shared/app_layout/presentation/widgets/sync_review_dialog.dart';

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
        body: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('SyncReviewDialog & Reconnect Gate UI Tests', () {
    late InMemoryTransactionalStore store;
    late DataModeService dataModeService;
    late FakeRemoteSyncApi fakeApi;
    late SyncEngine engine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = InMemoryTransactionalStore(persistToStorage: false);
      dataModeService = DataModeService(
        reachabilityProbe: (_, __) async => true,
        initialReachable: true,
      );
      fakeApi = FakeRemoteSyncApi();
      engine = SyncEngine(
        localStore: store,
        dataModeService: dataModeService,
        remoteApi: fakeApi,
      );

      if (getIt.isRegistered<TransactionalLocalStore>()) {
        getIt.unregister<TransactionalLocalStore>();
      }
      getIt.registerSingleton<TransactionalLocalStore>(store);

      if (getIt.isRegistered<DataModeService>()) {
        getIt.unregister<DataModeService>();
      }
      getIt.registerSingleton<DataModeService>(dataModeService);

      if (getIt.isRegistered<SyncEngine>()) {
        getIt.unregister<SyncEngine>();
      }
      getIt.registerSingleton<SyncEngine>(engine);

      if (getIt.isRegistered<RemoteSyncApi>()) {
        getIt.unregister<RemoteSyncApi>();
      }
      getIt.registerSingleton<RemoteSyncApi>(fakeApi);
    });

    tearDown(() {
      engine.dispose();
      dataModeService.dispose();
    });

    testWidgets('1. Displays section groups with counts and Arabic section names', (tester) async {
      await store.runInTransaction((txn) async {
        txn.upsertEntity(LocalEntityRecord(
          localId: 'P-101',
          entityType: 'patient',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'name': 'Ahmed Ali'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_p101',
          entityType: 'patient',
          localId: 'P-101',
          operation: OutboxOperationType.create,
          payload: {'name': 'Ahmed Ali'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));

        txn.upsertEntity(LocalEntityRecord(
          localId: 'B-201',
          entityType: 'booking',
          accountId: 'default',
          branchId: 'branch_1',
          payload: {'status': 'noShow'},
          isProvisional: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        txn.insertOutbox(OutboxEntry(
          operationId: 'op_b201',
          entityType: 'booking',
          localId: 'B-201',
          operation: OutboxOperationType.update,
          payload: {'status': 'noShow'},
          previousPayload: {'status': 'confirmed'},
          baseRevision: 1,
          createdAt: DateTime.now(),
        ));
      });

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildTestWidget(const SyncReviewDialog()));
      await tester.pumpAndSettle();

      // Verify Arabic section headers exist
      expect(find.text('المرضى'), findsOneWidget);
      expect(find.text('الحجوزات والمواعيد'), findsOneWidget);

      // Verify row text
      expect(find.textContaining('Ahmed Ali'), findsOneWidget);
    });

    testWidgets('2. "Stay in local mode" sets forced local to true and closes dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_buildTestWidget(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => SyncReviewDialog.show(ctx),
            child: const Text('Open Dialog'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(SyncReviewDialog), findsOneWidget);

      // Tap "البقاء في الوضع المحلي"
      final stayLocalBtn = find.byKey(const Key('sync_review_stay_local_btn'));
      expect(stayLocalBtn, findsOneWidget);
      await tester.tap(stayLocalBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SyncReviewDialog), findsNothing);
      expect(dataModeService.isForcedLocal, isTrue);
    });
  });
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_module_registry.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/nutrition_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/obgyn_module.dart';

Widget _wrapWidget(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar', 'EG'),
    startLocale: const Locale('ar', 'EG'),
    saveLocale: false,
    useOnlyLangCode: false,
    child: MaterialApp(
      locale: const Locale('ar', 'EG'),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTransactionalStore store;
  late DataModeService dataMode;
  late OfflineFirstSpecialtyRecordsRepo specRepo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await GetIt.instance.reset();
    dataMode = DataModeService()..setReachabilityForTesting(false);
    store = InMemoryTransactionalStore(dataModeService: dataMode);
    specRepo = OfflineFirstSpecialtyRecordsRepo(
      localStore: store,
      dataModeService: dataMode,
      getCurrentAccountId: () => 'acc-1',
      getCurrentBranchId: () => 'branch_1',
    );
    GetIt.instance.registerSingleton<OfflineFirstSpecialtyRecordsRepo>(specRepo);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Per-Specialty Module Widget Tests (Open, Save, Outbox)', () {
    for (final spec in MedicalSpecialty.values) {
      testWidgets('${spec.value} module opens, saves, and appears in outbox',
          (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final patient = PatientModel(
          id: 'PAT-${spec.value}',
          name: 'مريض ${spec.value}',
          dateOfBirth: spec == MedicalSpecialty.pediatrics
              ? DateTime.now().subtract(const Duration(days: 365))
              : DateTime(1992, 4, 10),
          gender: spec == MedicalSpecialty.obstetricsGynecology
              ? GenderEnum.female
              : GenderEnum.male,
          isPregnant: spec == MedicalSpecialty.obstetricsGynecology,
          lastMenstrualPeriodDate: spec == MedicalSpecialty.obstetricsGynecology
              ? DateTime.now().subtract(const Duration(days: 140))
              : null,
          allergies: spec == MedicalSpecialty.nutrition
              ? const ['فول سوداني']
              : null,
          weightKg: 70,
          heightCm: 170,
        );

        final module = SpecialtyModuleRegistry.forSpecialty(spec);
        await tester.pumpWidget(_wrapWidget(module.buildPatientTab(patient)));
        await tester.pumpAndSettle();

        // Tap the primary save/add button in the module
        final buttonFinder = find.byWidgetPredicate(
          (w) =>
              w is ElevatedButton ||
              (w is TextButton &&
                  (w.child is Text &&
                          ((w.child as Text).data ?? '').contains('إضافة') ||
                      true)),
        );

        if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
          await tester.tap(find.byType(ElevatedButton).first);
        } else {
          await tester.tap(buttonFinder.first);
        }
        await tester.pumpAndSettle();

        final outbox = await store.getPendingOutboxEntries();
        expect(
          outbox.any(
            (e) =>
                e.entityType == 'specialty_record_entry' &&
                e.payload['specialty'] == spec.value,
          ),
          isTrue,
          reason: '${spec.value} save did not appear in outbox',
        );
      });
    }

    testWidgets('Pediatrics hides vaccination schedule for adult patients (>= 18)',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adult = PatientModel(
        id: 'PAT-ADULT',
        name: 'مريض بالغ',
        dateOfBirth: DateTime(1990, 1, 1),
        gender: GenderEnum.male,
      );
      final mod = SpecialtyModuleRegistry.forSpecialty(MedicalSpecialty.pediatrics);
      await tester.pumpWidget(_wrapWidget(mod.buildPatientTab(adult)));
      await tester.pumpAndSettle();

      expect(find.textContaining('تم إخفاء جدول تطعيمات الأطفال'), findsOneWidget);
      expect(find.text('تسجيل التطعيم'), findsNothing);
    });

    test('OB/GYN countdown shows trimester and overdue warning when past EDD', () {
      final now = DateTime(2026, 11, 26);
      final overduePatient = PatientModel(
        id: 'PAT-OVERDUE',
        gender: GenderEnum.female,
        isPregnant: true,
        lastMenstrualPeriodDate: now.subtract(const Duration(days: 290)),
      );
      final text = ObstetricsGynecologyModule.formatPregnancyCountdown(
        overduePatient,
        now: now,
      );
      expect(text, contains('الثلث الثالث'));
      expect(text, contains('تحذير: تجاوز موعد الولادة المتوقع'));
    });

    test('Nutrition BMI & category calculation', () {
      final bmi = NutritionModule.computeBmi(80, 175);
      expect(bmi, closeTo(26.1, 0.1));
      expect(NutritionModule.bmiCategoryAr(bmi), equals('زيادة وزن'));
    });
  });
}

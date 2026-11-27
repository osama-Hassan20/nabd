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

  group('Per-Specialty Module Widget Tests (Validation, Open, Save, Outbox)', () {
    for (final spec in MedicalSpecialty.values) {
      testWidgets('${spec.value} module blocks empty save, then saves with input and writes to outbox',
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
        );

        final module = SpecialtyModuleRegistry.forSpecialty(spec);
        await tester.pumpWidget(_wrapWidget(module.buildPatientTab(patient)));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
          // Clear any pre-filled fields for modules with defaults (ophthalmology)
          for (int i = 0; i < textFields.evaluate().length; i++) {
            await tester.enterText(textFields.at(i), '');
          }
          await tester.pump();
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pumpAndSettle();

          // Empty save should be blocked for forms with text fields (except dentistry which has chip+dropdown)
          if (spec != MedicalSpecialty.dentistry) {
            expect(await store.getPendingOutboxEntries(), isEmpty,
                reason: '${spec.value} should block empty save');
          }

          if (textFields.evaluate().isNotEmpty) {
            await tester.enterText(textFields.first, '120');
            await tester.pump();
          }
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pumpAndSettle();
        } else {
          final btn = find.byType(TextButton).first;
          await tester.tap(btn);
          await tester.pumpAndSettle();
        }

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

    testWidgets('OB/GYN requires female patient and rejects male patient',
        (tester) async {
      const male = PatientModel(
        id: 'PAT-M',
        name: 'مريض ذكر',
        gender: GenderEnum.male,
      );
      final mod = SpecialtyModuleRegistry.forSpecialty(
          MedicalSpecialty.obstetricsGynecology);
      await tester.pumpWidget(_wrapWidget(mod.buildPatientTab(male)));
      await tester.pumpAndSettle();

      expect(find.text('ملف النساء والتوليد متاح للمريضات الإناث فقط.'), findsOneWidget);
    });

    test('PatientModel derives female gender when isPregnant is true and gender omitted', () {
      final p = PatientModel.fromJson({
        'id': 'PAT-DERIVED',
        'name': 'مريضة حامل',
        'isPregnant': true,
      });
      expect(p.gender, equals(GenderEnum.female));
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

    test('PatientModel incompleteProfileReason ignores optional DOB and flags required fields', () {
      const missingDobOnly = PatientModel(
        id: 'P1',
        name: 'سارة',
        phone: '01012345678',
        gender: GenderEnum.female,
      );
      expect(missingDobOnly.hasIncompleteProfile, isFalse);
      expect(missingDobOnly.incompleteProfileReason, isNull);

      const missingGender = PatientModel(
        id: 'P2',
        name: 'أحمد',
        phone: '01012345678',
      );
      expect(missingGender.hasIncompleteProfile, isTrue);
      expect(missingGender.incompleteProfileReason, equals('ناقص: النوع'));
    });

    testWidgets('Dental registering a tooth adds a visible row under sessions & packages with single outbox write',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const patient = PatientModel(id: 'PAT-DENT', name: 'مريض أسنان');
      final mod = SpecialtyModuleRegistry.forSpecialty(MedicalSpecialty.dentistry);
      await tester.pumpWidget(_wrapWidget(mod.buildPatientTab(patient)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تسجيل للسن 16'));
      await tester.pumpAndSettle();

      expect(find.textContaining('علاج عصب (سن 16'), findsOneWidget);
      final outbox = await store.getPendingOutboxEntries();
      expect(outbox.length, equals(1));
    });

    testWidgets('Derm add session/package opens form and creates exactly one row',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const patient = PatientModel(id: 'PAT-DERM', name: 'مريضة جلدية');
      final mod = SpecialtyModuleRegistry.forSpecialty(MedicalSpecialty.dermatology);
      await tester.pumpWidget(_wrapWidget(mod.buildPatientTab(patient)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إضافة جلسة / باقة'));
      await tester.pumpAndSettle();

      expect(find.text('حفظ الجلسة'), findsOneWidget);
      await tester.tap(find.text('حفظ الجلسة'));
      await tester.pumpAndSettle();

      final outbox = await store.getPendingOutboxEntries();
      final sessionOps = outbox
          .where((e) =>
              e.entityType == 'specialty_record_entry' &&
              e.payload['kind'] == 'session_package')
          .toList();
      expect(sessionOps.length, equals(1));
    });

    testWidgets('Pediatrics blocks empty save with Arabic validation message',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final child = PatientModel(
        id: 'PAT-CHILD',
        name: 'طفل',
        dateOfBirth: DateTime.now().subtract(const Duration(days: 365)),
      );
      final mod = SpecialtyModuleRegistry.forSpecialty(MedicalSpecialty.pediatrics);
      await tester.pumpWidget(_wrapWidget(mod.buildPatientTab(child)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ قياسات النمو'));
      await tester.pumpAndSettle();

      expect(
        find.text('يرجى إدخال بيانات في حقل واحد على الأقل قبل الحفظ.'),
        findsOneWidget,
      );
      expect(await store.getPendingOutboxEntries(), isEmpty);
    });
  });
}

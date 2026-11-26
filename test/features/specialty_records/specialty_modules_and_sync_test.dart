import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/helpers/pediatrics_growth_and_vaccine_helper.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_module_registry.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/dentistry_module.dart';
import 'package:eyadty/features/specialty_records/presentation/modules/obgyn_module.dart';

void main() {
  group('Part 3 & 4: Specialty Module Registry, Rehydrate & Discard Rollback', () {
    test('1. SpecialtyModuleRegistry provides a module for every MedicalSpecialty', () {
      for (final spec in MedicalSpecialty.values) {
        final module = SpecialtyModuleRegistry.forSpecialty(spec);
        expect(module.specialty, equals(spec));
        expect(module.tabLabelKey, equals(spec.labelKey));
        expect(module.emptyEntry(), isA<Map<String, dynamic>>());
      }
    });

    test('2. Pediatrics growth BMI, WHO percentile band & Egyptian vaccine schedule', () {
      final bmi = PediatricsGrowthAndVaccineHelper.computeBmi(10.0, 76.0);
      expect(bmi, closeTo(17.3, 0.2));

      final band = PediatricsGrowthAndVaccineHelper.estimateWeightPercentileBand(12, 9.6);
      expect(band, contains('P15 - P85'));

      final dob = DateTime(2025, 11, 26); // 12 months old
      final schedule = PediatricsGrowthAndVaccineHelper.buildEgyptianSchedule(
        dob: dob,
        now: DateTime(2026, 11, 26),
        givenByCode: {
          'BCG_HBV_0': {'dateGiven': '2025-11-27', 'batchNumber': 'B01'},
        },
      );
      expect(schedule.firstWhere((d) => d.code == 'BCG_HBV_0').status, equals('given'));
      expect(schedule.firstWhere((d) => d.code == 'PENTA_OPV_2').status, equals('overdue'));
    });

    test('3. OB/GYN pregnancy countdown formats month and remaining weeks', () {
      final now = DateTime(2026, 11, 26, 12, 0);
      final lmp = now.subtract(const Duration(days: 140)); // exactly 20w
      final patient = PatientModel(
        id: 'P-OB',
        gender: GenderEnum.female,
        isPregnant: true,
        lastMenstrualPeriodDate: lmp,
      );
      final countdown = ObstetricsGynecologyModule.formatPregnancyCountdown(
        patient,
        now: now,
      );
      expect(countdown, contains('الشهر 5 من 9'));
      expect(countdown, contains('باقي 20 أسبوع'));
    });

    test('4. Dentistry FDI tooth chart has 32 adult & 20 child teeth and validates FDI', () {
      expect(DentistryModule.adultFdiTeeth.length, equals(32));
      expect(DentistryModule.childFdiTeeth.length, equals(20));
      const mod = DentistryModule();
      expect(mod.validate({'toothFdi': 16}), isEmpty);
      expect(mod.validate({'toothFdi': 99}), isNotEmpty);
    });

    test('5. SpecialtyRecordEntry persists across store rebuild and rolls back on discard', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService()..setReachabilityForTesting(false);
      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo1 = OfflineFirstSpecialtyRecordsRepo(
        localStore: store1,
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      final entry = SpecialtyRecordEntryModel(
        id: 'SRE-TEST-1',
        patientId: 'PAT-1',
        visitId: 'VIS-1',
        specialty: MedicalSpecialty.pediatrics,
        kind: 'pediatrics_growth',
        data: const {'weightKg': 9.8, 'heightCm': 75.0},
        createdAt: DateTime.now(),
      );

      final saveRes = await repo1.saveEntry(entry);
      expect(saveRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstSpecialtyRecordsRepo(
        localStore: store2,
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      final listRes = await repo2.getEntriesForPatient(patientId: 'PAT-1');
      final list = listRes.getOrElse(() => []);
      expect(list.length, equals(1));
      expect(list.first.data['weightKg'], equals(9.8));

      // Discard outbox operation -> rolls back (deletes provisional entry)
      final outbox = await store2.getPendingOutboxEntries();
      final op = outbox.firstWhere((o) => o.entityType == 'specialty_record_entry');
      await store2.discardOutboxOperation(op.operationId);

      final afterDiscard = (await repo2.getEntriesForPatient(patientId: 'PAT-1')).getOrElse(() => []);
      expect(afterDiscard, isEmpty);
    });
  });
}

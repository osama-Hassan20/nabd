import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/marital_status_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/domain/helpers/female_intake_validator.dart';

void main() {
  group('Part 2: Female Patient Intake & Validation Tests', () {
    test('1. Validation rejects pregnant/nursing on male, future LMP, and missing LMP/EDD', () {
      final maleRes = FemaleIntakeValidator.validate(
        gender: GenderEnum.male,
        dateOfBirth: DateTime(1990, 1, 1),
        isPregnant: true,
        isNursing: false,
      );
      expect(maleRes.isValid, isFalse);

      final futureLmpRes = FemaleIntakeValidator.validate(
        gender: GenderEnum.female,
        dateOfBirth: DateTime(1995, 1, 1),
        isPregnant: true,
        isNursing: false,
        lmpDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(futureLmpRes.isValid, isFalse);

      final missingLmpEddRes = FemaleIntakeValidator.validate(
        gender: GenderEnum.female,
        dateOfBirth: DateTime(1995, 1, 1),
        isPregnant: true,
        isNursing: false,
      );
      expect(missingLmpEddRes.isValid, isFalse);

      final under12Res = FemaleIntakeValidator.validate(
        gender: GenderEnum.female,
        dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 8)),
        isPregnant: true,
        isNursing: false,
        lmpDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(under12Res.isValid, isFalse);
    });

    test('2. Pregnant + nursing emits non-blocking warning unless confirmed', () {
      final now = DateTime(2026, 11, 26);
      final res = FemaleIntakeValidator.validate(
        gender: GenderEnum.female,
        dateOfBirth: DateTime(1995, 1, 1),
        isPregnant: true,
        isNursing: true,
        lmpDate: now.subtract(const Duration(days: 70)),
        now: now,
      );
      expect(res.isValid, isTrue);
      expect(res.warnings, isNotEmpty);
    });

    test('3. Naegele EDD (LMP + 280 days) and gestational weeks compute accurately', () {
      final now = DateTime(2026, 11, 26);
      final lmp = now.subtract(const Duration(days: 140)); // 20 weeks
      final patient = PatientModel(
        id: 'PAT-F-1',
        name: 'سارة أحمد',
        gender: GenderEnum.female,
        maritalStatus: MaritalStatus.married,
        isPregnant: true,
        lastMenstrualPeriodDate: lmp,
      );

      expect(patient.computedEdd, equals(lmp.add(const Duration(days: 280))));
      expect(patient.gestationalWeeks(customNow: now), equals(20));
      expect(patient.gestationalMonth(customNow: now), equals(5));
    });

    test('4. DrugModel supports unsafeInPregnancy & unsafeInLactation flags (default false)', () {
      const safeDrug = DrugModel(id: 'D1', name: 'Paracetamol');
      expect(safeDrug.unsafeInPregnancy, isFalse);
      expect(safeDrug.unsafeInLactation, isFalse);

      const unsafeDrug = DrugModel(
        id: 'D2',
        name: 'Isotretinoin',
        unsafeInPregnancy: true,
        unsafeInLactation: true,
      );
      final roundTrip = DrugModel.fromJson(unsafeDrug.toJson());
      expect(roundTrip.unsafeInPregnancy, isTrue);
      expect(roundTrip.unsafeInLactation, isTrue);
    });

    test('5. All female intake fields persist across OfflineFirstPatientsRepo store rebuild', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService()..setReachabilityForTesting(false);
      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo1 = OfflineFirstPatientsRepo(
        localStore: store1,
        remoteRepo: null,
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      final lmp = DateTime(2026, 7, 1);
      final patient = PatientModel(
        id: 'PAT-OB-1',
        name: 'منى محمود',
        phone: '+201012345678',
        gender: GenderEnum.female,
        maritalStatus: MaritalStatus.married,
        isPregnant: true,
        lastMenstrualPeriodDate: lmp,
        estimatedDueDate: lmp.add(const Duration(days: 280)),
        isNursing: false,
        gravidaCount: 2,
        paraCount: 1,
        miscarriageCount: 0,
        cesareanCount: 1,
        hasPregnancyAllergyWarning: true,
      );

      final addRes = await repo1.addPatient(patient: patient);
      expect(addRes.isRight(), isTrue);

      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstPatientsRepo(
        localStore: store2,
        remoteRepo: null,
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      final getRes = await repo2.getPatientById(id: 'PAT-OB-1');
      final reloaded = getRes.getOrElse(() => throw 'err');
      expect(reloaded.maritalStatus, equals(MaritalStatus.married));
      expect(reloaded.isPregnant, isTrue);
      expect(reloaded.gravidaCount, equals(2));
      expect(reloaded.paraCount, equals(1));
      expect(reloaded.cesareanCount, equals(1));
      expect(reloaded.hasPregnancyAllergyWarning, isTrue);
    });
  });
}

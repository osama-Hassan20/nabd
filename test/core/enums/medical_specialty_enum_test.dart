import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/repositories/offline_first_doctors_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_gender_enum.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

void main() {
  group('MedicalSpecialty Enum, Migration & Persistence Tests', () {
    test('1. Old free-text Arabic strings migrate cleanly via fromValue and parseMultiple', () {
      expect(MedicalSpecialty.fromValue('أطفال وحديثي الولادة'), equals(MedicalSpecialty.pediatrics));
      expect(MedicalSpecialty.fromValue('جلدية وتجميل'), equals(MedicalSpecialty.cosmeticPlasticSurgery));
      expect(MedicalSpecialty.parseMultiple('جلدية وتجميل'), containsAll([MedicalSpecialty.dermatology, MedicalSpecialty.cosmeticPlasticSurgery]));
      expect(MedicalSpecialty.parseMultiple('باطنة وقلب'), containsAll([MedicalSpecialty.internalMedicine, MedicalSpecialty.cardiology]));
      expect(MedicalSpecialty.fromValue('نساء وتوليد'), equals(MedicalSpecialty.obstetricsGynecology));
      expect(MedicalSpecialty.fromValue('أسنان'), equals(MedicalSpecialty.dentistry));
      expect(MedicalSpecialty.fromValue('تقويم أسنان'), equals(MedicalSpecialty.orthodontics));
    });

    test('2. Serialization round trip for DoctorModel, BookingModel, VisitModel, CompanySettingsModel', () {
      final doc = DoctorModel.fromJson({
        'id': 'DOC-X',
        'name': 'د. اختبار',
        'specialty': 'باطنة وقلب',
      });
      expect(doc.specialties, containsAll([MedicalSpecialty.internalMedicine, MedicalSpecialty.cardiology]));
      final docRoundTrip = DoctorModel.fromJson(doc.toJson());
      expect(docRoundTrip.specialties, equals(doc.specialties));

      const booking = BookingModel(
        id: 'B-X',
        specialtyCode: MedicalSpecialty.obstetricsGynecology,
        serviceName: 'متابعة حمل',
      );
      final bRoundTrip = BookingModel.fromJson(booking.toJson());
      expect(bRoundTrip.specialtyCode, equals(MedicalSpecialty.obstetricsGynecology));
      expect(bRoundTrip.serviceName, equals('متابعة حمل'));

      const visit = VisitModel(
        id: 'V-X',
        specialtyCode: MedicalSpecialty.pediatrics,
      );
      final vRoundTrip = VisitModel.fromJson(visit.toJson());
      expect(vRoundTrip.specialtyCode, equals(MedicalSpecialty.pediatrics));

      const settings = CompanySettingsModel(
        companyName: 'عيادة التخصصات',
        enabledSpecialties: [MedicalSpecialty.pediatrics, MedicalSpecialty.dentistry],
      );
      final sRoundTrip = CompanySettingsModel.fromJson(settings.toJson());
      expect(sRoundTrip.enabledSpecialties, equals([MedicalSpecialty.pediatrics, MedicalSpecialty.dentistry]));
    });

    test('3. Translations parity: all specialty labelKeys exist in both ar-EG.json and en-US.json', () {
      final arMap = jsonDecode(File('assets/translations/ar-EG.json').readAsStringSync()) as Map<String, dynamic>;
      final enMap = jsonDecode(File('assets/translations/en-US.json').readAsStringSync()) as Map<String, dynamic>;

      for (final spec in MedicalSpecialty.values) {
        expect(arMap.containsKey(spec.labelKey), isTrue, reason: 'Missing ${spec.labelKey} in ar-EG.json');
        expect(enMap.containsKey(spec.labelKey), isTrue, reason: 'Missing ${spec.labelKey} in en-US.json');
      }
    });

    test('4. Doctor with two specialties persists across store rebuild (rehydrate)', () async {
      final sharedStorage = <String, String>{};
      final dataMode = DataModeService()..setReachabilityForTesting(true);
      final store1 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo1 = OfflineFirstDoctorsRepo(
        localStore: store1,
        remoteRepo: DoctorsRepoImpl(apiConsumer: LocalServerApiConsumer()),
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      const multiDoc = DoctorModel(
        id: 'DOC-MULTI-1',
        name: 'د. متعدد التخصصات',
        phone: '+20 10 0000 1111',
        specialty: 'جلدية، تجميل',
        specialties: [MedicalSpecialty.dermatology, MedicalSpecialty.cosmeticPlasticSurgery],
        gender: DoctorGenderEnum.female,
      );
      final addRes = await repo1.addDoctor(doctor: multiDoc);
      expect(addRes.isRight(), isTrue);

      // Rebuild store from storage
      final store2 = InMemoryTransactionalStore(
        dataModeService: dataMode,
        storageWriter: (k, v) async => sharedStorage[k] = v,
        storageReader: (k) => sharedStorage[k],
        storageRemover: (k) async => sharedStorage.remove(k),
      );
      final repo2 = OfflineFirstDoctorsRepo(
        localStore: store2,
        remoteRepo: DoctorsRepoImpl(apiConsumer: LocalServerApiConsumer()),
        dataModeService: dataMode,
        getCurrentAccountId: () => 'acc-1',
        getCurrentBranchId: () => 'branch-1',
      );

      final getRes = await repo2.getDoctorById(id: 'DOC-MULTI-1');
      expect(getRes.isRight(), isTrue);
      final reloaded = getRes.getOrElse(() => throw 'err');
      expect(reloaded.specialties, equals([MedicalSpecialty.dermatology, MedicalSpecialty.cosmeticPlasticSurgery]));
    });
  });
}

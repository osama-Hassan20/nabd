import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/remote/fake_remote_sync_api.dart';
import 'package:eyadty/core/offline/repositories/offline_first_bookings_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_cashier_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_doctors_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_patients_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/offline/repositories/offline_first_visits_repo.dart';
import 'package:eyadty/core/offline/store/in_memory_transactional_store.dart';
import 'package:eyadty/core/offline/sync/sync_engine.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/cashier/data/repo/cashier_repo_impl.dart';
import 'package:eyadty/features/doctors/data/repo/doctors_repo_impl.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/marital_status_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/domain/helpers/female_intake_validator.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/helpers/pediatrics_growth_and_vaccine_helper.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_module_registry.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_repo_impl.dart';
import 'package:eyadty/features/visits/presentation/manager/mixins/visit_prescription_mixin.dart';

void main() {
  group('Part 5: Full Patient Cycle Test (Parameterized by MedicalSpecialty)', () {
    for (final specialty in MedicalSpecialty.values) {
      test('Cycle passes end-to-end for ${specialty.value}', () async {
        final sharedStorage = <String, String>{};
        final dataMode = DataModeService()
          ..setReachabilityForTesting(true)
          ..setForcedLocal(true);

        InMemoryTransactionalStore buildStore() => InMemoryTransactionalStore(
              dataModeService: dataMode,
              storageWriter: (k, v) async => sharedStorage[k] = v,
              storageReader: (k) => sharedStorage[k],
              storageRemover: (k) async => sharedStorage.remove(k),
            );

        final store1 = buildStore();
        final doctorsRepo = OfflineFirstDoctorsRepo(
          localStore: store1,
          remoteRepo: DoctorsRepoImpl(apiConsumer: LocalServerApiConsumer()),
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final patientsRepo = OfflineFirstPatientsRepo(
          localStore: store1,
          remoteRepo: null,
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final bookingsRepo = OfflineFirstBookingsRepo(
          localStore: store1,
          remoteRepo: null,
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final cashierRepo = OfflineFirstCashierRepo(
          localStore: store1,
          remoteRepo: CashierRepoImpl(),
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final visitsRepo = OfflineFirstVisitsRepo(
          localStore: store1,
          remoteRepo: VisitsRepoImpl(apiConsumer: LocalServerApiConsumer()),
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final specialtyRepo = OfflineFirstSpecialtyRecordsRepo(
          localStore: store1,
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );

        // 1. Reception: Find seeded doctor for specialty
        final doctorsRes = await doctorsRepo.getDoctors(
          params: const PaginationParams(page: 1, limit: 100),
        );
        final allDoctors = doctorsRes.getOrElse(() => throw 'no doctors').items ?? [];
        final doctor = allDoctors.firstWhere(
          (d) => d.effectiveSpecialties.contains(specialty),
          orElse: () => throw 'No seeded doctor for ${specialty.value}',
        );

        // 2. Reception: Add suitable patient + check female validation
        final now = DateTime.now();
        late PatientModel patient;
        if (specialty == MedicalSpecialty.pediatrics) {
          patient = PatientModel(
            id: 'PAT-${specialty.value}',
            name: 'طفل اختبار ${specialty.value}',
            phone: '+201011112222',
            dateOfBirth: now.subtract(const Duration(days: 365)),
            gender: GenderEnum.male,
            guardianName: 'ولي أمر اختبار',
            guardianPhone: '+201099998888',
            guardianRelation: 'أب',
          );
        } else if (specialty == MedicalSpecialty.obstetricsGynecology) {
          final lmp = now.subtract(const Duration(days: 140));
          patient = PatientModel(
            id: 'PAT-${specialty.value}',
            name: 'مريضة نساء ${specialty.value}',
            phone: '+201022223333',
            dateOfBirth: DateTime(1995, 5, 10),
            gender: GenderEnum.female,
            maritalStatus: MaritalStatus.married,
            isPregnant: true,
            lastMenstrualPeriodDate: lmp,
            estimatedDueDate: lmp.add(const Duration(days: 280)),
          );
          final val = FemaleIntakeValidator.validate(
            gender: patient.gender,
            dateOfBirth: patient.dateOfBirth,
            isPregnant: true,
            isNursing: false,
            lmpDate: lmp,
          );
          expect(val.isValid, isTrue);
        } else {
          patient = PatientModel(
            id: 'PAT-${specialty.value}',
            name: 'مريض ${specialty.value}',
            phone: '+201033334444',
            dateOfBirth: DateTime(1990, 3, 15),
            gender: specialty == MedicalSpecialty.dermatology
                ? GenderEnum.female
                : GenderEnum.male,
          );
        }
        expect((await patientsRepo.addPatient(patient: patient)).isRight(), isTrue);

        // 3. Reception: Create booking + open cashier shift + collect payment
        final booking = BookingModel(
          id: 'BOOK-${specialty.value}',
          patientId: patient.id,
          patientName: patient.name,
          doctorId: doctor.id,
          doctorName: doctor.name,
          specialty: specialty.value,
          specialtyCode: specialty,
          serviceName: 'كشف ${specialty.value}',
          date: now,
          appointmentTime: now,
          consultationFee: 400,
          paidAmount: 400,
          paymentStatus: PaymentStatusEnum.paid,
          status: BookingStatusEnum.scheduled,
          branchId: 'branch_1',
        );
        expect((await bookingsRepo.createBooking(booking)).isRight(), isTrue);

        final shiftRes = await cashierRepo.openShift(
          branchId: 'branch_1',
          cashierUserId: 'USR-CASHIER',
          cashierName: 'كاشير الاختبار',
          openingBalancePiastres: 50000,
        );
        final shift = shiftRes.getOrElse(() => throw 'shift failed');
        final payRes = await cashierRepo.recordPayment(
          clientRequestId: 'REQ-PAY-${specialty.value}',
          shiftId: shift.id!,
          branchId: 'branch_1',
          bookingId: booking.id!,
          patientId: patient.id!,
          patientName: patient.name!,
          amountPiastres: 40000,
          paymentMethod: 'cash',
          cashierUserId: 'USR-CASHIER',
          cashierName: 'كاشير الاختبار',
        );
        expect(payRes.isRight(), isTrue);

        // 4. Nurse: Record vitals & Doctor: Save draft + finalize visit
        final visit = VisitModel(
          id: 'VIS-${specialty.value}',
          bookingId: booking.id,
          patientId: patient.id,
          branchId: 'branch_1',
          patientName: patient.name,
          doctorId: doctor.id,
          doctorName: doctor.name,
          specialty: specialty.value,
          specialtyCode: specialty,
          status: VisitStatusEnum.inProgress,
          vitals: const VitalsModel(
            systolicBp: 120,
            diastolicBp: 80,
            heartRate: 76,
            temperature: 37.0,
            weightKg: 10.2,
            heightCm: 76.0,
          ),
          diagnosis: 'تشخيص تجريبي ${specialty.value}',
          prescriptionItems: const [
            PrescriptionItemModel(
              id: 'RX-1',
              tradeName: 'Paracetamol',
              dosage: '500mg',
              frequency: 'كل 8 ساعات',
              duration: '5 أيام',
            ),
          ],
          finalizedAt: now,
        );
        expect((await visitsRepo.saveVisitDraft(draft: visit)).isRight(), isTrue);

        // 5. Doctor: Fill specialty record module
        final module = SpecialtyModuleRegistry.forSpecialty(specialty);
        final entryData = Map<String, dynamic>.from(module.emptyEntry());
        if (specialty == MedicalSpecialty.pediatrics) {
          entryData['weightKg'] = 10.2;
          entryData['heightCm'] = 76.0;
          entryData['headCircumferenceCm'] = 46.0;
          expect(
            PediatricsGrowthAndVaccineHelper.computeBmi(10.2, 76.0),
            isNotNull,
          );
        } else if (specialty == MedicalSpecialty.dentistry) {
          entryData['toothFdi'] = 16;
          entryData['procedure'] = 'علاج عصب';
          entryData['sessionIndex'] = 1;
          entryData['totalSessions'] = 3;
        }
        expect(module.validate(entryData), isEmpty);

        final specEntry = SpecialtyRecordEntryModel(
          id: 'SRE-${specialty.value}',
          patientId: patient.id!,
          visitId: visit.id,
          specialty: specialty,
          kind: 'cycle_entry',
          data: entryData,
          createdAt: now,
        );
        expect((await specialtyRepo.saveEntry(specEntry)).isRight(), isTrue);

        // 6. Restart (rebuild store from shared storage) & assert persistence
        final store2 = buildStore();
        final patientsRepo2 = OfflineFirstPatientsRepo(
          localStore: store2,
          remoteRepo: null,
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final visitsRepo2 = OfflineFirstVisitsRepo(
          localStore: store2,
          remoteRepo: VisitsRepoImpl(apiConsumer: LocalServerApiConsumer()),
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );
        final specialtyRepo2 = OfflineFirstSpecialtyRecordsRepo(
          localStore: store2,
          dataModeService: dataMode,
          getCurrentAccountId: () => 'acc-1',
          getCurrentBranchId: () => 'branch_1',
        );

        expect((await patientsRepo2.getPatientById(id: patient.id!)).isRight(), isTrue);
        final patientVisits =
            (await visitsRepo2.getVisitsByPatientId(patientId: patient.id!))
                .getOrElse(() => []);
        expect(patientVisits.any((v) => v.id == visit.id), isTrue);
        final specEntries =
            (await specialtyRepo2.getEntriesForPatient(patientId: patient.id!))
                .getOrElse(() => []);
        expect(specEntries.any((e) => e.id == specEntry.id), isTrue);

        // 7. Go online & sync via SyncEngine (discard extra, sync all)
        final extraEntry = SpecialtyRecordEntryModel(
          id: 'SRE-DISCARD-${specialty.value}',
          patientId: patient.id!,
          specialty: specialty,
          kind: 'discard_me',
          data: const {'note': 'temp'},
          createdAt: now,
        );
        await specialtyRepo2.saveEntry(extraEntry);

        final fakeApi = FakeRemoteSyncApi();
        final syncEngine = SyncEngine(
          localStore: store2,
          dataModeService: dataMode,
          remoteApi: fakeApi,
        );

        final pendingBefore = await store2.getPendingOutboxEntries();
        expect(pendingBefore.length, greaterThanOrEqualTo(5));

        final discardTarget = pendingBefore
            .firstWhere((e) => e.localId == 'SRE-DISCARD-${specialty.value}');
        await syncEngine.discardOperation(discardTarget.operationId);

        final afterDiscardEntries =
            (await specialtyRepo2.getEntriesForPatient(patientId: patient.id!))
                .getOrElse(() => []);
        expect(afterDiscardEntries.any((e) => e.id == extraEntry.id), isFalse);

        dataMode.setForcedLocal(false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if ((await store2.getPendingOutboxEntries()).isNotEmpty) {
          final syncRes = await syncEngine.syncNow();
          expect(syncRes.error, isNull);
          expect(syncRes.operationsFailed, equals(0));
        }
        final pendingAfter = await store2.getPendingOutboxEntries();
        expect(pendingAfter, isEmpty);
      });
    }

    test('Negative cases: male pregnancy rejected, future LMP rejected, unsafe drug warns', () {
      expect(
        FemaleIntakeValidator.validate(
          gender: GenderEnum.male,
          dateOfBirth: DateTime(1990, 1, 1),
          isPregnant: true,
          isNursing: false,
        ).isValid,
        isFalse,
      );
      expect(
        FemaleIntakeValidator.validate(
          gender: GenderEnum.female,
          dateOfBirth: DateTime(1995, 1, 1),
          isPregnant: true,
          isNursing: false,
          lmpDate: DateTime.now().add(const Duration(days: 2)),
        ).isValid,
        isFalse,
      );

      final pregnantPatient = PatientModel(
        id: 'P-PREG',
        gender: GenderEnum.female,
        isPregnant: true,
        lastMenstrualPeriodDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      const unsafeDrug = DrugModel(
        id: 'DRUG-UNSAFE',
        name: 'Isotretinoin',
        unsafeInPregnancy: true,
      );
      final warning = VisitPrescriptionMixin.checkPregnancyLactationWarning(
        drug: unsafeDrug,
        patient: pregnantPatient,
      );
      expect(warning, isNotNull);
      expect(warning, contains('غير آمن أثناء الحمل'));
    });
  });
}

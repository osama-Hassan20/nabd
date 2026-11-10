import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';

void main() {
  group('VisitStatusEnum Tests', () {
    test('values map correctly to expected string codes', () {
      expect(VisitStatusEnum.triage.value, 'triage');
      expect(VisitStatusEnum.inProgress.value, 'in_progress');
      expect(VisitStatusEnum.finalized.value, 'finalized');
    });

    test('fromValue returns corresponding enum or null safely', () {
      expect(VisitStatusEnum.fromValue('triage'), VisitStatusEnum.triage);
      expect(VisitStatusEnum.fromValue('in_progress'), VisitStatusEnum.inProgress);
      expect(VisitStatusEnum.fromValue('finalized'), VisitStatusEnum.finalized);
      expect(VisitStatusEnum.fromValue('unknown'), isNull);
      expect(VisitStatusEnum.fromValue(null), isNull);
    });
  });

  group('VitalsModel Tests', () {
    test('100% nullable: empty instance has null fields and props', () {
      const vitals = VitalsModel();
      expect(vitals.systolicBp, isNull);
      expect(vitals.diastolicBp, isNull);
      expect(vitals.heartRate, isNull);
      expect(vitals.temperature, isNull);
      expect(vitals.oxygenSaturation, isNull);
      expect(vitals.weightKg, isNull);
      expect(vitals.heightCm, isNull);
      expect(vitals.recordedAt, isNull);
      expect(vitals.recordedByUserId, isNull);
      expect(vitals.bmi, isNull);
      expect(vitals.hasAnyWarning, isFalse);
    });

    test('JSON serialization & deserialization roundtrip', () {
      final now = DateTime(2026, 11, 10, 10, 0);
      final vitals = VitalsModel(
        systolicBp: 120,
        diastolicBp: 80,
        heartRate: 72,
        temperature: 36.8,
        oxygenSaturation: 99,
        weightKg: 70.0,
        heightCm: 175.0,
        recordedAt: now,
        recordedByUserId: 'USR-02',
      );

      final json = vitals.toJson();
      final restored = VitalsModel.fromJson(json);

      expect(restored.systolicBp, 120);
      expect(restored.diastolicBp, 80);
      expect(restored.heartRate, 72);
      expect(restored.temperature, 36.8);
      expect(restored.oxygenSaturation, 99);
      expect(restored.weightKg, 70.0);
      expect(restored.heightCm, 175.0);
      expect(restored.recordedAt, now);
      expect(restored.recordedByUserId, 'USR-02');
      expect(restored, equals(vitals));
    });

    test('BMI calculation calculates accurately and handles null/zero', () {
      const normalVitals = VitalsModel(weightKg: 70.0, heightCm: 175.0);
      expect(normalVitals.bmi, 22.9);

      const zeroHeight = VitalsModel(weightKg: 70.0, heightCm: 0);
      expect(zeroHeight.bmi, isNull);

      const negativeHeight = VitalsModel(weightKg: 70.0, heightCm: -10);
      expect(negativeHeight.bmi, isNull);

      const missingWeight = VitalsModel(heightCm: 175.0);
      expect(missingWeight.bmi, isNull);
    });

    test('Warning flags trigger accurately on thresholds', () {
      // Normal values
      const normal = VitalsModel(
        systolicBp: 120,
        diastolicBp: 80,
        heartRate: 75,
        temperature: 37.0,
        oxygenSaturation: 98,
        weightKg: 70,
        heightCm: 175,
      );
      expect(normal.systolicBpWarning, isNull);
      expect(normal.diastolicBpWarning, isNull);
      expect(normal.heartRateWarning, isNull);
      expect(normal.temperatureWarning, isNull);
      expect(normal.oxygenSaturationWarning, isNull);
      expect(normal.weightWarning, isNull);
      expect(normal.heightWarning, isNull);
      expect(normal.hasAnyWarning, isFalse);

      // Systolic BP: min 60, max 200
      const highSys = VitalsModel(systolicBp: 205);
      expect(highSys.systolicBpWarning, 'visits_vitals_warn_bp_high');
      expect(highSys.hasAnyWarning, isTrue);

      const lowSys = VitalsModel(systolicBp: 55);
      expect(lowSys.systolicBpWarning, 'visits_vitals_warn_bp_low');

      // Diastolic BP: min 40, max 130
      const highDia = VitalsModel(diastolicBp: 135);
      expect(highDia.diastolicBpWarning, 'visits_vitals_warn_bp_high');

      const lowDia = VitalsModel(diastolicBp: 35);
      expect(lowDia.diastolicBpWarning, 'visits_vitals_warn_bp_low');

      // Heart rate: min 30, max 200
      const tachy = VitalsModel(heartRate: 205);
      expect(tachy.heartRateWarning, 'visits_vitals_warn_hr_high');

      const brady = VitalsModel(heartRate: 25);
      expect(brady.heartRateWarning, 'visits_vitals_warn_hr_low');

      // Temperature: min 34.0, max 42.0
      const fever = VitalsModel(temperature: 42.5);
      expect(fever.temperatureWarning, 'visits_vitals_warn_temp_high');

      const hypo = VitalsModel(temperature: 33.5);
      expect(hypo.temperatureWarning, 'visits_vitals_warn_temp_low');

      // SpO2: min 90, max 100
      const lowO2 = VitalsModel(oxygenSaturation: 88);
      expect(lowO2.oxygenSaturationWarning, 'visits_vitals_warn_spo2_low');

      const overO2 = VitalsModel(oxygenSaturation: 102);
      expect(overO2.oxygenSaturationWarning, 'visits_vitals_warn_spo2_high');

      // Weight: min 1, max 300
      const lowWeight = VitalsModel(weightKg: 0.5);
      expect(lowWeight.weightWarning, 'visits_vitals_warn_weight_low');

      const highWeight = VitalsModel(weightKg: 310);
      expect(highWeight.weightWarning, 'visits_vitals_warn_weight_high');

      // Height: min 30, max 250
      const lowHeight = VitalsModel(heightCm: 25);
      expect(lowHeight.heightWarning, 'visits_vitals_warn_height_low');

      const highHeight = VitalsModel(heightCm: 260);
      expect(highHeight.heightWarning, 'visits_vitals_warn_height_high');
    });

    test('copyWith updates specified fields only', () {
      const v = VitalsModel(systolicBp: 120, diastolicBp: 80);
      final updated = v.copyWith(systolicBp: 130);
      expect(updated.systolicBp, 130);
      expect(updated.diastolicBp, 80);
    });
  });

  group('VisitModel Tests', () {
    test('100% nullable: empty instance has all null fields', () {
      const visit = VisitModel();
      expect(visit.id, isNull);
      expect(visit.bookingId, isNull);
      expect(visit.patientId, isNull);
      expect(visit.branchId, isNull);
      expect(visit.patientName, isNull);
      expect(visit.patientPhone, isNull);
      expect(visit.doctorId, isNull);
      expect(visit.doctorName, isNull);
      expect(visit.specialty, isNull);
      expect(visit.status, isNull);
      expect(visit.vitals, isNull);
      expect(visit.diagnosis, isNull);
      expect(visit.treatmentPlan, isNull);
      expect(visit.followUpNotes, isNull);
      expect(visit.followUpDays, isNull);
      expect(visit.startedAt, isNull);
      expect(visit.finalizedAt, isNull);
      expect(visit.lastSavedAt, isNull);
    });

    test('JSON serialization & deserialization roundtrip', () {
      final now = DateTime(2026, 11, 10, 10, 0);
      final visit = VisitModel(
        id: 'VIS-101',
        bookingId: 'MED-101',
        patientId: 'PAT-000101',
        branchId: 'branch_1',
        patientName: 'سارة أحمد',
        patientPhone: '+201012345678',
        doctorId: 'DOC-01',
        doctorName: 'د. حسام',
        specialty: 'باطنة',
        status: VisitStatusEnum.inProgress,
        vitals: const VitalsModel(systolicBp: 120),
        chiefComplaint: 'صداع مستمر',
        diagnosis: 'صداع نصفي',
        treatmentPlan: 'مسكنات وراحة',
        followUpDays: 7,
        startedAt: now,
        lastSavedAt: now,
      );

      final json = visit.toJson();
      final restored = VisitModel.fromJson(json);

      expect(restored.id, 'VIS-101');
      expect(restored.bookingId, 'MED-101');
      expect(restored.status, VisitStatusEnum.inProgress);
      expect(restored.vitals?.systolicBp, 120);
      expect(restored.chiefComplaint, 'صداع مستمر');
      expect(restored.diagnosis, 'صداع نصفي');
      expect(restored.followUpDays, 7);
      expect(restored, equals(visit));
    });

    test('copyWith properly preserves unmodified properties', () {
      const visit = VisitModel(
        id: 'VIS-101',
        diagnosis: 'تشخيص أولي',
        status: VisitStatusEnum.inProgress,
      );

      final updated = visit.copyWith(
        diagnosis: 'تشخيص نهائي',
        status: VisitStatusEnum.finalized,
      );

      expect(updated.id, 'VIS-101');
      expect(updated.diagnosis, 'تشخيص نهائي');
      expect(updated.status, VisitStatusEnum.finalized);
    });
  });

  group('ConsultationQueueItemModel Tests', () {
    test('computed properties evaluate correctly for various states', () {
      const booking = BookingModel(
        id: 'MED-101',
        patientName: 'سارة',
        queueNumber: 1,
        status: BookingStatusEnum.inConsultation,
      );
      const inProgressVisit = VisitModel(
        id: 'VIS-001',
        status: VisitStatusEnum.inProgress,
      );

      final item1 = ConsultationQueueItemModel(
        booking: booking,
        visit: inProgressVisit,
      );

      expect(item1.bookingId, 'MED-101');
      expect(item1.visitId, 'VIS-001');
      expect(item1.patientName, 'سارة');
      expect(item1.queueNumber, 1);
      expect(item1.hasActiveVisit, isTrue);
      expect(item1.isFinalized, isFalse);
      expect(item1.isTriageOnly, isFalse);
      expect(item1.bookingStatus, BookingStatusEnum.inConsultation);
      expect(item1.visitStatus, VisitStatusEnum.inProgress);

      const triageVisit = VisitModel(
        id: 'VIS-002',
        status: VisitStatusEnum.triage,
      );
      final item2 = ConsultationQueueItemModel(
        booking: booking,
        visit: triageVisit,
      );
      expect(item2.isTriageOnly, isTrue);
      expect(item2.hasActiveVisit, isFalse);

      const finalizedVisit = VisitModel(
        id: 'VIS-003',
        status: VisitStatusEnum.finalized,
      );
      final item3 = ConsultationQueueItemModel(
        booking: booking,
        visit: finalizedVisit,
      );
      expect(item3.isFinalized, isTrue);
      expect(item3.hasActiveVisit, isFalse);
    });
  });
}


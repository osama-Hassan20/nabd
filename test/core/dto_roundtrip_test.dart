import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/enums/payment_method.dart';
import 'package:eyadty/features/analytics/data/models/analytics_summary_kpi_model.dart';
import 'package:eyadty/features/analytics/data/models/branch_analytics_comparison_model.dart';
import 'package:eyadty/features/analytics/data/models/doctor_performance_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/hourly_traffic_metric_model.dart';
import 'package:eyadty/features/analytics/data/models/revenue_trend_point_model.dart';
import 'package:eyadty/features/analytics/data/models/service_revenue_distribution_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/cashier/data/models/cash_movement_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/enums/cash_movement_type_enum.dart';
import 'package:eyadty/features/cashier/data/models/enums/shift_status_enum.dart';
import 'package:eyadty/features/cashier/data/models/payment_transaction_model.dart';
import 'package:eyadty/features/cashier/data/models/refund_transaction_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_compensation_rule_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/employee_ledger_entry_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/medical_catalogs/data/models/enums/medical_catalog_kind_enum.dart';
import 'package:eyadty/features/medical_catalogs/data/models/medical_catalog_entry_model.dart';
import 'package:eyadty/features/notifications/data/models/notification_item_model.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/data/models/special_holiday_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/security_audit_log_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';

Map<String, dynamic> _wireRoundTrip(Map<String, dynamic> json) {
  final encoded = jsonEncode({...json, '__unknown_extra_field': 'ignored'});
  return jsonDecode(encoded) as Map<String, dynamic>;
}

void main() {
  final now = DateTime.utc(2026, 11, 27, 10, 30);

  group('DTO JSON Round-Trip Tests (model -> json -> model)', () {
    test('BookingModel & BookingSummaryModel', () {
      final b = BookingModel(
        id: 'B-1',
        queueNumber: 1,
        patientId: 'P-1',
        patientName: 'أحمد',
        doctorId: 'D-1',
        doctorName: 'د. حسام',
        specialtyCode: MedicalSpecialty.cardiology,
        visitType: BookingTypeEnum.emergency,
        bookingType: BookingTypeEnum.emergency,
        status: BookingStatusEnum.waiting,
        paymentStatus: PaymentStatusEnum.unpaid,
        consultationFee: 300,
        totalPrice: 300,
        date: now,
        appointmentTime: now,
        startTime: '10:30',
        endTime: '10:45',
        branchId: 'branch_1',
      );
      final b2 = BookingModel.fromJson(_wireRoundTrip(b.toJson()));
      expect(b2.id, b.id);
      expect(b2.patientName, b.patientName);
      expect(b2.specialtyCode, b.specialtyCode);
      expect(b2.status, b.status);
      expect(b2.consultationFee, b.consultationFee);

      const s = BookingSummaryModel(
        totalBookings: 10,
        inWaitingCount: 4,
        completedBookings: 5,
        noShowCount: 1,
      );
      final s2 = BookingSummaryModel.fromJson(_wireRoundTrip(s.toJson()));
      expect(s2.totalBookings, 10);
      expect(s2.inWaiting, 4);
    });

    test('PatientModel', () {
      final p = PatientModel(
        id: 'P-1',
        name: 'سارة',
        phone: '01012345678',
        gender: GenderEnum.female,
        isPregnant: true,
        createdAt: now,
      );
      final p2 = PatientModel.fromJson(_wireRoundTrip(p.toJson()));
      expect(p2.id, p.id);
      expect(p2.name, p.name);
      expect(p2.gender, p.gender);
      expect(p2.isPregnant, isTrue);
    });

    test('VisitModel, VitalsModel & ConsultationQueueItemModel', () {
      const v = VitalsModel(
        systolicBp: 120,
        diastolicBp: 80,
        heartRate: 72,
        temperature: 36.8,
        weightKg: 70,
        oxygenSaturation: 99,
      );
      final v2 = VitalsModel.fromJson(_wireRoundTrip(v.toJson()));
      expect(v2, equals(v));

      final visit = VisitModel(
        id: 'V-1',
        bookingId: 'B-1',
        patientId: 'P-1',
        doctorId: 'D-1',
        branchId: 'branch_1',
        status: VisitStatusEnum.inProgress,
        vitals: v,
        chiefComplaint: 'صداع',
      );
      final visit2 = VisitModel.fromJson(_wireRoundTrip(visit.toJson()));
      expect(visit2.id, visit.id);
      expect(visit2.status, visit.status);
      expect(visit2.vitals, equals(v));

      final q = ConsultationQueueItemModel(visit: visit);
      final q2 = ConsultationQueueItemModel.fromJson(_wireRoundTrip(q.toJson()));
      expect(q2.visit?.id, 'V-1');
    });

    test('DoctorModel & DoctorLeaveModel', () {
      const d = DoctorModel(
        id: 'D-1',
        name: 'د. حسام',
        specialty: 'قلب',
        specialties: [MedicalSpecialty.cardiology],
      );
      final d2 = DoctorModel.fromJson(_wireRoundTrip(d.toJson()));
      expect(d2.id, d.id);
      expect(d2.specialties, d.specialties);

      final leave = DoctorLeaveModel(
        id: 'L-1',
        doctorId: 'D-1',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        reason: 'إجازة',
      );
      final leave2 = DoctorLeaveModel.fromJson(_wireRoundTrip(leave.toJson()));
      expect(leave2.id, leave.id);
      expect(leave2.doctorId, leave.doctorId);
    });

    test('Cashier models (Shift, Payment, Movement, Refund)', () {
      final shift = CashierShiftModel(
        id: 'SH-1',
        branchId: 'branch_1',
        cashierUserId: 'U-1',
        cashierName: 'كاشير',
        openedAt: now,
        openingBalancePiastres: 50000,
        status: ShiftStatusEnum.open,
      );
      expect(
        CashierShiftModel.fromJson(_wireRoundTrip(shift.toJson())).id,
        'SH-1',
      );

      final pay = PaymentTransactionModel(
        id: 'PAY-1',
        shiftId: 'SH-1',
        branchId: 'branch_1',
        bookingId: 'B-1',
        patientId: 'P-1',
        patientName: 'أحمد',
        amountPiastres: 30000,
        paymentMethod: PaymentMethod.cash,
        cashierUserId: 'U-1',
        cashierName: 'كاشير',
        createdAt: now,
      );
      expect(
        PaymentTransactionModel.fromJson(_wireRoundTrip(pay.toJson())).amountPiastres,
        30000,
      );

      final mov = CashMovementModel(
        id: 'MOV-1',
        shiftId: 'SH-1',
        branchId: 'branch_1',
        movementType: CashMovementTypeEnum.pettyExpense,
        amountPiastres: 5000,
        reason: 'مستلزمات',
        performedByUserId: 'U-1',
        createdAt: now,
      );
      expect(
        CashMovementModel.fromJson(_wireRoundTrip(mov.toJson())).amountPiastres,
        5000,
      );

      final ref = RefundTransactionModel(
        id: 'REF-1',
        originalPaymentId: 'PAY-1',
        shiftId: 'SH-1',
        branchId: 'branch_1',
        refundAmountPiastres: 10000,
        reason: 'إلغاء',
        authorizedByUserId: 'U-1',
        authorizedByName: 'كاشير',
        createdAt: now,
      );
      expect(
        RefundTransactionModel.fromJson(_wireRoundTrip(ref.toJson())).refundAmountPiastres,
        10000,
      );
    });

    test('Drugs, Inventory, MedicalCatalogs, MedicalServices, Settings, Branches', () {
      const drug = DrugModel(id: 'DR-1', name: 'Panadol', scientificName: 'Paracetamol');
      expect(DrugModel.fromJson(_wireRoundTrip(drug.toJson())).name, 'Panadol');

      const inv = InventoryItemModel(
        id: 'INV-1',
        name: 'قفازات',
        code: 'INV-001',
        category: 'مستهلكات',
        unit: 'علبة',
        currentStock: 100,
        minStockAlert: 10,
        unitCost: 50,
      );
      expect(InventoryItemModel.fromJson(_wireRoundTrip(inv.toJson())).currentStock, 100);

      final cat = MedicalCatalogEntryModel(
        id: 'CAT-1',
        name: 'CBC',
        code: 'LAB-CBC',
        kind: MedicalCatalogKindEnum.values.first,
        category: 'دم',
        createdAt: now,
      );
      expect(MedicalCatalogEntryModel.fromJson(_wireRoundTrip(cat.toJson())).name, 'CBC');

      const srv = MedicalServiceModel(id: 'SRV-1', name: 'كشف', consultationFee: 300);
      expect(MedicalServiceModel.fromJson(_wireRoundTrip(srv.toJson())).consultationFee, 300);

      const set = CompanySettingsModel(companyName: 'عيادتي');
      expect(CompanySettingsModel.fromJson(_wireRoundTrip(set.toJson())).companyName, 'عيادتي');

      final hol = SpecialHolidayModel(id: 'HOL-1', name: 'الجمعة', startDate: now, endDate: now);
      expect(SpecialHolidayModel.fromJson(_wireRoundTrip(hol.toJson())).name, 'الجمعة');

      const br = BranchModel(id: 'branch_1', name: 'الرئيسي');
      expect(BranchModel.fromJson(_wireRoundTrip(br.toJson())).id, 'branch_1');
    });

    test('HR, Staff, Audit, SpecialtyRecords, Notifications & Analytics models', () {
      const rule = DoctorCompensationRuleModel(id: 'R-1', doctorId: 'D-1', branchId: 'branch_1');
      expect(DoctorCompensationRuleModel.fromJson(_wireRoundTrip(rule.toJson())).id, 'R-1');

      final stl = DoctorSettlementModel(id: 'STL-1', doctorId: 'D-1', branchId: 'branch_1', periodStart: now, periodEnd: now);
      expect(DoctorSettlementModel.fromJson(_wireRoundTrip(stl.toJson())).id, 'STL-1');

      final led = EmployeeLedgerEntryModel(id: 'LED-1', employeeId: 'U-1', branchId: 'branch_1', amountPiastres: 10000, createdAt: now);
      expect(EmployeeLedgerEntryModel.fromJson(_wireRoundTrip(led.toJson())).id, 'LED-1');

      final pay = StaffPayrollPeriodModel(id: 'PR-1', primaryBranchId: 'branch_1', month: 11, year: 2026);
      expect(StaffPayrollPeriodModel.fromJson(_wireRoundTrip(pay.toJson())).id, 'PR-1');

      const user = StaffUserModel(id: 'U-1', fullName: 'د. أحمد');
      expect(StaffUserModel.fromJson(_wireRoundTrip(user.toJson())).id, 'U-1');

      const role = RoleDefinitionModel(id: 'role_doctor', nameAr: 'طبيب', nameEn: 'Doctor');
      expect(RoleDefinitionModel.fromJson(_wireRoundTrip(role.toJson())).id, 'role_doctor');

      final log = SecurityAuditLogModel(id: 'LOG-1', eventType: 'login', performedByUserId: 'U-1', performedByUserName: 'أحمد', timestamp: now);
      expect(SecurityAuditLogModel.fromJson(_wireRoundTrip(log.toJson())).id, 'LOG-1');

      final rec = SpecialtyRecordEntryModel(id: 'SR-1', patientId: 'P-1', specialty: MedicalSpecialty.pediatrics, kind: 'growth', data: const {'weightKg': 12}, createdAt: now);
      expect(SpecialtyRecordEntryModel.fromJson(_wireRoundTrip(rec.toJson())).id, 'SR-1');

      final notif = NotificationItemModel(id: 'N-1', title: 'تنبيه', body: 'محتوى', type: NotificationTypeEnum.booking, createdAt: now);
      expect(NotificationItemModel.fromJson(_wireRoundTrip(notif.toJson())), equals(notif));

      const kpi = AnalyticsSummaryKpiModel(totalRevenuePiastres: 100000);
      expect(AnalyticsSummaryKpiModel.fromJson(_wireRoundTrip(kpi.toJson())), equals(kpi));

      const bComp = BranchAnalyticsComparisonModel(branchId: 'branch_1', visitsCount: 5);
      expect(BranchAnalyticsComparisonModel.fromJson(_wireRoundTrip(bComp.toJson())), equals(bComp));

      const dPerf = DoctorPerformanceMetricModel(doctorId: 'D-1', visitsCount: 5);
      expect(DoctorPerformanceMetricModel.fromJson(_wireRoundTrip(dPerf.toJson())), equals(dPerf));

      const hTraf = HourlyTrafficMetricModel(hour: 10, visitsCount: 3);
      expect(HourlyTrafficMetricModel.fromJson(_wireRoundTrip(hTraf.toJson())), equals(hTraf));

      final rTrend = RevenueTrendPointModel(label: 'Nov', date: now, revenuePiastres: 50000);
      expect(RevenueTrendPointModel.fromJson(_wireRoundTrip(rTrend.toJson())), equals(rTrend));

      const sDist = ServiceRevenueDistributionModel(serviceName: 'كشف', count: 4);
      expect(ServiceRevenueDistributionModel.fromJson(_wireRoundTrip(sDist.toJson())), equals(sDist));
    });
  });
}

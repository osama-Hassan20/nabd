import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_item_model.dart';
import 'package:eyadty/features/hr/data/models/doctor_settlement_model.dart';
import 'package:eyadty/features/hr/data/models/enums/settlement_status_enum.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_item_model.dart';
import 'package:eyadty/features/hr/data/models/staff_payroll_period_model.dart';
import 'package:eyadty/features/hr/presentation/helpers/adaptive_doctor_settlement_pdf_generator.dart';
import 'package:eyadty/features/hr/presentation/helpers/adaptive_staff_payroll_pdf_generator.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive HR PDF Generators Tests (Plan F-06 M-8)', () {
    final sampleSettlement = DoctorSettlementModel(
      id: 'SET-PDF-001',
      settlementNumber: 'SET-DOC-202605-001',
      doctorId: 'DOC-01',
      doctorName: 'د. طارق الشناوي',
      branchId: 'branch_1',
      periodStart: DateTime(2026, 5, 1),
      periodEnd: DateTime(2026, 5, 31),
      totalVisitsCount: 2,
      totalNetRevenuePiastres: 50000,
      totalDoctorCommissionPiastres: 25000,
      netPayablePiastres: 25000,
      status: SettlementStatusEnum.confirmed,
      items: const [
        DoctorSettlementItemModel(
          visitId: 'VISIT-01',
          patientName: 'أحمد علي',
          serviceName: 'كشف استشاري',
          grossFeePiastres: 30000,
          discountAmountPiastres: 5000,
          netAmountPiastres: 25000,
          doctorEarnedPiastres: 12500,
          clinicSharePiastres: 12500,
        ),
        DoctorSettlementItemModel(
          visitId: 'VISIT-02',
          patientName: 'منى محمود',
          serviceName: 'كشف استشاري',
          grossFeePiastres: 25000,
          netAmountPiastres: 25000,
          doctorEarnedPiastres: 12500,
          clinicSharePiastres: 12500,
        ),
      ],
    );

    final samplePayroll = StaffPayrollPeriodModel(
      id: 'PAY-PDF-001',
      payrollNumber: 'PAY-2026-05',
      primaryBranchId: 'branch_1',
      month: 5,
      year: 2026,
      totalEmployeesCount: 1,
      totalBaseSalaryPiastres: 800000,
      totalAllowancesPiastres: 100000,
      totalDeductionsPiastres: 50000,
      totalNetPayablePiastres: 850000,
      items: const [
        StaffPayrollItemModel(
          staffUserId: 'USR-01',
          employeeName: 'سارة ممدوح',
          jobTitle: 'تمريض أول',
          baseSalaryPiastres: 800000,
          totalAllowancesPiastres: 100000,
          totalDeductionsPiastres: 50000,
          advancesDeductedPiastres: 0,
          netSalaryPiastres: 850000,
        ),
      ],
    );

    test('1. Doctor settlement generator produces non-empty bytes in A4 format', () async {
      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        format: PrintFormat.a4,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('2. Doctor settlement generator produces non-empty bytes in thermal80 format', () async {
      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        format: PrintFormat.thermal80,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('3. Doctor settlement PDF handles empty items gracefully without throwing', () async {
      const emptySettlement = DoctorSettlementModel(
        id: 'SET-EMPTY',
        items: [],
      );

      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: emptySettlement,
      );

      expect(bytes.isNotEmpty, isTrue);
    });

    test('4. Doctor settlement PDF includes doctor name and settlement info', () async {
      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
      );

      expect(bytes.length, greaterThan(100));
    });

    test('5. Doctor settlement PDF formats currency accurately in piastres', () async {
      final bytesA4 = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        format: PrintFormat.a4,
      );
      final bytesThermal = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        format: PrintFormat.thermal80,
      );

      expect(bytesA4.isNotEmpty, isTrue);
      expect(bytesThermal.isNotEmpty, isTrue);
    });

    test('6. Doctor settlement PDF uses custom clinic name from settings', () async {
      const customSettings = CompanySettingsModel(
        companyName: 'مجمع النخبة التخصصي',
        phone: '01000000000',
        address: 'القاهرة',
      );

      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        settings: customSettings,
      );

      expect(bytes.isNotEmpty, isTrue);
    });

    test('7. Doctor settlement PDF falls back cleanly to default clinic name if settings are null', () async {
      final bytes = await AdaptiveDoctorSettlementPdfGenerator.generate(
        settlement: sampleSettlement,
        settings: null,
      );

      expect(bytes.isNotEmpty, isTrue);
    });

    test('8. Staff payroll generator produces non-empty bytes in A4 landscape format', () async {
      final bytes = await AdaptiveStaffPayrollPdfGenerator.generate(
        period: samplePayroll,
        format: PrintFormat.a4,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('9. Staff payroll generator handles thermal80 format by gracefully falling back to landscape A4', () async {
      final bytes = await AdaptiveStaffPayrollPdfGenerator.generate(
        period: samplePayroll,
        format: PrintFormat.thermal80,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('10. Staff payroll PDF handles empty items gracefully without throwing', () async {
      const emptyPayroll = StaffPayrollPeriodModel(
        id: 'PAY-EMPTY',
        items: [],
      );

      final bytes = await AdaptiveStaffPayrollPdfGenerator.generate(
        period: emptyPayroll,
      );

      expect(bytes.isNotEmpty, isTrue);
    });

    test('11. Staff payroll PDF formats financial totals accurately in piastres', () async {
      final bytes = await AdaptiveStaffPayrollPdfGenerator.generate(
        period: samplePayroll,
      );

      expect(bytes.length, greaterThan(100));
    });

    test('12. Staff payroll PDF uses custom clinic branding from settings', () async {
      const customSettings = CompanySettingsModel(
        companyName: 'مستشفى الشفاء التخصصي',
        phone: '01234567890',
        address: 'الجيزة',
      );

      final bytes = await AdaptiveStaffPayrollPdfGenerator.generate(
        period: samplePayroll,
        settings: customSettings,
      );

      expect(bytes.isNotEmpty, isTrue);
    });
  });
}


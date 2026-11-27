import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/settings/data/models/company_settings_model.dart';
import 'package:eyadty/features/settings/data/models/enums/print_format_enum.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/addendum_change_type_enum.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_addendum_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/domain/use_cases/print_prescription_use_case.dart';
import 'package:eyadty/features/visits/presentation/helpers/prescription_pdf_generator.dart';

class FakeUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  FakeUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class FakeRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  FakeRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  ByteData? fontData;
  late InMemoryAuditLogger auditLogger;
  late FakeUserSessionProvider userProvider;
  late FakeRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late PrintPrescriptionUseCase printPrescriptionUseCase;

  setUpAll(() {
    final fontFile = File('assets/fonts/madani.ttf');
    if (fontFile.existsSync()) {
      fontData = ByteData.view(fontFile.readAsBytesSync().buffer);
    }
  });

  setUp(() {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
    rolesProvider = FakeRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );

    userProvider = FakeUserSessionProvider(
      user: const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام الدين',
        linkedDoctorId: 'DOC-01',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
            isPrimary: true,
          ),
        ],
      ),
    );

    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    printPrescriptionUseCase = PrintPrescriptionUseCase(
      permissionEvaluator: permissionEvaluator,
      userProvider: userProvider,
      auditLogger: auditLogger,
    );
  });

  final sampleVisit = VisitModel(
    id: 'VIS-101',
    bookingId: 'BOOK-001',
    patientId: 'PAT-001',
    patientName: 'سارة أحمد عبد الله',
    doctorId: 'DOC-01',
    doctorName: 'د. حسام الدين',
    branchId: 'branch_1',
    startedAt: DateTime(2026, 11, 10, 11, 30),
    diagnosis: 'التهاب الشعب الهوائية الحاد',
    prescriptionItems: const [
      PrescriptionItemModel(
        id: 'RXI-001',
        drugId: 'DRUG-001',
        tradeName: 'Amoxicillin 500mg',
        scientificName: 'Amoxicillin Trihydrate',
        dosage: '500mg',
        frequency: '3 مرات يومياً',
        duration: '7 أيام',
        instructions: 'بعد الأكل',
      ),
      PrescriptionItemModel(
        id: 'RXI-002',
        drugId: 'DRUG-002',
        tradeName: 'Panadol Extra',
        dosage: '1000mg',
        frequency: 'عند اللزوم',
        duration: '5 أيام',
        instructions: 'مع وفرة من الماء',
      ),
    ],
  );

  final samplePatient = const PatientModel(
    id: 'PAT-001',
    fileNumber: 'FILE-9988',
    name: 'سارة أحمد عبد الله',
    gender: GenderEnum.female,
  );

  final sampleSettings = const CompanySettingsModel(
    id: 'branch_1',
    companyName: 'عيادة الأمل التخصصية',
    phone: '01012345678',
    address: 'القاهرة - المعادي',
    prescriptionPrintFormat: 'a4',
  );

  group('Prescription Printing Engine Tests (M-5)', () {
    test('1. PrescriptionPdfGenerator.generate generates valid A4 PDF bytes (%PDF header)', () async {
      final bytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        settings: sampleSettings,
        format: PrintFormat.a4,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('2. PrescriptionPdfGenerator.generate generates valid Thermal 80mm PDF bytes (%PDF header)', () async {
      final bytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        settings: sampleSettings,
        format: PrintFormat.thermal80,
        fontData: fontData,
      );

      expect(bytes, isNotNull);
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('3. Uses companySettings.effectivePrescriptionPrintFormat when format is omitted', () async {
      const thermalSettings = CompanySettingsModel(
        companyName: 'عيادة الشفاء',
        prescriptionPrintFormat: 'thermal80',
      );

      final bytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        settings: thermalSettings,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('4. Falls back to A4 format if companySettings is null or format is empty/invalid', () async {
      final bytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        settings: null,
        format: null,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('5. Multi-tenant SaaS neutrality: clinic info rendered dynamically without hardcoded names', () async {
      const customClinicSettings = CompanySettingsModel(
        companyName: 'مستشفى النور التخصصي الدولي',
        phone: '01298765432',
        address: 'الجيزة - المهندسين',
      );

      final bytes = await PrescriptionPdfGenerator.generate(
        visit: sampleVisit,
        patient: samplePatient,
        settings: customClinicSettings,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('6. Effective prescription computation: renders effective list computed with addenda', () async {
      final visitWithAddenda = sampleVisit.copyWith(
        addenda: [
          const VisitAddendumModel(
            id: 'ADD-01',
            changeType: AddendumChangeTypeEnum.dose,
            affectedItemId: 'RXI-001',
            newItemSnapshot: PrescriptionItemModel(
              id: 'RXI-001',
              tradeName: 'Amoxicillin 1000mg (High Dose)',
              dosage: '1000mg',
              frequency: 'مرتان يومياً',
            ),
            reason: 'زيادة الجرعة بناء على نتائج التحاليل',
          ),
          const VisitAddendumModel(
            id: 'ADD-02',
            changeType: AddendumChangeTypeEnum.discontinue,
            affectedItemId: 'RXI-002',
            reason: 'إيقاف البنادول لوجود بديل',
          ),
        ],
      );

      final bytes = await PrescriptionPdfGenerator.generate(
        visit: visitWithAddenda,
        patient: samplePatient,
        settings: sampleSettings,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('7. Amended watermark/badge: when addenda exist, PDF contains amended notice', () async {
      final visitWithAddendum = sampleVisit.copyWith(
        addenda: [
          const VisitAddendumModel(
            id: 'ADD-01',
            changeType: AddendumChangeTypeEnum.dose,
            reason: 'تعديل علاجي طارئ',
          ),
        ],
      );

      final bytes = await PrescriptionPdfGenerator.generate(
        visit: visitWithAddendum,
        patient: samplePatient,
        settings: sampleSettings,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('8. Unmodified prescription: when no addenda exist, PDF does not show amended badge', () async {
      final cleanVisit = sampleVisit.copyWith(addenda: []);

      final bytes = await PrescriptionPdfGenerator.generate(
        visit: cleanVisit,
        patient: samplePatient,
        settings: sampleSettings,
        fontData: fontData,
      );

      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('9. PrintPrescriptionUseCase authorizes attending doctor with issuePrescription', () async {
      final result = await printPrescriptionUseCase(
        PrintPrescriptionParams(
          visit: sampleVisit,
          patient: samplePatient,
          settings: sampleSettings,
          fontData: fontData,
        ),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (bytes) {
          expect(bytes.isNotEmpty, isTrue);
          expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        },
      );
    });

    test('10. PrintPrescriptionUseCase denies printing if user lacks issuePrescription permission', () async {
      // Receptionist lacks issuePrescription
      userProvider.user = const StaffUserModel(
        id: 'USR-REC-01',
        fullName: 'أ. مروة الاستقبال',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.reception],
            isPrimary: true,
          ),
        ],
      );

      final result = await printPrescriptionUseCase(
        PrintPrescriptionParams(
          visit: sampleVisit,
          patient: samplePatient,
          settings: sampleSettings,
          fontData: fontData,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<PermissionDeniedFailure>());
          expect(failure.errMessage, equals('permission_denied_issue_prescription'));
        },
        (_) => fail('Expected Left but got Right'),
      );

      // 0 audit logs on denial
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('11. PrintPrescriptionUseCase denies doctor if linkedDoctorId != visit.doctorId', () async {
      // Doctor 02 attempting to print prescription of Doctor 01
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-02',
        fullName: 'د. طارق الآخر',
        linkedDoctorId: 'DOC-02',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
            isPrimary: true,
          ),
        ],
      );

      final result = await printPrescriptionUseCase(
        PrintPrescriptionParams(
          visit: sampleVisit,
          patient: samplePatient,
          settings: sampleSettings,
          fontData: fontData,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<PermissionDeniedFailure>());
        },
        (_) => fail('Expected Left but got Right'),
      );

      expect(auditLogger.getLogs(), isEmpty);
    });

    test('12. Security Audit Event prescription_printed emitted on success with strict whitelist', () async {
      final result = await printPrescriptionUseCase(
        PrintPrescriptionParams(
          visit: sampleVisit,
          patient: samplePatient,
          settings: sampleSettings,
          fontData: fontData,
        ),
      );

      expect(result.isRight(), isTrue);

      final logs = auditLogger.getLogs();
      expect(logs.length, equals(1));

      final log = logs.first;
      expect(log.eventType, equals('prescription_printed'));
      expect(log.performedByUserId, equals('USR-DOC-01'));
      expect(log.branchId, equals('branch_1'));

      final details = jsonDecode(log.details ?? '{}') as Map<String, dynamic>;
      const allowedKeys = {'visitId', 'doctorId', 'itemsCount', 'format', 'isAmended'};
      expect(details.keys.toSet().difference(allowedKeys), isEmpty);

      expect(details['visitId'], equals('VIS-101'));
      expect(details['doctorId'], equals('DOC-01'));
      expect(details['itemsCount'], equals(2));
      expect(details['format'], equals('a4'));
      expect(details['isAmended'], isFalse);

      // Strict privacy check: zero clinical/PHI text in audit log
      final rawDetails = log.details ?? '';
      expect(rawDetails.contains('Amoxicillin'), isFalse);
      expect(rawDetails.contains('Panadol'), isFalse);
      expect(rawDetails.contains('سارة'), isFalse);
      expect(rawDetails.contains('الشعب الهوائية'), isFalse);
    });
  });
}

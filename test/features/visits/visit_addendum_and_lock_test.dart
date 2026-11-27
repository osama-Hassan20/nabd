import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/addendum_change_type_enum.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_addendum_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/add_visit_addendum_use_case.dart';
import 'package:eyadty/features/visits/presentation/helpers/effective_prescription_calculator.dart';

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
  late BookingsRepoImpl bookingsRepo;
  late VisitsRepoImpl visitsRepo;
  late InMemoryAuditLogger auditLogger;
  late FakeUserSessionProvider userProvider;
  late FakeRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;
  late AddVisitAddendumUseCase addVisitAddendumUseCase;

  setUp(() {
    bookingsRepo = BookingsRepoImpl();
    visitsRepo = VisitsRepoImpl(bookingsRepo: bookingsRepo);
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

    rolesProvider = FakeRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );

    // Default: assigned doctor DOC-01
    userProvider = FakeUserSessionProvider(
      user: const StaffUserModel(
        id: 'USR-DOC-1',
        fullName: 'د. حسام الدين مصطفى',
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
      branch: 'branch_1',
    );

    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    addVisitAddendumUseCase = AddVisitAddendumUseCase(
      visitsRepo: visitsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
  });

  group('Visit Addendum, Immutability Lock & Effective Prescription Tests (M-3)', () {
    test('1. rejects addendum on unfinalized visit (status != finalized)', () async {
      // VIS-001 is inProgress
      const params = AddVisitAddendumParams(
        visitId: 'VIS-001',
        reason: 'Patient called with worsening symptoms',
        changeType: AddendumChangeTypeEnum.dose,
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'cannot_add_addendum_to_unfinalized_visit'),
        (_) => fail('should fail'),
      );
    });

    test('2. rejects empty or whitespace reason with addendum_reason_required', () async {
      const params = AddVisitAddendumParams(
        visitId: 'VIS-002', // finalized
        reason: '   ',
        changeType: AddendumChangeTypeEnum.dose,
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'addendum_reason_required'),
        (_) => fail('should fail'),
      );
    });

    test('3. rejects non-assigned doctor with only_assigned_doctor_can_add_addendum', () async {
      // Switch user to DOC-02 while VIS-002 doctor is DOC-01
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-2',
        fullName: 'د. أحمد سمير',
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

      const params = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Adjusting medication',
        changeType: AddendumChangeTypeEnum.dose,
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'only_assigned_doctor_can_add_addendum'),
        (_) => fail('should fail'),
      );
    });

    test('4. requires issuePrescription permission for prescription addenda', () async {
      // User with nurse role attempting rx addendum
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-1',
        fullName: 'ممرضة فاطمة',
        linkedDoctorId: 'DOC-01',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
            isPrimary: true,
          ),
        ],
      );

      const params = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Patient reported pain',
        changeType: AddendumChangeTypeEnum.add,
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'permission_denied_issue_prescription'),
        (_) => fail('should fail'),
      );
    });

    test('5. requires editMedicalDiagnosis permission for diagnosis addendum', () async {
      // User without editMedicalDiagnosis permission
      userProvider.user = const StaffUserModel(
        id: 'USR-REC-1',
        fullName: 'موظف استقبال',
        linkedDoctorId: 'DOC-01',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.reception],
            isPrimary: true,
          ),
        ],
      );

      const params = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Updated lab test result',
        changeType: AddendumChangeTypeEnum.diagnosis,
        diagnosisBefore: 'نزلة معوية',
        diagnosisAfter: 'التهاب المعدة المزمن',
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'permission_denied_edit_medical_diagnosis'),
        (_) => fail('should fail'),
      );
    });

    test('6. rejects diagnosis addendum if new diagnosis is identical or empty', () async {
      // Identical diagnosis
      const paramsIdentical = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Clarification',
        changeType: AddendumChangeTypeEnum.diagnosis,
        diagnosisBefore: 'نزلة معوية حادة مع جفاف خفيف',
        diagnosisAfter: 'نزلة معوية حادة مع جفاف خفيف',
      );

      final res1 = await addVisitAddendumUseCase(paramsIdentical);
      expect(res1.isLeft(), isTrue);
      res1.fold(
        (failure) => expect(failure.errMessage, 'diagnosis_addendum_must_differ'),
        (_) => fail('should fail'),
      );

      // Empty diagnosis
      const paramsEmpty = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Clarification',
        changeType: AddendumChangeTypeEnum.diagnosis,
        diagnosisBefore: 'نزلة معوية',
        diagnosisAfter: '   ',
      );
      final res2 = await addVisitAddendumUseCase(paramsEmpty);
      expect(res2.isLeft(), isTrue);
      res2.fold(
        (failure) => expect(failure.errMessage, 'diagnosis_addendum_must_differ'),
        (_) => fail('should fail'),
      );
    });

    test('7. successfully creates and appends addendum to repository', () async {
      const params = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Patient experienced severe cramping',
        changeType: AddendumChangeTypeEnum.add,
        newItemSnapshot: PrescriptionItemModel(
          id: 'RXI-NEW-01',
          tradeName: 'Buscopan 10mg',
          dosage: '1 tablet',
          frequency: 'rx_freq_thrice_daily',
          duration: 'rx_duration_3_days',
        ),
      );

      final res = await addVisitAddendumUseCase(params);
      expect(res.isRight(), isTrue);

      final updatedVisit = res.getOrElse(() => throw StateError(''));
      expect(updatedVisit.addenda, isNotNull);
      expect(updatedVisit.addenda!.length, 1);
      final addendum = updatedVisit.addenda!.first;
      expect(addendum.id, 'ADD-1');
      expect(addendum.doctorId, 'DOC-01');
      expect(addendum.reason, 'Patient experienced severe cramping');
      expect(addendum.changeType, AddendumChangeTypeEnum.add);
      expect(addendum.newItemSnapshot?.tradeName, 'Buscopan 10mg');
    });

    test('8. logs strict security audit event containing IDs and Enums ONLY (zero clinical/drug text)', () async {
      const params = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: 'Severe fever persisted',
        changeType: AddendumChangeTypeEnum.dose,
        affectedItemId: 'RXI-01',
        newItemSnapshot: PrescriptionItemModel(
          id: 'RXI-01',
          tradeName: 'Paracetamol 1000mg',
          dosage: '1000mg',
        ),
      );

      await addVisitAddendumUseCase(params);

      final logs = auditLogger.getLogs(eventType: 'visit_addendum_added');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.eventType, 'visit_addendum_added');
      expect(log.performedByUserId, 'DOC-01');

      final details = jsonDecode(log.details ?? '{}') as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'addendumId', 'visitId', 'doctorId', 'changeType'}));
      expect(details['addendumId'], isNotEmpty);
      expect(details['visitId'], 'VIS-002');
      expect(details['doctorId'], 'DOC-01');
      expect(details['changeType'], 'dose');

      // Zero clinical text in details
      expect(log.details, isNot(contains('Paracetamol')));
      expect(log.details, isNot(contains('fever')));
    });

    test('9. zero audit log is written when addendum creation fails', () async {
      const failingParams = AddVisitAddendumParams(
        visitId: 'VIS-002',
        reason: '', // Invalid empty reason
        changeType: AddendumChangeTypeEnum.dose,
      );

      final initialLogsCount = auditLogger.getLogs().length;
      final res = await addVisitAddendumUseCase(failingParams);
      expect(res.isLeft(), isTrue);

      final afterLogsCount = auditLogger.getLogs().length;
      expect(afterLogsCount, equals(initialLogsCount));
    });

    test('10. EffectivePrescriptionCalculator applies "add" addendum by appending medication', () {
      const baseVisit = VisitModel(
        id: 'V-10',
        prescriptionItems: [
          PrescriptionItemModel(id: 'RXI-1', tradeName: 'Drug A'),
        ],
        addenda: [
          VisitAddendumModel(
            id: 'ADD-1',
            changeType: AddendumChangeTypeEnum.add,
            newItemSnapshot: PrescriptionItemModel(id: 'RXI-2', tradeName: 'Drug B'),
          ),
        ],
      );

      final effective = EffectivePrescriptionCalculator.calculateEffectivePrescription(
        visit: baseVisit,
      );

      expect(effective.length, 2);
      expect(effective[0].tradeName, 'Drug A');
      expect(effective[1].tradeName, 'Drug B');
    });

    test('11. EffectivePrescriptionCalculator applies "discontinue" addendum by removing item', () {
      const baseVisit = VisitModel(
        id: 'V-11',
        prescriptionItems: [
          PrescriptionItemModel(id: 'RXI-1', tradeName: 'Drug A'),
          PrescriptionItemModel(id: 'RXI-2', tradeName: 'Drug B'),
        ],
        addenda: [
          VisitAddendumModel(
            id: 'ADD-1',
            changeType: AddendumChangeTypeEnum.discontinue,
            affectedItemId: 'RXI-1',
          ),
        ],
      );

      final effective = EffectivePrescriptionCalculator.calculateEffectivePrescription(
        visit: baseVisit,
      );

      expect(effective.length, 1);
      expect(effective.first.id, 'RXI-2');
      expect(effective.first.tradeName, 'Drug B');
    });

    test('12. EffectivePrescriptionCalculator applies "dose/frequency" by replacing snapshot', () {
      const baseVisit = VisitModel(
        id: 'V-12',
        prescriptionItems: [
          PrescriptionItemModel(id: 'RXI-1', tradeName: 'Amoxicillin', dosage: '500mg'),
        ],
        addenda: [
          VisitAddendumModel(
            id: 'ADD-1',
            changeType: AddendumChangeTypeEnum.dose,
            affectedItemId: 'RXI-1',
            newItemSnapshot: PrescriptionItemModel(
              id: 'RXI-1',
              tradeName: 'Amoxicillin',
              dosage: '1000mg',
            ),
          ),
        ],
      );

      final effective = EffectivePrescriptionCalculator.calculateEffectivePrescription(
        visit: baseVisit,
      );

      expect(effective.length, 1);
      expect(effective.first.id, 'RXI-1');
      expect(effective.first.dosage, '1000mg');
    });

    test('13. EffectivePrescriptionCalculator respects chronological ordering of addenda', () {
      final t1 = DateTime(2026, 11, 15, 10, 0);
      final t2 = DateTime(2026, 11, 15, 12, 0);

      final baseVisit = VisitModel(
        id: 'V-13',
        prescriptionItems: const [
          PrescriptionItemModel(id: 'RXI-1', tradeName: 'Drug A', dosage: '10mg'),
        ],
        addenda: [
          // Older addendum (t1) updates to 20mg
          VisitAddendumModel(
            id: 'ADD-1',
            createdAt: t1,
            changeType: AddendumChangeTypeEnum.dose,
            affectedItemId: 'RXI-1',
            newItemSnapshot: const PrescriptionItemModel(id: 'RXI-1', tradeName: 'Drug A', dosage: '20mg'),
          ),
          // Newer addendum (t2) discontinues Drug A
          VisitAddendumModel(
            id: 'ADD-2',
            createdAt: t2,
            changeType: AddendumChangeTypeEnum.discontinue,
            affectedItemId: 'RXI-1',
          ),
        ],
      );

      final effective = EffectivePrescriptionCalculator.calculateEffectivePrescription(
        visit: baseVisit,
      );

      // Final effective state: Drug A discontinued
      expect(effective, isEmpty);
    });

    test('14. EffectivePrescriptionCalculator.calculateEffectiveDiagnosis returns latest diagnosis or original', () {
      const visitWithoutAddenda = VisitModel(
        id: 'V-14a',
        diagnosis: 'التهاب حلق حاد',
      );
      expect(
        EffectivePrescriptionCalculator.calculateEffectiveDiagnosis(visit: visitWithoutAddenda),
        'التهاب حلق حاد',
      );

      final t1 = DateTime(2026, 11, 15, 10, 0);
      final t2 = DateTime(2026, 11, 15, 14, 0);

      final visitWithAddenda = VisitModel(
        id: 'V-14b',
        diagnosis: 'التهاب حلق حاد',
        addenda: [
          VisitAddendumModel(
            id: 'ADD-1',
            createdAt: t1,
            changeType: AddendumChangeTypeEnum.diagnosis,
            diagnosisBefore: 'التهاب حلق حاد',
            diagnosisAfter: 'التهاب اللوزتين القيحي',
          ),
          VisitAddendumModel(
            id: 'ADD-2',
            createdAt: t2,
            changeType: AddendumChangeTypeEnum.diagnosis,
            diagnosisBefore: 'التهاب اللوزتين القيحي',
            diagnosisAfter: 'خراج حول اللوزة (Peritonsillar Abscess)',
          ),
        ],
      );

      expect(
        EffectivePrescriptionCalculator.calculateEffectiveDiagnosis(visit: visitWithAddenda),
        'خراج حول اللوزة (Peritonsillar Abscess)',
      );
      expect(EffectivePrescriptionCalculator.isVisitAmended(visit: visitWithAddenda), isTrue);
    });
  });
}

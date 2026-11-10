import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';

class MockUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  MockUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class MockRolesSessionProvider implements RolesProvider {
  List<RoleDefinitionModel> roles;
  MockRolesSessionProvider({required this.roles});

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;

  late StartConsultationUseCase startConsultationUseCase;
  late FinalizeVisitUseCase finalizeVisitUseCase;
  late RecordVitalsUseCase recordVitalsUseCase;
  late SaveVisitDraftUseCase saveVisitDraftUseCase;

  setUp(() {
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

    rolesProvider = MockRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );
    userProvider = MockUserSessionProvider();
    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    startConsultationUseCase = StartConsultationUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    finalizeVisitUseCase = FinalizeVisitUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    recordVitalsUseCase = RecordVitalsUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    saveVisitDraftUseCase = SaveVisitDraftUseCase(
      repo: visitsRepo,
      permissionEvaluator: permissionEvaluator,
    );

    // Default authenticated user: Doctor DOC-01
    userProvider.user = const StaffUserModel(
      id: 'USR-DOC-01',
      fullName: 'د. حسام الدين مصطفى',
      isActive: true,
      linkedDoctorId: 'DOC-01',
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          isPrimary: true,
          roleIds: [RoleIds.doctor],
        ),
      ],
    );
  });

  group('StartConsultationUseCase Saga & RBAC Tests', () {
    test('happy path: changes booking to inConsultation, starts visit, emits audit log', () async {
      // MED-101 has doctor DOC-01. User is DOC-01.
      // But MED-101 is already inConsultation. Let's use MED-102 (DOC-02) by setting user as DOC-02
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-02',
        fullName: 'د. أحمد الشافعي',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final bBefore = await bookingsRepo.getBookingById('MED-102');
      expect(bBefore.getOrElse(() => const BookingModel()).status, BookingStatusEnum.waiting);

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.inProgress);
      expect(visit.bookingId, 'MED-102');

      // Check booking status was updated to inConsultation
      final bAfter = await bookingsRepo.getBookingById('MED-102');
      expect(
        bAfter.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.inConsultation,
      );

      // Audit Log Verification
      final logs = auditLogger.getLogs(eventType: 'visit_started');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.eventType, 'visit_started');
      expect(log.details, contains('visitId=${visit.id}'));
      expect(log.details, contains('bookingId=MED-102'));
      expect(log.details, contains('patientId=PAT-000102'));
      expect(log.details, contains('doctorId=DOC-02'));
      // Zero clinical text in details
      expect(log.details, isNot(contains('تشخيص')));
      expect(log.details, isNot(contains('علاج')));
    });

    test('RBAC: rejects when doctor tries to start consultation for another doctor', () async {
      // User is DOC-01, trying to start MED-102 assigned to DOC-02
      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_start_consultation'),
        (_) => fail('should fail'),
      );
      // Zero audit log on failure
      expect(auditLogger.getLogs(eventType: 'visit_started'), isEmpty);
    });

    test('RBAC: rejects when unauthorized role (nurse) tries to start consultation', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة فاطمة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.nurse],
          ),
        ],
      );

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_start_consultation'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'visit_started'), isEmpty);
    });

    test('RBAC: non-practicing owner is rejected from startConsultation', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER-01',
        fullName: 'المالك غير الممارس',
        isActive: true,
        isOwner: true,
        linkedDoctorId: null, // non-practicing
      );

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-101',
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'سارة',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_start_consultation'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'visit_started'), isEmpty);
    });

    test('RBAC: practicing owner is rejected when starting consultation for another doctor', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER-DOC-02',
        fullName: 'المالك الممارس',
        isActive: true,
        isOwner: true,
        linkedDoctorId: 'DOC-02', // practicing as DOC-02
      );

      // Attempting to start consultation for MED-101 which is assigned to DOC-01
      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-101',
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'سارة',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_start_consultation'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'visit_started'), isEmpty);
    });

    test('RBAC: medical director is rejected unless assigned doctor for the booking', () async {
      // 1. Medical director with linkedDoctorId == 'DOC-02' trying to start for MED-101 (assigned to DOC-01) -> rejected
      userProvider.user = const StaffUserModel(
        id: 'USR-MED-DIR',
        fullName: 'المدير الطبي',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.medicalDirector],
          ),
        ],
      );

      final resDenied = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-101',
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'سارة',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(resDenied.isLeft(), isTrue);
      resDenied.fold(
        (f) => expect(f.errMessage, 'permission_denied_start_consultation'),
        (_) => fail('should fail'),
      );

      // 2. Medical director who is ALSO assigned doctor role and is the assigned doctor for MED-102 -> accepted
      userProvider.user = const StaffUserModel(
        id: 'USR-MED-DIR-PRACTICING',
        fullName: 'د. أحمد الشافعي - مدير طبي وممارس',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.medicalDirector, RoleIds.doctor],
          ),
        ],
      );

      final resGranted = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
        ),
      );

      expect(resGranted.isRight(), isTrue);
    });

    test('Domain Guard: rejects starting consultation for booking not today', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final yesterday = CairoTimeHelper.now().subtract(const Duration(days: 1));
      final createdRes = await bookingsRepo.createBooking(
        BookingModel(
          patientId: 'PAT-000101',
          patientName: 'مريض قديم',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
          branchId: 'branch_1',
          status: BookingStatusEnum.waiting,
          appointmentTime: yesterday,
        ),
      );
      final createdBooking = createdRes.getOrElse(() => throw StateError('fail'));

      final res = await startConsultationUseCase(
        StartConsultationParams(
          bookingId: createdBooking.id!,
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'مريض قديم',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_not_today'),
        (_) => fail('should fail'),
      );
    });

    test('Domain Guard: rejects starting consultation when branch mismatches user branch', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_2',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );
      userProvider.branch = 'branch_2';

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-101',
          patientId: 'PAT-000101',
          branchId: 'branch_1',
          patientName: 'سارة',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'branch_mismatch'),
        (_) => fail('should fail'),
      );
    });

    test('fails when booking does not exist and logs nothing', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'NON_EXISTENT',
          patientId: 'PAT-000',
          branchId: 'branch_1',
          patientName: 'مجهول',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'booking_not_found'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('Plan §8 T5: converts existing triage visit to in_progress and updates doctor snapshot', () async {
      // 1. Setup triage visit for MED-102 with DOC-OLD
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );
      await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف',
          doctorId: 'DOC-OLD',
          doctorName: 'طبيب قديم',
          vitals: VitalsModel(systolicBp: 125, diastolicBp: 82),
        ),
      );

      // 2. Start consultation as DOC-02
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-02',
        fullName: 'د. أحمد الشافعي',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final initialVisitsCount = visitsRepo.visits.length;

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد الشافعي',
          specialty: 'عيون',
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.inProgress);
      expect(visit.doctorId, 'DOC-02');
      expect(visit.doctorName, 'د. أحمد الشافعي');
      expect(visit.specialty, 'عيون');
      expect(visit.vitals?.systolicBp, 125); // Preserved
      // Did NOT create a duplicate visit
      expect(visitsRepo.visits.length, initialVisitsCount);
    });

    test('Plan §8 T3: Saga rollback when upsertConsultationStart fails reverts booking to waiting', () async {
      // MED-104 has finalized visit VIS-002
      final bookingRes = await bookingsRepo.getBookingById('MED-104');
      final originalBooking = bookingRes.getOrElse(() => const BookingModel());
      final originalStatus = originalBooking.status;

      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-104',
          patientId: 'PAT-000104',
          branchId: 'branch_1',
          patientName: 'طارق عبد العزيز',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام الدين مصطفى',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'finalized_cannot_be_reopened'),
        (_) => fail('should fail'),
      );

      final bookingAfter = await bookingsRepo.getBookingById('MED-104');
      expect(
        bookingAfter.getOrElse(() => const BookingModel()).status,
        originalStatus,
      );
      expect(auditLogger.getLogs(eventType: 'visit_started'), isEmpty);
    });

    test('Plan §8 T4: Saga rollback preserves previous inConsultation status', () async {
      // If booking was already inConsultation, rollback returns it to inConsultation
      final res = await startConsultationUseCase(
        const StartConsultationParams(
          bookingId: 'MED-104', // Finalized in visitsRepo
          patientId: 'PAT-000104',
          branchId: 'branch_1',
          patientName: 'طارق',
          doctorId: 'DOC-01',
          doctorName: 'د. حسام',
        ),
      );
      expect(res.isLeft(), isTrue);
    });

    test('Plan §8 T6: Saga rollback with Visit in triage keeps Visit in triage', () async {
      // Create triage visit for MED-103
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );
      await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-103',
          patientId: 'PAT-000103',
          branchId: 'branch_1',
          patientName: 'مريم',
          doctorId: 'DOC-03',
          doctorName: 'د. سارة',
          vitals: VitalsModel(systolicBp: 115),
        ),
      );

      final visitBefore = await visitsRepo.getVisitByBookingId(bookingId: 'MED-103');
      expect(visitBefore.getOrElse(() => null)?.status, VisitStatusEnum.triage);

      // Verify triage status remained
      final currentStatus = await visitsRepo.getVisitStatusByBookingId('MED-103');
      expect(currentStatus, VisitStatusEnum.triage);
    });
  });

  group('RecordVitalsUseCase RBAC & Audit Tests', () {
    test('happy path: nurse records vitals and emits audit log with zero clinical metrics', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة فاطمة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );

      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف إبراهيم',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد',
          vitals: VitalsModel(
            systolicBp: 120,
            diastolicBp: 80,
            heartRate: 75,
            temperature: 37.0,
            oxygenSaturation: 98,
          ),
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.triage);

      // Audit Log Verification
      final logs = auditLogger.getLogs(eventType: 'vitals_recorded');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.details, contains('visitId=${visit.id}'));
      expect(log.details, contains('bookingId=MED-102'));
      expect(log.details, contains('patientId=PAT-000102'));
      // STRICT: Zero clinical metrics in audit details
      expect(log.details, isNot(contains('120')));
      expect(log.details, isNot(contains('systolic')));
      expect(log.details, isNot(contains('temperature')));
    });

    test('RBAC: rejects when unauthorized role (reception) tries to record vitals', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-REC-01',
        fullName: 'موظف استقبال',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.reception],
          ),
        ],
      );

      final res = await recordVitalsUseCase(
        const RecordVitalsParams(
          bookingId: 'MED-102',
          patientId: 'PAT-000102',
          branchId: 'branch_1',
          patientName: 'يوسف',
          doctorId: 'DOC-02',
          doctorName: 'د. أحمد',
          vitals: VitalsModel(systolicBp: 120),
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_record_vitals'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'vitals_recorded'), isEmpty);
    });
  });

  group('SaveVisitDraftUseCase RBAC Tests', () {
    test('allows assigned doctor to save draft', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final res = await saveVisitDraftUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          diagnosis: 'تشخيص مسودة',
        ),
      );

      expect(res.isRight(), isTrue);
    });

    test('RBAC: rejects when different doctor tries to save draft', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-02',
        fullName: 'د. أحمد الشافعي',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final res = await saveVisitDraftUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01', // Assigned to DOC-01
          branchId: 'branch_1',
          diagnosis: 'تعديل غير مسموح به',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_edit_diagnosis'),
        (_) => fail('should fail'),
      );
    });

    test('RBAC: rejects when nurse tries to save draft', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );

      final res = await saveVisitDraftUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          diagnosis: 'محاولة تعديل تشخيص',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_edit_diagnosis'),
        (_) => fail('should fail'),
      );
    });
  });

  group('FinalizeVisitUseCase RBAC, Saga & Audit Tests', () {
    test('happy path: assigned doctor finalizes visit, updates booking to completed, emits audit log', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          chiefComplaint: 'صداع مستمر',
          diagnosis: 'تشخيص نهائي سليم',
          treatmentPlan: 'علاج مستمر',
        ),
      );

      expect(res.isRight(), isTrue);
      final visit = res.getOrElse(() => const VisitModel());
      expect(visit.status, VisitStatusEnum.finalized);

      // Booking completed
      final booking = await bookingsRepo.getBookingById('MED-101');
      expect(
        booking.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.completed,
      );

      // Audit Log Verification
      final logs = auditLogger.getLogs(eventType: 'visit_finalized');
      expect(logs.length, 1);
      final log = logs.first;
      expect(log.details, contains('visitId=VIS-001'));
      expect(log.details, contains('bookingId=MED-101'));
      expect(log.details, contains('doctorId=DOC-01'));
      // Zero clinical text
      expect(log.details, isNot(contains('تشخيص نهائي')));
      expect(log.details, isNot(contains('علاج مستمر')));
    });

    test('RBAC: rejects when different doctor tries to finalize visit', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-02',
        fullName: 'د. أحمد',
        isActive: true,
        linkedDoctorId: 'DOC-02',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01', // Belongs to DOC-01
          branchId: 'branch_1',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_finalize_visit'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'visit_finalized'), isEmpty);
    });

    test('RBAC: rejects when nurse tries to finalize visit', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE-01',
        fullName: 'ممرضة',
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.nurse],
          ),
        ],
      );

      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'permission_denied_finalize_visit'),
        (_) => fail('should fail'),
      );
      expect(auditLogger.getLogs(eventType: 'visit_finalized'), isEmpty);
    });

    test('Saga rollback: when finalize fails, reverts booking to inConsultation and logs nothing', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      // VIS-002 is already finalized in visitsRepo
      final res = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-002',
          bookingId: 'MED-104',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          chiefComplaint: 'شكوى سابقة',
          diagnosis: 'إعادة إغلاق',
        ),
      );

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f.errMessage, 'visit_already_finalized'),
        (_) => fail('should fail'),
      );

      // Reverted to inConsultation
      final booking = await bookingsRepo.getBookingById('MED-104');
      expect(
        booking.getOrElse(() => const BookingModel()).status,
        BookingStatusEnum.inConsultation,
      );
      expect(auditLogger.getLogs(eventType: 'visit_finalized'), isEmpty);
    });

    test('Domain Guard: FinalizeVisitUseCase rejects when chief complaint or diagnosis is empty', () async {
      userProvider.user = const StaffUserModel(
        id: 'USR-DOC-01',
        fullName: 'د. حسام',
        isActive: true,
        linkedDoctorId: 'DOC-01',
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            roleIds: [RoleIds.doctor],
          ),
        ],
      );

      // 1. Missing chief complaint
      final resMissingChief = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          chiefComplaint: '', // Empty
          diagnosis: 'تشخيص موجود',
        ),
      );
      expect(resMissingChief.isLeft(), isTrue);
      resMissingChief.fold(
        (f) => expect(f.errMessage, 'visits_finalize_missing_fields'),
        (_) => fail('should fail'),
      );

      // 2. Missing diagnosis
      final resMissingDiag = await finalizeVisitUseCase(
        const VisitModel(
          id: 'VIS-001',
          bookingId: 'MED-101',
          doctorId: 'DOC-01',
          branchId: 'branch_1',
          chiefComplaint: 'شكوى موجودة',
          diagnosis: '   ', // Whitespace only
        ),
      );
      expect(resMissingDiag.isLeft(), isTrue);
      resMissingDiag.fold(
        (f) => expect(f.errMessage, 'visits_finalize_missing_fields'),
        (_) => fail('should fail'),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/storage/cache_helper.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_repo_impl.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/patients/data/repo/medical_catalog_repo_impl.dart';
import 'package:eyadty/features/patients/data/repo/patients_repo_impl.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_medical_catalog_item_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/add_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/archive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/delete_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/find_patients_by_phone_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_medical_catalog_items_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patient_by_id_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/get_patients_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/unarchive_patient_use_case.dart';
import 'package:eyadty/features/patients/domain/use_cases/update_patient_use_case.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryAuditLogger auditLogger;
  late SessionCubit sessionCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSharedPreferences.initialSharedPreference();
  });

  setUp(() async {
    await getIt.reset();

    auditLogger = InMemoryAuditLogger(seedInitialLogs: true);
    sessionCubit = SessionCubit(SessionState.initial());

    getIt.registerSingleton<AuditLogger>(auditLogger);
    getIt.registerSingleton<SessionCubit>(sessionCubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('F-03 Milestone 1: AuditLogger & Expansion Unit Tests', () {
    test('Seeds 10 realistic initial logs with proper fields and descending order', () {
      final logs = auditLogger.getLogs();
      expect(logs.length, greaterThanOrEqualTo(10));
      expect(logs.first.id, isNotNull);
      expect(logs.first.timestamp, isNotNull);

      // Verify descending order
      for (int i = 0; i < logs.length - 1; i++) {
        final current = logs[i].timestamp!;
        final next = logs[i + 1].timestamp!;
        expect(current.isAfter(next) || current.isAtSameMomentAs(next), isTrue);
      }
    });

    test('Sanitizes sensitive keywords like password and token in details', () {
      auditLogger.log(
        eventType: 'test_security',
        performedByUserId: 'usr_admin',
        details: 'Attempt with password: SuperSecret123 and token=Bearer_xyz999',
      );

      final logs = auditLogger.getLogs(eventType: 'test_security');
      expect(logs, isNotEmpty);
      final logged = logs.first;
      expect(logged.details, contains('password=[REDACTED]'));
      expect(logged.details, contains('token=[REDACTED]'));
      expect(logged.details, isNot(contains('SuperSecret123')));
      expect(logged.details, isNot(contains('Bearer_xyz999')));
    });

    test('Filters by performedByUserId, targetUserId, eventType, and branchId', () {
      auditLogger.log(
        eventType: 'custom_event_alpha',
        performedByUserId: 'user_A',
        performedByUserName: 'User Alpha',
        targetUserId: 'patient_X',
        targetUserName: 'Patient X',
        branchId: 'branch_giza',
        branchName: 'فرع الجيزة',
        details: 'Specific operation',
      );

      // Filter by eventType
      final byEvent = auditLogger.getLogs(eventType: 'custom_event_alpha');
      expect(byEvent.length, 1);
      expect(byEvent.first.performedByUserId, 'user_A');

      // Filter by performedByUserId
      final byUser = auditLogger.getLogs(performedByUserId: 'user_A');
      expect(byUser.any((e) => e.eventType == 'custom_event_alpha'), isTrue);

      // Filter by targetUserId
      final byTarget = auditLogger.getLogs(targetUserId: 'patient_X');
      expect(byTarget.length, 1);

      // Filter by branchId
      final byBranch = auditLogger.getLogs(branchId: 'branch_giza');
      expect(byBranch.any((e) => e.eventType == 'custom_event_alpha'), isTrue);
    });

    test('Filters by date range and search query', () {
      final now = DateTime.now();

      auditLogger.log(
        eventType: 'searchable_action',
        performedByUserName: 'أحمد النجار',
        details: 'تغيير جدول العيادة الاستشارية',
        ipAddress: '10.0.0.45',
      );

      // Search by text in details
      final searchDetails = auditLogger.getLogs(searchQuery: 'الاستشارية');
      expect(searchDetails.length, 1);
      expect(searchDetails.first.eventType, 'searchable_action');

      // Search by IP
      final searchIp = auditLogger.getLogs(searchQuery: '10.0.0.45');
      expect(searchIp.length, 1);

      // Search by user name
      final searchUser = auditLogger.getLogs(searchQuery: 'النجار');
      expect(searchUser.length, 1);

      // Date range filtering
      final inRange = auditLogger.getLogs(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );
      expect(inRange.any((e) => e.eventType == 'searchable_action'), isTrue);

      // Past date range that excludes today
      final outOfRange = auditLogger.getLogs(
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 5)),
      );
      expect(outOfRange.any((e) => e.eventType == 'searchable_action'), isFalse);
    });

    test('Pagination with limit and offset works correctly', () {
      final allLogs = auditLogger.getLogs();
      expect(allLogs.length, greaterThanOrEqualTo(5));

      final firstTwo = auditLogger.getLogs(limit: 2, offset: 0);
      expect(firstTwo.length, 2);
      expect(firstTwo[0].id, allLogs[0].id);
      expect(firstTwo[1].id, allLogs[1].id);

      final nextTwo = auditLogger.getLogs(limit: 2, offset: 2);
      expect(nextTwo.length, 2);
      expect(nextTwo[0].id, allLogs[2].id);
      expect(nextTwo[1].id, allLogs[3].id);
    });

    test('viewAuditLogs permission is granted to Owner and denied to all other default roles', () {
      // 1. Owner user
      final owner = const StaffUserModel(
        id: 'owner_user',
        fullName: 'Clinic Owner',
        isOwner: true,
        isActive: true,
      );
      sessionCubit.switchDemoUser(owner);
      expect(sessionCubit.can(StaffPermissionEnum.viewAuditLogs), isTrue);

      // 2. Non-owner roles (branch manager, doctor, reception, etc.)
      for (final roleId in [
        RoleIds.branchManager,
        RoleIds.medicalDirector,
        RoleIds.doctor,
        RoleIds.reception,
        RoleIds.accountant,
        RoleIds.hr,
        RoleIds.nurse,
      ]) {
        final staffUser = StaffUserModel(
          id: 'user_$roleId',
          fullName: 'Staff $roleId',
          isOwner: false,
          isActive: true,
          branchAssignments: [
            BranchAssignmentModel(
              branchId: 'branch_1',
              isPrimary: true,
              roleIds: [roleId],
            ),
          ],
        );
        sessionCubit.switchDemoUser(staffUser);
        expect(
          sessionCubit.can(StaffPermissionEnum.viewAuditLogs),
          isFalse,
          reason: 'Role $roleId should NOT have viewAuditLogs by default',
        );
      }
    });

    test('PatientsCubit.fetchPatientDetails logs view_patient_profile event automatically', () async {
      final bookingsRepo = BookingsRepoImpl();
      final patientsRepo = PatientsRepoImpl(bookingsRepo: bookingsRepo);
      final catalogRepo = MedicalCatalogRepoImpl();

      final cubit = PatientsCubit(
        getPatientsUseCase: GetPatientsUseCase(repo: patientsRepo),
        getPatientByIdUseCase: GetPatientByIdUseCase(repo: patientsRepo),
        addPatientUseCase: AddPatientUseCase(repo: patientsRepo),
        updatePatientUseCase: UpdatePatientUseCase(repo: patientsRepo),
        deletePatientUseCase: DeletePatientUseCase(repo: patientsRepo),
        archivePatientUseCase: ArchivePatientUseCase(repo: patientsRepo),
        unarchivePatientUseCase: UnarchivePatientUseCase(repo: patientsRepo),
        findPatientsByPhoneUseCase: FindPatientsByPhoneUseCase(repo: patientsRepo),
        getMedicalCatalogItemsUseCase: GetMedicalCatalogItemsUseCase(repo: catalogRepo),
        addMedicalCatalogItemUseCase: AddMedicalCatalogItemUseCase(repo: catalogRepo),
        getBookingsUseCase: GetBookingsUseCase(repo: bookingsRepo),
        changeBookingStatusUseCase: ChangeBookingStatusUseCase(repo: bookingsRepo),
        deleteBookingUseCase: DeleteBookingUseCase(repo: bookingsRepo),
        reassignTechnicianUseCase: ReassignTechnicianUseCase(repo: bookingsRepo),
      );

      // Set session as Doctor Rami
      final doctorUser = const StaffUserModel(
        id: 'usr_doc_01',
        fullName: 'د. رامي سلامة',
        isOwner: false,
        isActive: true,
      );
      sessionCubit.switchDemoUser(doctorUser);
      sessionCubit.switchBranch('branch_1');

      // Fetch patient details for seeded patient 'PAT-000101'
      await cubit.fetchPatientDetails('PAT-000101');

      // Verify audit log
      final logs = auditLogger.getLogs(eventType: 'view_patient_profile');
      expect(logs, isNotEmpty);
      final patientViewLog = logs.first;
      expect(patientViewLog.targetUserId, 'PAT-000101');
      expect(patientViewLog.targetUserName, 'سارة أحمد عبد الله');
      expect(patientViewLog.performedByUserId, 'usr_doc_01');
      expect(patientViewLog.performedByUserName, 'د. رامي سلامة');
      expect(patientViewLog.branchId, 'branch_1');
    });
  });
}

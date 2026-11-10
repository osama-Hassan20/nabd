import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/presentation/helpers/consultation_action_helper.dart';
import 'package:flutter_test/flutter_test.dart';

class TestUserSessionProvider implements CurrentUserProvider {
  StaffUserModel? user;
  String? branch;

  TestUserSessionProvider({this.user, this.branch = 'branch_1'});

  @override
  StaffUserModel? get currentUser => user;

  @override
  String? get activeBranchId => branch;
}

class TestRolesProvider implements RolesProvider {
  final List<RoleDefinitionModel> roles;
  TestRolesProvider(this.roles);

  @override
  List<RoleDefinitionModel> get currentRoles => roles;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestUserSessionProvider sessionProvider;
  late TestRolesProvider rolesProvider;
  late PermissionEvaluator evaluator;

  final defaultRoles = RoleDefinitionModel.defaultSystemRoles();

  setUp(() {
    CairoTimeHelper.setFixedClock(DateTime(2026, 11, 10, 10, 0));
    sessionProvider = TestUserSessionProvider();
    rolesProvider = TestRolesProvider(defaultRoles);
    evaluator = PermissionEvaluator(
      userProvider: sessionProvider,
      rolesProvider: rolesProvider,
    );
  });

  tearDown(() {
    CairoTimeHelper.resetFixedClock();
  });

  // ─── 8 Real Users from defaultSystemRoles() ────────────────────────────────
  final users = <String, StaffUserModel>{
    'assignedDoctor': const StaffUserModel(
      id: 'USR-DOC-01',
      fullName: 'د. حسام (طبيب الحجز)',
      isActive: true,
      linkedDoctorId: 'DOC-01',
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.doctor],
        ),
      ],
    ),
    'otherDoctor': const StaffUserModel(
      id: 'USR-DOC-02',
      fullName: 'د. أحمد (طبيب آخر)',
      isActive: true,
      linkedDoctorId: 'DOC-02',
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.doctor],
        ),
      ],
    ),
    'medicalDirector': const StaffUserModel(
      id: 'USR-MED-DIR',
      fullName: 'المدير الطبي',
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.medicalDirector],
        ),
      ],
    ),
    'nurse': const StaffUserModel(
      id: 'USR-NURSE',
      fullName: 'ممرض',
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.nurse],
        ),
      ],
    ),
    'nonPracticingOwner': const StaffUserModel(
      id: 'USR-OWNER',
      fullName: 'مالك غير ممارس',
      isActive: true,
      isOwner: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [],
        ),
      ],
    ),
    'branchManager': const StaffUserModel(
      id: 'USR-BM',
      fullName: 'مدير فرع',
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.branchManager],
        ),
      ],
    ),
    'accountant': const StaffUserModel(
      id: 'USR-ACC',
      fullName: 'محاسب',
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.accountant],
        ),
      ],
    ),
    'receptionist': const StaffUserModel(
      id: 'USR-REC',
      fullName: 'موظف استقبال',
      isActive: true,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.reception],
        ),
      ],
    ),
  };

  final today = CairoTimeHelper.now();
  final yesterday = today.subtract(const Duration(days: 1));

  group('Table-Driven Row Action Buttons State Matrix Tests', () {
    // ─── Case 1: waiting without visit (today, branch_1) ──────────────────────
    test('Case 1: waiting without visit (today, branch_1)', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: null);

      final expected = <String, Map<String, bool>>{
        'assignedDoctor': {'start': true, 'vitals': true, 'continue': false, 'view': false},
        'otherDoctor': {'start': false, 'vitals': true, 'continue': false, 'view': false},
        'medicalDirector': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'nurse': {'start': false, 'vitals': true, 'continue': false, 'view': false},
        'nonPracticingOwner': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'branchManager': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'accountant': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'receptionist': {'start': false, 'vitals': false, 'continue': false, 'view': false},
      };

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;
        final exp = expected[roleKey]!;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canView = ConsultationActionHelper.canViewConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, exp['start'], reason: '$roleKey canStart mismatch');
        expect(canVitals, exp['vitals'], reason: '$roleKey canVitals mismatch');
        expect(canContinue, exp['continue'], reason: '$roleKey canContinue mismatch');
        expect(canView, exp['view'], reason: '$roleKey canView mismatch');
      }
    });

    // ─── Case 2: waiting + triage visit (today, branch_1) ─────────────────────
    test('Case 2: waiting + triage visit (today, branch_1)', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );
      final visit = VisitModel(
        id: 'VIS-01',
        bookingId: 'MED-101',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: VisitStatusEnum.triage,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: visit);

      final expected = <String, Map<String, bool>>{
        'assignedDoctor': {'start': true, 'vitals': true, 'continue': false, 'view': false},
        'otherDoctor': {'start': false, 'vitals': true, 'continue': false, 'view': false},
        'medicalDirector': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'nurse': {'start': false, 'vitals': true, 'continue': false, 'view': false},
        'nonPracticingOwner': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'branchManager': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'accountant': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'receptionist': {'start': false, 'vitals': false, 'continue': false, 'view': false},
      };

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;
        final exp = expected[roleKey]!;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canView = ConsultationActionHelper.canViewConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, exp['start'], reason: '$roleKey canStart mismatch');
        expect(canVitals, exp['vitals'], reason: '$roleKey canVitals mismatch');
        expect(canContinue, exp['continue'], reason: '$roleKey canContinue mismatch');
        expect(canView, exp['view'], reason: '$roleKey canView mismatch');

        if (roleKey == 'assignedDoctor') {
          final buttonKey = ConsultationActionHelper.getConsultationButtonKey(
            booking: item.booking,
            visit: item.visit,
          );
          expect(buttonKey, 'visits_complete_vitals');
        }
      }
    });

    // ─── Case 3: inConsultation (ongoing) ─────────────────────────────────────
    test('Case 3: inConsultation / inProgress (today, branch_1)', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.inConsultation,
        appointmentTime: today,
      );
      final visit = VisitModel(
        id: 'VIS-01',
        bookingId: 'MED-101',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: VisitStatusEnum.inProgress,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: visit);

      final expected = <String, Map<String, bool>>{
        'assignedDoctor': {'start': false, 'vitals': false, 'continue': true, 'view': false},
        'otherDoctor': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'medicalDirector': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'nurse': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'nonPracticingOwner': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'branchManager': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'accountant': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'receptionist': {'start': false, 'vitals': false, 'continue': false, 'view': false},
      };

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;
        final exp = expected[roleKey]!;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canView = ConsultationActionHelper.canViewConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, exp['start'], reason: '$roleKey canStart mismatch');
        expect(canVitals, exp['vitals'], reason: '$roleKey canVitals mismatch');
        expect(canContinue, exp['continue'], reason: '$roleKey canContinue mismatch');
        expect(canView, exp['view'], reason: '$roleKey canView mismatch');
      }
    });

    // ─── Case 4: completed + finalized visit ──────────────────────────────────
    test('Case 4: completed + finalized visit (today, branch_1)', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.completed,
        appointmentTime: today,
      );
      final visit = VisitModel(
        id: 'VIS-01',
        bookingId: 'MED-101',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: VisitStatusEnum.finalized,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: visit);

      final expected = <String, Map<String, bool>>{
        'assignedDoctor': {'start': false, 'vitals': false, 'continue': false, 'view': true},
        'otherDoctor': {'start': false, 'vitals': false, 'continue': false, 'view': true},
        'medicalDirector': {'start': false, 'vitals': false, 'continue': false, 'view': true},
        'nurse': {'start': false, 'vitals': false, 'continue': false, 'view': false}, // Nurse lacks viewConsultationNotes
        'nonPracticingOwner': {'start': false, 'vitals': false, 'continue': false, 'view': true},
        'branchManager': {'start': false, 'vitals': false, 'continue': false, 'view': true},
        'accountant': {'start': false, 'vitals': false, 'continue': false, 'view': false},
        'receptionist': {'start': false, 'vitals': false, 'continue': false, 'view': false},
      };

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;
        final exp = expected[roleKey]!;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canView = ConsultationActionHelper.canViewConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, exp['start'], reason: '$roleKey canStart mismatch');
        expect(canVitals, exp['vitals'], reason: '$roleKey canVitals mismatch');
        expect(canContinue, exp['continue'], reason: '$roleKey canContinue mismatch');
        expect(canView, exp['view'], reason: '$roleKey canView mismatch');
      }
    });

    // ─── Case 5: completed without visit (null visit) ─────────────────────────
    test('Case 5: completed without visit -> ZERO buttons for all roles', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.completed,
        appointmentTime: today,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: null);

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canView = ConsultationActionHelper.canViewConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, isFalse, reason: '$roleKey canStart must be false');
        expect(canVitals, isFalse, reason: '$roleKey canVitals must be false');
        expect(canContinue, isFalse, reason: '$roleKey canContinue must be false');
        expect(canView, isFalse, reason: '$roleKey canView must be false');
      }
    });

    // ─── Case 6: Not Today (yesterday) ────────────────────────────────────────
    test('Case 6: Booking not today -> clinical action buttons disappear', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_1',
        status: BookingStatusEnum.waiting,
        appointmentTime: yesterday,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: null);

      for (final entry in users.entries) {
        sessionProvider.user = entry.value;
        final roleKey = entry.key;

        final canStart = ConsultationActionHelper.canStartConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canVitals = ConsultationActionHelper.canRecordVitals(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );
        final canContinue = ConsultationActionHelper.canContinueConsultation(
          booking: item.booking,
          visit: item.visit,
          evaluator: evaluator,
        );

        expect(canStart, isFalse, reason: '$roleKey canStart must be false for past day');
        expect(canVitals, isFalse, reason: '$roleKey canVitals must be false for past day');
        expect(canContinue, isFalse, reason: '$roleKey canContinue must be false for past day');
      }
    });

    // ─── Case 7: Branch Mismatch ──────────────────────────────────────────────
    test('Case 7: Branch mismatch -> buttons disappear', () {
      final booking = BookingModel(
        id: 'MED-101',
        patientId: 'PAT-01',
        doctorId: 'DOC-01',
        branchId: 'branch_2', // Booking in branch_2
        status: BookingStatusEnum.waiting,
        appointmentTime: today,
      );
      final item = ConsultationQueueItemModel(booking: booking, visit: null);

      sessionProvider.branch = 'branch_1'; // User in branch_1
      sessionProvider.user = users['assignedDoctor'];

      final canStart = ConsultationActionHelper.canStartConsultation(
        booking: item.booking,
        visit: item.visit,
        evaluator: evaluator,
      );
      final canVitals = ConsultationActionHelper.canRecordVitals(
        booking: item.booking,
        visit: item.visit,
        evaluator: evaluator,
      );

      expect(canStart, isFalse);
      expect(canVitals, isFalse);
    });
  });
}

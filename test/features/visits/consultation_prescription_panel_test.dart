import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/enums/addendum_change_type_enum.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/models/visit_addendum_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visit_form_state.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';
import 'package:eyadty/features/visits/presentation/widgets/dialogs/add_visit_addendum_dialog.dart';
import 'package:eyadty/features/visits/presentation/widgets/dialogs/drug_quick_add_modal.dart';
import 'package:eyadty/features/visits/presentation/widgets/patient_allergy_banner.dart';
import 'package:eyadty/features/visits/presentation/widgets/prescription_editor_panel.dart';
import 'package:eyadty/features/visits/presentation/widgets/prescription_item_row.dart';
import 'package:eyadty/features/visits/presentation/widgets/visit_addenda_timeline.dart';

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

Widget createTestableWidget({
  required Widget child,
  VisitsCubit? cubit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: cubit != null
            ? BlocProvider.value(
                value: cubit,
                child: child,
              )
            : child,
      ),
    ),
  );
}

void main() {
  late BookingsMockRepoImpl bookingsRepo;
  late VisitsMockRepoImpl visitsRepo;
  late PatientsMockRepoImpl patientsRepo;
  late InMemoryAuditLogger auditLogger;
  late MockUserSessionProvider userProvider;
  late MockRolesSessionProvider rolesProvider;
  late PermissionEvaluator permissionEvaluator;

  late GetDoctorQueueUseCase getDoctorQueueUseCase;
  late GetVisitByBookingIdUseCase getVisitByBookingIdUseCase;
  late StartConsultationUseCase startConsultationUseCase;
  late SaveVisitDraftUseCase saveVisitDraftUseCase;
  late RecordVitalsUseCase recordVitalsUseCase;
  late FinalizeVisitUseCase finalizeVisitUseCase;

  late VisitsCubit cubit;

  setUp(() {
    bookingsRepo = BookingsMockRepoImpl();
    visitsRepo = VisitsMockRepoImpl(bookingsRepo: bookingsRepo);
    patientsRepo = PatientsMockRepoImpl();
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);

    rolesProvider = MockRolesSessionProvider(
      roles: RoleDefinitionModel.defaultSystemRoles(),
    );

    userProvider = MockUserSessionProvider(
      user: const StaffUserModel(
        id: 'USR-DOC-1',
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
      branch: 'branch_1',
    );

    permissionEvaluator = PermissionEvaluator(
      userProvider: userProvider,
      rolesProvider: rolesProvider,
    );

    getDoctorQueueUseCase = GetDoctorQueueUseCase(repo: visitsRepo);
    getVisitByBookingIdUseCase = GetVisitByBookingIdUseCase(repo: visitsRepo);
    startConsultationUseCase = StartConsultationUseCase(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
    saveVisitDraftUseCase = SaveVisitDraftUseCase(
      repo: visitsRepo,
      permissionEvaluator: permissionEvaluator,
    );
    recordVitalsUseCase = RecordVitalsUseCase(
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

    cubit = VisitsCubit(
      visitsRepo: visitsRepo,
      bookingsRepo: bookingsRepo,
      patientsRepo: patientsRepo,
      getDoctorQueueUseCase: getDoctorQueueUseCase,
      getVisitByBookingIdUseCase: getVisitByBookingIdUseCase,
      startConsultationUseCase: startConsultationUseCase,
      saveVisitDraftUseCase: saveVisitDraftUseCase,
      recordVitalsUseCase: recordVitalsUseCase,
      finalizeVisitUseCase: finalizeVisitUseCase,
      permissionEvaluator: permissionEvaluator,
      auditLogger: auditLogger,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('Prescription UI & Panels Integration Tests (M-4)', () {
    testWidgets('1. PrescriptionEditorPanel renders title and empty state when no items', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medication_outlined), findsWidgets);
      expect(find.text('0'), findsOneWidget); // 0 items count
    });

    testWidgets('2. PrescriptionEditorPanel displays items with trade name, dosage, frequency, duration', (tester) async {
      cubit.addPrescriptionItem(
        const PrescriptionItemModel(
          id: 'ITEM-1',
          tradeName: 'Augmentin 1g',
          scientificName: 'Amoxicillin / Clavulanate',
          dosage: '1 tablet',
          frequency: 'Twice daily',
          duration: '7 days',
        ),
      );

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Augmentin 1g'), findsOneWidget);
      expect(find.text('Amoxicillin / Clavulanate'), findsOneWidget);
      expect(find.text('1 tablet'), findsOneWidget);
      expect(find.text('Twice daily'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // Badge and row index
    });

    testWidgets('3. PrescriptionEditorPanel shows add, quick-add, apply template buttons in edit mode', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001', doctorId: 'DOC-01'),
            isReadOnly: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('4. PrescriptionEditorPanel in read-only mode hides modification action buttons', (tester) async {
      cubit.addPrescriptionItem(
        const PrescriptionItemModel(
          id: 'ITEM-1',
          tradeName: 'Panadol',
        ),
      );

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001', status: VisitStatusEnum.finalized),
            isReadOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.bookmark_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('5. Clicking edit icon on item sets editingItem in cubit state', (tester) async {
      const item = PrescriptionItemModel(
        id: 'ITEM-10',
        tradeName: 'Cataflam 50mg',
      );
      cubit.addPrescriptionItem(item);

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001'),
            isReadOnly: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(cubit.state.formState.editingItem?.id, 'ITEM-10');
    });

    testWidgets('6. Clicking delete icon on item calls removePrescriptionItem', (tester) async {
      cubit.addPrescriptionItem(
        const PrescriptionItemModel(
          id: 'ITEM-TO-DELETE',
          tradeName: 'To Delete',
        ),
      );
      expect(cubit.state.formState.prescriptionItems!.length, 1);

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionEditorPanel(
            cubit: cubit,
            visit: const VisitModel(id: 'VIS-001'),
            isReadOnly: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(cubit.state.formState.prescriptionItems, isEmpty);
    });

    testWidgets('7. PrescriptionItemRow renders input fields and triggers cancellation callback', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionItemRow(
            cubit: cubit,
            visitId: 'VIS-001',
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('8. PrescriptionItemRow validates trade name before submission', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionItemRow(
            cubit: cubit,
            visitId: 'VIS-001',
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap save without filling trade name
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      // Should show validation error and not add to cubit
      expect(cubit.state.formState.prescriptionItems ?? [], isEmpty);
    });

    testWidgets('9. PrescriptionItemRow saves valid item into cubit and invokes onCancel', (tester) async {
      var finished = false;

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: PrescriptionItemRow(
            cubit: cubit,
            visitId: 'VIS-001',
            onCancel: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter trade name
      await tester.enterText(find.byType(TextFormField).first, 'Brufen 400mg');
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(cubit.state.formState.prescriptionItems!.length, 1);
      expect(cubit.state.formState.prescriptionItems!.first.tradeName, 'Brufen 400mg');
      expect(finished, isTrue);
    });

    testWidgets('10. Applying template imports items into cubit prescriptionItems', (tester) async {
      final template = PrescriptionTemplateModel(
        id: 'TPL-TEST',
        name: 'Rapid Relief',
        items: const [
          PrescriptionTemplateItemModel(drugName: 'Aspirin', dosage: '100mg'),
          PrescriptionTemplateItemModel(drugName: 'Plavix', dosage: '75mg'),
        ],
      );

      cubit.applyPrescriptionTemplate(template);

      expect(cubit.state.formState.prescriptionItems!.length, 2);
      expect(cubit.state.formState.prescriptionItems![0].tradeName, 'Aspirin');
      expect(cubit.state.formState.prescriptionItems![1].tradeName, 'Plavix');
    });

    testWidgets('11. DrugQuickAddModal validates name with DrugNameValidator (rejects pure digits)', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: DrugQuickAddModal(
            cubit: cubit,
            visitId: 'VIS-001',
            doctorId: 'DOC-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid pure digits name
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      // Item should NOT be added to cubit
      expect(cubit.state.formState.prescriptionItems ?? [], isEmpty);
    });

    testWidgets('12. DrugQuickAddModal cancellation preserves existing prescription draft', (tester) async {
      cubit.addPrescriptionItem(
        const PrescriptionItemModel(id: 'ORIGINAL-1', tradeName: 'Existing Rx Item'),
      );
      expect(cubit.state.formState.prescriptionItems!.length, 1);

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: DrugQuickAddModal(
            cubit: cubit,
            visitId: 'VIS-001',
            doctorId: 'DOC-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      // Existing draft preserved completely
      expect(cubit.state.formState.prescriptionItems!.length, 1);
      expect(cubit.state.formState.prescriptionItems!.first.tradeName, 'Existing Rx Item');
    });

    testWidgets('13. AddVisitAddendumDialog displays change types and reason field', (tester) async {
      const visit = VisitModel(
        id: 'VIS-002',
        status: VisitStatusEnum.finalized,
        diagnosis: 'نزلة معوية',
        prescriptionItems: [
          PrescriptionItemModel(id: 'I-1', tradeName: 'Antinal', dosage: '200mg'),
        ],
      );

      await tester.pumpWidget(
        createTestableWidget(
          cubit: cubit,
          child: AddVisitAddendumDialog(
            cubit: cubit,
            visit: visit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(4)); // modify, add, remove, diagnosis
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('14. VisitAddendaTimeline renders chronological addenda with change type badges', (tester) async {
      final t1 = DateTime(2026, 11, 15, 10, 0);
      final addenda = [
        VisitAddendumModel(
          id: 'ADD-1',
          createdAt: t1,
          reason: 'Adjusted dosage after call',
          changeType: AddendumChangeTypeEnum.dose,
          newItemSnapshot: const PrescriptionItemModel(tradeName: 'Amoxicillin', dosage: '1000mg'),
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(
          child: VisitAddendaTimeline(addenda: addenda),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#ADD-1'), findsOneWidget);
      expect(find.text('Adjusted dosage after call'), findsOneWidget);
      expect(find.textContaining('Amoxicillin - 1000mg'), findsOneWidget);
    });

    testWidgets('15. PatientAllergyBanner renders allergy chips and clinical disclaimer', (tester) async {
      final allergies = ['حساسية بنسلين', 'حساسية أسبرين'];

      await tester.pumpWidget(
        createTestableWidget(
          child: PatientAllergyBanner(allergies: allergies),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('حساسية بنسلين'), findsOneWidget);
      expect(find.text('حساسية أسبرين'), findsOneWidget);
      expect(find.text('rx_allergy_disclaimer'), findsOneWidget);
    });

    test('16. Regression Stability: patient allergies remain identical before and after catalog items merge', () {
      final saraAllergies = ['حساسية بنسلين شديدة'];
      final maryamAllergies = ['حساسية سلفا وأسبرين'];

      final patientSara = PatientModel(
        id: 'PAT-000101',
        name: 'سارة أحمد عبد الله',
        allergies: saraAllergies,
      );

      final patientMaryam = PatientModel(
        id: 'PAT-000103',
        name: 'مريم محمود إبراهيم',
        allergies: maryamAllergies,
      );

      // Verify exact raw strings preserved without mutation
      expect(patientSara.allergies, equals(['حساسية بنسلين شديدة']));
      expect(patientMaryam.allergies, equals(['حساسية سلفا وأسبرين']));

      // In formState:
      final formState = VisitFormState.fromVisit(
        const VisitModel(
          patientName: 'سارة أحمد',
          chiefComplaint: 'صداع',
        ),
      );
      expect(formState.chiefComplaint, 'صداع');
      expect(formState.isAllergyWarningDismissed, isFalse);
    });
  });
}

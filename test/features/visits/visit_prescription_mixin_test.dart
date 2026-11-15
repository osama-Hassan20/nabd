import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/bookings/data/repo/bookings_mock_repo_impl.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:eyadty/features/patients/data/repo/patients_mock_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/visits/data/models/prescription_item_model.dart';
import 'package:eyadty/features/visits/data/repo/visits_mock_repo_impl.dart';
import 'package:eyadty/features/visits/domain/use_cases/finalize_visit_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_doctor_queue_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/get_visit_by_booking_id_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/record_vitals_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/save_visit_draft_use_case.dart';
import 'package:eyadty/features/visits/domain/use_cases/start_consultation_use_case.dart';
import 'package:eyadty/features/visits/presentation/manager/visits_cubit.dart';

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
            roleIds: ['doctor'],
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

  group('VisitPrescriptionMixin Integration Tests (M-3)', () {
    test('1. addPrescriptionItem adds item, sets orderIndex, and marks formState dirty', () {
      const item = PrescriptionItemModel(
        tradeName: 'Augmentin',
        scientificName: 'Amoxicillin',
        concentration: '1g',
        dosage: '1 tablet',
        frequency: 'rx_freq_twice_daily',
        duration: 'rx_duration_7_days',
      );

      final ok = cubit.addPrescriptionItem(item);
      expect(ok, isTrue);

      final items = cubit.state.formState.prescriptionItems;
      expect(items, isNotNull);
      expect(items!.length, 1);
      expect(items.first.tradeName, 'Augmentin');
      expect(items.first.orderIndex, 1);
      expect(items.first.id, isNotNull);
      expect(cubit.state.formState.isDirty, isTrue);
    });

    test('2. addPrescriptionItem preserves explicitly provided ID or auto-generates', () {
      const itemWithId = PrescriptionItemModel(
        id: 'CUSTOM-RXI-99',
        tradeName: 'Panadol',
      );
      cubit.addPrescriptionItem(itemWithId);

      expect(cubit.state.formState.prescriptionItems!.first.id, 'CUSTOM-RXI-99');
    });

    test('3. addPrescriptionItem enforces maxPrescriptionItems = 20 limit', () {
      for (var i = 1; i <= 20; i++) {
        final added = cubit.addPrescriptionItem(
          PrescriptionItemModel(tradeName: 'Drug $i'),
        );
        expect(added, isTrue);
      }

      expect(cubit.state.formState.prescriptionItems!.length, 20);

      // 21st item rejected
      final rejected = cubit.addPrescriptionItem(
        const PrescriptionItemModel(tradeName: 'Drug 21'),
      );
      expect(rejected, isFalse);
      expect(cubit.state.errorMessage, 'rx_max_items_reached');
      expect(cubit.state.formState.prescriptionItems!.length, 20);
    });

    test('4. updatePrescriptionItem modifies existing item by ID and keeps dirty state', () {
      cubit.addPrescriptionItem(
        const PrescriptionItemModel(
          id: 'ITEM-1',
          tradeName: 'Amoxicillin',
          dosage: '500mg',
        ),
      );

      const updated = PrescriptionItemModel(
        id: 'ITEM-1',
        tradeName: 'Amoxicillin',
        dosage: '1000mg',
      );
      cubit.updatePrescriptionItem(updated);

      final items = cubit.state.formState.prescriptionItems!;
      expect(items.length, 1);
      expect(items.first.dosage, '1000mg');
      expect(cubit.state.formState.isDirty, isTrue);
    });

    test('5. removePrescriptionItem removes target item and re-indexes remaining items sequentially', () {
      cubit.addPrescriptionItem(const PrescriptionItemModel(id: 'I-1', tradeName: 'A'));
      cubit.addPrescriptionItem(const PrescriptionItemModel(id: 'I-2', tradeName: 'B'));
      cubit.addPrescriptionItem(const PrescriptionItemModel(id: 'I-3', tradeName: 'C'));

      expect(cubit.state.formState.prescriptionItems!.length, 3);

      cubit.removePrescriptionItem('I-2');

      final remaining = cubit.state.formState.prescriptionItems!;
      expect(remaining.length, 2);
      expect(remaining[0].id, 'I-1');
      expect(remaining[0].orderIndex, 1);
      expect(remaining[1].id, 'I-3');
      expect(remaining[1].orderIndex, 2);
      expect(cubit.state.formState.isDirty, isTrue);
    });

    test('6. clearPrescription removes all items and clears editing state', () {
      cubit.addPrescriptionItem(const PrescriptionItemModel(tradeName: 'A'));
      cubit.addPrescriptionItem(const PrescriptionItemModel(tradeName: 'B'));
      expect(cubit.state.formState.prescriptionItems!.length, 2);

      cubit.clearPrescription();

      expect(cubit.state.formState.prescriptionItems, isEmpty);
      expect(cubit.state.formState.isDirty, isTrue);
    });

    test('7. setEditingPrescriptionItem and clearEditingPrescriptionItem update state correctly', () {
      const item = PrescriptionItemModel(id: 'I-10', tradeName: 'Cataflam');
      cubit.setEditingPrescriptionItem(item);
      expect(cubit.state.formState.editingItem, equals(item));

      cubit.clearEditingPrescriptionItem();
      expect(cubit.state.formState.editingItem, isNull);
    });

    test('8. dismissAllergyWarning sets isAllergyWarningDismissed to true', () {
      expect(cubit.state.formState.isAllergyWarningDismissed, isFalse);
      cubit.dismissAllergyWarning();
      expect(cubit.state.formState.isAllergyWarningDismissed, isTrue);
    });

    test('9. applyPrescriptionTemplate imports all active template items into formState', () {
      final template = PrescriptionTemplateModel(
        id: 'TPL-01',
        name: 'Gastroenteritis Protocol',
        items: const [
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-01',
            drugName: 'Antinal 200mg',
            dosage: '1 cap',
            frequency: 'rx_freq_thrice_daily',
            duration: 'rx_duration_3_days',
          ),
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-02',
            drugName: 'Motinorm 10mg',
            dosage: '1 tab',
            frequency: 'rx_freq_before_meals',
            duration: 'rx_duration_5_days',
          ),
        ],
      );

      final skipped = cubit.applyPrescriptionTemplate(template);
      expect(skipped, 0);

      final items = cubit.state.formState.prescriptionItems!;
      expect(items.length, 2);
      expect(items[0].tradeName, 'Antinal 200mg');
      expect(items[1].tradeName, 'Motinorm 10mg');
      expect(cubit.state.formState.isDirty, isTrue);
    });

    test('10. applyPrescriptionTemplate skips archived drugs when catalog is provided and returns count', () {
      final catalog = [
        const DrugModel(id: 'DRUG-01', name: 'Antinal', isActive: true),
        const DrugModel(id: 'DRUG-02', name: 'Old Drug', isActive: false),
      ];

      final template = PrescriptionTemplateModel(
        id: 'TPL-02',
        name: 'Protocol with Archived Drug',
        items: const [
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-01',
            drugName: 'Antinal',
          ),
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-02',
            drugName: 'Old Drug',
          ),
        ],
      );

      final skipped = cubit.applyPrescriptionTemplate(template, catalog: catalog);
      expect(skipped, 1);

      final items = cubit.state.formState.prescriptionItems!;
      expect(items.length, 1);
      expect(items.first.tradeName, 'Antinal');
    });

    test('11. applyPrescriptionTemplate breaks when maxPrescriptionItems (20) is reached', () {
      for (var i = 1; i <= 19; i++) {
        cubit.addPrescriptionItem(PrescriptionItemModel(tradeName: 'Pre-existing $i'));
      }
      expect(cubit.state.formState.prescriptionItems!.length, 19);

      final template = PrescriptionTemplateModel(
        id: 'TPL-03',
        name: 'Big Template',
        items: const [
          PrescriptionTemplateItemModel(drugName: 'Template 1'),
          PrescriptionTemplateItemModel(drugName: 'Template 2'),
          PrescriptionTemplateItemModel(drugName: 'Template 3'),
        ],
      );

      cubit.applyPrescriptionTemplate(template);

      expect(cubit.state.formState.prescriptionItems!.length, 20);
      expect(cubit.state.formState.prescriptionItems!.last.tradeName, 'Template 1');
    });

    test('12. checkDrugAllergy delegates to DrugAllergyMatcher with patient allergies from state', () {
      cubit.emit(
        cubit.state.copyWith(
          patientAllergies: ['حساسية بنسلين'],
        ),
      );

      // Direct match
      const directDrug = DrugModel(
        id: 'D-1',
        name: 'بنسلين 500mg',
      );
      final directMatch = cubit.checkDrugAllergy(drug: directDrug);
      expect(directMatch.hasConflict, isTrue);

      // Alias match with catalog
      const aliasDrug = DrugModel(
        id: 'D-2',
        name: 'Augmentin 1g',
        scientificName: 'Amoxicillin',
      );
      final catalog = [
        const MedicalCatalogItemModel(
          id: 'CAT-ALL-001',
          name: 'بنسلين',
          type: 'allergy',
          aliases: ['amoxicillin', 'augmentin'],
        ),
      ];
      final aliasMatch = cubit.checkDrugAllergy(drug: aliasDrug, catalogItems: catalog);
      expect(aliasMatch.hasConflict, isTrue);
      expect(aliasMatch.matchSource, 'catalog_item');

      // Safe drug (no conflict)
      const safeDrug = DrugModel(
        id: 'D-3',
        name: 'Paracetamol 500mg',
      );
      final safeMatch = cubit.checkDrugAllergy(drug: safeDrug, catalogItems: catalog);
      expect(safeMatch.hasConflict, isFalse);
    });

    test('13. PrescriptionItemModel supports both preset and custom duration and frequency', () {
      const itemWithPresets = PrescriptionItemModel(
        tradeName: 'Aspirin',
        frequency: 'rx_freq_twice_daily',
        frequencyPreset: 'rx_freq_twice_daily',
        duration: 'rx_duration_7_days',
        durationPreset: 'rx_duration_7_days',
      );
      expect(itemWithPresets.frequencyPreset, 'rx_freq_twice_daily');
      expect(itemWithPresets.durationPreset, 'rx_duration_7_days');

      const itemWithCustom = PrescriptionItemModel(
        tradeName: 'Special Drops',
        frequency: 'قطرة كل 4 ساعات لمدة يومين',
        frequencyCustom: 'قطرة كل 4 ساعات لمدة يومين',
        duration: 'يومين فقط',
        durationCustom: 'يومين فقط',
      );
      expect(itemWithCustom.frequencyCustom, 'قطرة كل 4 ساعات لمدة يومين');
      expect(itemWithCustom.durationCustom, 'يومين فقط');
    });

    test('14. PrescriptionItemModel serialization and copyWith integrity', () {
      final now = DateTime(2026, 11, 15, 12, 0);
      final model = PrescriptionItemModel(
        id: 'RXI-01',
        drugId: 'DRUG-100',
        tradeName: 'Panadol Extra',
        scientificName: 'Paracetamol / Caffeine',
        concentration: '500mg / 65mg',
        dosage: '2 tablets',
        frequency: 'rx_freq_thrice_daily',
        duration: 'rx_duration_5_days',
        instructions: 'After meals',
        orderIndex: 1,
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = PrescriptionItemModel.fromJson(json);

      expect(fromJson, equals(model));

      final modified = model.copyWith(dosage: '1 tablet');
      expect(modified.dosage, '1 tablet');
      expect(modified.tradeName, 'Panadol Extra');
    });
  });
}

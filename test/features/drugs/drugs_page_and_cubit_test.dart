import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_repo_impl.dart';
import 'package:eyadty/features/drugs/domain/use_cases/add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/archive_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/delete_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_doctor_templates_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_drugs_catalog_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/review_quick_add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/save_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_allergy_aliases_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_drug_use_case.dart';
import 'package:eyadty/features/drugs/presentation/manager/drugs_cubit.dart';
import 'package:eyadty/features/patients/data/repo/medical_catalog_repo_impl.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';

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
  group('DrugsCubit & Page Milestone 6 Suite', () {
    late DrugsRepoImpl repo;
    late MedicalCatalogRepoImpl medicalCatalogRepo;
    late InMemoryAuditLogger auditLogger;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late GetDrugsCatalogUseCase getDrugsUseCase;
    late AddDrugUseCase addDrugUseCase;
    late UpdateDrugUseCase updateDrugUseCase;
    late ArchiveDrugUseCase archiveDrugUseCase;
    late ReviewQuickAddDrugUseCase reviewQuickAddDrugUseCase;
    late GetDoctorTemplatesUseCase getDoctorTemplatesUseCase;
    late SavePrescriptionTemplateUseCase saveTemplateUseCase;
    late DeletePrescriptionTemplateUseCase deleteTemplateUseCase;
    late UpdateAllergyAliasesUseCase updateAliasesUseCase;

    late DrugsCubit cubit;

    final directorUser = const StaffUserModel(
      id: 'user_director',
      fullName: 'Dr. Director',
      linkedDoctorId: 'DOC-001',
      isActive: true,
      isOwner: true,
    );

    final doctorUser = const StaffUserModel(
      id: 'user_doc',
      fullName: 'Dr. Physician',
      linkedDoctorId: 'DOC-002',
      isActive: true,
      isOwner: false,
      branchAssignments: [
        BranchAssignmentModel(
          branchId: 'branch_1',
          roleIds: [RoleIds.doctor],
        ),
      ],
    );

    setUp(() {
      repo = DrugsRepoImpl(apiConsumer: LocalServerApiConsumer());
      medicalCatalogRepo = MedicalCatalogRepoImpl(apiConsumer: LocalServerApiConsumer());
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
      rolesProvider = FakeRolesSessionProvider(
        roles: RoleDefinitionModel.defaultSystemRoles(),
      );
      userProvider = FakeUserSessionProvider(user: directorUser);
      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      getDrugsUseCase = GetDrugsCatalogUseCase(repo: repo);
      addDrugUseCase = AddDrugUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );
      updateDrugUseCase = UpdateDrugUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );
      archiveDrugUseCase = ArchiveDrugUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );
      reviewQuickAddDrugUseCase = ReviewQuickAddDrugUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );
      getDoctorTemplatesUseCase = GetDoctorTemplatesUseCase(repo: repo);
      saveTemplateUseCase = SavePrescriptionTemplateUseCase(
        repo: repo,
        auditLogger: auditLogger,
      );
      deleteTemplateUseCase = DeletePrescriptionTemplateUseCase(
        repo: repo,
        auditLogger: auditLogger,
      );
      updateAliasesUseCase = UpdateAllergyAliasesUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );

      cubit = DrugsCubit(
        repo: repo,
        medicalCatalogRepo: medicalCatalogRepo,
        getDrugsCatalogUseCase: getDrugsUseCase,
        addDrugUseCase: addDrugUseCase,
        updateDrugUseCase: updateDrugUseCase,
        archiveDrugUseCase: archiveDrugUseCase,
        reviewQuickAddDrugUseCase: reviewQuickAddDrugUseCase,
        getDoctorTemplatesUseCase: getDoctorTemplatesUseCase,
        savePrescriptionTemplateUseCase: saveTemplateUseCase,
        deletePrescriptionTemplateUseCase: deleteTemplateUseCase,
        updateAllergyAliasesUseCase: updateAliasesUseCase,
        permissionEvaluator: permissionEvaluator,
        userProvider: userProvider,
        auditLogger: auditLogger,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('1. DrugsCubit loads catalog, categories, templates, allergy catalog items, and aliases successfully', () async {
      await cubit.loadData();

      expect(cubit.state.status, RequestStatusEnum.success);
      expect(cubit.state.drugs, isNotEmpty);
      expect(cubit.state.categories, isNotEmpty);
      expect(cubit.state.allergyItems, isNotEmpty);
      expect(cubit.state.allergyAliasesMap, isNotEmpty);
    });

    test('2. DrugsCubit tab selection updates activeTab index', () async {
      expect(cubit.state.activeTab, 0);

      cubit.setActiveTab(1);
      expect(cubit.state.activeTab, 1);

      cubit.setActiveTab(2);
      expect(cubit.state.activeTab, 2);
    });

    test('3. DrugsCubit filters drugs by search query (trade name and scientific name)', () async {
      await cubit.loadData();

      // Search by trade name "Augmentin"
      cubit.setSearchQuery('Augmentin');
      expect(cubit.state.filteredDrugs.every((d) =>
        (d.name ?? '').toLowerCase().contains('augmentin') ||
        (d.scientificName ?? '').toLowerCase().contains('augmentin')
      ), isTrue);

      // Search by scientific name "Amoxicillin"
      cubit.setSearchQuery('Amoxicillin');
      expect(cubit.state.filteredDrugs.isNotEmpty, isTrue);
      expect(cubit.state.filteredDrugs.every((d) =>
        (d.name ?? '').toLowerCase().contains('amoxicillin') ||
        (d.scientificName ?? '').toLowerCase().contains('amoxicillin')
      ), isTrue);
    });

    test('4. DrugsCubit filters drugs by category ID', () async {
      await cubit.loadData();
      final targetCategory = cubit.state.categories.first.id;

      cubit.setSelectedCategory(targetCategory);
      expect(cubit.state.filteredDrugs.every((d) => d.categoryId == targetCategory), isTrue);

      cubit.setSelectedCategory(null);
      expect(cubit.state.filteredDrugs.length, equals(cubit.state.drugs.length));
    });

    test('5. DrugsCubit filters drugs by review status (all, pending, approved)', () async {
      await cubit.loadData();

      // Seed a pending drug
      await repo.addDrug(
        const DrugModel(
          id: 'DRUG-PENDING-001',
          name: 'Pending Test Drug',
          reviewStatus: ReviewStatusEnum.pending,
          isQuickAdded: true,
        ),
      );
      await cubit.loadData();

      // Filter: pending
      cubit.setReviewFilter('pending');
      expect(cubit.state.filteredDrugs.every((d) => d.reviewStatus == ReviewStatusEnum.pending), isTrue);

      // Filter: approved
      cubit.setReviewFilter('approved');
      expect(cubit.state.filteredDrugs.every((d) => d.reviewStatus == ReviewStatusEnum.approved), isTrue);

      // Filter: all
      cubit.setReviewFilter('all');
      expect(cubit.state.filteredDrugs.length, equals(cubit.state.drugs.length));
    });

    test('6. DrugsCubit addDrug creates drug and updates catalog', () async {
      await cubit.loadData();
      final initialCount = cubit.state.drugs.length;

      const newDrug = DrugModel(
        name: 'Cataflam 50mg',
        scientificName: 'Diclofenac Potassium',
        concentration: '50mg',
        defaultDosage: '1 tablet',
        defaultFrequency: 'TID',
        defaultDuration: '5 days',
      );

      final success = await cubit.addDrug(newDrug);
      expect(success, isTrue);
      expect(cubit.state.drugs.length, equals(initialCount + 1));
      expect(cubit.state.drugs.any((d) => d.name == 'Cataflam 50mg'), isTrue);

      // Audit logged
      expect(auditLogger.getLogs().any((e) => e.eventType == 'drug_created'), isTrue);
    });

    test('7. DrugsCubit updateDrug updates drug attributes in catalog', () async {
      await cubit.loadData();
      final targetDrug = cubit.state.drugs.first;

      final updated = targetDrug.copyWith(
        concentration: 'Updated 1000mg',
      );

      final success = await cubit.updateDrug(updated);
      expect(success, isTrue);
      expect(cubit.state.drugs.firstWhere((d) => d.id == targetDrug.id).concentration, equals('Updated 1000mg'));

      // Audit logged
      expect(auditLogger.getLogs().any((e) => e.eventType == 'drug_updated'), isTrue);
    });

    test('8. DrugsCubit archiveDrug soft-deletes/archives drug', () async {
      await cubit.loadData();
      final drugToArchive = cubit.state.drugs.first;

      final success = await cubit.archiveDrug(drugToArchive.id!);
      expect(success, isTrue);
      expect(cubit.state.drugs.any((d) => d.id == drugToArchive.id), isFalse);

      // Audit logged
      expect(auditLogger.getLogs().any((e) => e.eventType == 'drug_archived'), isTrue);
    });

    test('9. DrugsCubit reviewQuickAdd approves quick-added drug', () async {
      // Add a quick-added drug
      final addRes = await repo.addDrug(
        const DrugModel(
          id: 'DRUG-Q-100',
          name: 'Unreviewed Syrup',
          reviewStatus: ReviewStatusEnum.pending,
          isQuickAdded: true,
        ),
      );
      final pendingDrug = addRes.getOrElse(() => const DrugModel());
      await cubit.loadData();

      final success = await cubit.reviewQuickAdd(
        drugId: pendingDrug.id!,
        decision: ReviewStatusEnum.approved,
      );
      expect(success, isTrue);
      final reviewed = cubit.state.drugs.firstWhere((d) => d.id == pendingDrug.id);
      expect(reviewed.reviewStatus, equals(ReviewStatusEnum.approved));

      // Audit logged
      final audit = auditLogger.getLogs().firstWhere((e) => e.eventType == 'drug_reviewed');
      final details = jsonDecode(audit.details!);
      expect(details['decision'], equals('approved'));
    });

    test('10. DrugsCubit reviewQuickAdd rejects quick-added drug and archives it', () async {
      // Add a quick-added drug
      final addRes = await repo.addDrug(
        const DrugModel(
          id: 'DRUG-Q-200',
          name: 'Wrong Entry Drug',
          reviewStatus: ReviewStatusEnum.pending,
          isQuickAdded: true,
        ),
      );
      final pendingDrug = addRes.getOrElse(() => const DrugModel());
      await cubit.loadData();

      final success = await cubit.reviewQuickAdd(
        drugId: pendingDrug.id!,
        decision: ReviewStatusEnum.rejected,
      );
      expect(success, isTrue);

      final audit = auditLogger.getLogs().firstWhere((e) => e.eventType == 'drug_reviewed');
      final details = jsonDecode(audit.details!);
      expect(details['decision'], equals('rejected'));
    });

    test('11. DrugsCubit updateAliases updates allergy aliases and emits allergy_aliases_updated audit', () async {
      await cubit.loadData();
      final allergyItem = cubit.state.allergyItems.first;

      final success = await cubit.updateAliases(
        catalogItemId: allergyItem.id!,
        aliases: ['alias_alpha', 'alias_beta', 'alias_gamma'],
      );
      expect(success, isTrue);
      expect(cubit.state.allergyAliasesMap[allergyItem.id!], contains('alias_alpha'));

      // Check security audit whitelist: numeric counts and IDs only, 0 allergy texts
      final audit = auditLogger.getLogs().firstWhere((e) => e.eventType == 'allergy_aliases_updated');
      final details = jsonDecode(audit.details!);
      expect(details['allergyCatalogItemId'], equals(allergyItem.id));
      expect(details['aliasesCountAfter'], equals(3));
      expect(details.containsKey('aliases'), isFalse); // Whitelist: no text array in audit
    });

    test('12. DrugsCubit deleteTemplate removes template from list', () async {
      // Seed a template for doctor DOC-001
      final savedRes = await repo.savePrescriptionTemplate(
        const PrescriptionTemplateModel(
          name: 'Flu Protocol',
          doctorId: 'DOC-001',
          items: [
            PrescriptionTemplateItemModel(
              drugId: 'DRUG-001',
              dosage: '1 tablet',
            ),
          ],
        ),
      );
      final createdTemplate = savedRes.getOrElse(() => const PrescriptionTemplateModel());
      await cubit.loadData();
      expect(cubit.state.templates.any((t) => t.id == createdTemplate.id), isTrue);

      final success = await cubit.deleteTemplate(createdTemplate.id!);
      expect(success, isTrue);
      expect(cubit.state.templates.any((t) => t.id == createdTemplate.id), isFalse);

      // Audit logged
      expect(auditLogger.getLogs().any((e) => e.eventType == 'prescription_template_deleted'), isTrue);
    });

    test('13. DrugsCubit canManageCatalog is false when user lacks manageDrugCatalog permission', () async {
      expect(cubit.canManageCatalog, isTrue); // Director has manageDrugCatalog

      // Switch to regular doctor
      userProvider.user = doctorUser;
      expect(cubit.canManageCatalog, isFalse);

      // Attempting to add drug fails fail-closed
      final success = await cubit.addDrug(
        const DrugModel(name: 'Unauthorized Drug'),
      );
      expect(success, isFalse);
      expect(cubit.state.errMessage, equals('permission_denied'));
    });
  });
}

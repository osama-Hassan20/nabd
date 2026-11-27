import 'package:eyadty/core/local_server/local_server_api_consumer.dart';
import 'dart:convert';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/drug_source_enum.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_repo_impl.dart';
import 'package:eyadty/features/drugs/domain/use_cases/add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/archive_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/delete_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_doctor_templates_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/get_drugs_catalog_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/quick_add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/review_quick_add_drug_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/save_prescription_template_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_allergy_aliases_use_case.dart';
import 'package:eyadty/features/drugs/domain/use_cases/update_drug_use_case.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('Drugs Feature Use Cases & Governance Audit Tests', () {
    late DrugsRepoImpl repo;
    late InMemoryAuditLogger auditLogger;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;

    late GetDrugsCatalogUseCase getDrugsUseCase;
    late AddDrugUseCase addDrugUseCase;
    late UpdateDrugUseCase updateDrugUseCase;
    late ArchiveDrugUseCase archiveDrugUseCase;
    late QuickAddDrugUseCase quickAddDrugUseCase;
    late ReviewQuickAddDrugUseCase reviewQuickAddDrugUseCase;
    late GetDoctorTemplatesUseCase getDoctorTemplatesUseCase;
    late SavePrescriptionTemplateUseCase saveTemplateUseCase;
    late DeletePrescriptionTemplateUseCase deleteTemplateUseCase;
    late UpdateAllergyAliasesUseCase updateAliasesUseCase;

    setUp(() {
      repo = DrugsRepoImpl(apiConsumer: LocalServerApiConsumer());
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
      userProvider = FakeUserSessionProvider();
      rolesProvider = FakeRolesSessionProvider(
        roles: RoleDefinitionModel.defaultSystemRoles(),
      );
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
      quickAddDrugUseCase = QuickAddDrugUseCase(
        repo: repo,
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
    });

    void setAuthorizedOwner() {
      userProvider.user = const StaffUserModel(
        id: 'USR-OWNER',
        fullName: 'المالك',
        isActive: true,
        isDeleted: false,
        isOwner: true,
      );
    }

    void setUnauthorizedStaff() {
      userProvider.user = const StaffUserModel(
        id: 'USR-NURSE',
        fullName: 'ممرض',
        isActive: true,
        isDeleted: false,
        isOwner: false,
        branchAssignments: [
          BranchAssignmentModel(branchId: 'branch_1', roleIds: ['nurse']),
        ],
      );
    }

    test('1. GetDrugsCatalogUseCase retrieves drugs accurately', () async {
      final res = await getDrugsUseCase(const GetDrugsParams(query: 'Augmentin'));
      expect(res.isRight(), isTrue);
      res.fold((_) => fail('should succeed'), (drugs) {
        expect(drugs.length, 1);
        expect(drugs.first.name, 'Augmentin 1g');
      });
    });

    test('2. AddDrugUseCase succeeds for authorized user and emits drug_created audit', () async {
      setAuthorizedOwner();

      const newDrug = DrugModel(
        name: 'New Antibiotic 500mg',
        scientificName: 'Amoxicillin Trihydrate',
        categoryId: 'CAT-DRUG-01',
        concentration: '500mg',
      );

      final res = await addDrugUseCase(const AddDrugParams(drug: newDrug, userId: 'USR-OWNER'));
      expect(res.isRight(), isTrue);

      final logs = auditLogger.getLogs(eventType: 'drug_created');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'drug_created');
      expect(event.performedByUserId, 'USR-OWNER');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'drugId', 'categoryId', 'userId'}));
      expect(details['userId'], 'USR-OWNER');
      expect(details['categoryId'], 'CAT-DRUG-01');
    });

    test('3. AddDrugUseCase fails for unauthorized user and logs NO audit event', () async {
      setUnauthorizedStaff();

      const newDrug = DrugModel(
        name: 'Malicious Drug',
        categoryId: 'CAT-DRUG-01',
      );

      final res = await addDrugUseCase(const AddDrugParams(drug: newDrug, userId: 'USR-NURSE'));
      expect(res.isLeft(), isTrue);
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('4. UpdateDrugUseCase succeeds for authorized user and emits drug_updated audit', () async {
      setAuthorizedOwner();

      const updatedDrug = DrugModel(
        id: 'DRUG-001',
        name: 'Augmentin 1g Forte',
        categoryId: 'CAT-DRUG-01',
      );

      final res = await updateDrugUseCase(
        const UpdateDrugParams(
          drug: updatedDrug,
          updatedFields: ['name'],
          userId: 'USR-OWNER',
        ),
      );

      expect(res.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'drug_updated');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'drug_updated');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'drugId', 'updatedFields', 'userId'}));
      expect(details['updatedFields'], ['name']);
    });

    test('5. UpdateDrugUseCase fails for unauthorized user and logs NO audit event', () async {
      setUnauthorizedStaff();

      const updatedDrug = DrugModel(id: 'DRUG-001', name: 'Hacked Name');
      final res = await updateDrugUseCase(
        const UpdateDrugParams(
          drug: updatedDrug,
          updatedFields: ['name'],
          userId: 'USR-NURSE',
        ),
      );

      expect(res.isLeft(), isTrue);
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('6. ArchiveDrugUseCase succeeds for authorized user and emits drug_archived audit', () async {
      setAuthorizedOwner();

      final res = await archiveDrugUseCase(
        const ArchiveDrugParams(drugId: 'DRUG-003', userId: 'USR-OWNER'),
      );

      expect(res.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'drug_archived');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'drug_archived');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'drugId', 'userId'}));
      expect(details['drugId'], 'DRUG-003');
    });

    test('7. ArchiveDrugUseCase fails for unauthorized user and logs NO audit event', () async {
      setUnauthorizedStaff();

      final res = await archiveDrugUseCase(
        const ArchiveDrugParams(drugId: 'DRUG-003', userId: 'USR-NURSE'),
      );

      expect(res.isLeft(), isTrue);
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('8. QuickAddDrugUseCase creates pending review drug and emits drug_quick_added audit', () async {
      final res = await quickAddDrugUseCase(
        const QuickAddDrugParams(
          name: 'Uncataloged Antihistamine 10mg',
          visitId: 'VIS-001',
          doctorId: 'DOC-01',
          concentration: '10mg',
          dosage: 'قرص واحد',
          frequency: 'مرة يومياً',
          duration: '5 أيام',
        ),
      );

      expect(res.isRight(), isTrue);
      res.fold((_) => fail('should succeed'), (created) {
        expect(created.isQuickAdded, isTrue);
        expect(created.reviewStatus, ReviewStatusEnum.pending);
        expect(created.source, DrugSourceEnum.quickAdd);
      });

      final logs = auditLogger.getLogs(eventType: 'drug_quick_added');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'drug_quick_added');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'drugId', 'visitId', 'doctorId'}));
      expect(details['visitId'], 'VIS-001');
      expect(details['doctorId'], 'DOC-01');
    });

    test('9. ReviewQuickAddDrugUseCase approves drug and emits drug_reviewed audit', () async {
      setAuthorizedOwner();

      // First quick add a drug
      final quickRes = await repo.quickAddDrug(
        name: 'Quick Drug To Approve',
        visitId: 'VIS-001',
        doctorId: 'DOC-01',
      );
      final drugId = quickRes.getOrElse(() => const DrugModel()).id!;

      final reviewRes = await reviewQuickAddDrugUseCase(
        ReviewQuickAddDrugParams(
          drugId: drugId,
          decision: ReviewStatusEnum.approved,
          reviewedByUserId: 'USR-OWNER',
        ),
      );

      expect(reviewRes.isRight(), isTrue);
      reviewRes.fold((_) => fail('should succeed'), (approved) {
        expect(approved.reviewStatus, ReviewStatusEnum.approved);
        expect(approved.isActive, isTrue);
      });

      final logs = auditLogger.getLogs(eventType: 'drug_reviewed');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'drug_reviewed');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'drugId', 'decision', 'reviewedByUserId'}));
      expect(details['decision'], 'approved');
    });

    test('10. ReviewQuickAddDrugUseCase rejects drug and deactivates it', () async {
      setAuthorizedOwner();

      final quickRes = await repo.quickAddDrug(
        name: 'Quick Drug To Reject',
        visitId: 'VIS-001',
        doctorId: 'DOC-01',
      );
      final drugId = quickRes.getOrElse(() => const DrugModel()).id!;

      final reviewRes = await reviewQuickAddDrugUseCase(
        ReviewQuickAddDrugParams(
          drugId: drugId,
          decision: ReviewStatusEnum.rejected,
          reviewedByUserId: 'USR-OWNER',
        ),
      );

      expect(reviewRes.isRight(), isTrue);
      reviewRes.fold((_) => fail('should succeed'), (rejected) {
        expect(rejected.reviewStatus, ReviewStatusEnum.rejected);
        expect(rejected.isActive, isFalse);
      });
    });

    test('11. ReviewQuickAddDrugUseCase fails for unauthorized user and logs NO audit event', () async {
      setUnauthorizedStaff();

      final res = await reviewQuickAddDrugUseCase(
        const ReviewQuickAddDrugParams(
          drugId: 'DRUG-001',
          decision: ReviewStatusEnum.approved,
          reviewedByUserId: 'USR-NURSE',
        ),
      );

      expect(res.isLeft(), isTrue);
      expect(auditLogger.getLogs(), isEmpty);
    });

    test('12. GetDoctorTemplatesUseCase returns doctor specific templates', () async {
      final res = await getDoctorTemplatesUseCase('DOC-01');
      expect(res.isRight(), isTrue);
      res.fold((_) => fail('should succeed'), (templates) {
        expect(templates.length, 2);
      });
    });

    test('13. SavePrescriptionTemplateUseCase creates template and logs audit event', () async {
      const template = PrescriptionTemplateModel(
        doctorId: 'DOC-01',
        name: 'بروتوكول علاج التهاب المعدة',
        items: [
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-013',
            drugName: 'Omeprazole 20mg',
            dosage: 'كبسولة واحدة',
          ),
        ],
      );

      final res = await saveTemplateUseCase(template);
      expect(res.isRight(), isTrue);

      final logs = auditLogger.getLogs(eventType: 'prescription_template_created');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'prescription_template_created');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details.keys.toSet(), equals({'templateId', 'doctorId', 'itemsCount'}));
      expect(details['doctorId'], 'DOC-01');
      expect(details['itemsCount'], 1);
    });

    test('13b. DeletePrescriptionTemplateUseCase soft-deletes template and emits audit event', () async {
      final res = await deleteTemplateUseCase(
        const DeleteTemplateParams(
          templateId: 'TPL-001',
          doctorId: 'DOC-01',
        ),
      );
      expect(res.isRight(), isTrue);

      final logs = auditLogger.getLogs(eventType: 'prescription_template_deleted');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'prescription_template_deleted');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(details['templateId'], 'TPL-001');
      expect(details['doctorId'], 'DOC-01');
    });

    test('14. UpdateAllergyAliasesUseCase succeeds for authorized user and emits audit event', () async {
      setAuthorizedOwner();

      final res = await updateAliasesUseCase(
        const UpdateAllergyAliasesParams(
          catalogItemId: 'CAT-ALL-001',
          aliases: ['بنسلين', 'penicillin', 'اموكسيسيلين', 'amoxicillin', 'مضاف_جديد'],
          aliasesCountBefore: 4,
          userId: 'USR-OWNER',
        ),
      );

      expect(res.isRight(), isTrue);
      final logs = auditLogger.getLogs(eventType: 'allergy_aliases_updated');
      expect(logs.length, 1);
      final event = logs.first;
      expect(event.eventType, 'allergy_aliases_updated');

      final details = jsonDecode(event.details!) as Map<String, dynamic>;
      expect(
        details.keys.toSet(),
        equals({'allergyCatalogItemId', 'aliasesCountBefore', 'aliasesCountAfter', 'userId'}),
      );
      expect(details['aliasesCountBefore'], 4);
      expect(details['aliasesCountAfter'], 5);
      expect(details['userId'], 'USR-OWNER');
    });
  });
}

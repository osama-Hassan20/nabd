import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_repo_impl.dart';
import 'package:eyadty/features/drugs/domain/helpers/drug_csv_import_engine.dart';
import 'package:eyadty/features/drugs/domain/use_cases/import_drugs_use_case.dart';
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
  group('Milestone 7: Drug Import Engine Tests (CSV & UTF-8 BOM)', () {
    late DrugsRepoImpl repo;
    late InMemoryAuditLogger auditLogger;
    late FakeUserSessionProvider userProvider;
    late FakeRolesSessionProvider rolesProvider;
    late PermissionEvaluator permissionEvaluator;
    late ImportDrugsUseCase importDrugsUseCase;

    final directorUser = const StaffUserModel(
      id: 'USR-DIR-1',
      fullName: 'مدير طبي',
      isActive: true,
      isOwner: true,
    );

    final doctorUser = const StaffUserModel(
      id: 'USR-DOC-1',
      fullName: 'طبيب عادي',
      isActive: true,
      isOwner: false,
      branchAssignments: [
        BranchAssignmentModel(branchId: 'branch_1', roleIds: [RoleIds.doctor]),
      ],
    );

    setUp(() {
      repo = DrugsRepoImpl();
      auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
      rolesProvider = FakeRolesSessionProvider(
        roles: RoleDefinitionModel.defaultSystemRoles(),
      );
      userProvider = FakeUserSessionProvider(user: directorUser);
      permissionEvaluator = PermissionEvaluator(
        userProvider: userProvider,
        rolesProvider: rolesProvider,
      );

      importDrugsUseCase = ImportDrugsUseCase(
        repo: repo,
        permissionEvaluator: permissionEvaluator,
        auditLogger: auditLogger,
      );
    });

    test('1. Imports valid UTF-8 CSV bytes successfully with preview report', () {
      const csv = '''
name,scientificName,concentration,defaultDosage,defaultFrequency,defaultDuration,manufacturer,categoryId
Amoclan 1g,Amoxicillin / Clavulanic Acid,1000mg,1 tablet,Q12H,7 days,Hikma,CAT-MED-01
Panadol Extra,Paracetamol / Caffeine,500mg,2 tablets,TID,3 days,GSK,CAT-MED-02
''';

      final bytes = utf8.encode(csv);
      final res = DrugCsvImportEngine.parseCsvBytes(bytes);

      expect(res.isRight(), isTrue);
      final preview = res.getOrElse(() => throw Exception());
      expect(preview.totalRows, 2);
      expect(preview.validCount, 2);
      expect(preview.invalidCount, 0);
      expect(preview.duplicateCount, 0);
      expect(preview.validRows!.first.name, 'Amoclan 1g');
      expect(preview.validRows!.first.scientificName, 'Amoxicillin / Clavulanic Acid');
      expect(preview.validRows!.last.name, 'Panadol Extra');
    });

    test('2. Handles and strips UTF-8 BOM [0xEF, 0xBB, 0xBF] correctly', () {
      const csv = 'name,concentration\nCongestal,500mg\n';
      final rawBytes = utf8.encode(csv);
      // Prepend BOM
      final bomBytes = [0xEF, 0xBB, 0xBF, ...rawBytes];

      final res = DrugCsvImportEngine.parseCsvBytes(bomBytes);
      expect(res.isRight(), isTrue);
      final preview = res.getOrElse(() => throw Exception());
      expect(preview.validCount, 1);
      expect(preview.validRows!.first.name, 'Congestal');
    });

    test('3. Rejects invalid encodings (like Windows-1256 / malformed bytes) with proper error message', () {
      // Create malformed UTF-8 bytes (lone continuation byte 0x80 or invalid 0xFF)
      final invalidBytes = [0xFF, 0xFE, 0xFD, 0xFC];

      final res = DrugCsvImportEngine.parseCsvBytes(invalidBytes);
      expect(res.isLeft(), isTrue);
      final failure = res.swap().getOrElse(() => throw Exception());
      expect(failure.errMessage, 'drugs_import_encoding_error');
    });

    test('4. Validation report partitions rows into valid, invalid, and duplicate lists', () {
      // Existing drug in catalog
      const existing = DrugModel(id: 'DRG-CAT-1', name: 'Augmentin 1g');

      const csv = '''
name,scientificName
Valid Drug A,Chemical A
12345,Numeric Only Invalid
Valid Drug A,Chemical A Duplicate in File
Augmentin 1g,Duplicate with Catalog
Short,Valid B
X,Too short invalid
''';

      final res = DrugCsvImportEngine.parseCsvString(csv, existingDrugs: [existing]);
      expect(res.isRight(), isTrue);
      final preview = res.getOrElse(() => throw Exception());

      expect(preview.validCount, 2); // Valid Drug A, Short
      expect(preview.invalidCount, 2); // 12345 (pure digits), X (length < 2)
      expect(preview.duplicateCount, 2); // Duplicate in file, Duplicate with catalog
      expect(preview.previewRows!.length, 2);
    });

    test('5. Valid-only import option commits valid rows and skips invalid/duplicate rows atomically', () async {
      final initialCount = (await repo.getDrugs()).getOrElse(() => []).length;

      final validRows = [
        const DrugModel(name: 'Imported Drug Alpha', concentration: '10mg'),
        const DrugModel(name: 'Imported Drug Beta', concentration: '20mg'),
      ];

      final params = ImportDrugsParams(
        drugsToImport: validRows,
        skippedCount: 3, // 3 rows were invalid or duplicate
        userId: directorUser.id!,
      );

      final res = await importDrugsUseCase(params);
      expect(res.isRight(), isTrue);
      final importedCount = res.getOrElse(() => 0);
      expect(importedCount, 2);

      final newDrugs = (await repo.getDrugs()).getOrElse(() => []);
      expect(newDrugs.length, initialCount + 2);
      expect(newDrugs.any((d) => d.name == 'Imported Drug Alpha'), isTrue);
      expect(newDrugs.any((d) => d.name == 'Imported Drug Beta'), isTrue);
    });

    test('6. Enforces DrugNameValidator on each row (name required, min length 2, no pure digits)', () {
      const csv = '''
name,concentration
,Empty Name Invalid
  ,Whitespace Invalid
987654,Pure Digits Invalid
@@@@###,Symbols Only Invalid
OK Drug,10mg Valid
''';

      final res = DrugCsvImportEngine.parseCsvString(csv);
      expect(res.isRight(), isTrue);
      final preview = res.getOrElse(() => throw Exception());

      expect(preview.validCount, 1);
      expect(preview.invalidCount, 4);
      expect(preview.invalidRows!.any((e) => e.reason == 'drugs_validation_name_required'), isTrue);
      expect(preview.invalidRows!.any((e) => e.reason == 'drugs_validation_name_pure_digits'), isTrue);
      expect(preview.invalidRows!.any((e) => e.reason == 'drugs_validation_name_invalid_symbols'), isTrue);
    });

    test('7. Audit log drugs_imported_batch records numeric counts only (importedCount, skippedCount, userId) and strictly excludes fileName/paths', () async {
      final validRows = [
        const DrugModel(name: 'Batch Audit Drug', concentration: '50mg'),
      ];

      final params = ImportDrugsParams(
        drugsToImport: validRows,
        skippedCount: 5,
        userId: directorUser.id!,
      );

      final res = await importDrugsUseCase(params);
      expect(res.isRight(), isTrue);

      final audit = auditLogger.getLogs().firstWhere((e) => e.eventType == 'drugs_imported_batch');
      expect(audit.performedByUserId, directorUser.id);

      final details = jsonDecode(audit.details!);
      expect(details['importedCount'], 1);
      expect(details['skippedCount'], 5);
      expect(details['userId'], directorUser.id);

      // Security check: zero fileName or file path
      expect(details.containsKey('fileName'), isFalse);
      expect(details.containsKey('path'), isFalse);
      expect(details.containsKey('filePath'), isFalse);
      expect(details.containsKey('drugs'), isFalse);
    });

    test('8. RBAC check: non-permitted users cannot execute drug import (manageDrugCatalog required)', () async {
      userProvider.user = doctorUser;

      final validRows = [
        const DrugModel(name: 'Unauthorized Drug Entry'),
      ];

      final params = ImportDrugsParams(
        drugsToImport: validRows,
        skippedCount: 0,
        userId: doctorUser.id!,
      );

      final res = await importDrugsUseCase(params);
      expect(res.isLeft(), isTrue);
      final failure = res.swap().getOrElse(() => throw Exception());
      expect(failure.errMessage, 'permission_denied');

      // Zero audit logged on failure
      expect(auditLogger.getLogs().any((e) => e.eventType == 'drugs_imported_batch'), isFalse);
    });
  });
}

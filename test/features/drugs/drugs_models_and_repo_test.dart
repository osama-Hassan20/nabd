import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/drugs/data/models/drug_category_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/drug_source_enum.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_mock_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrugCategoryModel Tests', () {
    test('1. Serializes and deserializes DrugCategoryModel accurately', () {
      const model = DrugCategoryModel(
        id: 'CAT-TEST-01',
        nameAr: 'تجربة',
        nameEn: 'Test',
        description: 'وصف تجريبي',
        isActive: true,
      );

      final json = model.toJson();
      final fromJson = DrugCategoryModel.fromJson(json);

      expect(fromJson, equals(model));
      expect(fromJson.props, equals(['CAT-TEST-01', 'تجربة', 'Test', 'وصف تجريبي', true]));

      final copied = model.copyWith(nameAr: 'محدث');
      expect(copied.nameAr, 'محدث');
      expect(copied.id, 'CAT-TEST-01');
    });
  });

  group('DrugModel Tests', () {
    test('2. Serializes and deserializes DrugModel accurately', () {
      final now = CairoTimeHelper.now();
      final model = DrugModel(
        id: 'DRUG-TEST-01',
        name: 'Test Drug',
        scientificName: 'Test Active Ingredient',
        categoryId: 'CAT-DRUG-01',
        concentration: '500mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً',
        defaultDuration: '5 أيام',
        description: 'ملاحظات تجريبية',
        manufacturer: 'Pharma Test',
        isActive: true,
        isQuickAdded: false,
        reviewStatus: ReviewStatusEnum.approved,
        source: DrugSourceEnum.preset,
        createdByUserId: 'USR-001',
        createdAt: now,
      );

      final json = model.toJson();
      final fromJson = DrugModel.fromJson(json);

      expect(fromJson.id, model.id);
      expect(fromJson.name, model.name);
      expect(fromJson.scientificName, model.scientificName);
      expect(fromJson.categoryId, model.categoryId);
      expect(fromJson.concentration, model.concentration);
      expect(fromJson.reviewStatus, ReviewStatusEnum.approved);
      expect(fromJson.source, DrugSourceEnum.preset);
      expect(fromJson.props.length, 18);

      final copied = model.copyWith(concentration: '1000mg');
      expect(copied.concentration, '1000mg');
      expect(copied.id, 'DRUG-TEST-01');
    });

    test('3. Enums defensive parsing and fallbacks', () {
      expect(DrugSourceEnum.fromJson('preset'), DrugSourceEnum.preset);
      expect(DrugSourceEnum.fromJson('quickAdd'), DrugSourceEnum.quickAdd);
      expect(DrugSourceEnum.fromJson('invalid'), DrugSourceEnum.preset);
      expect(DrugSourceEnum.fromJson(null), isNull);

      expect(ReviewStatusEnum.fromJson('pending'), ReviewStatusEnum.pending);
      expect(ReviewStatusEnum.fromJson('approved'), ReviewStatusEnum.approved);
      expect(ReviewStatusEnum.fromJson('invalid'), ReviewStatusEnum.pending);
      expect(ReviewStatusEnum.fromJson(null), isNull);
    });
  });

  group('DrugsMockRepoImpl Tests', () {
    late DrugsMockRepoImpl repo;

    setUp(() {
      repo = DrugsMockRepoImpl();
    });

    test('4. Initializes with 25 seed drugs and 8 categories', () async {
      final drugsRes = await repo.getDrugs();
      final catsRes = await repo.getCategories();

      expect(drugsRes.isRight(), isTrue);
      expect(catsRes.isRight(), isTrue);

      drugsRes.fold((_) => fail('should succeed'), (drugs) {
        expect(drugs.length, 25);
      });

      catsRes.fold((_) => fail('should succeed'), (cats) {
        expect(cats.length, 8);
      });
    });

    test('5. Verifies all seed drugs have preset source, approved status, and active flag', () async {
      final drugsRes = await repo.getDrugs();
      drugsRes.fold((_) => fail('should succeed'), (drugs) {
        for (final drug in drugs) {
          expect(drug.source, DrugSourceEnum.preset);
          expect(drug.reviewStatus, ReviewStatusEnum.approved);
          expect(drug.isActive, isTrue);
          expect(drug.createdAt, isNotNull);
        }
      });
    });

    test('6. getDrugs returns all 25 active drugs by default', () async {
      final res = await repo.getDrugs();
      expect(res.isRight(), isTrue);
      expect(res.getOrElse(() => []).length, 25);
    });

    test('7. Filters drugs by category accurately', () async {
      final antibioticsRes = await repo.getDrugs(categoryId: 'CAT-DRUG-01');
      antibioticsRes.fold((_) => fail('should succeed'), (drugs) {
        expect(drugs.length, 7);
        for (final drug in drugs) {
          expect(drug.categoryId, 'CAT-DRUG-01');
        }
      });
    });

    test('8. Searches drugs by trade name accurately', () async {
      final res = await repo.getDrugs(query: 'Augmentin');
      res.fold((_) => fail('should succeed'), (drugs) {
        expect(drugs.length, 1);
        expect(drugs.first.name, 'Augmentin 1g');
      });
    });

    test('9. Searches drugs by Arabic scientific name with normalization', () async {
      final res = await repo.getDrugs(query: 'اموكسيسيلين');
      res.fold((_) => fail('should succeed'), (drugs) {
        // Amoxil, Augmentin, Hibiotic contain Amoxicillin
        expect(drugs.length, greaterThanOrEqualTo(3));
        expect(drugs.any((d) => d.name == 'Augmentin 1g'), isTrue);
      });
    });

    test('10. Adds a new drug with validation and auto-increment ID', () async {
      const newDrug = DrugModel(
        name: 'New Drug 500mg',
        scientificName: 'New Molecule',
        categoryId: 'CAT-DRUG-02',
        concentration: '500mg',
      );

      final res = await repo.addDrug(newDrug);
      expect(res.isRight(), isTrue);
      res.fold((_) => fail('should succeed'), (added) {
        expect(added.id, startsWith('DRUG-'));
        expect(added.name, 'New Drug 500mg');
        expect(added.isActive, isTrue);
      });

      final allDrugs = (await repo.getDrugs()).getOrElse(() => []);
      expect(allDrugs.length, 26);
    });

    test('11. Updates existing drug information', () async {
      final updateRes = await repo.updateDrug(
        const DrugModel(
          id: 'DRUG-001',
          name: 'Augmentin 1g Updated',
          scientificName: 'Amoxicillin / Clavulanic Acid',
          categoryId: 'CAT-DRUG-01',
          concentration: '1g',
        ),
      );

      expect(updateRes.isRight(), isTrue);
      final drugs = (await repo.getDrugs()).getOrElse(() => []);
      final updatedDrug = drugs.firstWhere((d) => d.id == 'DRUG-001');
      expect(updatedDrug.name, 'Augmentin 1g Updated');
    });

    test('12. Archives drug softly and excludes it from default query', () async {
      final archiveRes = await repo.archiveDrug('DRUG-002');
      expect(archiveRes.isRight(), isTrue);

      final activeDrugs = (await repo.getDrugs()).getOrElse(() => []);
      expect(activeDrugs.any((d) => d.id == 'DRUG-002'), isFalse);

      final allWithArchived = (await repo.getDrugs(includeArchived: true)).getOrElse(() => []);
      final archived = allWithArchived.firstWhere((d) => d.id == 'DRUG-002');
      expect(archived.isActive, isFalse);
    });
  });
}

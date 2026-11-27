import 'package:eyadty/features/drugs/domain/helpers/drug_allergy_matcher.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrugAllergyMatcher Tests', () {
    // Standard mock catalog items matching MedicalCatalogRepoImpl
    final catalogAllergies = [
      const MedicalCatalogItemModel(
        id: 'CAT-ALL-001',
        name: 'بنسلين',
        type: 'allergy',
        aliases: [
          'بنسلين',
          'penicillin',
          'اموكسيسيلين',
          'amoxicillin',
          'اموكسيل',
          'amoxil',
          'اوجمنتين',
          'augmentin',
          'هاي بيوتك',
          'hibiotic',
          'امبيسيلين',
          'ampicillin',
          'حساسية بنسلين شديدة',
          'حساسية بنسلين',
        ],
      ),
      const MedicalCatalogItemModel(
        id: 'CAT-ALL-003',
        name: 'أسبرين',
        type: 'allergy',
        aliases: [
          'اسبرين',
          'aspirin',
          'اسبوسيد',
          'aspocid',
          'حمض اسيتيل ساليسيليك',
          'acetylsalicylic acid',
          'ريفو',
          'rivo',
          'حساسية اسبرين',
        ],
      ),
      const MedicalCatalogItemModel(
        id: 'CAT-ALL-005',
        name: 'سلفا',
        type: 'allergy',
        aliases: [
          'سلفا',
          'sulfa',
          'سلفاميثوكسازول',
          'sulfamethoxazole',
          'سبترين',
          'septrin',
          'سوتريم',
          'sutrim',
          'حساسية سلفا',
        ],
      ),
      const MedicalCatalogItemModel(
        id: 'CAT-ALL-007',
        name: 'مضادات الالتهاب غير الستيرويدية',
        type: 'allergy',
        aliases: [],
      ),
    ];

    test('1. Exact direct word match between drug and allergy', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Aspirin 100mg',
        patientAllergies: ['أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-003');
      expect(result.matchSource, 'catalog_item');
    });

    test('2. Match via catalog aliases (Augmentin trade name matches Penicillin allergy)', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Augmentin 1g',
        scientificName: 'Amoxicillin / Clavulanic Acid',
        patientAllergies: ['حساسية بنسلين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-001');
      expect(result.matchSource, 'catalog_item');
    });

    test('3. Strips Arabic stop-words (حساسية, شديدة, من, ضد)', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Amoxil 500mg',
        scientificName: 'Amoxicillin',
        patientAllergies: ['حساسية بنسلين شديدة'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-001');
    });

    test('4. Strips "ال" definition prefix when remainder is >= 3 letters', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Penicillin G',
        patientAllergies: ['البنسلين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-001');
    });

    test('5. Protects root letters and does not strip "ب" or "ل" as prefixes', () {
      // Paracetamol starts with 'ب', Loratadine starts with 'ل'
      expect(DrugAllergyMatcher.stripPrefix('باراسيتامول'), 'باراسيتامول');
      expect(DrugAllergyMatcher.stripPrefix('بنسلين'), 'بنسلين');
      expect(DrugAllergyMatcher.stripPrefix('لوراتادين'), 'لوراتادين');
    });

    test('6. Tokenizes units (mg, g, ml) and punctuation combinations cleanly', () {
      final tokens1 = DrugAllergyMatcher.tokenize('Augmentin 1g');
      expect(tokens1, contains('augmentin'));
      expect(tokens1, isNot(contains('1g')));

      final tokens2 = DrugAllergyMatcher.tokenize('Amoxicillin/Clavulanate 500mg/125mg');
      expect(tokens2, containsAll(['amoxicillin', 'clavulanate']));
    });

    test('7. NO intra-word substring match: Aspartame vs Aspirin yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Aspartame',
        patientAllergies: ['أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('8. NO intra-word substring match: Pension vs Penicillin yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Pension 50mg',
        patientAllergies: ['بنسلين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('9. NO intra-word substring match: Sulfolane vs Sulfa yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Sulfolane 100',
        patientAllergies: ['سلفا'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('10. Synthetic token: سلفاتور_وهمي vs سلفا yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'سلفاتور_وهمي',
        patientAllergies: ['سلفا'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('11. Synthetic token: بنسلاتين_وهمي vs بنسلين yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'بنسلاتين_وهمي',
        patientAllergies: ['بنسلين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('12. Synthetic token: Aspi_synthetic vs aspirin yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Aspi_synthetic',
        patientAllergies: ['أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('13. Synthetic token: Penicil_mock vs penicillin yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Penicil_mock',
        patientAllergies: ['بنسلين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('14. Maryam Case 1: [سلفا, أسبرين] against Aspocid 75mg yields warning (Aspirin)', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Aspocid 75mg',
        scientificName: 'Acetylsalicylic acid / Aspirin',
        patientAllergies: ['سلفا', 'أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-003');
    });

    test('15. Maryam Case 2: [سلفا, أسبرين] against Septrin yields warning (Sulfa)', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Septrin',
        scientificName: 'Sulfamethoxazole / Trimethoprim',
        patientAllergies: ['سلفا', 'أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-005');
    });

    test('16. Maryam Case 3: [سلفا, أسبرين] against Omeprazole 20mg yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Omeprazole 20mg',
        scientificName: 'Omeprazole',
        patientAllergies: ['سلفا', 'أسبرين'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('17. Sarah Case 1: [حساسية بنسلين شديدة] against Augmentin 1g yields warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Augmentin 1g',
        scientificName: 'Amoxicillin / Clavulanic Acid',
        patientAllergies: ['حساسية بنسلين شديدة'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-001');
    });

    test('18. Sarah Case 2: [حساسية بنسلين شديدة] against Amoxicillin 500mg yields warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Amoxicillin 500mg',
        scientificName: 'Amoxicillin',
        patientAllergies: ['حساسية بنسلين شديدة'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isTrue);
      expect(result.catalogItemId, 'CAT-ALL-001');
    });

    test('19. Sarah Case 3: [حساسية بنسلين شديدة] against Paracetamol 500mg yields NO warning', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'Paracetamol 500mg',
        scientificName: 'Paracetamol',
        patientAllergies: ['حساسية بنسلين شديدة'],
        allergyCatalogItems: catalogAllergies,
      );

      expect(result.hasConflict, isFalse);
    });

    test('20. Patient with null or empty allergies yields NO warning for any medication', () {
      final resultNull = DrugAllergyMatcher.checkAllergy(
        drugName: 'Augmentin 1g',
        scientificName: 'Amoxicillin',
        patientAllergies: null,
        allergyCatalogItems: catalogAllergies,
      );
      expect(resultNull.hasConflict, isFalse);

      final resultEmpty = DrugAllergyMatcher.checkAllergy(
        drugName: 'Aspocid 75mg',
        scientificName: 'Aspirin',
        patientAllergies: [],
        allergyCatalogItems: catalogAllergies,
      );
      expect(resultEmpty.hasConflict, isFalse);
    });

    test('21. CAT-ALL-007 (NSAIDs) with empty aliases does not trigger warning for Brufen or Omeprazole', () {
      final result1 = DrugAllergyMatcher.checkAllergy(
        drugName: 'Brufen 400mg',
        scientificName: 'Ibuprofen',
        patientAllergies: ['مضادات الالتهاب غير الستيرويدية'],
        allergyCatalogItems: catalogAllergies,
      );
      expect(result1.hasConflict, isFalse);

      final result2 = DrugAllergyMatcher.checkAllergy(
        drugName: 'Omeprazole 20mg',
        scientificName: 'Omeprazole',
        patientAllergies: ['مضادات الالتهاب غير الستيرويدية'],
        allergyCatalogItems: catalogAllergies,
      );
      expect(result2.hasConflict, isFalse);
    });

    test('22. Custom aliases dictionary correctly triggers warning for mapped drugs', () {
      final result = DrugAllergyMatcher.checkAllergy(
        drugName: 'CustomDrugX',
        patientAllergies: ['بنسلين'],
        allergyCatalogItems: catalogAllergies,
        customAliases: {
          'بنسلين': ['customdrugx'],
        },
      );

      expect(result.hasConflict, isTrue);
      expect(result.matchedTerm, 'customdrugx');
    });
  });
}


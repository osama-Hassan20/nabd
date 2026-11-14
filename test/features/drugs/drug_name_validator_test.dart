import 'package:eyadty/features/drugs/domain/helpers/drug_name_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrugNameValidator Tests', () {
    test('1. Validates standard simple drug name successfully', () {
      expect(DrugNameValidator.isValid('Augmentin'), isTrue);
      expect(DrugNameValidator.validate('Augmentin'), isNull);
    });

    test('2. Validates compound Arabic drug name with dosage', () {
      expect(DrugNameValidator.isValid('أوجمنتين 1 جم'), isTrue);
      expect(DrugNameValidator.validate('أوجمنتين 1 جم'), isNull);
    });

    test('3. Validates compound Latin drug name with strength and form', () {
      expect(DrugNameValidator.isValid('Panadol Extra 500mg'), isTrue);
      expect(DrugNameValidator.validate('Panadol Extra 500mg'), isNull);
    });

    test('4. Validates drug name with scientific slashes and combinations', () {
      expect(DrugNameValidator.isValid('Amoxicillin / Clavulanic Acid'), isTrue);
      expect(DrugNameValidator.validate('Amoxicillin / Clavulanic Acid'), isNull);
    });

    test('5. Rejects null input with required error key', () {
      expect(DrugNameValidator.isValid(null), isFalse);
      expect(DrugNameValidator.validate(null), 'drugs_validation_name_required');
    });

    test('6. Rejects empty string and whitespace-only input', () {
      expect(DrugNameValidator.isValid(''), isFalse);
      expect(DrugNameValidator.validate(''), 'drugs_validation_name_required');
      expect(DrugNameValidator.isValid('   \t  \n  '), isFalse);
      expect(DrugNameValidator.validate('   \t  \n  '), 'drugs_validation_name_required');
    });

    test('7. Rejects drug name shorter than 2 characters', () {
      expect(DrugNameValidator.isValid('A'), isFalse);
      expect(DrugNameValidator.validate('A'), 'drugs_validation_name_too_short');
      expect(DrugNameValidator.isValid(' د '), isFalse);
      expect(DrugNameValidator.validate(' د '), 'drugs_validation_name_too_short');
    });

    test('8. Rejects drug name longer than 100 characters', () {
      final longName = 'A' * 101;
      expect(DrugNameValidator.isValid(longName), isFalse);
      expect(DrugNameValidator.validate(longName), 'drugs_validation_name_too_long');
    });

    test('9. Rejects pure numbers and numeric digits string', () {
      expect(DrugNameValidator.isValid('7'), isFalse);
      expect(DrugNameValidator.validate('123123'), 'drugs_validation_name_pure_digits');
      expect(DrugNameValidator.isValid('000999'), isFalse);
    });

    test('10. Rejects pure symbols and punctuation without alphabetic characters', () {
      expect(DrugNameValidator.isValid('!@#\$%'), isFalse);
      expect(DrugNameValidator.validate('!@#\$%'), 'drugs_validation_name_invalid_symbols');
      expect(DrugNameValidator.isValid('---///+++'), isFalse);
      expect(DrugNameValidator.validate('---///+++'), 'drugs_validation_name_invalid_symbols');
    });
  });
}

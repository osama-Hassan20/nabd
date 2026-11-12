import 'package:eyadty/features/cashier/domain/helpers/money.dart';
import 'package:eyadty/features/cashier/domain/helpers/money_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money Value Object & MoneyHelper Tests', () {
    test('1. Money.zero creates zero piastres and zero pounds', () {
      const m = Money.zero();
      expect(m.piastres, 0);
      expect(m.toPounds(), 0.0);
    });

    test('2. Money.fromPounds correctly converts pounds to integer piastres with half-up rounding', () {
      final m1 = Money.fromPounds(100);
      expect(m1.piastres, 10000);
      expect(m1.toPounds(), 100.0);

      final m2 = Money.fromPounds(50.5);
      expect(m2.piastres, 5050);
      expect(m2.toPounds(), 50.5);

      // 1.005 pounds rounds half-up to 101 piastres (1.01 EGP) avoiding IEEE 754 drift
      final m3 = Money.fromPounds(1.005);
      expect(m3.piastres, 101);
      expect(m3.toPounds(), 1.01);
    });

    test('3. Money.fromPiastres preserves exact piastres value', () {
      final m = Money.fromPiastres(12345);
      expect(m.piastres, 12345);
      expect(m.toPounds(), 123.45);
    });

    test('4. Floating point precision safety: 0.1 + 0.2 equals 0.3 without IEEE 754 drift', () {
      final m1 = Money.fromPounds(0.1);
      final m2 = Money.fromPounds(0.2);
      final sum = m1 + m2;
      expect(sum.piastres, 30);
      expect(sum.toPounds(), 0.3);
      expect(sum, equals(Money.fromPounds(0.3)));
    });

    test('5. Integer currency arithmetic: 33.33 * 3 equals 99.99 EGP (9999 piastres)', () {
      final installment = Money.fromString('33.33');
      expect(installment.piastres, 3333);
      final total = installment * 3;
      expect(total.piastres, 9999);
      expect(total.toPounds(), 99.99);

      // Distributing the 1 remainder piastre to reach exactly 100.00 EGP (10000 piastres)
      final remainderPiastre = Money(1);
      final reconciled = total + remainderPiastre;
      expect(reconciled.piastres, 10000);
      expect(reconciled.toPounds(), 100.0);
    });

    test('6. Money.fromString parses standard decimal with period correctly', () {
      final m = Money.fromString('250.75');
      expect(m.piastres, 25075);
      expect(m.toPounds(), 250.75);
    });

    test('7. Money.fromString parses Arabic decimal comma and accepts Hindi / Eastern Arabic digits', () {
      final mComma = Money.fromString('150,50');
      expect(mComma.piastres, 15050);

      final mArabic = Money.fromString('75٫25');
      expect(mArabic.piastres, 7525);

      // Hindi digits: ٣٠٠٫٥٠ = 300.50 EGP = 30050 piastres
      final mHindi = Money.fromString('٣٠٠٫٥٠');
      expect(mHindi.piastres, 30050);
      expect(mHindi.toPounds(), 300.50);
    });

    test('8. Rejects ambiguous inputs like 1,500 or inputs exceeding 2 decimal places', () {
      // 1,500 has 3 digits after comma -> ambiguous (could mean 1500 or 1.500) -> rejected!
      expect(Money.tryFromString('1,500'), isNull);
      expect(() => Money.fromString('1,500'), throwsA(isA<FormatException>()));

      // 10.555 has 3 decimal places -> rejected
      expect(Money.tryFromString('10.555'), isNull);
      expect(() => Money.fromString('10.555'), throwsA(isA<FormatException>()));

      // Multiple decimal separators -> rejected
      expect(Money.tryFromString('10.5.2'), isNull);
      expect(Money.tryFromString('10,5,2'), isNull);
    });

    test('9. Money.fromString handles empty, null, or whitespace as Money.zero()', () {
      expect(Money.fromString(null).piastres, 0);
      expect(Money.fromString('').piastres, 0);
      expect(Money.fromString('   ').piastres, 0);
      expect(Money.tryFromString(null), equals(const Money.zero()));
      expect(Money.tryFromString(''), equals(const Money.zero()));
    });

    test('10. Money parses negative amounts correctly', () {
      final m1 = Money.fromString('-50.25');
      expect(m1.piastres, -5025);
      expect(m1.toPounds(), -50.25);

      final m2 = Money.fromString('-١٠٠٫٥٠');
      expect(m2.piastres, -10050);
      expect(m2.toPounds(), -100.50);
    });

    test('11. Money addition operator (+)', () {
      final m1 = Money(15000);
      final m2 = Money(35000);
      final res = m1 + m2;
      expect(res.piastres, 50000);
      expect(res.toPounds(), 500.0);
    });

    test('12. Money subtraction operator (-)', () {
      final m1 = Money(50000);
      final m2 = Money(12000);
      final res = m1 - m2;
      expect(res.piastres, 38000);
      expect(res.toPounds(), 380.0);
    });

    test('13. Money multiplication operator (*)', () {
      final m = Money(2500); // 25.00 EGP
      final res = m * 4;
      expect(res.piastres, 10000);
      expect(res.toPounds(), 100.0);
    });

    test('14. Money comparisons (<, <=, >, >=)', () {
      final m1 = Money(1000);
      final m2 = Money(2000);
      final m3 = Money(2000);

      expect(m1 < m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m2 <= m3, isTrue);
      expect(m2 >= m3, isTrue);
      expect(m2 < m1, isFalse);
    });

    test('15. Money equality and hashCode contract', () {
      final m1 = Money(5000);
      final m2 = Money.fromPounds(50);
      final m3 = Money(5001);

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1, isNot(equals(m3)));
    });

    test('16. MoneyHelper conversion utilities between pounds and piastres', () {
      expect(MoneyHelper.toPiastres(150), 15000);
      expect(MoneyHelper.toPiastres(null), 0);
      expect(MoneyHelper.toPounds(15000), 150.0);
      expect(MoneyHelper.toPounds(null), 0.0);

      final m = MoneyHelper.fromNum(250.5);
      expect(m.piastres, 25050);
    });
  });
}

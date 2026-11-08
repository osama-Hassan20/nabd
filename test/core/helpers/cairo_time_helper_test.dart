import 'package:flutter_test/flutter_test.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';

void main() {
  group('R-2: CairoTimeHelper & Injectable Fixed Clock Tests', () {
    tearDown(() {
      CairoTimeHelper.resetFixedClock();
    });

    test('1. setFixedClock sets exact deterministic time', () {
      final fixed = DateTime(2026, 11, 8, 8, 30);
      CairoTimeHelper.setFixedClock(fixed);

      expect(CairoTimeHelper.now(), equals(fixed));
      expect(CairoTimeHelper.isToday(fixed), isTrue);
      expect(CairoTimeHelper.isToday(DateTime(2026, 11, 9)), isFalse);
    });

    test('2. resetFixedClock restores real time', () {
      final fixed = DateTime(2020, 1, 1, 12, 0);
      CairoTimeHelper.setFixedClock(fixed);
      expect(CairoTimeHelper.now(), equals(fixed));

      CairoTimeHelper.resetFixedClock();
      expect(CairoTimeHelper.now().year, greaterThanOrEqualTo(2024));
    });

    test('3. CairoTimeHelper calculates DST correctly (Winter UTC+2, Summer UTC+3)', () {
      // Winter: January (UTC+2)
      final winterUtc = DateTime.utc(2026, 1, 15, 10, 0);
      final winterCairo = CairoTimeHelper.now(customUtc: winterUtc);
      expect(winterCairo.hour, equals(12)); // 10 + 2

      // Summer: July (UTC+3)
      final summerUtc = DateTime.utc(2026, 7, 15, 10, 0);
      final summerCairo = CairoTimeHelper.now(customUtc: summerUtc);
      expect(summerCairo.hour, equals(13)); // 10 + 3
    });

    test('4. isSameDay accurately compares dates', () {
      final d1 = DateTime(2026, 5, 10, 9, 30);
      final d2 = DateTime(2026, 5, 10, 23, 15);
      final d3 = DateTime(2026, 5, 11, 9, 30);

      expect(CairoTimeHelper.isSameDay(d1, d2), isTrue);
      expect(CairoTimeHelper.isSameDay(d1, d3), isFalse);
      expect(CairoTimeHelper.isSameDay(d1, null), isFalse);
    });
  });
}

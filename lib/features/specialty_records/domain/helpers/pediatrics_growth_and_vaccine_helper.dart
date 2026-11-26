/// MOCK / REFERENCE DATA ONLY — NOT FOR CLINICAL DIAGNOSIS.
/// Must be reviewed by a licensed clinician before real use.
class PediatricsVaccineDose {
  final String code;
  final String nameAr;
  final int dueAtMonths;
  final DateTime dueDate;
  final String status; // 'given', 'due', 'overdue'
  final DateTime? dateGiven;
  final String? batchNumber;

  const PediatricsVaccineDose({
    required this.code,
    required this.nameAr,
    required this.dueAtMonths,
    required this.dueDate,
    required this.status,
    this.dateGiven,
    this.batchNumber,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'nameAr': nameAr,
        'dueAtMonths': dueAtMonths,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        if (dateGiven != null) 'dateGiven': dateGiven!.toIso8601String(),
        if (batchNumber != null) 'batchNumber': batchNumber,
      };
}

class PediatricsGrowthAndVaccineHelper {
  PediatricsGrowthAndVaccineHelper._();

  static const String medicalDisclaimer =
      'بيانات مرجعية تجريبية (WHO / جدول التطعيمات) — للمراجعة الطبية قبل الاستخدام الفعلي.';

  // Mock subset of WHO weight-for-age medians (kg) by age in months
  static const Map<int, Map<String, double>> _weightRefs = {
    0: {'p3': 2.5, 'p15': 2.9, 'p50': 3.3, 'p85': 3.9, 'p97': 4.4},
    3: {'p3': 5.0, 'p15': 5.6, 'p50': 6.4, 'p85': 7.2, 'p97': 8.0},
    6: {'p3': 6.4, 'p15': 7.1, 'p50': 7.9, 'p85': 8.8, 'p97': 9.8},
    12: {'p3': 7.7, 'p15': 8.6, 'p50': 9.6, 'p85': 10.8, 'p97': 12.0},
    24: {'p3': 9.7, 'p15': 10.8, 'p50': 12.2, 'p85': 13.7, 'p97': 15.3},
    36: {'p3': 11.3, 'p15': 12.7, 'p50': 14.3, 'p85': 16.2, 'p97': 18.3},
    48: {'p3': 12.7, 'p15': 14.4, 'p50': 16.3, 'p85': 18.6, 'p97': 21.2},
    60: {'p3': 14.1, 'p15': 16.0, 'p50': 18.3, 'p85': 21.0, 'p97': 24.2},
  };

  static String estimateWeightPercentileBand(int ageMonths, double weightKg) {
    final nearestAge = _weightRefs.keys.reduce(
      (a, b) => (a - ageMonths).abs() < (b - ageMonths).abs() ? a : b,
    );
    final ref = _weightRefs[nearestAge]!;
    if (weightKg < ref['p3']!) return '< P3 (أقل من الطبيعي - مرجعي)';
    if (weightKg < ref['p15']!) return 'P3 - P15';
    if (weightKg <= ref['p85']!) return 'P15 - P85 (نطاق طبيعي - مرجعي)';
    if (weightKg <= ref['p97']!) return 'P85 - P97';
    return '> P97 (أعلى من الطبيعي - مرجعي)';
  }

  static double? computeBmi(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
      return null;
    }
    final m = heightCm / 100.0;
    return double.parse((weightKg / (m * m)).toStringAsFixed(1));
  }

  static String formatPediatricAge(DateTime? dob, {DateTime? now}) {
    if (dob == null) return 'غير محدد';
    final current = now ?? DateTime.now();
    int months = (current.year - dob.year) * 12 + (current.month - dob.month);
    if (current.day < dob.day) months--;
    if (months < 0) months = 0;
    if (months < 24) {
      return '$months شهر';
    }
    return '${months ~/ 12} سنة';
  }

  static List<PediatricsVaccineDose> buildEgyptianSchedule({
    required DateTime dob,
    Map<String, Map<String, dynamic>> givenByCode = const {},
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    const defs = [
      ('BCG_HBV_0', 'الدرن (BCG) + التهاب الكبد ب (الجرعة الصفرية)', 0),
      ('PENTA_OPV_2', 'الخماسي + شلل الأطفال (شهرين)', 2),
      ('PENTA_OPV_4', 'الخماسي + شلل الأطفال (4 شهور)', 4),
      ('PENTA_OPV_6', 'الخماسي + شلل الأطفال (6 شهور)', 6),
      ('OPV_VIT_A_9', 'شلل الأطفال + فيتامين أ (9 شهور)', 9),
      ('MMR_12', 'الثلاثي الفيروسي MMR + شلل الأطفال (12 شهر)', 12),
      ('MMR_DPT_18', 'المنشطة الثلاثي + MMR (18 شهر)', 18),
    ];

    return defs.map((d) {
      final dueDate = DateTime(dob.year, dob.month + d.$3, dob.day);
      final recorded = givenByCode[d.$1];
      String status;
      DateTime? dateGiven;
      String? batch;
      if (recorded != null) {
        status = 'given';
        dateGiven = DateTime.tryParse(recorded['dateGiven']?.toString() ?? '');
        batch = recorded['batchNumber']?.toString();
      } else if (dueDate.isBefore(current)) {
        status = 'overdue';
      } else {
        status = 'due';
      }

      return PediatricsVaccineDose(
        code: d.$1,
        nameAr: d.$2,
        dueAtMonths: d.$3,
        dueDate: dueDate,
        status: status,
        dateGiven: dateGiven,
        batchNumber: batch,
      );
    }).toList();
  }
}

import 'money.dart';

class MoneyHelper {
  MoneyHelper._();

  static int poundsToPiastres(num? pounds) => ((pounds ?? 0) * 100).round();
  static double piastresToPounds(int? piastres) => (piastres ?? 0) / 100.0;

  static int toPiastres(num? pounds) => poundsToPiastres(pounds);
  static double toPounds(int? piastres) => piastresToPounds(piastres);
  static Money fromNum(num? pounds) => Money.fromPounds(pounds ?? 0);
}

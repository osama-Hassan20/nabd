import 'package:easy_localization/easy_localization.dart';

class EgyptianGovernorateModel {
  final String key;
  final String arabicName;
  final String englishName;

  const EgyptianGovernorateModel({
    required this.key,
    required this.arabicName,
    required this.englishName,
  });

  String get localizedName {
    final trValue = key.tr();
    if (trValue.isNotEmpty && trValue != key) return trValue;
    return arabicName;
  }
}

class EgyptianGovernorates {
  EgyptianGovernorates._();

  /// Egyptian governorates with Cairo, Giza, and Alexandria first,
  /// followed by remaining governorates sorted alphabetically.
  static const List<EgyptianGovernorateModel> list = [
    // Top priority (major metropolitan governorates)
    EgyptianGovernorateModel(
      key: 'gov_cairo',
      arabicName: 'القاهرة',
      englishName: 'Cairo',
    ),
    EgyptianGovernorateModel(
      key: 'gov_giza',
      arabicName: 'الجيزة',
      englishName: 'Giza',
    ),
    EgyptianGovernorateModel(
      key: 'gov_alexandria',
      arabicName: 'الإسكندرية',
      englishName: 'Alexandria',
    ),

    // Alphabetical order for the remaining governorates
    EgyptianGovernorateModel(
      key: 'gov_ismailia',
      arabicName: 'الإسماعيلية',
      englishName: 'Ismailia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_aswan',
      arabicName: 'أسوان',
      englishName: 'Aswan',
    ),
    EgyptianGovernorateModel(
      key: 'gov_asyut',
      arabicName: 'أسيوط',
      englishName: 'Asyut',
    ),
    EgyptianGovernorateModel(
      key: 'gov_luxor',
      arabicName: 'الأقصر',
      englishName: 'Luxor',
    ),
    EgyptianGovernorateModel(
      key: 'gov_red_sea',
      arabicName: 'البحر الأحمر',
      englishName: 'Red Sea',
    ),
    EgyptianGovernorateModel(
      key: 'gov_beheira',
      arabicName: 'البحيرة',
      englishName: 'Beheira',
    ),
    EgyptianGovernorateModel(
      key: 'gov_beni_suef',
      arabicName: 'بني سويف',
      englishName: 'Beni Suef',
    ),
    EgyptianGovernorateModel(
      key: 'gov_port_said',
      arabicName: 'بورسعيد',
      englishName: 'Port Said',
    ),
    EgyptianGovernorateModel(
      key: 'gov_south_sinai',
      arabicName: 'جنوب سيناء',
      englishName: 'South Sinai',
    ),
    EgyptianGovernorateModel(
      key: 'gov_dakahlia',
      arabicName: 'الدقهلية',
      englishName: 'Dakahlia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_damietta',
      arabicName: 'دمياط',
      englishName: 'Damietta',
    ),
    EgyptianGovernorateModel(
      key: 'gov_sohag',
      arabicName: 'سوهاج',
      englishName: 'Sohag',
    ),
    EgyptianGovernorateModel(
      key: 'gov_suez',
      arabicName: 'السويس',
      englishName: 'Suez',
    ),
    EgyptianGovernorateModel(
      key: 'gov_sharkia',
      arabicName: 'الشرقية',
      englishName: 'Sharqia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_north_sinai',
      arabicName: 'شمال سيناء',
      englishName: 'North Sinai',
    ),
    EgyptianGovernorateModel(
      key: 'gov_gharbia',
      arabicName: 'الغربية',
      englishName: 'Gharbia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_fayoum',
      arabicName: 'الفيوم',
      englishName: 'Fayoum',
    ),
    EgyptianGovernorateModel(
      key: 'gov_qalyubia',
      arabicName: 'القليوبية',
      englishName: 'Qalyubia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_qena',
      arabicName: 'قنا',
      englishName: 'Qena',
    ),
    EgyptianGovernorateModel(
      key: 'gov_kafr_el_sheikh',
      arabicName: 'كفر الشيخ',
      englishName: 'Kafr El Sheikh',
    ),
    EgyptianGovernorateModel(
      key: 'gov_matrouh',
      arabicName: 'مطروح',
      englishName: 'Matrouh',
    ),
    EgyptianGovernorateModel(
      key: 'gov_monufia',
      arabicName: 'المنوفية',
      englishName: 'Monufia',
    ),
    EgyptianGovernorateModel(
      key: 'gov_minya',
      arabicName: 'المنيا',
      englishName: 'Minya',
    ),
    EgyptianGovernorateModel(
      key: 'gov_new_valley',
      arabicName: 'الوادي الجديد',
      englishName: 'New Valley',
    ),
    EgyptianGovernorateModel(
      key: 'gov_born_abroad',
      arabicName: 'خارج جمهورية مصر العربية',
      englishName: 'Born Abroad',
    ),
  ];

  static List<String> get keys => list.map((g) => g.key).toList();

  static String? getDisplayName(String? key) {
    if (key == null) return null;
    final match = list.where((g) => g.key == key).firstOrNull;
    if (match != null) return match.key.tr();
    return key;
  }
}


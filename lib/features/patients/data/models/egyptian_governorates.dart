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

  /// Egyptian Centers and Cities categorized per governorate
  static const Map<String, List<String>> governorateCities = {
    'gov_cairo': [
      'المعادي',
      'مصر الجديدة',
      'مدينة نصر',
      'التجمع الخامس',
      'التجمع الأول',
      'الرحاب',
      'مدينتي',
      'الشروق',
      'بدر',
      'العبور',
      'الزمالك',
      'وسط البلد',
      'شبرا',
      'حلوان',
      'المقطم',
      'النزهة',
      'عين شمس',
      'الزيتون',
      'المرج',
      'روض الفرج',
      'المطرية',
      'حدائق القبة',
      'السيدة زينب',
      'المعصرة',
      '15 مايو',
    ],
    'gov_giza': [
      'الدقي',
      'المهندسين',
      'العجوزة',
      '6 أكتوبر',
      'الشيخ زايد',
      'الهرم',
      'فيصل',
      'العمرانية',
      'بولاق الدكرور',
      'الحوامدية',
      'البدرشين',
      'العياط',
      'الصف',
      'أطفيح',
      'منشأة القناطر',
      'أوسيم',
      'كرداسة',
      'الوراق',
      'أبو النمرس',
    ],
    'gov_alexandria': [
      'سموحة',
      'سيدي جابر',
      'لوران',
      'سان ستيفانو',
      'جليم',
      'رشدي',
      'الإبراهيمية',
      'الشاطبي',
      'محطة الرمل',
      'بحري',
      'المنشية',
      'العطارين',
      'سيدي بشر',
      'العصافرة',
      'ميامي',
      'المندرة',
      'المعمورة',
      'المنتزه',
      'العجمي',
      'الدخيلة',
      'العامرية',
      'برج العرب',
    ],
    'gov_ismailia': [
      'مدينة الإسماعيلية',
      'التل الكبير',
      'فايد',
      'القنطرة شرق',
      'القنطرة غرب',
      'أبو صوير',
      'القصاصين',
    ],
    'gov_aswan': [
      'مدينة أسوان',
      'كوم أمبو',
      'إدفو',
      'نصر النوبة',
      'دراو',
      'أبو سمبل',
    ],
    'gov_asyut': [
      'أسيوط',
      'ديروط',
      'القوصية',
      'أبنوب',
      'منفلوط',
      'الفتح',
      'أبو تيج',
      'الغنايم',
      'ساحل سليم',
      'البداري',
      'صدفا',
      'أسيوط الجديدة',
    ],
    'gov_luxor': [
      'الأقصر',
      'إسنا',
      'أرمنت',
      'القرنة',
      'البياضية',
      'الطود',
      'الزينية',
    ],
    'gov_red_sea': [
      'الغردقة',
      'سفاجا',
      'القصير',
      'مرسى علم',
      'رأس غارب',
      'شلاتين',
      'حلايب',
    ],
    'gov_beheira': [
      'دمنهور',
      'كفر الدوار',
      'إيتاي البارود',
      'كوم حمادة',
      'أبو حمص',
      'رشيد',
      'المحمودية',
      'الدلنجات',
      'حوش عيسى',
      'وادي النطرون',
      'بدر',
      'إدكو',
      'أبو المطامير',
      'شبراخيت',
      'الرحمانية',
    ],
    'gov_beni_suef': [
      'بني سويف',
      'الواسطى',
      'ناصر',
      'إهناسيا',
      'ببا',
      'الفشن',
      'سمسطا',
      'بني سويف الجديدة',
    ],
    'gov_port_said': [
      'الشرق',
      'العرب',
      'المناخ',
      'الضواحي',
      'الزهور',
      'الجنوب',
      'الغرب',
      'بورفؤاد',
    ],
    'gov_south_sinai': [
      'شرم الشيخ',
      'دهب',
      'نويبع',
      'طابا',
      'طور سيناء',
      'رأس سدر',
      'سانت كاترين',
      'أبو رديس',
      'أبو زنيمة',
    ],
    'gov_dakahlia': [
      'المنصورة',
      'ميت غمر',
      'السنبلاوين',
      'دكرنس',
      'طلخا',
      'بلقاس',
      'شربين',
      'المنزلة',
      'منية النصر',
      'أجا',
      'نبروه',
      'بني عبيد',
      'جمصة',
      'الكردي',
      'تمي الأمديد',
      'ميت سلسيل',
    ],
    'gov_damietta': [
      'مدينة دمياط',
      'دمياط الجديدة',
      'رأس البر',
      'فارسكور',
      'الزرقا',
      'كفر سعد',
      'كفر البطيخ',
      'السرو',
      'ميت أبو غالب',
      'الروضة',
    ],
    'gov_sohag': [
      'سوهاج',
      'سوهاج الجديدة',
      'أخميم',
      'طهطا',
      'طما',
      'المراغة',
      'المنشأة',
      'جرجا',
      'البلينا',
      'دار السلام',
      'جهينة',
      'ساقلتة',
    ],
    'gov_suez': [
      'السويس',
      'الأربعين',
      'عتاقة',
      'فيصل',
      'الجناين',
    ],
    'gov_sharkia': [
      'الزقازيق',
      'العاشر من رمضان',
      'بلبيس',
      'منيا القمح',
      'فاقوس',
      'أبو حماد',
      'ههيا',
      'أبو كبير',
      'الحسينية',
      'كفر صقر',
      'أولاد صقر',
      'مشتول السوق',
      'ديرب نجم',
      'الإبراهيمية',
      'القنايات',
      'الصالحية الجديدة',
    ],
    'gov_north_sinai': [
      'العريش',
      'الشيخ زويد',
      'رفح',
      'بئر العبد',
      'نخل',
      'الحسنة',
    ],
    'gov_gharbia': [
      'طنطا',
      'المحلة الكبرى',
      'زفتى',
      'كفر الزيات',
      'سمنود',
      'قطور',
      'بسيون',
      'السنطة',
    ],
    'gov_fayoum': [
      'الفيوم',
      'الفيوم الجديدة',
      'طامية',
      'سنورس',
      'إطسا',
      'إبشواي',
      'يوسف الصديق',
    ],
    'gov_qalyubia': [
      'بنها',
      'شبرا الخيمة',
      'قليوب',
      'القناطر الخيرية',
      'الخانكة',
      'كفر شكر',
      'طوخ',
      'شبين القناطر',
      'العبور',
      'قها',
      'الخصوص',
    ],
    'gov_qena': [
      'قنا',
      'قنا الجديدة',
      'نجع حمادي',
      'دشنا',
      'قوص',
      'الوقف',
      'نقادة',
      'فرشوط',
      'أبو تشت',
      'قفط',
    ],
    'gov_kafr_el_sheikh': [
      'كفر الشيخ',
      'دسوق',
      'فوه',
      'مطوبس',
      'بيلا',
      'قلين',
      'سيدي سالم',
      'الرياض',
      'الحامول',
      'بلطيم',
      'سيدي غازي',
    ],
    'gov_matrouh': [
      'مرسى مطروح',
      'العلمين',
      'مارينا',
      'الضبعة',
      'الحمام',
      'سيوة',
      'السلوم',
      'براني',
      'النجيلة',
    ],
    'gov_monufia': [
      'شبين الكوم',
      'منوف',
      'أشمون',
      'قويسنا',
      'بركة السبع',
      'تلا',
      'الشهداء',
      'الباجور',
      'سرس الليان',
      'مدينة السادات',
    ],
    'gov_minya': [
      'المنيا',
      'المنيا الجديدة',
      'ملوي',
      'مغاغة',
      'بني مزار',
      'مطاي',
      'سمالوط',
      'أبو قرقاص',
      'دير مواس',
      'العدوة',
    ],
    'gov_new_valley': [
      'الخارجة',
      'الداخلة',
      'الفرافرة',
      'باريس',
      'بلاط',
    ],
    'gov_born_abroad': [
      'أخرى / خارج مصر',
    ],
  };

  /// Common major Egyptian cities fallback
  static const List<String> defaultMajorCities = [
    'المعادي',
    'مدينة نصر',
    'مصر الجديدة',
    'التجمع الخامس',
    'الشيخ زايد',
    '6 أكتوبر',
    'الدقي',
    'المهندسين',
    'سموحة',
    'المنصورة',
    'طنطا',
    'الزقازيق',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'أسيوط',
    'سوهاج',
  ];

  /// Get list of cities/centers for a given governorate (key or arabic name)
  static List<String> getCitiesForGovernorate(String? keyOrName) {
    if (keyOrName == null || keyOrName.trim().isEmpty) {
      return defaultMajorCities;
    }

    // Try finding by direct key
    if (governorateCities.containsKey(keyOrName)) {
      return governorateCities[keyOrName]!;
    }

    // Try finding by arabic name match
    final matchedGov = list.where((g) =>
        g.key == keyOrName ||
        g.arabicName == keyOrName ||
        g.localizedName == keyOrName).firstOrNull;

    if (matchedGov != null && governorateCities.containsKey(matchedGov.key)) {
      return governorateCities[matchedGov.key]!;
    }

    return defaultMajorCities;
  }
}

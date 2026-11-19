import 'package:eyadty/core/utils/theme/app_icons.dart';

enum MedicalCatalogKindEnum {
  radiology(
    key: 'radiology',
    title: 'فحوصات شعاعية',
    header: 'دليل الأشعة والتصوير الطبي',
    subtitle: 'إدارة وتصنيف أنواع الأشعة السينية، الرنين، والمقطعية',
    iconPath: AppIcons.radiology,
    codePrefix: 'RAD',
    defaultCategories: [
      'أشعة سينية (X-Ray)',
      'أشعة مقطعية (CT)',
      'رنين مغناطيسي (MRI)',
      'موجات صوتية (Ultrasound)',
      'دوبلر (Doppler)',
      'رسم قلب (Echo/ECG)',
    ],
  ),
  labTests(
    key: 'lab-tests',
    title: 'فحوصات مختبرية',
    header: 'دليل التحاليل والمختبر',
    subtitle: 'إدارة وتصنيف تحاليل الدم، كيمياء الجسم، والمختبرات',
    iconPath: AppIcons.labTests,
    codePrefix: 'LAB',
    defaultCategories: [
      'أمراض الدم (Hematology)',
      'كيمياء الدم (Biochemistry)',
      'هرمونات (Hormones)',
      'مناعة ومصليات (Immunology)',
      'تحاليل بول وبراز (Urinalysis)',
      'فيتامينات ومعادن (Vitamins)',
    ],
  ),
  chronicDiseases(
    key: 'chronic-diseases',
    title: 'الأمراض المزمنة',
    header: 'دليل الحالات المزمنة',
    subtitle: 'إدارة وتصنيف الأمراض المزمنة لمتابعة سجلات المرضى',
    iconPath: AppIcons.chronicDiseases,
    codePrefix: 'CHR',
    defaultCategories: [
      'أمراض القلب والشرايين',
      'أمراض الغدد والسكري',
      'أمراض الجهاز التنفسي',
      'أمراض الكلى والمسالك',
      'أمراض الجهاز الهضمي والكبد',
      'أمراض المفاصل والروماتيزم',
      'أمراض عصبية ونفسية',
    ],
  ),
  allergies(
    key: 'allergies',
    title: 'الحساسيات',
    header: 'دليل الحساسيات والتفاعلات',
    subtitle: 'إدارة مسببات الحساسية الدوائية والغذائية والبيئية لحماية المرضى',
    iconPath: AppIcons.allergies,
    codePrefix: 'ALL',
    defaultCategories: [
      'حساسية دوائية',
      'حساسية غذائية',
      'حساسية بيئية وتنفسية',
      'حساسية جلدية وتلامسية',
      'حساسية سموم ولسعات',
    ],
  ),
  surgeries(
    key: 'surgeries',
    title: 'العمليات الجراحية',
    header: 'دليل العمليات والإجراءات الجراحية',
    subtitle: 'إدارة وتصنيف التدخلات الجراحية وإجراءات غرف العمليات',
    iconPath: AppIcons.surgeries,
    codePrefix: 'SUR',
    defaultCategories: [
      'جراحة عامة ومناظير',
      'جراحة العظام والمفاصل',
      'جراحة النساء والتوليد',
      'جراحة المسالك البولية',
      'جراحة الأنف والأذن والحنجرة',
      'جراحة العيون',
      'جراحة المخ والأعصاب',
      'قسطرة وجراحة القلب والأوعية',
    ],
  );

  final String key;
  final String title;
  final String header;
  final String subtitle;
  final String iconPath;
  final String codePrefix;
  final List<String> defaultCategories;

  const MedicalCatalogKindEnum({
    required this.key,
    required this.title,
    required this.header,
    required this.subtitle,
    required this.iconPath,
    required this.codePrefix,
    required this.defaultCategories,
  });

  static MedicalCatalogKindEnum fromKey(String? key) {
    return MedicalCatalogKindEnum.values.firstWhere(
      (e) => e.key == key,
      orElse: () => MedicalCatalogKindEnum.radiology,
    );
  }
}

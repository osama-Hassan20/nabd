class PrescriptionTemplateModel {
  final String clinicDisplayName;
  final String doctorDisplayName; // اسم الشهرة أو الاسم المفضل للطبيب
  final String doctorTitle; // الدرجة العلمية والتخصص
  final String medicalLicenseNumber; // رقم قيد النقابة / ترخيص مزاولة المهنة
  final String ministryLicenseNumber; // ترخيص وزارة الصحة
  final List<String> addresses; // أكثر من عنوان لمختلف الفروع
  final List<String> phoneNumbers; // أكثر من رقم تليفون / خط ساخن / واتساب

  // Header options
  final String headerLayout; // 'dual' (ترويسة ثنائية), 'centered' (ترويسة مركزية), 'preprinted' (ورق مطبوع مسبقاً)
  final double preprintedHeaderHeight; // ارتفاع المسافة الفارغة للورق المطبوع مسبقاً (e.g. 45.0 mm)
  final bool showQrCode;
  final bool showMinistryLicense;
  final bool showEmergencyPhones;
  final bool showFileBarcode;

  // Clinical & Patient display options (requested specifically by user!)
  final bool showChronicDiseasesAndAllergies; // شريط الأمراض المزمنة والحساسية
  final bool showVitalSigns; // القياسات الحيوية (الضغط، الوزن)
  final bool showClinicalDiagnosis; // التشخيص الطبي السريري

  // Watermark & Security options
  final bool watermarkEnabled;
  final String watermarkType; // 'logo', 'customText', 'code'
  final String watermarkCustomText;
  final double watermarkOpacity; // 0.05 to 0.30
  final String watermarkPosition; // 'center', 'tiled'
  final bool enableMicroprintProtection; // حماية ضد التصوير الضوئي

  // Footer & Signatures
  final bool includeDoctorSignature;
  final bool includeOfficialStamp;
  final String officialStampText;
  final String legalDisclaimer; // تنبيه قانوني وإخلاء مسؤولية

  // Paper margins (mm)
  final double topMargin;
  final double bottomMargin;
  final double rightMargin;
  final double leftMargin;

  // Paper size
  final String defaultPaperSize; // 'a4', 'a5', 'thermal80'

  const PrescriptionTemplateModel({
    this.clinicDisplayName = 'مجمع المهندسين التخصصي',
    this.doctorDisplayName = 'أ.د. حسام الدين عزمي',
    this.doctorTitle = 'استشاري الأمراض الباطنة والقلب والأوعية الدموية',
    this.medicalLicenseNumber = '441092',
    this.ministryLicenseNumber = '8849/2021 - قطاع أ',
    this.addresses = const [
      'فرع المهندسين: 42 شارع جامعة الدول العربية، الجيزة',
      'فرع المعادي: 15 شارع النصر، القاهرة',
    ],
    this.phoneNumbers = const [
      '010 1234 5678',
      '02 2750 8800',
    ],
    this.headerLayout = 'dual',
    this.preprintedHeaderHeight = 45.0,
    this.showQrCode = true,
    this.showMinistryLicense = true,
    this.showEmergencyPhones = true,
    this.showFileBarcode = true,
    this.showChronicDiseasesAndAllergies = true,
    this.showVitalSigns = true,
    this.showClinicalDiagnosis = true,
    this.watermarkEnabled = true,
    this.watermarkType = 'logo',
    this.watermarkCustomText = 'نسخة رسمية معتمدة',
    this.watermarkOpacity = 0.12,
    this.watermarkPosition = 'center',
    this.enableMicroprintProtection = true,
    this.includeDoctorSignature = true,
    this.includeOfficialStamp = true,
    this.officialStampText = 'مركز المهندسين - ختم معتمد',
    this.legalDisclaimer =
        'صالح للصرف خلال 7 أيام من تاريخ التحرير - لا يتم استبدال الدواء إلا بموافقة الطبيب المعالج.',
    this.topMargin = 25.0,
    this.bottomMargin = 20.0,
    this.rightMargin = 15.0,
    this.leftMargin = 15.0,
    this.defaultPaperSize = 'a4',
  });

  factory PrescriptionTemplateModel.defaultTemplate() {
    return const PrescriptionTemplateModel();
  }

  factory PrescriptionTemplateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrescriptionTemplateModel();
    return PrescriptionTemplateModel(
      clinicDisplayName: json['clinicDisplayName'] as String? ?? 'مجمع المهندسين التخصصي',
      doctorDisplayName: json['doctorDisplayName'] as String? ?? 'أ.د. حسام الدين عزمي',
      doctorTitle: json['doctorTitle'] as String? ?? 'استشاري الأمراض الباطنة والقلب والأوعية الدموية',
      medicalLicenseNumber: json['medicalLicenseNumber'] as String? ?? '441092',
      ministryLicenseNumber: json['ministryLicenseNumber'] as String? ?? '8849/2021 - قطاع أ',
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'فرع المهندسين: 42 شارع جامعة الدول العربية، الجيزة',
            'فرع المعادي: 15 شارع النصر، القاهرة',
          ],
      phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            '010 1234 5678',
            '02 2750 8800',
          ],
      headerLayout: json['headerLayout'] as String? ?? 'dual',
      preprintedHeaderHeight: (json['preprintedHeaderHeight'] as num?)?.toDouble() ?? 45.0,
      showQrCode: json['showQrCode'] as bool? ?? true,
      showMinistryLicense: json['showMinistryLicense'] as bool? ?? true,
      showEmergencyPhones: json['showEmergencyPhones'] as bool? ?? true,
      showFileBarcode: json['showFileBarcode'] as bool? ?? true,
      showChronicDiseasesAndAllergies: json['showChronicDiseasesAndAllergies'] as bool? ?? true,
      showVitalSigns: json['showVitalSigns'] as bool? ?? true,
      showClinicalDiagnosis: json['showClinicalDiagnosis'] as bool? ?? true,
      watermarkEnabled: json['watermarkEnabled'] as bool? ?? true,
      watermarkType: json['watermarkType'] as String? ?? 'logo',
      watermarkCustomText: json['watermarkCustomText'] as String? ?? 'نسخة رسمية معتمدة',
      watermarkOpacity: (json['watermarkOpacity'] as num?)?.toDouble() ?? 0.12,
      watermarkPosition: json['watermarkPosition'] as String? ?? 'center',
      enableMicroprintProtection: json['enableMicroprintProtection'] as bool? ?? true,
      includeDoctorSignature: json['includeDoctorSignature'] as bool? ?? true,
      includeOfficialStamp: json['includeOfficialStamp'] as bool? ?? true,
      officialStampText: json['officialStampText'] as String? ?? 'مركز المهندسين - ختم معتمد',
      legalDisclaimer: json['legalDisclaimer'] as String? ??
          'صالح للصرف خلال 7 أيام من تاريخ التحرير - لا يتم استبدال الدواء إلا بموافقة الطبيب المعالج.',
      topMargin: (json['topMargin'] as num?)?.toDouble() ?? 25.0,
      bottomMargin: (json['bottomMargin'] as num?)?.toDouble() ?? 20.0,
      rightMargin: (json['rightMargin'] as num?)?.toDouble() ?? 15.0,
      leftMargin: (json['leftMargin'] as num?)?.toDouble() ?? 15.0,
      defaultPaperSize: json['defaultPaperSize'] as String? ?? 'a4',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinicDisplayName': clinicDisplayName,
      'doctorDisplayName': doctorDisplayName,
      'doctorTitle': doctorTitle,
      'medicalLicenseNumber': medicalLicenseNumber,
      'ministryLicenseNumber': ministryLicenseNumber,
      'addresses': addresses,
      'phoneNumbers': phoneNumbers,
      'headerLayout': headerLayout,
      'preprintedHeaderHeight': preprintedHeaderHeight,
      'showQrCode': showQrCode,
      'showMinistryLicense': showMinistryLicense,
      'showEmergencyPhones': showEmergencyPhones,
      'showFileBarcode': showFileBarcode,
      'showChronicDiseasesAndAllergies': showChronicDiseasesAndAllergies,
      'showVitalSigns': showVitalSigns,
      'showClinicalDiagnosis': showClinicalDiagnosis,
      'watermarkEnabled': watermarkEnabled,
      'watermarkType': watermarkType,
      'watermarkCustomText': watermarkCustomText,
      'watermarkOpacity': watermarkOpacity,
      'watermarkPosition': watermarkPosition,
      'enableMicroprintProtection': enableMicroprintProtection,
      'includeDoctorSignature': includeDoctorSignature,
      'includeOfficialStamp': includeOfficialStamp,
      'officialStampText': officialStampText,
      'legalDisclaimer': legalDisclaimer,
      'topMargin': topMargin,
      'bottomMargin': bottomMargin,
      'rightMargin': rightMargin,
      'leftMargin': leftMargin,
      'defaultPaperSize': defaultPaperSize,
    };
  }

  PrescriptionTemplateModel copyWith({
    String? clinicDisplayName,
    String? doctorDisplayName,
    String? doctorTitle,
    String? medicalLicenseNumber,
    String? ministryLicenseNumber,
    List<String>? addresses,
    List<String>? phoneNumbers,
    String? headerLayout,
    double? preprintedHeaderHeight,
    bool? showQrCode,
    bool? showMinistryLicense,
    bool? showEmergencyPhones,
    bool? showFileBarcode,
    bool? showChronicDiseasesAndAllergies,
    bool? showVitalSigns,
    bool? showClinicalDiagnosis,
    bool? watermarkEnabled,
    String? watermarkType,
    String? watermarkCustomText,
    double? watermarkOpacity,
    String? watermarkPosition,
    bool? enableMicroprintProtection,
    bool? includeDoctorSignature,
    bool? includeOfficialStamp,
    String? officialStampText,
    String? legalDisclaimer,
    double? topMargin,
    double? bottomMargin,
    double? rightMargin,
    double? leftMargin,
    String? defaultPaperSize,
  }) {
    return PrescriptionTemplateModel(
      clinicDisplayName: clinicDisplayName ?? this.clinicDisplayName,
      doctorDisplayName: doctorDisplayName ?? this.doctorDisplayName,
      doctorTitle: doctorTitle ?? this.doctorTitle,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      ministryLicenseNumber: ministryLicenseNumber ?? this.ministryLicenseNumber,
      addresses: addresses ?? this.addresses,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      headerLayout: headerLayout ?? this.headerLayout,
      preprintedHeaderHeight: preprintedHeaderHeight ?? this.preprintedHeaderHeight,
      showQrCode: showQrCode ?? this.showQrCode,
      showMinistryLicense: showMinistryLicense ?? this.showMinistryLicense,
      showEmergencyPhones: showEmergencyPhones ?? this.showEmergencyPhones,
      showFileBarcode: showFileBarcode ?? this.showFileBarcode,
      showChronicDiseasesAndAllergies:
          showChronicDiseasesAndAllergies ?? this.showChronicDiseasesAndAllergies,
      showVitalSigns: showVitalSigns ?? this.showVitalSigns,
      showClinicalDiagnosis: showClinicalDiagnosis ?? this.showClinicalDiagnosis,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkType: watermarkType ?? this.watermarkType,
      watermarkCustomText: watermarkCustomText ?? this.watermarkCustomText,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      enableMicroprintProtection:
          enableMicroprintProtection ?? this.enableMicroprintProtection,
      includeDoctorSignature:
          includeDoctorSignature ?? this.includeDoctorSignature,
      includeOfficialStamp: includeOfficialStamp ?? this.includeOfficialStamp,
      officialStampText: officialStampText ?? this.officialStampText,
      legalDisclaimer: legalDisclaimer ?? this.legalDisclaimer,
      topMargin: topMargin ?? this.topMargin,
      bottomMargin: bottomMargin ?? this.bottomMargin,
      rightMargin: rightMargin ?? this.rightMargin,
      leftMargin: leftMargin ?? this.leftMargin,
      defaultPaperSize: defaultPaperSize ?? this.defaultPaperSize,
    );
  }
}

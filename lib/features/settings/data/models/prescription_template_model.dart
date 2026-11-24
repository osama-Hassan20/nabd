class PrescriptionTemplateModel {
  final String clinicDisplayName;
  final String doctorDisplayName; // اسم الشهرة أو الاسم المفضل للطبيب
  final String doctorTitle; // الدرجة العلمية والتخصص
  final String englishDoctorName; // الاسم بالإنجليزية (للترويسة الثنائية / اللغات)
  final String englishDoctorTitle; // التخصص بالإنجليزية
  final String medicalLicenseNumber; // رقم قيد النقابة / ترخيص مزاولة المهنة
  final String ministryLicenseNumber; // ترخيص وزارة الصحة
  final List<String> addresses; // أكثر من عنوان لمختلف الفروع
  final List<String> phoneNumbers; // أكثر من رقم تليفون / خط ساخن / واتساب

  // ── Header Customization & Photoshop-style Dynamics ────────────
  // headerMode: 'customBannerImage' (رفع بانر جاهز كصورة), 'dynamicComposed' (تصميم ديناميكي), 'preprinted' (ورق مطبوع مسبقاً)
  final String headerMode;
  final String? headerBannerBase64; // صورة البانر المصممة بالكامل (كما في صور المستخدم المرفقة)
  final double headerHeight; // ارتفاع الهيدر / البانر بالبكسل أو الملم
  final String headerBackgroundStyle; // 'gradientBlue', 'gradientTeal', 'gradientPurple', 'gradientWavy', 'solid', 'white'
  final String headerAlignment; // 'dual', 'centered', 'bilingual', 'logoRight'
  final String headerLayout; // توافق خلفي مع الترويسة القديمة ('dual', 'centered', 'preprinted')
  final double preprintedHeaderHeight; // ارتفاع المسافة الفارغة للترويسة للورق المطبوع مسبقاً (e.g. 45.0 mm)
  final double preprintedFooterHeight; // ارتفاع المسافة الفارغة لتذييل الورق المطبوع مسبقاً (e.g. 30.0 mm)
  final bool hideFooterOnPreprinted; // إخفاء تذييل العناوين والهواتف عند استخدام ورق مطبوع مسبقاً
  final String rxLayoutStyle; // 'lines' (أسطر كلاسيكية) أو 'table' (جدول علاجي منظم)
  final bool showFollowUpBox; // إظهار صندوق موعد الاستشارة والإعادة
  final String followUpText; // نص موعد الاستشارة والإعادة

  // ── Uploaded Images & Custom Assets (Base64) ────────────────────
  final String? logoImageBase64; // شعار المركز أو الطبيب كصورة مرفوعة
  final String? watermarkImageBase64; // صورة العلامة المائية المرفوعة
  final String? qrCodeImageBase64; // صورة QR Code أو باركود مخصص مرفوع
  final String? stampImageBase64; // صورة الختم الرسمي الشفاف PNG المرفوع
  final String? signatureImageBase64; // صورة توقيع الطبيب المعتمد المرفوع
  final String? fullPageBackgroundBase64; // صورة خلفية الورقة الرسمية الكاملة (خلفية A4 جاهزة)

  // ── Clinical & Patient display options ─────────────────────────
  final bool showQrCode;
  final bool showMinistryLicense;
  final bool showEmergencyPhones;
  final bool showFileBarcode;
  final bool showChronicDiseasesAndAllergies; // شريط الأمراض المزمنة والحساسية
  final bool showVitalSigns; // القياسات الحيوية (الضغط، الوزن)
  final bool showClinicalDiagnosis; // التشخيص الطبي السريري

  // ── Watermark & Security options ───────────────────────────────
  final bool watermarkEnabled;
  final String watermarkType; // 'logo', 'customImage', 'customText', 'code'
  final String watermarkCustomText;
  final double watermarkOpacity; // 0.05 to 0.40
  final String watermarkPosition; // 'center', 'tiled'
  final bool enableMicroprintProtection; // حماية ضد التصوير الضوئي

  // ── Footer & Signatures ────────────────────────────────────────
  final bool includeDoctorSignature;
  final bool includeOfficialStamp;
  final String officialStampText;
  final String legalDisclaimer; // تنبيه قانوني وإخلاء مسؤولية

  // ── Paper margins (mm) & Size ──────────────────────────────────
  final double topMargin;
  final double bottomMargin;
  final double rightMargin;
  final double leftMargin;
  final String defaultPaperSize; // 'a4', 'a5', 'thermal80'

  // ── Independent Section Margins (Header, Body, Footer) & Heights ────
  final double footerHeight; // ارتفاع التذييل بالبكسل / أرقام مباشرة
  final double headerMarginTop;
  final double headerMarginBottom;
  final double headerMarginRight;
  final double headerMarginLeft;

  final double bodyMarginTop;
  final double bodyMarginBottom;
  final double bodyMarginRight;
  final double bodyMarginLeft;

  final double footerMarginTop;
  final double footerMarginBottom;
  final double footerMarginRight;
  final double footerMarginLeft;

  // ── Back Page (تصميم ظهر الروشتة للتعليمات والإرشادات) ─────────────
  final bool enableBackPage; // خيار تفعيل طباعة ظهر الروشتة
  final String backPageTitle; // عنوان ظهر الروشتة (مثال: تعليمات وإرشادات هامة للمريض)
  final String? backPageHeaderBannerBase64; // بانر هيدر لظهر الروشتة
  final List<String> backPageInstructions; // قائمة التعليمات والنصائح الطبية كنقاط
  final String backPageDietAdvice; // إرشادات التغذية والحمية الغذائية
  final String backPageEmergencyNotes; // تعليمات الطوارئ وموعد الاستشارة القادمة
  final String backPageFooterNotes; // تذييل ظهر الروشتة وأرقام التواصل

  const PrescriptionTemplateModel({
    this.clinicDisplayName = 'مجمع المهندسين التخصصي',
    this.doctorDisplayName = 'أ.د. حسام الدين عزمي',
    this.doctorTitle = 'استشاري الأمراض الباطنة والقلب والأوعية الدموية',
    this.englishDoctorName = 'Prof. Dr. Hossam El-Din Azmy',
    this.englishDoctorTitle = 'Consultant of Internal Medicine & Cardiology',
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
    this.headerMode = 'dynamicComposed',
    this.headerBannerBase64,
    this.headerHeight = 110.0,
    this.headerBackgroundStyle = 'gradientBlue',
    this.headerAlignment = 'dual',
    this.headerLayout = 'dual',
    this.preprintedHeaderHeight = 45.0,
    this.preprintedFooterHeight = 30.0,
    this.hideFooterOnPreprinted = true,
    this.rxLayoutStyle = 'lines',
    this.showFollowUpBox = true,
    this.followUpText = 'خلال 7 أيام من تاريخ الكشف مع إحضار أصل الروشتة للمتابعة السريرية',
    this.logoImageBase64,
    this.watermarkImageBase64,
    this.qrCodeImageBase64,
    this.stampImageBase64,
    this.signatureImageBase64,
    this.fullPageBackgroundBase64,
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
    this.footerHeight = 70.0,
    this.headerMarginTop = 0.0,
    this.headerMarginBottom = 8.0,
    this.headerMarginRight = 15.0,
    this.headerMarginLeft = 15.0,
    this.bodyMarginTop = 8.0,
    this.bodyMarginBottom = 8.0,
    this.bodyMarginRight = 15.0,
    this.bodyMarginLeft = 15.0,
    this.footerMarginTop = 8.0,
    this.footerMarginBottom = 12.0,
    this.footerMarginRight = 15.0,
    this.footerMarginLeft = 15.0,
    this.enableBackPage = false,
    this.backPageTitle = 'إرشادات وتعليمات طبية هامة للمريض',
    this.backPageHeaderBannerBase64,
    this.backPageInstructions = const [
      'الالتزام التام بالجرعات المقررة ومواعيد تناول الدواء قبل أو بعد الأكل بدقة.',
      'عدم التوقف عن تناول المضاد الحيوي أو العلاج المزمن دون مراجعة الطبيب المعالج.',
      'في حالة حدوث أي أعراض حساسية أو طفح جلدي، يرجى إيقاف الدواء فوراً والتواصل مع العيادة.',
      'شرب كميات وفيرة من الماء والراحة التامة لسرعة التعافي.',
      'إحضار هذه الروشتة في زيارة الاستشارة أو الإعادة خلال أسبوع من تاريخ الكشف.',
    ],
    this.backPageDietAdvice =
        'تجنب الأطعمة الدسمة والمشروبات الغازية، وتناول وجبات خفيفة غنية بالخضروات الطازجة والفواكه.',
    this.backPageEmergencyNotes =
        'في حالات الطوارئ العاجلة، يرجى التوجه لأقرب مستشفى أو الاتصال بالخط الساخن: 01012345678.',
    this.backPageFooterNotes =
        'مواعيد العمل: يومياً من 10 صباحاً حتى 10 مساءً عدا الجمعة - نتمنى لكم دوام الصحة والعافية.',
  });

  factory PrescriptionTemplateModel.defaultTemplate() {
    return const PrescriptionTemplateModel();
  }

  factory PrescriptionTemplateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrescriptionTemplateModel();
    return PrescriptionTemplateModel(
      clinicDisplayName:
          json['clinicDisplayName'] as String? ?? 'مجمع المهندسين التخصصي',
      doctorDisplayName:
          json['doctorDisplayName'] as String? ?? 'أ.د. حسام الدين عزمي',
      doctorTitle: json['doctorTitle'] as String? ??
          'استشاري الأمراض الباطنة والقلب والأوعية الدموية',
      englishDoctorName: json['englishDoctorName'] as String? ??
          'Prof. Dr. Hossam El-Din Azmy',
      englishDoctorTitle: json['englishDoctorTitle'] as String? ??
          'Consultant of Internal Medicine & Cardiology',
      medicalLicenseNumber:
          json['medicalLicenseNumber'] as String? ?? '441092',
      ministryLicenseNumber:
          json['ministryLicenseNumber'] as String? ?? '8849/2021 - قطاع أ',
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
      headerMode: json['headerMode'] as String? ?? 'dynamicComposed',
      headerBannerBase64: json['headerBannerBase64'] as String?,
      headerHeight: (json['headerHeight'] as num?)?.toDouble() ?? 110.0,
      headerBackgroundStyle:
          json['headerBackgroundStyle'] as String? ?? 'gradientBlue',
      headerAlignment: json['headerAlignment'] as String? ?? 'dual',
      headerLayout: json['headerLayout'] as String? ?? 'dual',
      preprintedHeaderHeight:
          (json['preprintedHeaderHeight'] as num?)?.toDouble() ?? 45.0,
      preprintedFooterHeight:
          (json['preprintedFooterHeight'] as num?)?.toDouble() ?? 30.0,
      hideFooterOnPreprinted: json['hideFooterOnPreprinted'] as bool? ?? true,
      rxLayoutStyle: json['rxLayoutStyle'] as String? ?? 'lines',
      showFollowUpBox: json['showFollowUpBox'] as bool? ?? true,
      followUpText: json['followUpText'] as String? ??
          'خلال 7 أيام من تاريخ الكشف مع إحضار أصل الروشتة للمتابعة السريرية',
      logoImageBase64: json['logoImageBase64'] as String?,
      watermarkImageBase64: json['watermarkImageBase64'] as String?,
      qrCodeImageBase64: json['qrCodeImageBase64'] as String?,
      stampImageBase64: json['stampImageBase64'] as String?,
      signatureImageBase64: json['signatureImageBase64'] as String?,
      fullPageBackgroundBase64: json['fullPageBackgroundBase64'] as String?,
      showQrCode: json['showQrCode'] as bool? ?? true,
      showMinistryLicense: json['showMinistryLicense'] as bool? ?? true,
      showEmergencyPhones: json['showEmergencyPhones'] as bool? ?? true,
      showFileBarcode: json['showFileBarcode'] as bool? ?? true,
      showChronicDiseasesAndAllergies:
          json['showChronicDiseasesAndAllergies'] as bool? ?? true,
      showVitalSigns: json['showVitalSigns'] as bool? ?? true,
      showClinicalDiagnosis: json['showClinicalDiagnosis'] as bool? ?? true,
      watermarkEnabled: json['watermarkEnabled'] as bool? ?? true,
      watermarkType: json['watermarkType'] as String? ?? 'logo',
      watermarkCustomText:
          json['watermarkCustomText'] as String? ?? 'نسخة رسمية معتمدة',
      watermarkOpacity:
          (json['watermarkOpacity'] as num?)?.toDouble() ?? 0.12,
      watermarkPosition: json['watermarkPosition'] as String? ?? 'center',
      enableMicroprintProtection:
          json['enableMicroprintProtection'] as bool? ?? true,
      includeDoctorSignature:
          json['includeDoctorSignature'] as bool? ?? true,
      includeOfficialStamp: json['includeOfficialStamp'] as bool? ?? true,
      officialStampText:
          json['officialStampText'] as String? ?? 'مركز المهندسين - ختم معتمد',
      legalDisclaimer: json['legalDisclaimer'] as String? ??
          'صالح للصرف خلال 7 أيام من تاريخ التحرير - لا يتم استبدال الدواء إلا بموافقة الطبيب المعالج.',
      topMargin: (json['topMargin'] as num?)?.toDouble() ?? 25.0,
      bottomMargin: (json['bottomMargin'] as num?)?.toDouble() ?? 20.0,
      rightMargin: (json['rightMargin'] as num?)?.toDouble() ?? 15.0,
      leftMargin: (json['leftMargin'] as num?)?.toDouble() ?? 15.0,
      defaultPaperSize: json['defaultPaperSize'] as String? ?? 'a4',
      footerHeight: (json['footerHeight'] as num?)?.toDouble() ?? 70.0,
      headerMarginTop: (json['headerMarginTop'] as num?)?.toDouble() ?? 0.0,
      headerMarginBottom:
          (json['headerMarginBottom'] as num?)?.toDouble() ?? 8.0,
      headerMarginRight:
          (json['headerMarginRight'] as num?)?.toDouble() ?? 15.0,
      headerMarginLeft:
          (json['headerMarginLeft'] as num?)?.toDouble() ?? 15.0,
      bodyMarginTop: (json['bodyMarginTop'] as num?)?.toDouble() ?? 8.0,
      bodyMarginBottom:
          (json['bodyMarginBottom'] as num?)?.toDouble() ?? 8.0,
      bodyMarginRight:
          (json['bodyMarginRight'] as num?)?.toDouble() ?? 15.0,
      bodyMarginLeft:
          (json['bodyMarginLeft'] as num?)?.toDouble() ?? 15.0,
      footerMarginTop: (json['footerMarginTop'] as num?)?.toDouble() ?? 8.0,
      footerMarginBottom:
          (json['footerMarginBottom'] as num?)?.toDouble() ?? 12.0,
      footerMarginRight:
          (json['footerMarginRight'] as num?)?.toDouble() ?? 15.0,
      footerMarginLeft:
          (json['footerMarginLeft'] as num?)?.toDouble() ?? 15.0,
      enableBackPage: json['enableBackPage'] as bool? ?? false,
      backPageTitle: json['backPageTitle'] as String? ??
          'إرشادات وتعليمات طبية هامة للمريض',
      backPageHeaderBannerBase64:
          json['backPageHeaderBannerBase64'] as String?,
      backPageInstructions: (json['backPageInstructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'الالتزام التام بالجرعات المقررة ومواعيد تناول الدواء قبل أو بعد الأكل بدقة.',
            'عدم التوقف عن تناول المضاد الحيوي أو العلاج المزمن دون مراجعة الطبيب المعالج.',
            'في حالة حدوث أي أعراض حساسية أو طفح جلدي، يرجى إيقاف الدواء فوراً والتواصل مع العيادة.',
            'شرب كميات وفيرة من الماء والراحة التامة لسرعة التعافي.',
            'إحضار هذه الروشتة في زيارة الاستشارة أو الإعادة خلال أسبوع من تاريخ الكشف.',
          ],
      backPageDietAdvice: json['backPageDietAdvice'] as String? ??
          'تجنب الأطعمة الدسمة والمشروبات الغازية، وتناول وجبات خفيفة غنية بالخضروات الطازجة والفواكه.',
      backPageEmergencyNotes: json['backPageEmergencyNotes'] as String? ??
          'في حالات الطوارئ العاجلة، يرجى التوجه لأقرب مستشفى أو الاتصال بالخط الساخن: 01012345678.',
      backPageFooterNotes: json['backPageFooterNotes'] as String? ??
          'مواعيد العمل: يومياً من 10 صباحاً حتى 10 مساءً عدا الجمعة - نتمنى لكم دوام الصحة والعافية.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinicDisplayName': clinicDisplayName,
      'doctorDisplayName': doctorDisplayName,
      'doctorTitle': doctorTitle,
      'englishDoctorName': englishDoctorName,
      'englishDoctorTitle': englishDoctorTitle,
      'medicalLicenseNumber': medicalLicenseNumber,
      'ministryLicenseNumber': ministryLicenseNumber,
      'addresses': addresses,
      'phoneNumbers': phoneNumbers,
      'headerMode': headerMode,
      'headerBannerBase64': headerBannerBase64,
      'headerHeight': headerHeight,
      'headerBackgroundStyle': headerBackgroundStyle,
      'headerAlignment': headerAlignment,
      'headerLayout': headerLayout,
      'preprintedHeaderHeight': preprintedHeaderHeight,
      'preprintedFooterHeight': preprintedFooterHeight,
      'hideFooterOnPreprinted': hideFooterOnPreprinted,
      'rxLayoutStyle': rxLayoutStyle,
      'showFollowUpBox': showFollowUpBox,
      'followUpText': followUpText,
      'logoImageBase64': logoImageBase64,
      'watermarkImageBase64': watermarkImageBase64,
      'qrCodeImageBase64': qrCodeImageBase64,
      'stampImageBase64': stampImageBase64,
      'signatureImageBase64': signatureImageBase64,
      'fullPageBackgroundBase64': fullPageBackgroundBase64,
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
      'footerHeight': footerHeight,
      'headerMarginTop': headerMarginTop,
      'headerMarginBottom': headerMarginBottom,
      'headerMarginRight': headerMarginRight,
      'headerMarginLeft': headerMarginLeft,
      'bodyMarginTop': bodyMarginTop,
      'bodyMarginBottom': bodyMarginBottom,
      'bodyMarginRight': bodyMarginRight,
      'bodyMarginLeft': bodyMarginLeft,
      'footerMarginTop': footerMarginTop,
      'footerMarginBottom': footerMarginBottom,
      'footerMarginRight': footerMarginRight,
      'footerMarginLeft': footerMarginLeft,
      'enableBackPage': enableBackPage,
      'backPageTitle': backPageTitle,
      'backPageHeaderBannerBase64': backPageHeaderBannerBase64,
      'backPageInstructions': backPageInstructions,
      'backPageDietAdvice': backPageDietAdvice,
      'backPageEmergencyNotes': backPageEmergencyNotes,
      'backPageFooterNotes': backPageFooterNotes,
    };
  }

  PrescriptionTemplateModel copyWith({
    String? clinicDisplayName,
    String? doctorDisplayName,
    String? doctorTitle,
    String? englishDoctorName,
    String? englishDoctorTitle,
    String? medicalLicenseNumber,
    String? ministryLicenseNumber,
    List<String>? addresses,
    List<String>? phoneNumbers,
    String? headerMode,
    String? headerBannerBase64,
    double? headerHeight,
    String? headerBackgroundStyle,
    String? headerAlignment,
    String? headerLayout,
    double? preprintedHeaderHeight,
    double? preprintedFooterHeight,
    bool? hideFooterOnPreprinted,
    String? rxLayoutStyle,
    bool? showFollowUpBox,
    String? followUpText,
    String? logoImageBase64,
    String? watermarkImageBase64,
    String? qrCodeImageBase64,
    String? stampImageBase64,
    String? signatureImageBase64,
    String? fullPageBackgroundBase64,
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
    double? footerHeight,
    double? headerMarginTop,
    double? headerMarginBottom,
    double? headerMarginRight,
    double? headerMarginLeft,
    double? bodyMarginTop,
    double? bodyMarginBottom,
    double? bodyMarginRight,
    double? bodyMarginLeft,
    double? footerMarginTop,
    double? footerMarginBottom,
    double? footerMarginRight,
    double? footerMarginLeft,
    bool? enableBackPage,
    String? backPageTitle,
    String? backPageHeaderBannerBase64,
    List<String>? backPageInstructions,
    String? backPageDietAdvice,
    String? backPageEmergencyNotes,
    String? backPageFooterNotes,
  }) {
    return PrescriptionTemplateModel(
      clinicDisplayName: clinicDisplayName ?? this.clinicDisplayName,
      doctorDisplayName: doctorDisplayName ?? this.doctorDisplayName,
      doctorTitle: doctorTitle ?? this.doctorTitle,
      englishDoctorName: englishDoctorName ?? this.englishDoctorName,
      englishDoctorTitle: englishDoctorTitle ?? this.englishDoctorTitle,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      ministryLicenseNumber:
          ministryLicenseNumber ?? this.ministryLicenseNumber,
      addresses: addresses ?? this.addresses,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      headerMode: headerMode ?? this.headerMode,
      headerBannerBase64: headerBannerBase64 ?? this.headerBannerBase64,
      headerHeight: headerHeight ?? this.headerHeight,
      headerBackgroundStyle:
          headerBackgroundStyle ?? this.headerBackgroundStyle,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      headerLayout: headerLayout ?? this.headerLayout,
      preprintedHeaderHeight:
          preprintedHeaderHeight ?? this.preprintedHeaderHeight,
      preprintedFooterHeight:
          preprintedFooterHeight ?? this.preprintedFooterHeight,
      hideFooterOnPreprinted:
          hideFooterOnPreprinted ?? this.hideFooterOnPreprinted,
      rxLayoutStyle: rxLayoutStyle ?? this.rxLayoutStyle,
      showFollowUpBox: showFollowUpBox ?? this.showFollowUpBox,
      followUpText: followUpText ?? this.followUpText,
      logoImageBase64: logoImageBase64 ?? this.logoImageBase64,
      watermarkImageBase64: watermarkImageBase64 ?? this.watermarkImageBase64,
      qrCodeImageBase64: qrCodeImageBase64 ?? this.qrCodeImageBase64,
      stampImageBase64: stampImageBase64 ?? this.stampImageBase64,
      signatureImageBase64: signatureImageBase64 ?? this.signatureImageBase64,
      fullPageBackgroundBase64:
          fullPageBackgroundBase64 ?? this.fullPageBackgroundBase64,
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
      footerHeight: footerHeight ?? this.footerHeight,
      headerMarginTop: headerMarginTop ?? this.headerMarginTop,
      headerMarginBottom: headerMarginBottom ?? this.headerMarginBottom,
      headerMarginRight: headerMarginRight ?? this.headerMarginRight,
      headerMarginLeft: headerMarginLeft ?? this.headerMarginLeft,
      bodyMarginTop: bodyMarginTop ?? this.bodyMarginTop,
      bodyMarginBottom: bodyMarginBottom ?? this.bodyMarginBottom,
      bodyMarginRight: bodyMarginRight ?? this.bodyMarginRight,
      bodyMarginLeft: bodyMarginLeft ?? this.bodyMarginLeft,
      footerMarginTop: footerMarginTop ?? this.footerMarginTop,
      footerMarginBottom: footerMarginBottom ?? this.footerMarginBottom,
      footerMarginRight: footerMarginRight ?? this.footerMarginRight,
      footerMarginLeft: footerMarginLeft ?? this.footerMarginLeft,
      enableBackPage: enableBackPage ?? this.enableBackPage,
      backPageTitle: backPageTitle ?? this.backPageTitle,
      backPageHeaderBannerBase64:
          backPageHeaderBannerBase64 ?? this.backPageHeaderBannerBase64,
      backPageInstructions: backPageInstructions ?? this.backPageInstructions,
      backPageDietAdvice: backPageDietAdvice ?? this.backPageDietAdvice,
      backPageEmergencyNotes:
          backPageEmergencyNotes ?? this.backPageEmergencyNotes,
      backPageFooterNotes: backPageFooterNotes ?? this.backPageFooterNotes,
    );
  }
}

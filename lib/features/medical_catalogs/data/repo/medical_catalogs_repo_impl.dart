import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import '../../domain/repo/medical_catalogs_repo.dart';
import '../models/enums/medical_catalog_kind_enum.dart';
import '../models/medical_catalog_entry_model.dart';

class MedicalCatalogsRepoImpl implements MedicalCatalogsRepo {
  final List<MedicalCatalogEntryModel> _entries = [];

  MedicalCatalogsRepoImpl() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime(2026, 1, 15);

    // ─── 1. Radiology (فحوصات شعاعية) ─────────────────────────────────────────
    final radiologySeeds = [
      ('RAD-001', 'أشعة سينية رقمية على الصدر', 'CXR-01', 'أشعة سينية (X-Ray)', 'وضعان أمامي وخلفي لتقييم الرئتين والقلب'),
      ('RAD-002', 'أشعة سينية على العمود الفقري القطني', 'LSS-02', 'أشعة سينية (X-Ray)', 'تقييم الفقرات والانزلاق الغضروفي'),
      ('RAD-003', 'رنين مغناطيسي على المخ', 'MRI-01', 'رنين مغناطيسي (MRI)', 'بدون صبغة مع تسلسلات انتشار متقدمة'),
      ('RAD-004', 'رنين مغناطيسي على مفصل الركبة', 'MRI-02', 'رنين مغناطيسي (MRI)', 'تقييم الغضروف الهلالي والأربطة الصليبية'),
      ('RAD-005', 'أشعة مقطعية على البطن والحوض بالصبغة', 'CT-01', 'أشعة مقطعية (CT)', 'تقييم شامل للأعضاء الداخلية والكتل'),
      ('RAD-006', 'أشعة مقطعية ثلاثية الأبعاد على المخ', 'CT-02', 'أشعة مقطعية (CT)', 'طوارئ إصابات الرأس والنزيف'),
      ('RAD-007', 'موجات فوق صوتية على البطن والحوض', 'US-01', 'موجات صوتية (Ultrasound)', 'تقييم الكبد والكلى والبنكرياس والمرارة'),
      ('RAD-008', 'موجات صوتية وسونار على الثدي', 'US-02', 'موجات صوتية (Ultrasound)', 'فحص كتل الثدي والغدد الليمفاوية'),
      ('RAD-009', 'إيكو ورسم قلب بالموجات فوق الصوتية', 'ECHO-01', 'رسم قلب (Echo/ECG)', 'تقييم كفاءة العضلة وصمامات القلب'),
      ('RAD-010', 'دوبلر ملون على شرايين وأوردة الساقين', 'DOP-01', 'دوبلر (Doppler)', 'تشخيص الدوالي والجلطات الوريدية العميقة DVT'),
      ('RAD-011', 'أشعة بانوراما رقمية للأسنان والفكين', 'PAN-01', 'أشعة سينية (X-Ray)', 'تقييم عظام الفك وضرس العقل والتقويم'),
      ('RAD-012', 'فحص كثافة وهشاشة العظام ديكسا', 'DEXA-01', 'أشعة سينية (X-Ray)', 'قياس كثافة عظام الحوض والعمود الفقري'),
    ];

    for (final s in radiologySeeds) {
      _entries.add(
        MedicalCatalogEntryModel(
          id: s.$1,
          name: s.$2,
          code: s.$3,
          kind: MedicalCatalogKindEnum.radiology,
          category: s.$4,
          notes: s.$5,
          isActive: true,
          createdAt: now,
        ),
      );
    }

    // ─── 2. Lab Tests (فحوصات مختبرية) ────────────────────────────────────────
    final labSeeds = [
      ('LAB-001', 'صورة دم كاملة شاملة', 'CBC-01', 'أمراض الدم (Hematology)', 'تحليل كريات الدم والصفائح والهيموجلوبين'),
      ('LAB-002', 'سكر تراكمي في الدم', 'HBA1C-01', 'كيمياء الدم (Biochemistry)', 'معدل السكر التراكمي خلال 3 أشهر'),
      ('LAB-003', 'سكر صائم وسكر بعد الأكل بساعتين', 'FBS-01', 'كيمياء الدم (Biochemistry)', 'تشخيص ومتابعة مرضى السكري'),
      ('LAB-004', 'وظائف كبد متكاملة', 'LFT-01', 'كيمياء الدم (Biochemistry)', 'ALT, AST, Bilirubin, Albumin, Alkaline Phos'),
      ('LAB-005', 'وظائف كلى ونسبة الكرياتينين واليوريا', 'KFT-01', 'كيمياء الدم (Biochemistry)', 'Serum Creatinine, Blood Urea, eGFR'),
      ('LAB-006', 'تحليل الدهون الثلاثية والكوليسترول الشامل', 'LIP-01', 'كيمياء الدم (Biochemistry)', 'Total Cholesterol, Triglycerides, HDL, LDL'),
      ('LAB-007', 'هرمون منبه الغدة الدرقية', 'TSH-01', 'هرمونات (Hormones)', 'تقييم نشاط أو خمول الغدة الدرقية'),
      ('LAB-008', 'هرمونات درقية حرة', 'FT3-FT4', 'هرمونات (Hormones)', 'Free T3 & Free T4'),
      ('LAB-009', 'فيتامين د 25-هيدروكسي', 'VIT-D', 'فيتامينات ومعادن (Vitamins)', 'قياس مخزون فيتامين د في المصل'),
      ('LAB-010', 'فيتامين ب12 والزنك', 'VIT-B12', 'فيتامينات ومعادن (Vitamins)', 'تقييم فقر الدم والأعصاب'),
      ('LAB-011', 'مخزون الحديد في الدم', 'FERR-01', 'أمراض الدم (Hematology)', 'Serum Ferritin لتشخيص أنيميا نقص الحديد'),
      ('LAB-012', 'تحليل بول كامل وميكروسكوبي', 'URI-01', 'تحاليل بول وبراز (Urinalysis)', 'رواسب البول والأملاح والصديد والزلال'),
      ('LAB-013', 'تحليل براز وبحث عن طفيليات ودم خفي', 'STL-01', 'تحاليل بول وبراز (Urinalysis)', 'Stool Examination & Occult Blood'),
      ('LAB-014', 'بروتين سي التفاعلي وسرعة الترسيب', 'CRP-ESR', 'مناعة ومصليات (Immunology)', 'تقييم معدلات الالتهاب الحاد والروماتيزم'),
    ];

    for (final s in labSeeds) {
      _entries.add(
        MedicalCatalogEntryModel(
          id: s.$1,
          name: s.$2,
          code: s.$3,
          kind: MedicalCatalogKindEnum.labTests,
          category: s.$4,
          notes: s.$5,
          isActive: true,
          createdAt: now,
        ),
      );
    }

    // ─── 3. Chronic Diseases (الأمراض المزمنة) ──────────────────────────────────
    final chronicSeeds = [
      ('CHR-001', 'سكري النوع الأول', 'DM-T1', 'أمراض الغدد والسكري', 'معتمد على الأنسولين يتطلب قياس سكر دوري'),
      ('CHR-002', 'سكري النوع الثاني', 'DM-T2', 'أمراض الغدد والسكري', 'متابعة الحمية والأدوية الفموية ونمط الحياة'),
      ('CHR-003', 'ارتفاع ضغط الدم الشرياني الأساسي', 'HTN-01', 'أمراض القلب والشرايين', 'ضغط دم انقباضي/انبساطي مزمن يتطلب خافضات ضغط'),
      ('CHR-004', 'قصور الشريان التاجي والذبحة الصدرية', 'CAD-01', 'أمراض القلب والشرايين', 'تصلب الشرايين التاجية ومتابعة دهون الدم'),
      ('CHR-005', 'قصور عضلة القلب الاحتقاني', 'CHF-01', 'أمراض القلب والشرايين', 'انخفاض الكسر القذفي ومتابعة مدرات البول'),
      ('CHR-006', 'الربو الشعبي والتحسسي', 'ASTH-01', 'أمراض الجهاز التنفسي', 'نوبات ضيق تنفس متكررة وبخاخات وقائية'),
      ('CHR-007', 'مرض الانسداد الرئوي المزمن', 'COPD-01', 'أمراض الجهاز التنفسي', 'سعال مزمن وضيق تنفس لدى المدخنين'),
      ('CHR-008', 'القصور الكلوي المزمن', 'CKD-01', 'أمراض الكلى والمسالك', 'متابعة معدل الترشيح الكبيبي وقيود السوائل'),
      ('CHR-009', 'خمول الغدة الدرقية', 'HYPO-T', 'أمراض الغدد والسكري', 'علاج تعويضي بهرمون الثيروكسين'),
      ('CHR-010', 'فرط نشاط الغدة الدرقية المناعي', 'HYPER-T', 'أمراض الغدد والسكري', 'داء غريفز ومتابعة الأدوية المضادة للدرق'),
      ('CHR-011', 'التهاب الكبد وتليف الكبد المزمن', 'CIRR-01', 'أمراض الجهاز الهضمي والكبد', 'متابعة وظائف الكبد والموجات الصوتية الدورية'),
      ('CHR-012', 'التهاب المفاصل الروماتويدي المزمن', 'RA-01', 'أمراض المفاصل والروماتيزم', 'التهاب مناعي بالمفاصل الصغيرة مع تيبس صباحي'),
      ('CHR-013', 'الذئبة الحمراء الجهازية', 'SLE-01', 'أمراض المفاصل والروماتيزم', 'مرض مناعي ذاتي متعدد الأعضاء'),
      ('CHR-014', 'الصرع ونوبات التشنج المزمنة', 'EPI-01', 'أمراض عصبية ونفسية', 'علاج بمضادات التشنج ومتابعة تخطيط الدماغ'),
    ];

    for (final s in chronicSeeds) {
      _entries.add(
        MedicalCatalogEntryModel(
          id: s.$1,
          name: s.$2,
          code: s.$3,
          kind: MedicalCatalogKindEnum.chronicDiseases,
          category: s.$4,
          notes: s.$5,
          isActive: true,
          createdAt: now,
        ),
      );
    }

    // ─── 4. Allergies (الحساسيات) ─────────────────────────────────────────────
    final allergySeeds = [
      ('ALL-001', 'بنسلين ومشتقات البيتالاكتام', 'MED-PEN', 'حساسية دوائية', 'صدمة تحسسية وحكة وصعوبة تنفس مع أموكسيسيلين وأوجمنتين'),
      ('ALL-002', 'مركبات السلفا ومضادات السلفوناميد', 'MED-SULF', 'حساسية دوائية', 'طفح جلدي وحساسية ضوئية مع سبترين وسوتريم'),
      ('ALL-003', 'الأسبرين ومضادات الالتهاب غير الستيرويدية', 'MED-NSAID', 'حساسية دوائية', 'حساسية مع أسبرين، كيتوفان، بروفين، وفولتارين'),
      ('ALL-004', 'صبغة الأشعة الوريدية اليودية', 'MED-CONT', 'حساسية دوائية', 'تفاعل مع وسائط التباين المستخدمة في الأشعة المقطعية'),
      ('ALL-005', 'المخدر الموضعي ومشتقات الليدوكايين', 'MED-LIDO', 'حساسية دوائية', 'تنبيه طبيب الأسنان وجراحة اليوم الواحد قبل الحقن'),
      ('ALL-006', 'اللاتكس والمطاط الطبي الطبيعي', 'ENV-LATX', 'حساسية بيئية وتنفسية', 'حساسية من القفازات والأدوات الطبية المطاطية'),
      ('ALL-007', 'الفول السوداني والمكسرات الشجرية', 'FOOD-NUT', 'حساسية غذائية', 'حساسية شديدة مهددة للحياة تتطلب قلم إبينفرين طارئ'),
      ('ALL-008', 'حليب الأبقار وبروتين اللبن واللاكتوز', 'FOOD-MLK', 'حساسية غذائية', 'اضطرابات هضمية وطفح جلدي لدى الرضع والأطفال'),
      ('ALL-009', 'بياض وصفار بيض الدجاج', 'FOOD-EGG', 'حساسية غذائية', 'تنبيه عند أخذ اللقاحات المصنعة في أجنة البيض'),
      ('ALL-010', 'الأسماك والمأكولات البحرية والقشريات', 'FOOD-SEA', 'حساسية غذائية', 'حساسية الجمبري والاستاكوزا والتونة'),
      ('ALL-011', 'الغلوتين وحبوب القمح', 'FOOD-GLU', 'حساسية غذائية', 'داء الزلاقي / حساسية القمح المعوية'),
      ('ALL-012', 'حبوب اللقاح وغبار الطلع الموسمي', 'ENV-POL', 'حساسية بيئية وتنفسية', 'حمى القش والتهاب الأنف التحسسي في الربيع'),
      ('ALL-013', 'عثة غبار المنزل', 'ENV-DUST', 'حساسية بيئية وتنفسية', 'حساسية صدرية وربو تزداد داخل المنازل والمفروشات'),
      ('ALL-014', 'سم النحل ولدغات الحشرات', 'ENV-BEE', 'حساسية سموم ولسعات', 'تورم حاد وتأق يستدعي إسعاف فوري'),
    ];

    for (final s in allergySeeds) {
      _entries.add(
        MedicalCatalogEntryModel(
          id: s.$1,
          name: s.$2,
          code: s.$3,
          kind: MedicalCatalogKindEnum.allergies,
          category: s.$4,
          notes: s.$5,
          isActive: true,
          createdAt: now,
        ),
      );
    }

    // ─── 5. Surgeries (العمليات الجراحية) ──────────────────────────────────────
    final surgerySeeds = [
      ('SUR-001', 'استئصال الزائدة الدودية بالمنظار', 'GS-APP', 'جراحة عامة ومناظير', 'تدخل طارئ لاستئصال الزائدة الملتهبة بالمنظار الجراحي'),
      ('SUR-002', 'استئصال المرارة وحصواتها بالمنظار', 'GS-CHOL', 'جراحة عامة ومناظير', 'جراحة شائعة لإزالة الحصوات المرارية والالتهاب'),
      ('SUR-003', 'إصلاح الفتق الإربي وتثبيت شبكة دعامية', 'GS-HERN', 'جراحة عامة ومناظير', 'إصلاح أحادي أو ثنائي الجانب بالمنظار أو الجراحة'),
      ('SUR-004', 'ولادة قيصرية وتوليد جراحي', 'OB-CS', 'جراحة النساء والتوليد', 'ولادة قيصرية مجدولة أو طارئة مع خياطة تجميلية'),
      ('SUR-005', 'استئصال الرحم الكامل أو الجزئي', 'GYN-HYST', 'جراحة النساء والتوليد', 'جراحة لعلاج الأورام الليفية والنزيف الرحمي المتكرر'),
      ('SUR-006', 'استئصال اللوزتين واللحمية', 'ENT-TON', 'جراحة الأنف والأذن والحنجرة', 'جراحة شائعة لعلاج تكرار الالتهاب والانسداد التنفسي'),
      ('SUR-007', 'إزالة المياه البيضاء بالفاكو وزرع عدسة داخل العين', 'OPH-CAT', 'جراحة العيون', 'جراحة دقيقة بالموجات فوق الصوتية واستعادة الرؤية'),
      ('SUR-008', 'استبدال مفصل الركبة الصناعي الكامل', 'ORTH-TKR', 'جراحة العظام والمفاصل', 'علاج خشونة وتآكل مفصل الركبة المتقدم'),
      ('SUR-009', 'منظار مفصل الكتف وإصلاح وتر الكفة المدورة', 'ORTH-SH', 'جراحة العظام والمفاصل', 'إصلاح قطوع الأوتار وإزالة الالتهابات بالمنظار'),
      ('SUR-010', 'قسطرة القلب العلاجية وتوسيع الشرايين بدعامة', 'CARD-PCI', 'قسطرة وجراحة القلب والأوعية', 'فتح الانسدادات الشريانية الحادة وتركيب دعامة دوائية'),
      ('SUR-011', 'استئصال الانزلاق الغضروفي القطني المجهري', 'NS-DISC', 'جراحة المخ والأعصاب', 'تخفيف الضغط عن جذور الأعصاب وعلاج عرق النسا'),
      ('SUR-012', 'تفتيت واستخراج حصوات الكلى والحالب بالليزر', 'URO-URS', 'جراحة المسالك البولية', 'منظار الحالب المرن وتفتيت الليزر المتقدم'),
    ];

    for (final s in surgerySeeds) {
      _entries.add(
        MedicalCatalogEntryModel(
          id: s.$1,
          name: s.$2,
          code: s.$3,
          kind: MedicalCatalogKindEnum.surgeries,
          category: s.$4,
          notes: s.$5,
          isActive: true,
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<Either<Failures, List<MedicalCatalogEntryModel>>> getEntries({
    required MedicalCatalogKindEnum kind,
    String? query,
    String? category,
  }) async {
    var list = _entries.where((e) => e.kind == kind).toList();

    if (category != null && category.isNotEmpty && category != 'الكل') {
      list = list.where((e) => e.category == category).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      list = list.where((e) {
        return ArabicTextHelper.containsNormalized(e.name, q) ||
            ArabicTextHelper.containsNormalized(e.code, q) ||
            ArabicTextHelper.containsNormalized(e.category, q) ||
            (e.notes != null &&
                ArabicTextHelper.containsNormalized(e.notes!, q));
      }).toList();
    }

    return Right(list);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> addEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    final trimmedName = entry.name.trim();
    if (trimmedName.isEmpty) {
      return Left(ValidationFailure(errMessage: 'اسم العنصر مطلوب'));
    }

    // Auto-generate code if empty
    final code = entry.code.trim().isNotEmpty
        ? entry.code.trim()
        : '${entry.kind.codePrefix}-${(_entries.where((e) => e.kind == entry.kind).length + 1).toString().padLeft(3, '0')}';

    final created = entry.copyWith(
      id: '${entry.kind.codePrefix}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: trimmedName,
      code: code,
      createdAt: DateTime.now(),
    );

    _entries.insert(0, created);
    return Right(created);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> updateEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      return Left(ServerFailure(errMessage: 'العنصر غير موجود'));
    }

    _entries[idx] = entry;
    return Right(entry);
  }

  @override
  Future<Either<Failures, bool>> deleteEntry(String id) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) {
      return Left(ServerFailure(errMessage: 'العنصر غير موجود'));
    }
    _entries.removeAt(idx);
    return const Right(true);
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) {
      return Left(ServerFailure(errMessage: 'العنصر غير موجود'));
    }
    final updated = _entries[idx].copyWith(isActive: isActive);
    _entries[idx] = updated;
    return Right(updated);
  }
}

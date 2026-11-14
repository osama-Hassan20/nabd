import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import '../../domain/helpers/drug_allergy_matcher.dart';
import '../../domain/helpers/drug_name_validator.dart';
import '../../domain/repo/drugs_repo.dart';
import '../models/drug_category_model.dart';
import '../models/drug_model.dart';
import '../models/enums/drug_source_enum.dart';
import '../models/enums/review_status_enum.dart';

class DrugsMockRepoImpl implements DrugsRepo {
  final List<DrugModel> _drugs = [];
  final List<DrugCategoryModel> _categories = [];
  final Map<String, List<String>> _allergyAliasesMap = {};
  int _idCounter = 25;

  DrugsMockRepoImpl() {
    _initSeed();
  }

  void _initSeed() {
    // ─── Allergy Aliases Seed for Cross-Lingual Search ───────────────────────
    _allergyAliasesMap['CAT-ALL-001'] = [
      'بنسلين',
      'penicillin',
      'اموكسيسيلين',
      'amoxicillin',
      'اموكسيل',
      'amoxil',
      'اوجمنتين',
      'augmentin',
      'هاي بيوتك',
      'hibiotic',
      'امبيسيلين',
      'ampicillin',
    ];
    _allergyAliasesMap['CAT-ALL-003'] = [
      'اسبرين',
      'aspirin',
      'اسبوسيد',
      'aspocid',
      'حمض اسيتيل ساليسيليك',
      'acetylsalicylic acid',
      'ريفو',
      'rivo',
    ];
    _allergyAliasesMap['CAT-ALL-005'] = [
      'سلفا',
      'sulfa',
      'سلفاميثوكسازول',
      'sulfamethoxazole',
      'سبترين',
      'septrin',
      'سوتريم',
      'sutrim',
    ];

    // ─── 8 Categories Seed ──────────────────────────────────────────────────
    _categories.addAll([
      const DrugCategoryModel(
        id: 'CAT-DRUG-01',
        nameAr: 'المضادات الحيوية',
        nameEn: 'Antibiotics',
        description: 'مضادات الميكروبات والبكتيريا واسعة وضيق المجال',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-02',
        nameAr: 'المسكنات ومضادات الالتهاب',
        nameEn: 'Analgesics & NSAIDs',
        description: 'مسكنات الألم وخافضات الحرارة ومضادات الالتهاب غير الستيرويدية',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-03',
        nameAr: 'أدوية الجهاز الهضمي',
        nameEn: 'Gastrointestinal',
        description: 'مثبطات الحموضة ومضادات التقلصات وحركة الأمعاء',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-04',
        nameAr: 'أدوية القلب والضغط',
        nameEn: 'Cardiovascular & Antihypertensives',
        description: 'علاجات ضغط الدم وأمراض القلب والشرايين',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-05',
        nameAr: 'أدوية السكري',
        nameEn: 'Antidiabetics',
        description: 'خافضات السكر الفموية والإنسولين',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-06',
        nameAr: 'أدوية الجهاز التنفسي',
        nameEn: 'Respiratory & Bronchodilators',
        description: 'موسعات الشعب الهوائية وبخاخات الربو والحساسية الصدرية',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-07',
        nameAr: 'مضادات الحساسية',
        nameEn: 'Antihistamines',
        description: 'مضادات الهستامين وأدوية الحساسية الموسمية والجلدية',
      ),
      const DrugCategoryModel(
        id: 'CAT-DRUG-08',
        nameAr: 'الفيتامينات والمكملات',
        nameEn: 'Vitamins & Supplements',
        description: 'الفيتامينات والمعادن والمقويات العامة',
      ),
    ]);

    final seedDate = CairoTimeHelper.now().subtract(const Duration(days: 30));

    // ─── 25 Realistic Egyptian Market Drugs Seed ─────────────────────────────
    _drugs.addAll([
      // 1. Antibiotics
      DrugModel(
        id: 'DRUG-001',
        name: 'Augmentin 1g',
        scientificName: 'Amoxicillin / Clavulanic Acid',
        categoryId: 'CAT-DRUG-01',
        concentration: '1g',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (كل 12 ساعة)',
        defaultDuration: '7 أيام',
        description: 'مضاد حيوي واسع المجال بعد الأكل',
        manufacturer: 'GlaxoSmithKline',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-002',
        name: 'Amoxil 500mg',
        scientificName: 'Amoxicillin',
        categoryId: 'CAT-DRUG-01',
        concentration: '500mg',
        defaultDosage: 'كبسولة واحدة',
        defaultFrequency: '3 مرات يومياً (كل 8 ساعات)',
        defaultDuration: '7 أيام',
        description: 'مضاد حيوي مشتق من البنسلين',
        manufacturer: 'GlaxoSmithKline',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-003',
        name: 'Hibiotic 1g',
        scientificName: 'Amoxicillin / Clavulanic Acid',
        categoryId: 'CAT-DRUG-01',
        concentration: '1g',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (كل 12 ساعة)',
        defaultDuration: '7 أيام',
        description: 'مضاد حيوي لعلاج التهابات الجهاز التنفسي',
        manufacturer: 'Amoun',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-004',
        name: 'Septrin',
        scientificName: 'Sulfamethoxazole / Trimethoprim',
        categoryId: 'CAT-DRUG-01',
        concentration: '480mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (كل 12 ساعة)',
        defaultDuration: '5 أيام',
        description: 'مضاد حيوي من مركبات السلفا',
        manufacturer: 'GlaxoSmithKline',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-005',
        name: 'Sutrim',
        scientificName: 'Sulfamethoxazole / Trimethoprim',
        categoryId: 'CAT-DRUG-01',
        concentration: '400mg/80mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (كل 12 ساعة)',
        defaultDuration: '5 أيام',
        description: 'علاج التهابات المسالك البولية من مشتقات السلفا',
        manufacturer: 'EVA Pharma',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-006',
        name: 'Zithrokan 500mg',
        scientificName: 'Azithromycin',
        categoryId: 'CAT-DRUG-01',
        concentration: '500mg',
        defaultDosage: 'كبسولة واحدة',
        defaultFrequency: 'مرة واحدة يومياً',
        defaultDuration: '3 أيام',
        description: 'مضاد حيوي ماكروليد قبل الأكل بساعة أو بعده بساعتين',
        manufacturer: 'Hikma',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-007',
        name: 'Ciprodar 500mg',
        scientificName: 'Ciprofloxacin',
        categoryId: 'CAT-DRUG-01',
        concentration: '500mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (كل 12 ساعة)',
        defaultDuration: '7 أيام',
        description: 'مضاد حيوي من عائلة الفلوروكينولون',
        manufacturer: 'Dar Al Dawa',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 2. Analgesics & NSAIDs
      DrugModel(
        id: 'DRUG-008',
        name: 'Cataflam 50mg',
        scientificName: 'Diclofenac Potassium',
        categoryId: 'CAT-DRUG-02',
        concentration: '50mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'عند اللزوم',
        defaultDuration: '5 أيام',
        description: 'مسكن ومضاد للالتهاب سريع المفعول بعد الأكل',
        manufacturer: 'Novartis',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-009',
        name: 'Brufen 400mg',
        scientificName: 'Ibuprofen',
        categoryId: 'CAT-DRUG-02',
        concentration: '400mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: '3 مرات يومياً (بعد الأكل)',
        defaultDuration: '5 أيام',
        description: 'مسكن ومضاد للالتهاب وخافض للحرارة',
        manufacturer: 'Abbott',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-010',
        name: 'Panadol Extra',
        scientificName: 'Paracetamol / Caffeine',
        categoryId: 'CAT-DRUG-02',
        concentration: '500mg/65mg',
        defaultDosage: 'قرصان',
        defaultFrequency: 'عند اللزوم',
        defaultDuration: '3 أيام',
        description: 'مسكن آمن وخافض للحرارة عند اللزوم',
        manufacturer: 'Haleon',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-011',
        name: 'Aspocid 75mg',
        scientificName: 'Acetylsalicylic acid / Aspirin',
        categoryId: 'CAT-DRUG-02',
        concentration: '75mg',
        defaultDosage: 'قرص للمضغ',
        defaultFrequency: 'مرة واحدة يومياً',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'مضاد لتجلط الصفائح الدموية بعد الغداء',
        manufacturer: 'CID',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-012',
        name: 'Ketofan 50mg',
        scientificName: 'Ketoprofen',
        categoryId: 'CAT-DRUG-02',
        concentration: '50mg',
        defaultDosage: 'كبسولة واحدة',
        defaultFrequency: 'مرتان يومياً (بعد الأكل)',
        defaultDuration: '5 أيام',
        description: 'مسكن للآلام المفصلية والعضلية',
        manufacturer: 'Amoun',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 3. Gastrointestinal
      DrugModel(
        id: 'DRUG-013',
        name: 'Omeprazole 20mg',
        scientificName: 'Omeprazole',
        categoryId: 'CAT-DRUG-03',
        concentration: '20mg',
        defaultDosage: 'كبسولة واحدة',
        defaultFrequency: 'مرة واحدة يومياً (قبل الأكل)',
        defaultDuration: '14 يوماً',
        description: 'مثبط مضخة البروتون لعلاج قرحة وحموضة المعدة',
        manufacturer: 'Sedico',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-014',
        name: 'Controloc 40mg',
        scientificName: 'Pantoprazole',
        categoryId: 'CAT-DRUG-03',
        concentration: '40mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً (قبل الإفطار)',
        defaultDuration: '14 يوماً',
        description: 'علاج ارتجاع المريء والتهاب المعدة',
        manufacturer: 'Takeda',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-015',
        name: 'Motinorm 10mg',
        scientificName: 'Domperidone',
        categoryId: 'CAT-DRUG-03',
        concentration: '10mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: '3 مرات يومياً (قبل الأكل)',
        defaultDuration: '5 أيام',
        description: 'منظم لحركة الجهاز الهضمي ومضاد للغثيان',
        manufacturer: 'Medical Union',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-016',
        name: 'Visceralgine',
        scientificName: 'Tiemonium Methylsulfate',
        categoryId: 'CAT-DRUG-03',
        concentration: '50mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: '3 مرات يومياً',
        defaultDuration: '5 أيام',
        description: 'مضاد للتقلصات ومغص البطن والمسالك',
        manufacturer: 'Sedico',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 4. Cardiovascular & Antihypertensives
      DrugModel(
        id: 'DRUG-017',
        name: 'Concor 5mg',
        scientificName: 'Bisoprolol Fumarate',
        categoryId: 'CAT-DRUG-04',
        concentration: '5mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً (صباحاً)',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'حاصر بيتا لعلاج ضغط الدم وتنظيم ضربات القلب',
        manufacturer: 'Merck',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-018',
        name: 'Capoten 25mg',
        scientificName: 'Captopril',
        categoryId: 'CAT-DRUG-04',
        concentration: '25mg',
        defaultDosage: 'نصف قرص',
        defaultFrequency: 'مرتان يومياً',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'مثبط الإنزيم المحول للأنجيوتنسين لارتفاع ضغط الدم',
        manufacturer: 'Bristol-Myers Squibb',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-019',
        name: 'Norvasc 5mg',
        scientificName: 'Amlodipine',
        categoryId: 'CAT-DRUG-04',
        concentration: '5mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'حاصر قنوات الكالسيوم لضغط الدم والذبحة الصدرية',
        manufacturer: 'Pfizer',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 5. Antidiabetics
      DrugModel(
        id: 'DRUG-020',
        name: 'Glucophage 1000mg',
        scientificName: 'Metformin Hydrochloride',
        categoryId: 'CAT-DRUG-05',
        concentration: '1000mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرتان يومياً (مع الأكل)',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'منظم سكر الدم ومقاومة الإنسولين',
        manufacturer: 'Merck',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-021',
        name: 'Amaryl 2mg',
        scientificName: 'Glimepiride',
        categoryId: 'CAT-DRUG-05',
        concentration: '2mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً (قبل الإفطار)',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'محفز إفراز الإنسولين لمرضى السكري من النوع الثاني',
        manufacturer: 'Sanofi',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 6. Respiratory
      DrugModel(
        id: 'DRUG-022',
        name: 'Ventolin Inhaler',
        scientificName: 'Salbutamol',
        categoryId: 'CAT-DRUG-06',
        concentration: '100mcg/dose',
        defaultDosage: 'بختان',
        defaultFrequency: 'عند اللزوم',
        defaultDuration: 'مستمر (علاج مزمن)',
        description: 'بخاخ موسع للشعب الهوائية سريع المفعول للأزمات',
        manufacturer: 'GlaxoSmithKline',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 7. Antihistamines
      DrugModel(
        id: 'DRUG-023',
        name: 'Zyrtec 10mg',
        scientificName: 'Cetirizine Dihydrochloride',
        categoryId: 'CAT-DRUG-07',
        concentration: '10mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً (مساءً)',
        defaultDuration: '7 أيام',
        description: 'مضاد للحساسية والرشح والحكة',
        manufacturer: 'GlaxoSmithKline',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
      DrugModel(
        id: 'DRUG-024',
        name: 'Claritine 10mg',
        scientificName: 'Loratadine',
        categoryId: 'CAT-DRUG-07',
        concentration: '10mg',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً',
        defaultDuration: '10 أيام',
        description: 'مضاد للهستامين لا يسبب النعاس',
        manufacturer: 'Bayer',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),

      // 8. Vitamins
      DrugModel(
        id: 'DRUG-025',
        name: 'Neurobion',
        scientificName: 'Vitamin B1, B6, B12',
        categoryId: 'CAT-DRUG-08',
        concentration: 'Forte',
        defaultDosage: 'قرص واحد',
        defaultFrequency: 'مرة واحدة يومياً',
        defaultDuration: 'شهر واحد',
        description: 'فيتامينات ب المركبة لتقوية الأعصاب الطرفية',
        manufacturer: 'Merck',
        isActive: true,
        source: DrugSourceEnum.preset,
        reviewStatus: ReviewStatusEnum.approved,
        createdAt: seedDate,
      ),
    ]);
  }

  @override
  Future<Either<Failures, List<DrugModel>>> getDrugs({
    String? query,
    String? categoryId,
    String? reviewFilter,
    bool includeArchived = false,
  }) async {
    var result = _drugs.where((d) {
      if (!includeArchived && d.isActive == false) return false;
      if (categoryId != null && categoryId.isNotEmpty && d.categoryId != categoryId) {
        return false;
      }
      if (reviewFilter != null && reviewFilter.isNotEmpty && reviewFilter != 'all') {
        if (reviewFilter == 'pending' && d.reviewStatus != ReviewStatusEnum.pending) {
          return false;
        }
        if (reviewFilter == 'approved' && d.reviewStatus != ReviewStatusEnum.approved) {
          return false;
        }
      }
      return true;
    }).toList();

    if (query != null && query.trim().isNotEmpty) {
      final normQuery = DrugAllergyMatcher.normalize(query);
      final isArabicQuery = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
      final queryTokens = DrugAllergyMatcher.tokenize(query);

      result = result.where((d) {
        final normName = DrugAllergyMatcher.normalize(d.name);
        final normScientific = DrugAllergyMatcher.normalize(d.scientificName);
        final normManufacturer = DrugAllergyMatcher.normalize(d.manufacturer);

        if (normName.contains(normQuery) ||
            normScientific.contains(normQuery) ||
            normManufacturer.contains(normQuery)) {
          return true;
        }

        // Cross-lingual alias search for Arabic queries matching Latin ingredients
        if (isArabicQuery) {
          final drugTokens = {
            ...DrugAllergyMatcher.tokenize(d.name),
            ...DrugAllergyMatcher.tokenize(d.scientificName),
          };

          for (final aliasesList in _allergyAliasesMap.values) {
            final normalizedAliases = aliasesList.map(DrugAllergyMatcher.normalize).toSet();
            final matchesQuery = queryTokens.any(normalizedAliases.contains) || normalizedAliases.contains(normQuery);
            final matchesDrug = drugTokens.any(normalizedAliases.contains);
            if (matchesQuery && matchesDrug) {
              return true;
            }
          }
        }

        return false;
      }).toList();
    }

    return Right(result);
  }

  @override
  Future<Either<Failures, List<DrugCategoryModel>>> getCategories() async {
    return Right(_categories.where((c) => c.isActive == true).toList());
  }

  @override
  Future<Either<Failures, DrugModel>> addDrug(DrugModel drug) async {
    final validationErr = DrugNameValidator.validate(drug.name);
    if (validationErr != null) {
      return Left(ValidationFailure(errMessage: validationErr));
    }

    final newId = 'DRUG-${(++_idCounter).toString().padLeft(3, '0')}';
    final newDrug = drug.copyWith(
      id: newId,
      name: DrugNameValidator.sanitize(drug.name),
      createdAt: CairoTimeHelper.now(),
      isActive: true,
    );

    _drugs.add(newDrug);
    return Right(newDrug);
  }

  @override
  Future<Either<Failures, DrugModel>> updateDrug(DrugModel drug) async {
    if (drug.id == null) {
      return const Left(ValidationFailure(errMessage: 'drugs_missing_id'));
    }

    final validationErr = DrugNameValidator.validate(drug.name);
    if (validationErr != null) {
      return Left(ValidationFailure(errMessage: validationErr));
    }

    final index = _drugs.indexWhere((d) => d.id == drug.id);
    if (index == -1) {
      return const Left(ValidationFailure(errMessage: 'drugs_not_found'));
    }

    final updated = drug.copyWith(name: DrugNameValidator.sanitize(drug.name));
    _drugs[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failures, Unit>> archiveDrug(String drugId) async {
    final index = _drugs.indexWhere((d) => d.id == drugId);
    if (index == -1) {
      return const Left(ValidationFailure(errMessage: 'drugs_not_found'));
    }

    final current = _drugs[index];
    _drugs[index] = current.copyWith(isActive: false);
    return const Right(unit);
  }

  @override
  Future<Either<Failures, DrugModel>> quickAddDrug({
    required String name,
    required String visitId,
    required String doctorId,
    String? concentration,
    String? dosage,
    String? frequency,
    String? duration,
  }) async {
    final validationErr = DrugNameValidator.validate(name);
    if (validationErr != null) {
      return Left(ValidationFailure(errMessage: validationErr));
    }

    final newId = 'DRUG-${(++_idCounter).toString().padLeft(3, '0')}';
    final quickDrug = DrugModel(
      id: newId,
      name: DrugNameValidator.sanitize(name),
      concentration: concentration,
      defaultDosage: dosage,
      defaultFrequency: frequency,
      defaultDuration: duration,
      source: DrugSourceEnum.quickAdd,
      reviewStatus: ReviewStatusEnum.pending,
      isQuickAdded: true,
      isActive: true,
      createdByUserId: doctorId,
      createdAt: CairoTimeHelper.now(),
    );

    _drugs.add(quickDrug);
    return Right(quickDrug);
  }

  @override
  Future<Either<Failures, DrugModel>> reviewQuickAddDrug({
    required String drugId,
    required ReviewStatusEnum decision,
    required String reviewedByUserId,
    String? mergeTargetDrugId,
  }) async {
    final index = _drugs.indexWhere((d) => d.id == drugId);
    if (index == -1) {
      return const Left(ValidationFailure(errMessage: 'drugs_not_found'));
    }

    final current = _drugs[index];
    final updated = current.copyWith(
      reviewStatus: decision,
      reviewedByUserId: reviewedByUserId,
      reviewedAt: CairoTimeHelper.now(),
      isActive: decision == ReviewStatusEnum.rejected ? false : current.isActive,
    );

    _drugs[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failures, Unit>> updateAllergyAliases({
    required String catalogItemId,
    required List<String> aliases,
  }) async {
    _allergyAliasesMap[catalogItemId] = List<String>.from(aliases);
    return const Right(unit);
  }
}

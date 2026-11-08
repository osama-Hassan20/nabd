import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import '../../domain/repo/medical_catalog_repo.dart';
import '../models/medical_catalog_item_model.dart';

class MedicalCatalogMockRepoImpl implements MedicalCatalogRepo {
  final List<MedicalCatalogItemModel> _items = [];

  MedicalCatalogMockRepoImpl() {
    _initSeedData();
  }

  void _initSeedData() {
    int idCounter = 1;

    // ─── Allergies Seed ──────────────────────────────────────────────────────
    final allergies = [
      'بنسلين',
      'حساسية بنسلين شديدة',
      'أسبرين',
      'حساسية أسبرين',
      'سلفا',
      'حساسية سلفا',
      'مضادات الالتهاب غير الستيرويدية',
      'لاتكس',
      'بيض',
      'لبن',
      'فول سوداني',
      'مكسرات',
      'مأكولات بحرية',
      'غبار الطلع',
      'غبار المنزل',
      'لسعات الحشرات',
    ];

    for (final name in allergies) {
      _items.add(
        MedicalCatalogItemModel(
          id: 'CAT-ALL-${(idCounter++).toString().padLeft(3, '0')}',
          name: name,
          type: 'allergy',
        ),
      );
    }

    // ─── Chronic Diseases Seed ───────────────────────────────────────────────
    final chronicDiseases = [
      'سكري النوع الأول',
      'سكري النوع الثاني',
      'ضغط مرتفع',
      'ارتفاع ضغط الدم',
      'أمراض القلب',
      'أمراض قلب وشرايين',
      'قصور الشريان التاجي',
      'ربو',
      'ربو شعبي مزمن',
      'انسداد رئوي مزمن',
      'فشل كلوي مزمن',
      'أمراض الغدة الدرقية',
      'أمراض الكبد',
      'صرع',
      'أنيميا',
      'روماتويد',
      'ارتفاع الكوليسترول',
      'سمنة',
    ];

    for (final name in chronicDiseases) {
      _items.add(
        MedicalCatalogItemModel(
          id: 'CAT-CHR-${(idCounter++).toString().padLeft(3, '0')}',
          name: name,
          type: 'chronic_disease',
        ),
      );
    }
  }

  @override
  Future<Either<Failures, List<MedicalCatalogItemModel>>> getCatalogItems({
    required String type,
    String? query,
  }) async {
    final typeMatches = _items.where((i) => i.type == type).toList();

    if (query == null || query.trim().isEmpty) {
      return Right(typeMatches);
    }

    final filtered = typeMatches.where((item) {
      return ArabicTextHelper.containsNormalized(item.name, query);
    }).toList();

    return Right(filtered);
  }

  @override
  Future<Either<Failures, MedicalCatalogItemModel>> addCatalogItem({
    required String name,
    required String type,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Left(ValidationFailure(errMessage: 'اسم العنصر لا يمكن أن يكون فارغاً'));
    }

    final normNew = ArabicTextHelper.normalize(trimmedName);

    // Check if normalized version already exists in this type
    final existing = _items.where((i) {
      return i.type == type && ArabicTextHelper.normalize(i.name) == normNew;
    }).firstOrNull;

    if (existing != null) {
      return Right(existing);
    }

    // Create new
    final prefix = type == 'allergy' ? 'CAT-ALL' : 'CAT-CHR';
    final newItem = MedicalCatalogItemModel(
      id: '$prefix-${(_items.length + 1).toString().padLeft(3, '0')}',
      name: trimmedName,
      type: type,
    );
    _items.add(newItem);

    return Right(newItem);
  }
}


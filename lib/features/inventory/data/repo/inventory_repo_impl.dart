import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import '../../domain/repo/inventory_repo.dart';
import '../models/inventory_item_model.dart';

class InventoryRepoImpl implements InventoryRepo {
  final List<InventoryItemModel> _items = [];
  final List<InventoryTransactionModel> _transactions = [];

  InventoryRepoImpl() {
    _seedLocalData();
  }

  void _seedLocalData() {
    final now = CairoTimeHelper.now();

    _items.addAll([
      // ─── 1. مستلزمات طب الأسنان ─────────────────────────────────────────────
      InventoryItemModel(
        id: 'INV-DEN-01',
        name: 'كاربولات بنج موضعي (Articaine 4% + Adrenaline)',
        code: 'DEN-ANES-01',
        category: 'طب الأسنان',
        unit: 'أمبولة / كاربولة',
        currentStock: 8,
        minStockAlert: 15, // تنبيه انخفاض!
        unitCost: 28,
        shelfLocation: 'دولاب مستلزمات الأسنان - رف 1',
        description: 'بنج موضعي سريع المفعول لعمليات الخلع والحشو وجراحة اللثة',
        expiryDate: now.add(const Duration(days: 365)),
        lastConsumedDate: now.subtract(const Duration(hours: 4)),
      ),
      InventoryItemModel(
        id: 'INV-DEN-02',
        name: 'شفرات مشارط جراحية رقم 15 معقمة',
        code: 'DEN-SCAL-15',
        category: 'طب الأسنان',
        unit: 'شفرة معقمة',
        currentStock: 25,
        minStockAlert: 10,
        unitCost: 12,
        shelfLocation: 'درج الأدوات الجراحية المعقمة',
        description: 'شفرات جراحية دقيقة لشقوق اللثة والعمليات الجراحية الصغرى',
        expiryDate: now.add(const Duration(days: 700)),
      ),
      InventoryItemModel(
        id: 'INV-DEN-03',
        name: 'حشوات كمبوزيت ضوئي نانو A2 (Filtek Z350)',
        code: 'DEN-COMP-A2',
        category: 'طب الأسنان',
        unit: 'حقنة 4 جم',
        currentStock: 2,
        minStockAlert: 4, // تنبيه انخفاض!
        unitCost: 450,
        shelfLocation: 'ثلاجة مواد الحشو والترميم',
        description: 'كمبوزيت تجميلي عالي الجودة للأسنان الأمامية والخلفية',
        expiryDate: now.add(const Duration(days: 400)),
      ),
      InventoryItemModel(
        id: 'INV-DEN-04',
        name: 'مبارد عصب روتاري NiTi ProTaper Gold',
        code: 'DEN-ENDO-PTG',
        category: 'طب الأسنان',
        unit: 'طقم 6 مبارد',
        currentStock: 6,
        minStockAlert: 3,
        unitCost: 380,
        shelfLocation: 'جهاز الروتاري وسحب العصب',
        description: 'مبارد مرنة لتوسيع قنوات الجذور المنحنية',
      ),

      // ─── 2. مستلزمات الجلدية والليزر والتجميل ──────────────────────────────
      InventoryItemModel(
        id: 'INV-DERM-01',
        name: 'أسطوانات غاز تبريد أجهزة ليزر كانديلا (Cryogen DCD)',
        code: 'LSR-CRYO-01',
        category: 'الجلدية والليزر والتجميل',
        unit: 'أسطوانة 1000 جم',
        currentStock: 1,
        minStockAlert: 3, // تنبيه حرج جداً!
        unitCost: 1250,
        shelfLocation: 'غرفة أجهزة الليزر - وحدة كانديلا',
        description: 'غاز التبريد الديناميكي لحماية الجلد أثناء نبضات الليزر وتفادي الحروق',
        expiryDate: now.add(const Duration(days: 600)),
        lastConsumedDate: now.subtract(const Duration(hours: 2)),
      ),
      InventoryItemModel(
        id: 'INV-DERM-02',
        name: 'عدسات ورؤوس أجهزة كانديلا جنتل ليز 18 مم',
        code: 'LSR-LENS-18',
        category: 'الجلدية والليزر والتجميل',
        unit: 'عدسة بصرية',
        currentStock: 0,
        minStockAlert: 2, // نفد تماماً!
        unitCost: 850,
        shelfLocation: 'خزنة قطع غيار الليزر المعقمة',
        description: 'عدسات تركيز النبضة لجلسات إزالة الشعر للجسم والمناطق الواسعة',
        expiryDate: now.add(const Duration(days: 800)),
      ),
      InventoryItemModel(
        id: 'INV-DERM-03',
        name: 'سنون ديرمابن معقمة للاستخدام الفردي (12 سن)',
        code: 'DERM-NEEDLE-12',
        category: 'الجلدية والليزر والتجميل',
        unit: 'رأس معقم',
        currentStock: 18,
        minStockAlert: 10,
        unitCost: 35,
        shelfLocation: 'غرفة العناية بالبشرة والهيدرافيشيل',
        description: 'رؤوس مايكرونيدل لعلاج الندبات وتحفيز الكولاجين والميزوثيرابي',
        expiryDate: now.add(const Duration(days: 500)),
      ),
      InventoryItemModel(
        id: 'INV-DERM-04',
        name: 'أمبولات بوتوكس 100 وحدة (Allergan Botox)',
        code: 'DERM-BOT-100',
        category: 'الجلدية والليزر والتجميل',
        unit: 'أمبولة معقمة',
        currentStock: 2,
        minStockAlert: 4, // تنبيه انخفاض!
        unitCost: 2600,
        shelfLocation: 'ثلاجة الأدوية والبيولوجيات (2-8 م°)',
        description: 'توكسين البوتولينوم لعلاج التجاعيد التعبيرية وفرط التعرق',
        expiryDate: now.add(const Duration(days: 200)),
      ),
      InventoryItemModel(
        id: 'INV-DERM-05',
        name: 'حقن فيلر حمض الهيالورونيك (Juvederm Ultra 4)',
        code: 'DERM-FIL-UV4',
        category: 'الجلدية والليزر والتجميل',
        unit: 'حقنة 1 مل',
        currentStock: 5,
        minStockAlert: 3,
        unitCost: 3200,
        shelfLocation: 'ثلاجة الأدوية والبيولوجيات (2-8 م°)',
        description: 'فيلر عالي اللزوجة لتحديد الشفاه والوجنتين وملء الخطوط العميقة',
        expiryDate: now.add(const Duration(days: 300)),
      ),
      InventoryItemModel(
        id: 'INV-DERM-06',
        name: 'سنون كوي جراحي وتبخير زوائد جلدية بالكي الكهربائي',
        code: 'SURG-CAUT-01',
        category: 'الجلدية والليزر والتجميل',
        unit: 'سن كوي طبي',
        currentStock: 7,
        minStockAlert: 4,
        unitCost: 65,
        shelfLocation: 'وحدة جهاز الكي الجراحي Hyfrecator',
        description: 'سنون معقمة لاستئصال الثآليل والزوائد الجلدية والشامات السطحية',
        expiryDate: now.add(const Duration(days: 900)),
      ),

      // ─── 3. الجراحة والعمليات والمستهلكات العامة ──────────────────────────
      InventoryItemModel(
        id: 'INV-SURG-01',
        name: 'خيوط جراحية نايلون 3/0 مع إبرة قطع عكسي',
        code: 'SURG-SUT-30',
        category: 'الجراحة والعمليات الصغرى',
        unit: 'باكيت 12 خيط',
        currentStock: 10,
        minStockAlert: 5,
        unitCost: 110,
        shelfLocation: 'دولاب الغيار والعمليات الصغرى',
        description: 'خيوط غير ممتصة لخياطة الجلد والجروح السطحية والوجه',
        expiryDate: now.add(const Duration(days: 650)),
      ),
      InventoryItemModel(
        id: 'INV-GEN-01',
        name: 'قفازات فحص طبية لاتكس بدون بودرة مقاس M',
        code: 'GEN-GLV-LAT-M',
        category: 'مستهلكات عامة ومطهرات',
        unit: 'علبة (100 قفاز)',
        currentStock: 4,
        minStockAlert: 8, // تنبيه انخفاض!
        unitCost: 85,
        shelfLocation: 'مخزن المستهلكات المركزي',
        description: 'قفازات طبية مريحة ومعقمة للفحص والاستخدام السريري اليومي',
        expiryDate: now.add(const Duration(days: 450)),
      ),
      InventoryItemModel(
        id: 'INV-GEN-02',
        name: 'محلول بيتادين جراحي مطهر ومطهر موضعي 10%',
        code: 'GEN-ANT-BET-1L',
        category: 'مستهلكات عامة ومطهرات',
        unit: 'عبوة 1 لتر',
        currentStock: 6,
        minStockAlert: 3,
        unitCost: 95,
        shelfLocation: 'غرفة التعقيم وتطهير الأدوات',
        description: 'بوفيدون يود لتطهير الجلد قبل الحقن والجراحات وغسيل الأدوات',
        expiryDate: now.add(const Duration(days: 550)),
      ),
    ]);

    // Seed realistic transactions
    _transactions.addAll([
      InventoryTransactionModel(
        id: 'TXN-01',
        itemId: 'INV-DEN-01',
        itemName: 'كاربولات بنج موضعي (Articaine 4% + Adrenaline)',
        type: 'consumption',
        quantity: 2,
        date: now.subtract(const Duration(hours: 4)),
        performedBy: 'د. طارق المنشاوي',
        notes: 'سحب لحالة خلع ضرس عقل جراحي لمريض بالعيادة 1',
      ),
      InventoryTransactionModel(
        id: 'TXN-02',
        itemId: 'INV-DERM-01',
        itemName: 'أسطوانات غاز تبريد أجهزة ليزر كانديلا (Cryogen DCD)',
        type: 'consumption',
        quantity: 1,
        date: now.subtract(const Duration(hours: 2)),
        performedBy: 'د. سارة عادل',
        notes: 'تركيب أسطوانة جديدة بعد نفاد السابقة أثناء جلسات الليزر الصباحية',
      ),
      InventoryTransactionModel(
        id: 'TXN-03',
        itemId: 'INV-DEN-02',
        itemName: 'شفرات مشارط جراحية رقم 15 معقمة',
        type: 'restock',
        quantity: 20,
        date: now.subtract(const Duration(days: 3)),
        performedBy: 'الاستقبال (أحمد مصطفى)',
        notes: 'استلام وتوريد شحنة من شركة الأمل للمستلزمات الطبية',
      ),
    ]);
  }

  @override
  Future<Either<Failures, List<InventoryItemModel>>> getItems({
    String? query,
    String? category,
    bool onlyLowStock = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      var result = List<InventoryItemModel>.from(_items);

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        result = result
            .where((item) =>
                item.name.toLowerCase().contains(q) ||
                item.code.toLowerCase().contains(q) ||
                item.shelfLocation.toLowerCase().contains(q))
            .toList();
      }

      if (category != null && category.isNotEmpty && category != 'all') {
        result = result.where((item) => item.category == category).toList();
      }

      if (onlyLowStock) {
        result = result.where((item) => item.isLowStock || item.isOutOfStock).toList();
      }

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تحميل بيانات المخزون والمستلزمات'));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> addItem(InventoryItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      _items.insert(0, item);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل إضافة الصنف إلى المخزون'));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> updateItem(InventoryItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final idx = _items.indexWhere((it) => it.id == item.id);
      if (idx == -1) {
        return Left(ServerFailure(errMessage: 'الصنف غير موجود بالمخزون'));
      }
      _items[idx] = item;
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تعديل بيانات الصنف'));
    }
  }

  @override
  Future<Either<Failures, String>> deleteItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      _items.removeWhere((it) => it.id == id);
      return const Right('تم حذف الصنف من المخزون بنجاح');
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل حذف الصنف'));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordConsumption({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final idx = _items.indexWhere((it) => it.id == itemId);
      if (idx == -1) {
        return Left(ServerFailure(errMessage: 'الصنف غير موجود بالمخزون'));
      }
      final current = _items[idx];
      if (current.currentStock < quantity) {
        return Left(ServerFailure(
          errMessage: 'الكمية المطلوبة سحبها ($quantity) تتجاوز الرصيد المتوفر (${current.currentStock})',
        ));
      }

      final now = CairoTimeHelper.now();
      final updated = current.copyWith(
        currentStock: current.currentStock - quantity,
        lastConsumedDate: now,
      );
      _items[idx] = updated;

      _transactions.insert(
        0,
        InventoryTransactionModel(
          id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          itemId: itemId,
          itemName: current.name,
          type: 'consumption',
          quantity: quantity,
          date: now,
          performedBy: performedBy,
          notes: notes ?? 'سحب مستلزمات طبية',
        ),
      );

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تسجيل عملية السحب والاستهلاك'));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordRestock({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? supplier,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final idx = _items.indexWhere((it) => it.id == itemId);
      if (idx == -1) {
        return Left(ServerFailure(errMessage: 'الصنف غير موجود بالمخزون'));
      }
      final current = _items[idx];
      final now = CairoTimeHelper.now();
      final updated = current.copyWith(
        currentStock: current.currentStock + quantity,
        lastRestockDate: now,
      );
      _items[idx] = updated;

      final supplierNote = supplier != null && supplier.isNotEmpty ? 'المورد: $supplier - ' : '';
      _transactions.insert(
        0,
        InventoryTransactionModel(
          id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          itemId: itemId,
          itemName: current.name,
          type: 'restock',
          quantity: quantity,
          date: now,
          performedBy: performedBy,
          notes: '$supplierNote${notes ?? 'توريد واستلام شحنة جديدة'}',
        ),
      );

      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل توريد واستلام الشحنة'));
    }
  }

  @override
  Future<Either<Failures, List<InventoryTransactionModel>>> getTransactions({
    String? itemId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      if (itemId != null && itemId.isNotEmpty) {
        return Right(_transactions.where((t) => t.itemId == itemId).toList());
      }
      return Right(List<InventoryTransactionModel>.from(_transactions));
    } catch (e) {
      return Left(ServerFailure(errMessage: 'فشل تحميل سجل حركات المخزون'));
    }
  }
}

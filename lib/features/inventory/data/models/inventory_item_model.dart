import 'package:equatable/equatable.dart';

class InventoryTransactionModel extends Equatable {
  final String id;
  final String itemId;
  final String itemName;
  final String type; // 'consumption' (سحب/استهلاك) | 'restock' (توريد/إضافة)
  final int quantity;
  final DateTime date;
  final String performedBy;
  final String notes;

  const InventoryTransactionModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.date,
    required this.performedBy,
    this.notes = '',
  });

  bool get isConsumption => type == 'consumption';
  bool get isRestock => type == 'restock';

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName'] as String? ?? '',
      type: json['type'] as String? ?? 'consumption',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      performedBy: json['performedBy'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'type': type,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'performedBy': performedBy,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemName,
        type,
        quantity,
        date,
        performedBy,
        notes,
      ];
}

class InventoryItemModel extends Equatable {
  final String id;
  final String name;
  final String code; // كود الصنف أو الباركود
  final String category; // 'طب الأسنان', 'الجلدية والليزر والتجميل', 'الجراحة والعمليات', 'مستهلكات عامة ومطهرات'
  final String unit; // 'أمبولة / كاربولة', 'علبة', 'شفرة', 'أسطوانة تبريد', 'قطعة'
  final int currentStock;
  final int minStockAlert; // حد التنبيه / نقطة إعادة الطلب
  final num unitCost; // سعر التكلفة للوحدة
  final DateTime? expiryDate;
  final String shelfLocation; // موقع التخزين في العيادة
  final String description;
  final DateTime? lastRestockDate;
  final DateTime? lastConsumedDate;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minStockAlert,
    this.unitCost = 0,
    this.expiryDate,
    this.shelfLocation = '',
    this.description = '',
    this.lastRestockDate,
    this.lastConsumedDate,
  });

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock => currentStock > 0 && currentStock <= minStockAlert;
  bool get isAdequateStock => currentStock > minStockAlert;

  num get totalEstimatedValue => currentStock * unitCost;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
      unit: json['unit'] as String? ?? 'قطعة',
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      minStockAlert: (json['minStockAlert'] as num?)?.toInt() ?? 5,
      unitCost: (json['unitCost'] as num?) ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      shelfLocation: json['shelfLocation'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lastRestockDate: json['lastRestockDate'] != null
          ? DateTime.tryParse(json['lastRestockDate'].toString())
          : null,
      lastConsumedDate: json['lastConsumedDate'] != null
          ? DateTime.tryParse(json['lastConsumedDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'minStockAlert': minStockAlert,
      'unitCost': unitCost,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'shelfLocation': shelfLocation,
      'description': description,
      if (lastRestockDate != null)
        'lastRestockDate': lastRestockDate!.toIso8601String(),
      if (lastConsumedDate != null)
        'lastConsumedDate': lastConsumedDate!.toIso8601String(),
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? unit,
    int? currentStock,
    int? minStockAlert,
    num? unitCost,
    DateTime? expiryDate,
    String? shelfLocation,
    String? description,
    DateTime? lastRestockDate,
    DateTime? lastConsumedDate,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unitCost: unitCost ?? this.unitCost,
      expiryDate: expiryDate ?? this.expiryDate,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      description: description ?? this.description,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      lastConsumedDate: lastConsumedDate ?? this.lastConsumedDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        category,
        unit,
        currentStock,
        minStockAlert,
        unitCost,
        expiryDate,
        shelfLocation,
        description,
        lastRestockDate,
        lastConsumedDate,
      ];
}

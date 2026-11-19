import 'package:equatable/equatable.dart';
import 'enums/medical_catalog_kind_enum.dart';

class MedicalCatalogEntryModel extends Equatable {
  final String id;
  final String name;
  final String code;
  final MedicalCatalogKindEnum kind;
  final String category;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  const MedicalCatalogEntryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.kind,
    required this.category,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  MedicalCatalogEntryModel copyWith({
    String? id,
    String? name,
    String? code,
    MedicalCatalogKindEnum? kind,
    String? category,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MedicalCatalogEntryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MedicalCatalogEntryModel.fromJson(Map<String, dynamic> json) {
    return MedicalCatalogEntryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      kind: MedicalCatalogKindEnum.fromKey(json['kind'] as String?),
      category: json['category'] as String? ?? 'عام',
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'kind': kind.key,
      'category': category,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        kind,
        category,
        notes,
        isActive,
        createdAt,
      ];
}

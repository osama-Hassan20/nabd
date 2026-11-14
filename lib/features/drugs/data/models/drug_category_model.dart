import 'package:equatable/equatable.dart';

class DrugCategoryModel extends Equatable {
  final String? id;
  final String? nameAr;
  final String? nameEn;
  final String? description;
  final bool? isActive;

  const DrugCategoryModel({
    this.id,
    this.nameAr,
    this.nameEn,
    this.description,
    this.isActive = true,
  });

  factory DrugCategoryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DrugCategoryModel();
    return DrugCategoryModel(
      id: json['id']?.toString(),
      nameAr: json['nameAr'] as String?,
      nameEn: json['nameEn'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nameAr != null) 'nameAr': nameAr,
      if (nameEn != null) 'nameEn': nameEn,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
    };
  }

  DrugCategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? description,
    bool? isActive,
  }) {
    return DrugCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, nameAr, nameEn, description, isActive];
}

import 'package:equatable/equatable.dart';

class MedicalCatalogItemModel extends Equatable {
  final String? id;
  final String? name;
  final String? type; // 'allergy' | 'chronic_disease'

  const MedicalCatalogItemModel({
    this.id,
    this.name,
    this.type,
  });

  factory MedicalCatalogItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MedicalCatalogItemModel();
    return MedicalCatalogItemModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
    };
  }

  MedicalCatalogItemModel copyWith({
    String? id,
    String? name,
    String? type,
  }) {
    return MedicalCatalogItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, name, type];
}


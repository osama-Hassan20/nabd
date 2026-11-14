import 'package:equatable/equatable.dart';

class MedicalCatalogItemModel extends Equatable {
  final String? id;
  final String? name;
  final String? type; // 'allergy' | 'chronic_disease'
  final List<String>? aliases;

  const MedicalCatalogItemModel({
    this.id,
    this.name,
    this.type,
    this.aliases,
  });

  factory MedicalCatalogItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MedicalCatalogItemModel();
    return MedicalCatalogItemModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      type: json['type'] as String?,
      aliases: (json['aliases'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (aliases != null) 'aliases': aliases,
    };
  }

  MedicalCatalogItemModel copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? aliases,
  }) {
    return MedicalCatalogItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      aliases: aliases ?? this.aliases,
    );
  }

  @override
  List<Object?> get props => [id, name, type, aliases];
}

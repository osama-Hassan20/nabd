import 'package:equatable/equatable.dart';
import 'prescription_template_item_model.dart';

class PrescriptionTemplateModel extends Equatable {
  final String? id;
  final String? doctorId; // Doctor owner ID (privacy isolation)
  final String? name; // Template name (e.g. 'بروتوكول نزلة معوية')
  final String? description;
  final List<PrescriptionTemplateItemModel>? items;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrescriptionTemplateModel({
    this.id,
    this.doctorId,
    this.name,
    this.description,
    this.items,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PrescriptionTemplateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrescriptionTemplateModel();
    return PrescriptionTemplateModel(
      id: json['id']?.toString(),
      doctorId: json['doctorId'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PrescriptionTemplateItemModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (doctorId != null) 'doctorId': doctorId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (items != null) 'items': items?.map((i) => i.toJson()).toList(),
      if (isActive != null) 'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PrescriptionTemplateModel copyWith({
    String? id,
    String? doctorId,
    String? name,
    String? description,
    List<PrescriptionTemplateItemModel>? items,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrescriptionTemplateModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        doctorId,
        name,
        description,
        items,
        isActive,
        createdAt,
        updatedAt,
      ];
}


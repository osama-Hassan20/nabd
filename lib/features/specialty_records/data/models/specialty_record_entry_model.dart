import 'package:equatable/equatable.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';

class SpecialtyRecordEntryModel extends Equatable {
  final String id;
  final String patientId;
  final String? visitId;
  final MedicalSpecialty specialty;
  final String kind;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? createdBy;
  final int revision;

  const SpecialtyRecordEntryModel({
    required this.id,
    required this.patientId,
    this.visitId,
    required this.specialty,
    required this.kind,
    required this.data,
    required this.createdAt,
    this.createdBy,
    this.revision = 1,
  });

  factory SpecialtyRecordEntryModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyRecordEntryModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      visitId: json['visitId']?.toString(),
      specialty: MedicalSpecialty.fromValue(json['specialty']?.toString()),
      kind: json['kind']?.toString() ?? 'structured_visit',
      data: Map<String, dynamic>.from(
        (json['data'] as Map?) ?? const <String, dynamic>{},
      ),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      createdBy: json['createdBy']?.toString(),
      revision: (json['revision'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      if (visitId != null) 'visitId': visitId,
      'specialty': specialty.value,
      'kind': kind,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      'revision': revision,
    };
  }

  SpecialtyRecordEntryModel copyWith({
    String? id,
    String? patientId,
    String? visitId,
    MedicalSpecialty? specialty,
    String? kind,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    String? createdBy,
    int? revision,
  }) {
    return SpecialtyRecordEntryModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      specialty: specialty ?? this.specialty,
      kind: kind ?? this.kind,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        visitId,
        specialty,
        kind,
        data,
        createdAt,
        createdBy,
        revision,
      ];
}

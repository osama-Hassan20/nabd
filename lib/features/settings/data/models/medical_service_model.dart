import 'package:equatable/equatable.dart';

class MedicalServiceModel extends Equatable {
  final String? id;
  final String? name;
  final num? consultationFee;
  final int? durationMinutes;
  final bool? isActive;
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final String? description;
  final bool? isMultiSession;
  final int? sessionsCount;
  final String? category;

  const MedicalServiceModel({
    this.id,
    this.name,
    this.consultationFee,
    this.durationMinutes,
    this.isActive,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.description,
    this.isMultiSession,
    this.sessionsCount,
    this.category,
  });

  bool get isServiceActive => isActive ?? true;
  bool get isMultiSessionService => isMultiSession ?? false;

  factory MedicalServiceModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MedicalServiceModel();
    return MedicalServiceModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      consultationFee: json['consultationFee'] as num?,
      durationMinutes: json['durationMinutes'] as int?,
      isActive: json['isActive'] as bool?,
      assignedDoctorId: json['assignedDoctorId']?.toString(),
      assignedDoctorName: json['assignedDoctorName'] as String?,
      description: json['description'] as String?,
      isMultiSession: json['isMultiSession'] as bool?,
      sessionsCount: json['sessionsCount'] as int?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (consultationFee != null) 'consultationFee': consultationFee,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (isActive != null) 'isActive': isActive,
      if (assignedDoctorId != null) 'assignedDoctorId': assignedDoctorId,
      if (assignedDoctorName != null) 'assignedDoctorName': assignedDoctorName,
      if (description != null) 'description': description,
      if (isMultiSession != null) 'isMultiSession': isMultiSession,
      if (sessionsCount != null) 'sessionsCount': sessionsCount,
      if (category != null) 'category': category,
    };
  }

  MedicalServiceModel copyWith({
    String? id,
    String? name,
    num? consultationFee,
    int? durationMinutes,
    bool? isActive,
    String? assignedDoctorId,
    bool clearAssignedDoctor = false,
    String? assignedDoctorName,
    String? description,
    bool? isMultiSession,
    int? sessionsCount,
    String? category,
  }) {
    return MedicalServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      consultationFee: consultationFee ?? this.consultationFee,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      assignedDoctorId: clearAssignedDoctor
          ? null
          : (assignedDoctorId ?? this.assignedDoctorId),
      assignedDoctorName: clearAssignedDoctor
          ? null
          : (assignedDoctorName ?? this.assignedDoctorName),
      description: description ?? this.description,
      isMultiSession: isMultiSession ?? this.isMultiSession,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        consultationFee,
        durationMinutes,
        isActive,
        assignedDoctorId,
        assignedDoctorName,
        description,
        isMultiSession,
        sessionsCount,
        category,
      ];
}


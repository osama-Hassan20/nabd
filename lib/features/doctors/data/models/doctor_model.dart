import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'enums/doctor_gender_enum.dart';
import 'enums/doctor_status_enum.dart';

class DoctorModel {
  final String? id;
  final String? name;
  final String? phone;
  final String? image;
  final String? specialty;
  final List<MedicalSpecialty> specialties;
  final DoctorGenderEnum? gender;
  final DoctorStatusEnum? status;
  final int? todayTasksCount;
  final int? upcomingBookingsCount;
  final int? completedBookingsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DoctorModel({
    this.id,
    this.name,
    this.phone,
    this.image,
    this.specialty,
    this.specialties = const [],
    this.gender,
    this.status,
    this.todayTasksCount,
    this.upcomingBookingsCount,
    this.completedBookingsCount,
    this.createdAt,
    this.updatedAt,
  });

  List<MedicalSpecialty> get effectiveSpecialties {
    if (specialties.isNotEmpty) return specialties;
    if (specialty != null && specialty!.trim().isNotEmpty) {
      return MedicalSpecialty.parseMultiple(specialty);
    }
    return const [MedicalSpecialty.generalPractice];
  }

  MedicalSpecialty get primarySpecialty => effectiveSpecialties.first;

  String get defaultAvatar => AppIcons.user;

  String get avatarPath =>
      (image != null && image!.isNotEmpty) ? image! : defaultAvatar;

  factory DoctorModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorModel();
    final legacySpec = json['specialty'] as String?;
    final rawSpecialties = json['specialties'];
    List<MedicalSpecialty> parsedSpecialties = const [];
    if (rawSpecialties is List && rawSpecialties.isNotEmpty) {
      parsedSpecialties = rawSpecialties
          .map((e) => MedicalSpecialty.fromValue(e?.toString()))
          .toSet()
          .toList();
    } else if (legacySpec != null && legacySpec.trim().isNotEmpty) {
      parsedSpecialties = MedicalSpecialty.parseMultiple(legacySpec);
    }

    return DoctorModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      image: json['image'] as String?,
      specialty: legacySpec,
      specialties: parsedSpecialties,
      gender: DoctorGenderEnum.fromValue(json['gender'] as String?),
      status: DoctorStatusEnum.fromValue(json['status'] as String?),
      todayTasksCount: json['todayTasksCount'] as int? ?? json['today_tasks_count'] as int?,
      upcomingBookingsCount: json['upcomingBookingsCount'] as int? ?? json['upcoming_bookings_count'] as int?,
      completedBookingsCount: json['completedBookingsCount'] as int? ?? json['completed_bookings_count'] as int?,
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
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (image != null) 'image': image,
      if (specialty != null) 'specialty': specialty,
      if (specialties.isNotEmpty)
        'specialties': specialties.map((e) => e.value).toList(),
      if (gender != null) 'gender': gender?.value,
      if (status != null) 'status': status?.value,
      if (todayTasksCount != null) 'todayTasksCount': todayTasksCount,
      if (upcomingBookingsCount != null)
        'upcomingBookingsCount': upcomingBookingsCount,
      if (completedBookingsCount != null)
        'completedBookingsCount': completedBookingsCount,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? image,
    String? specialty,
    List<MedicalSpecialty>? specialties,
    DoctorGenderEnum? gender,
    DoctorStatusEnum? status,
    int? todayTasksCount,
    int? upcomingBookingsCount,
    int? completedBookingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      specialty: specialty ?? this.specialty,
      specialties: specialties ?? this.specialties,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      todayTasksCount: todayTasksCount ?? this.todayTasksCount,
      upcomingBookingsCount:
          upcomingBookingsCount ?? this.upcomingBookingsCount,
      completedBookingsCount:
          completedBookingsCount ?? this.completedBookingsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:eyadty/core/utils/theme/app_images.dart';
import 'enums/technician_gender_enum.dart';
import 'enums/technician_status_enum.dart';

class TechnicianModel {
  final String? id;
  final String? name;
  final String? phone;
  final String? image;
  final TechnicianGenderEnum? gender;
  final TechnicianStatusEnum? status;
  final int? todayTasksCount;
  final int? upcomingBookingsCount;
  final int? completedBookingsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TechnicianModel({
    this.id,
    this.name,
    this.phone,
    this.image,
    this.gender,
    this.status,
    this.todayTasksCount,
    this.upcomingBookingsCount,
    this.completedBookingsCount,
    this.createdAt,
    this.updatedAt,
  });

  String get defaultAvatar =>
      gender == TechnicianGenderEnum.female
          ? AppImages.cleanerWomen
          : AppImages.cleanerMan;

  String get avatarPath =>
      (image != null && image!.isNotEmpty) ? image! : defaultAvatar;

  factory TechnicianModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TechnicianModel();
    return TechnicianModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      image: json['image'] as String?,
      gender: TechnicianGenderEnum.fromValue(json['gender'] as String?),
      status: TechnicianStatusEnum.fromValue(json['status'] as String?),
      todayTasksCount: json['todayTasksCount'] as int?,
      upcomingBookingsCount: json['upcomingBookingsCount'] as int?,
      completedBookingsCount: json['completedBookingsCount'] as int?,
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

  TechnicianModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? image,
    TechnicianGenderEnum? gender,
    TechnicianStatusEnum? status,
    int? todayTasksCount,
    int? upcomingBookingsCount,
    int? completedBookingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      image: image ?? this.image,
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

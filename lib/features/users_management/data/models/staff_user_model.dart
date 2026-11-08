import 'package:equatable/equatable.dart';
import 'branch_assignment_model.dart';

class StaffUserModel extends Equatable {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final bool? isOwner;
  final String? linkedDoctorId;
  final bool? isActive;
  final bool? mustChangePassword;
  final bool? isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final List<BranchAssignmentModel>? branchAssignments;

  const StaffUserModel({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.jobTitle,
    this.isOwner,
    this.linkedDoctorId,
    this.isActive,
    this.mustChangePassword,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.branchAssignments,
  });

  bool get isPracticingDoctor => linkedDoctorId != null && linkedDoctorId!.isNotEmpty;

  bool get canAuthenticate =>
      isActive == true && isDeleted != true;

  StaffUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? jobTitle,
    bool? isOwner,
    String? linkedDoctorId,
    bool? isActive,
    bool? mustChangePassword,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    List<BranchAssignmentModel>? branchAssignments,
  }) {
    return StaffUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      isOwner: isOwner ?? this.isOwner,
      linkedDoctorId: linkedDoctorId ?? this.linkedDoctorId,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      branchAssignments: branchAssignments ?? this.branchAssignments,
    );
  }

  factory StaffUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StaffUserModel();
    return StaffUserModel(
      id: json['id'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      jobTitle: json['jobTitle'] as String?,
      isOwner: json['isOwner'] as bool?,
      linkedDoctorId: json['linkedDoctorId'] as String?,
      isActive: json['isActive'] as bool?,
      mustChangePassword: json['mustChangePassword'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'].toString())
          : null,
      branchAssignments: (json['branchAssignments'] as List<dynamic>?)
          ?.map((e) =>
              BranchAssignmentModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'jobTitle': jobTitle,
      'isOwner': isOwner,
      'linkedDoctorId': linkedDoctorId,
      'isActive': isActive,
      'mustChangePassword': mustChangePassword,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'branchAssignments': branchAssignments?.map((b) => b.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        jobTitle,
        isOwner,
        linkedDoctorId,
        isActive,
        mustChangePassword,
        isDeleted,
        createdAt,
        updatedAt,
        lastLoginAt,
        branchAssignments,
      ];
}


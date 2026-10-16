import 'package:purexo/shared/auth/data/models/user_model.dart';

class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final AdminRoles roles;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.roles = AdminRoles.admin,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['displayName'] ?? '',
      email: json['userName'] ?? '',
      avatar: json['image'],
      roles: AdminRoles.admin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': name,
      'userName': email,
      'image': avatar,
      'role': roles.name,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    AdminRoles? roles,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      roles: roles ?? this.roles,
    );
  }
}

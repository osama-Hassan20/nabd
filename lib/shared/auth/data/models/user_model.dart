class AdminModel {
  final String id;
  final String accessToken;
  final String refreshToken;
  final String? phoneNumber;
  final String? userName;
  final String? imagePath;
  final AdminRoles adminRoles;

  AdminModel({
    required this.accessToken,
    required this.id,
    this.phoneNumber,
    required this.refreshToken,
    this.userName,
    this.imagePath,
    this.adminRoles = AdminRoles.admin,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['data']?['id'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      phoneNumber: json['data']?['phone'],
      userName: json['data']?['userName'],
      adminRoles: AdminRoles.admin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      "userName": userName,
      "role": adminRoles.name,
    };
  }
}

enum AdminRoles { admin }

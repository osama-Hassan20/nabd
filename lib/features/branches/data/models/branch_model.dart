import '../../../settings/data/models/special_holiday_model.dart';

class BranchModel {
  final String? id;
  final String? name;
  final String? nameKey;
  final String? address;
  final String? phone;
  final String? email;
  final bool? isActive;
  final bool? isMain;
  final String? openingTime;
  final String? closingTime;
  final List<String>? workingDays;
  final List<SpecialHolidayModel>? specialHolidays;
  final int? activeRoomsCount;
  final int? staffMembersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BranchModel({
    this.id,
    this.name,
    this.nameKey,
    this.address,
    this.phone,
    this.email,
    this.isActive,
    this.isMain,
    this.openingTime,
    this.closingTime,
    this.workingDays,
    this.specialHolidays,
    this.activeRoomsCount,
    this.staffMembersCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isBranchActive => isActive ?? true;
  bool get isMainBranch => isMain ?? false;

  factory BranchModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BranchModel();
    return BranchModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      nameKey: json['nameKey'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool?,
      isMain: json['isMain'] as bool?,
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      workingDays: (json['workingDays'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      specialHolidays: (json['specialHolidays'] as List<dynamic>?)
          ?.map((e) => SpecialHolidayModel.fromJson(e as Map<String, dynamic>?))
          .toList(),
      activeRoomsCount: json['activeRoomsCount'] as int?,
      staffMembersCount: json['staffMembersCount'] as int?,
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
      if (nameKey != null) 'nameKey': nameKey,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (isActive != null) 'isActive': isActive,
      if (isMain != null) 'isMain': isMain,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (workingDays != null) 'workingDays': workingDays,
      if (specialHolidays != null)
        'specialHolidays': specialHolidays?.map((e) => e.toJson()).toList(),
      if (activeRoomsCount != null) 'activeRoomsCount': activeRoomsCount,
      if (staffMembersCount != null) 'staffMembersCount': staffMembersCount,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BranchModel copyWith({
    String? id,
    String? name,
    String? nameKey,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    bool? isMain,
    String? openingTime,
    String? closingTime,
    List<String>? workingDays,
    List<SpecialHolidayModel>? specialHolidays,
    int? activeRoomsCount,
    int? staffMembersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      isMain: isMain ?? this.isMain,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      workingDays: workingDays ?? this.workingDays,
      specialHolidays: specialHolidays ?? this.specialHolidays,
      activeRoomsCount: activeRoomsCount ?? this.activeRoomsCount,
      staffMembersCount: staffMembersCount ?? this.staffMembersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


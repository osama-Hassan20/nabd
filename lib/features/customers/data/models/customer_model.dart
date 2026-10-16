import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';

class CustomerModel {
  final String? id;
  final String? name;
  final String? phone;
  final String? address;
  final int? totalBookings;
  final int? upcomingBookings;
  final bool? hasRepeatedBooking;
  final RecurrenceRuleModel? recurrence;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    this.id,
    this.name,
    this.phone,
    this.address,
    this.totalBookings,
    this.upcomingBookings,
    this.hasRepeatedBooking,
    this.recurrence,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CustomerModel();
    return CustomerModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      totalBookings: json['totalBookings'] as int?,
      upcomingBookings: json['upcomingBookings'] as int?,
      hasRepeatedBooking: json['hasRepeatedBooking'] as bool? ??
          (json['has_repeated_booking'] as bool?),
      recurrence: json['recurrence'] != null
          ? RecurrenceRuleModel.fromJson(
              json['recurrence'] as Map<String, dynamic>?)
          : null,
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
      if (address != null) 'address': address,
      if (totalBookings != null) 'totalBookings': totalBookings,
      if (upcomingBookings != null) 'upcomingBookings': upcomingBookings,
      if (hasRepeatedBooking != null) 'hasRepeatedBooking': hasRepeatedBooking,
      if (recurrence != null) 'recurrence': recurrence?.toJson(),
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    int? totalBookings,
    int? upcomingBookings,
    bool? hasRepeatedBooking,
    RecurrenceRuleModel? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalBookings: totalBookings ?? this.totalBookings,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      hasRepeatedBooking: hasRepeatedBooking ?? this.hasRepeatedBooking,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

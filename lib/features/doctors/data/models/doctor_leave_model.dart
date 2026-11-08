import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';

class DoctorLeaveModel {
  final String? id;
  final String? doctorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reason;
  final DateTime? createdAt;

  const DoctorLeaveModel({
    this.id,
    this.doctorId,
    this.startDate,
    this.endDate,
    this.reason,
    this.createdAt,
  });

  String? get technicianId => doctorId;

  int get durationDays {
    if (startDate == null || endDate == null) return 1;
    final diff = endDate!.difference(startDate!).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  bool isCurrentlyActive([DateTime? now]) {
    final current = now ?? CairoTimeHelper.now();
    if (startDate == null || endDate == null) return false;
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      23,
      59,
      59,
    );
    return current.isAfter(start.subtract(const Duration(seconds: 1))) &&
        current.isBefore(end.add(const Duration(seconds: 1)));
  }

  factory DoctorLeaveModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorLeaveModel();
    return DoctorLeaveModel(
      id: json['id']?.toString(),
      doctorId: json['doctorId']?.toString() ?? json['technicianId']?.toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (doctorId != null) 'doctorId': doctorId,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  DoctorLeaveModel copyWith({
    String? id,
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    DateTime? createdAt,
  }) {
    return DoctorLeaveModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


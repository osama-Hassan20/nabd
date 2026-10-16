class TechnicianLeaveModel {
  final String? id;
  final String? technicianId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reason;
  final DateTime? createdAt;

  const TechnicianLeaveModel({
    this.id,
    this.technicianId,
    this.startDate,
    this.endDate,
    this.reason,
    this.createdAt,
  });

  int get durationDays {
    if (startDate == null || endDate == null) return 1;
    final diff = endDate!.difference(startDate!).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  bool isCurrentlyActive([DateTime? now]) {
    final current = now ?? DateTime.now();
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

  factory TechnicianLeaveModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TechnicianLeaveModel();
    return TechnicianLeaveModel(
      id: json['id']?.toString(),
      technicianId: json['technicianId']?.toString(),
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
      if (technicianId != null) 'technicianId': technicianId,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  TechnicianLeaveModel copyWith({
    String? id,
    String? technicianId,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    DateTime? createdAt,
  }) {
    return TechnicianLeaveModel(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

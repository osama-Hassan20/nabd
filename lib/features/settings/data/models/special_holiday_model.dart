class SpecialHolidayModel {
  final String? id;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;

  const SpecialHolidayModel({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
  });

  factory SpecialHolidayModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SpecialHolidayModel();
    return SpecialHolidayModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
    };
  }

  SpecialHolidayModel copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return SpecialHolidayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  int get durationDays {
    if (startDate == null || endDate == null) return 1;
    final diff = endDate!.difference(startDate!).inDays;
    return (diff >= 0 ? diff + 1 : 1);
  }
}

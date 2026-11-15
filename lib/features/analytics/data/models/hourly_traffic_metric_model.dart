import 'package:equatable/equatable.dart';

class HourlyTrafficMetricModel extends Equatable {
  final int? hour;
  final int? dayOfWeek; // 1 (Mon) to 7 (Sun) or custom
  final int? visitsCount;
  final String? occupancyLevel; // 'low', 'medium', 'high', 'peak'

  const HourlyTrafficMetricModel({
    this.hour,
    this.dayOfWeek,
    this.visitsCount,
    this.occupancyLevel,
  });

  HourlyTrafficMetricModel copyWith({
    int? hour,
    int? dayOfWeek,
    int? visitsCount,
    String? occupancyLevel,
  }) {
    return HourlyTrafficMetricModel(
      hour: hour ?? this.hour,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      visitsCount: visitsCount ?? this.visitsCount,
      occupancyLevel: occupancyLevel ?? this.occupancyLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'dayOfWeek': dayOfWeek,
      'visitsCount': visitsCount,
      'occupancyLevel': occupancyLevel,
    };
  }

  factory HourlyTrafficMetricModel.fromMap(Map<String, dynamic> map) {
    return HourlyTrafficMetricModel(
      hour: (map['hour'] as num?)?.toInt(),
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt(),
      visitsCount: (map['visitsCount'] as num?)?.toInt(),
      occupancyLevel: map['occupancyLevel'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        hour,
        dayOfWeek,
        visitsCount,
        occupancyLevel,
      ];
}

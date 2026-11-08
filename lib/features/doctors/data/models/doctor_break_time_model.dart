import 'package:equatable/equatable.dart';

class DoctorBreakTimeModel extends Equatable {
  final String? name;
  final String? startTime; // "HH:mm" 24-hour Latin format
  final String? endTime;   // "HH:mm" 24-hour Latin format

  const DoctorBreakTimeModel({
    this.name,
    this.startTime,
    this.endTime,
  });

  factory DoctorBreakTimeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorBreakTimeModel();
    return DoctorBreakTimeModel(
      name: json['name'] as String?,
      startTime: json['startTime'] as String? ?? json['start_time'] as String?,
      endTime: json['endTime'] as String? ?? json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
    };
  }

  DoctorBreakTimeModel copyWith({
    String? name,
    String? startTime,
    String? endTime,
  }) {
    return DoctorBreakTimeModel(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [name, startTime, endTime];
}


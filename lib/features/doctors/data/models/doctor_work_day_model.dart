import 'package:equatable/equatable.dart';
import 'doctor_break_time_model.dart';
import 'enums/week_day_enum.dart';

class DoctorWorkDayModel extends Equatable {
  final WeekDayEnum? dayOfWeek;
  final bool? isWorking;
  final String? startTime; // "HH:mm" 24-hour Latin format
  final String? endTime;   // "HH:mm" 24-hour Latin format
  final List<DoctorBreakTimeModel>? breaks;

  const DoctorWorkDayModel({
    this.dayOfWeek,
    this.isWorking,
    this.startTime,
    this.endTime,
    this.breaks,
  });

  factory DoctorWorkDayModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorWorkDayModel();
    return DoctorWorkDayModel(
      dayOfWeek: WeekDayEnum.fromValue(
        json['dayOfWeek'] as String? ?? json['day_of_week'] as String?,
      ),
      isWorking: json['isWorking'] as bool? ?? json['is_working'] as bool?,
      startTime: json['startTime'] as String? ?? json['start_time'] as String?,
      endTime: json['endTime'] as String? ?? json['end_time'] as String?,
      breaks: json['breaks'] != null
          ? (json['breaks'] as List)
              .map(
                (b) => DoctorBreakTimeModel.fromJson(
                  b as Map<String, dynamic>?,
                ),
              )
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek?.value,
      if (isWorking != null) 'isWorking': isWorking,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (breaks != null)
        'breaks': breaks?.map((b) => b.toJson()).toList(),
    };
  }

  DoctorWorkDayModel copyWith({
    WeekDayEnum? dayOfWeek,
    bool? isWorking,
    String? startTime,
    String? endTime,
    List<DoctorBreakTimeModel>? breaks,
  }) {
    return DoctorWorkDayModel(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isWorking: isWorking ?? this.isWorking,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breaks: breaks ?? this.breaks,
    );
  }

  @override
  List<Object?> get props => [
        dayOfWeek,
        isWorking,
        startTime,
        endTime,
        breaks,
      ];
}


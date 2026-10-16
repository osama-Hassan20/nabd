import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DayOfWeekOption {
  final String key;
  final String arabicName;
  final String englishName;

  const DayOfWeekOption({
    required this.key,
    required this.arabicName,
    required this.englishName,
  });

  String getName(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return isAr ? arabicName : englishName;
  }

  static const List<DayOfWeekOption> all = [
    DayOfWeekOption(key: 'sunday', arabicName: 'الأحد', englishName: 'Sunday'),
    DayOfWeekOption(key: 'monday', arabicName: 'الاثنين', englishName: 'Monday'),
    DayOfWeekOption(key: 'tuesday', arabicName: 'الثلاثاء', englishName: 'Tuesday'),
    DayOfWeekOption(key: 'wednesday', arabicName: 'الأربعاء', englishName: 'Wednesday'),
    DayOfWeekOption(key: 'thursday', arabicName: 'الخميس', englishName: 'Thursday'),
    DayOfWeekOption(key: 'friday', arabicName: 'الجمعة', englishName: 'Friday'),
    DayOfWeekOption(key: 'saturday', arabicName: 'السبت', englishName: 'Saturday'),
  ];

  static DayOfWeekOption fromKey(String key) {
    return all.firstWhere(
      (d) => d.key == key.toLowerCase(),
      orElse: () => DayOfWeekOption(key: key, arabicName: key, englishName: key),
    );
  }
}

class RecurringDaySchedule {
  final String day; // "sunday", "monday", ...
  final String startTime; // "10:00"
  final String endTime; // "12:00"

  const RecurringDaySchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  RecurringDaySchedule copyWith({
    String? day,
    String? startTime,
    String? endTime,
  }) {
    return RecurringDaySchedule(
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  factory RecurringDaySchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RecurringDaySchedule(day: '', startTime: '', endTime: '');
    }
    return RecurringDaySchedule(
      day: json['day']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringDaySchedule &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => day.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}

class RecurrenceRuleModel {
  final String? frequency; // "weekly", "bi_weekly", "monthly"
  final List<String>? daysOfWeek; // ["sunday", "tuesday"]
  final List<RecurringDaySchedule>? daySchedules; // Multi-day with individual times
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOngoing; // true = مستمر حتى الإلغاء, false = ينتهي في تاريخ محدد

  const RecurrenceRuleModel({
    this.frequency,
    this.daysOfWeek,
    this.daySchedules,
    this.startDate,
    this.endDate,
    this.isOngoing = true,
  });

  factory RecurrenceRuleModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecurrenceRuleModel();

    final dayScheds = (json['daySchedules'] as List<dynamic>?)
        ?.map((e) => RecurringDaySchedule.fromJson(e as Map<String, dynamic>?))
        .toList();

    final days = (json['daysOfWeek'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        dayScheds?.map((e) => e.day).toList();

    return RecurrenceRuleModel(
      frequency: json['frequency'] as String?,
      daysOfWeek: days,
      daySchedules: dayScheds,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      isOngoing: json['isOngoing'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (frequency != null) 'frequency': frequency,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (daySchedules != null)
        'daySchedules': daySchedules!.map((e) => e.toJson()).toList(),
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      'isOngoing': isOngoing,
      if (!isOngoing && endDate != null)
        'endDate': endDate?.toIso8601String(),
    };
  }
}

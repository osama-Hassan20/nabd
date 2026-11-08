import 'package:equatable/equatable.dart';
import 'doctor_work_day_model.dart';

/// DoctorScheduleModel: يمثل جدول دوام الطبيب الأسبوعي وقواعد توليد الفترات.
///
/// معاني الحقول وقواعدها المعتمدة:
/// - [slotDurationMinutes]: الفاصل الزمني لعرض أوقات البدء المتاحة للفترات
///   (مثلاً كل 15 أو 20 أو 30 دقيقة). مدة الكشف نفسها تُحدد عبر الخدمة الطبية
///   (المرحلة 2). النطاق المسموح به: من 5 إلى 120 دقيقة.
/// - [bufferDurationMinutes]: فترة راحة فاصلة بين حالتين متتاليتين (0 إلى 60 دقيقة).
/// - [isAcceptingWalkIns]: هل يقبل الطبيب حالات الكشف الفوري العائم (Walk-in).
class DoctorScheduleModel extends Equatable {
  final String? id;
  final String? doctorId;
  final List<DoctorWorkDayModel>? workDays;
  final int? slotDurationMinutes;
  final int? bufferDurationMinutes;
  final bool? isAcceptingWalkIns;

  const DoctorScheduleModel({
    this.id,
    this.doctorId,
    this.workDays,
    this.slotDurationMinutes,
    this.bufferDurationMinutes,
    this.isAcceptingWalkIns,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorScheduleModel();
    return DoctorScheduleModel(
      id: json['id']?.toString(),
      doctorId: json['doctorId']?.toString() ?? json['doctor_id']?.toString(),
      workDays: json['workDays'] != null || json['work_days'] != null
          ? ((json['workDays'] ?? json['work_days']) as List)
              .map(
                (w) => DoctorWorkDayModel.fromJson(
                  w as Map<String, dynamic>?,
                ),
              )
              .toList()
          : null,
      slotDurationMinutes: json['slotDurationMinutes'] as int? ??
          json['slot_duration_minutes'] as int?,
      bufferDurationMinutes: json['bufferDurationMinutes'] as int? ??
          json['buffer_duration_minutes'] as int?,
      isAcceptingWalkIns: json['isAcceptingWalkIns'] as bool? ??
          json['is_accepting_walk_ins'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (doctorId != null) 'doctorId': doctorId,
      if (workDays != null)
        'workDays': workDays?.map((w) => w.toJson()).toList(),
      if (slotDurationMinutes != null)
        'slotDurationMinutes': slotDurationMinutes,
      if (bufferDurationMinutes != null)
        'bufferDurationMinutes': bufferDurationMinutes,
      if (isAcceptingWalkIns != null)
        'isAcceptingWalkIns': isAcceptingWalkIns,
    };
  }

  DoctorScheduleModel copyWith({
    String? id,
    String? doctorId,
    List<DoctorWorkDayModel>? workDays,
    int? slotDurationMinutes,
    int? bufferDurationMinutes,
    bool? isAcceptingWalkIns,
  }) {
    return DoctorScheduleModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      workDays: workDays ?? this.workDays,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      bufferDurationMinutes:
          bufferDurationMinutes ?? this.bufferDurationMinutes,
      isAcceptingWalkIns: isAcceptingWalkIns ?? this.isAcceptingWalkIns,
    );
  }

  @override
  List<Object?> get props => [
        id,
        doctorId,
        workDays,
        slotDurationMinutes,
        bufferDurationMinutes,
        isAcceptingWalkIns,
      ];
}


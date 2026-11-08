import 'package:equatable/equatable.dart';
import 'enums/slot_status_enum.dart';

/// TimeSlotModel: يمثل فترة زمنية مرشحة أو محجوزة في جدول الطبيب
///
/// القوانين المتبعة:
/// - جميع الحقول nullable دون أي قيم افتراضية أو required في الـ constructor.
/// - الأوقات بتنسيق 24 ساعة بأرقام لاتينية "HH:mm".
/// - لا code generators: الـ copyWith والـ props يدوية.
class TimeSlotModel extends Equatable {
  final String? startTime;
  final String? endTime;
  final String? occupiedEndTime;
  final SlotStatusEnum? status;
  final String? bookedPatientName;
  final String? bookedBookingId;
  final int? serviceDurationMinutes;
  final int? bufferDurationMinutes;
  final bool? isCurrentBookingSlot;
  final String? reasonKey;
  final bool? isMorning;

  const TimeSlotModel({
    this.startTime,
    this.endTime,
    this.occupiedEndTime,
    this.status,
    this.bookedPatientName,
    this.bookedBookingId,
    this.serviceDurationMinutes,
    this.bufferDurationMinutes,
    this.isCurrentBookingSlot,
    this.reasonKey,
    this.isMorning,
  });

  bool get isAvailable => status == SlotStatusEnum.available;
  bool get isBooked => status == SlotStatusEnum.booked;
  bool get isPast => status == SlotStatusEnum.past;
  bool get isBreakTime => status == SlotStatusEnum.breakTime;
  bool get isInsufficientTime => status == SlotStatusEnum.insufficientTime;

  factory TimeSlotModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TimeSlotModel();
    return TimeSlotModel(
      startTime: json['startTime'] as String? ?? json['start_time'] as String?,
      endTime: json['endTime'] as String? ?? json['end_time'] as String?,
      occupiedEndTime: json['occupiedEndTime'] as String? ??
          json['occupied_end_time'] as String?,
      status: json['status'] != null
          ? SlotStatusEnum.fromValue(json['status'] as String?)
          : null,
      bookedPatientName: json['bookedPatientName'] as String? ??
          json['booked_patient_name'] as String?,
      bookedBookingId: json['bookedBookingId'] as String? ??
          json['booked_booking_id'] as String?,
      serviceDurationMinutes: json['serviceDurationMinutes'] as int? ??
          json['service_duration_minutes'] as int?,
      bufferDurationMinutes: json['bufferDurationMinutes'] as int? ??
          json['buffer_duration_minutes'] as int?,
      isCurrentBookingSlot: json['isCurrentBookingSlot'] as bool? ??
          json['is_current_booking_slot'] as bool?,
      reasonKey: json['reasonKey'] as String? ?? json['reason_key'] as String?,
      isMorning: json['isMorning'] as bool? ?? json['is_morning'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (occupiedEndTime != null) 'occupiedEndTime': occupiedEndTime,
      if (status != null) 'status': status?.value,
      if (bookedPatientName != null) 'bookedPatientName': bookedPatientName,
      if (bookedBookingId != null) 'bookedBookingId': bookedBookingId,
      if (serviceDurationMinutes != null)
        'serviceDurationMinutes': serviceDurationMinutes,
      if (bufferDurationMinutes != null)
        'bufferDurationMinutes': bufferDurationMinutes,
      if (isCurrentBookingSlot != null)
        'isCurrentBookingSlot': isCurrentBookingSlot,
      if (reasonKey != null) 'reasonKey': reasonKey,
      if (isMorning != null) 'isMorning': isMorning,
    };
  }

  TimeSlotModel copyWith({
    String? startTime,
    String? endTime,
    String? occupiedEndTime,
    SlotStatusEnum? status,
    String? bookedPatientName,
    String? bookedBookingId,
    int? serviceDurationMinutes,
    int? bufferDurationMinutes,
    bool? isCurrentBookingSlot,
    String? reasonKey,
    bool? isMorning,
  }) {
    return TimeSlotModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      occupiedEndTime: occupiedEndTime ?? this.occupiedEndTime,
      status: status ?? this.status,
      bookedPatientName: bookedPatientName ?? this.bookedPatientName,
      bookedBookingId: bookedBookingId ?? this.bookedBookingId,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      bufferDurationMinutes:
          bufferDurationMinutes ?? this.bufferDurationMinutes,
      isCurrentBookingSlot: isCurrentBookingSlot ?? this.isCurrentBookingSlot,
      reasonKey: reasonKey ?? this.reasonKey,
      isMorning: isMorning ?? this.isMorning,
    );
  }

  @override
  List<Object?> get props => [
        startTime,
        endTime,
        occupiedEndTime,
        status,
        bookedPatientName,
        bookedBookingId,
        serviceDurationMinutes,
        bufferDurationMinutes,
        isCurrentBookingSlot,
        reasonKey,
        isMorning,
      ];
}


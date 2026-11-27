import 'package:equatable/equatable.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import 'enums/visit_status_enum.dart';
import 'visit_model.dart';

class ConsultationQueueItemModel extends Equatable {
  final BookingModel? booking;
  final VisitModel? visit;

  const ConsultationQueueItemModel({
    this.booking,
    this.visit,
  });

  bool get hasActiveVisit => visit?.status == VisitStatusEnum.inProgress;
  bool get isFinalized => visit?.status == VisitStatusEnum.finalized;
  bool get isTriageOnly => visit?.status == VisitStatusEnum.triage;

  String? get bookingId => booking?.id;
  String? get visitId => visit?.id;
  String? get patientName => booking?.patientName ?? visit?.patientName;
  int? get queueNumber => booking?.queueNumber;
  BookingStatusEnum? get bookingStatus => booking?.status;
  VisitStatusEnum? get visitStatus => visit?.status;

  ConsultationQueueItemModel copyWith({
    BookingModel? booking,
    VisitModel? visit,
  }) {
    return ConsultationQueueItemModel(
      booking: booking ?? this.booking,
      visit: visit ?? this.visit,
    );
  }

  factory ConsultationQueueItemModel.fromJson(Map<String, dynamic> json) {
    return ConsultationQueueItemModel(
      booking: json['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
      visit: json['visit'] is Map<String, dynamic>
          ? VisitModel.fromJson(json['visit'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (booking != null) 'booking': booking!.toJson(),
        if (visit != null) 'visit': visit!.toJson(),
      };

  @override
  List<Object?> get props => [booking, visit];
}

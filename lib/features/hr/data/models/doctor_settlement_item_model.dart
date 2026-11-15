import 'package:equatable/equatable.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';

class DoctorSettlementItemModel extends Equatable {
  final String? visitId;
  final String? bookingId;
  final DateTime? recognitionDate;
  final String? branchId;
  final String? patientId;
  final String? patientName;
  final String? serviceName;
  final int? grossFeePiastres;
  final int? discountAmountPiastres;
  final int? netAmountPiastres;
  final int? recognizedAmountPiastres;
  final num? commissionPercentageSnapshot;
  final int? fixedFeeSnapshotPiastres;
  final int? doctorEarnedPiastres;
  final int? clinicSharePiastres;
  final PaymentStatusEnum? paymentStatusSnapshot;
  final bool? isFullyCollected;
  final List<String>? eventIds;

  const DoctorSettlementItemModel({
    this.visitId,
    this.bookingId,
    this.recognitionDate,
    this.branchId,
    this.patientId,
    this.patientName,
    this.serviceName,
    this.grossFeePiastres,
    this.discountAmountPiastres,
    this.netAmountPiastres,
    this.recognizedAmountPiastres,
    this.commissionPercentageSnapshot,
    this.fixedFeeSnapshotPiastres,
    this.doctorEarnedPiastres,
    this.clinicSharePiastres,
    this.paymentStatusSnapshot,
    this.isFullyCollected,
    this.eventIds,
  });

  factory DoctorSettlementItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DoctorSettlementItemModel();
    return DoctorSettlementItemModel(
      visitId: json['visitId'] as String?,
      bookingId: json['bookingId'] as String?,
      recognitionDate: json['recognitionDate'] != null
          ? DateTime.tryParse(json['recognitionDate'].toString())
          : null,
      branchId: json['branchId'] as String?,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      serviceName: json['serviceName'] as String?,
      grossFeePiastres: json['grossFeePiastres'] is num
          ? (json['grossFeePiastres'] as num).toInt()
          : null,
      discountAmountPiastres: json['discountAmountPiastres'] is num
          ? (json['discountAmountPiastres'] as num).toInt()
          : null,
      netAmountPiastres: json['netAmountPiastres'] is num
          ? (json['netAmountPiastres'] as num).toInt()
          : null,
      recognizedAmountPiastres: json['recognizedAmountPiastres'] is num
          ? (json['recognizedAmountPiastres'] as num).toInt()
          : null,
      commissionPercentageSnapshot: json['commissionPercentageSnapshot'] as num?,
      fixedFeeSnapshotPiastres: json['fixedFeeSnapshotPiastres'] is num
          ? (json['fixedFeeSnapshotPiastres'] as num).toInt()
          : null,
      doctorEarnedPiastres: json['doctorEarnedPiastres'] is num
          ? (json['doctorEarnedPiastres'] as num).toInt()
          : null,
      clinicSharePiastres: json['clinicSharePiastres'] is num
          ? (json['clinicSharePiastres'] as num).toInt()
          : null,
      paymentStatusSnapshot: PaymentStatusEnum.fromValue(json['paymentStatusSnapshot'] as String?),
      isFullyCollected: json['isFullyCollected'] as bool?,
      eventIds: (json['eventIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'visitId': visitId,
    'bookingId': bookingId,
    'recognitionDate': recognitionDate?.toIso8601String(),
    'branchId': branchId,
    'patientId': patientId,
    'patientName': patientName,
    'serviceName': serviceName,
    'grossFeePiastres': grossFeePiastres,
    'discountAmountPiastres': discountAmountPiastres,
    'netAmountPiastres': netAmountPiastres,
    'recognizedAmountPiastres': recognizedAmountPiastres,
    'commissionPercentageSnapshot': commissionPercentageSnapshot,
    'fixedFeeSnapshotPiastres': fixedFeeSnapshotPiastres,
    'doctorEarnedPiastres': doctorEarnedPiastres,
    'clinicSharePiastres': clinicSharePiastres,
    'paymentStatusSnapshot': paymentStatusSnapshot?.value,
    'isFullyCollected': isFullyCollected,
    'eventIds': eventIds,
  };

  DoctorSettlementItemModel copyWith({
    String? visitId,
    String? bookingId,
    DateTime? recognitionDate,
    String? branchId,
    String? patientId,
    String? patientName,
    String? serviceName,
    int? grossFeePiastres,
    int? discountAmountPiastres,
    int? netAmountPiastres,
    int? recognizedAmountPiastres,
    num? commissionPercentageSnapshot,
    int? fixedFeeSnapshotPiastres,
    int? doctorEarnedPiastres,
    int? clinicSharePiastres,
    PaymentStatusEnum? paymentStatusSnapshot,
    bool? isFullyCollected,
    List<String>? eventIds,
  }) {
    return DoctorSettlementItemModel(
      visitId: visitId ?? this.visitId,
      bookingId: bookingId ?? this.bookingId,
      recognitionDate: recognitionDate ?? this.recognitionDate,
      branchId: branchId ?? this.branchId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      serviceName: serviceName ?? this.serviceName,
      grossFeePiastres: grossFeePiastres ?? this.grossFeePiastres,
      discountAmountPiastres: discountAmountPiastres ?? this.discountAmountPiastres,
      netAmountPiastres: netAmountPiastres ?? this.netAmountPiastres,
      recognizedAmountPiastres: recognizedAmountPiastres ?? this.recognizedAmountPiastres,
      commissionPercentageSnapshot: commissionPercentageSnapshot ?? this.commissionPercentageSnapshot,
      fixedFeeSnapshotPiastres: fixedFeeSnapshotPiastres ?? this.fixedFeeSnapshotPiastres,
      doctorEarnedPiastres: doctorEarnedPiastres ?? this.doctorEarnedPiastres,
      clinicSharePiastres: clinicSharePiastres ?? this.clinicSharePiastres,
      paymentStatusSnapshot: paymentStatusSnapshot ?? this.paymentStatusSnapshot,
      isFullyCollected: isFullyCollected ?? this.isFullyCollected,
      eventIds: eventIds ?? this.eventIds,
    );
  }

  @override
  List<Object?> get props => [
    visitId,
    bookingId,
    recognitionDate,
    branchId,
    patientId,
    patientName,
    serviceName,
    grossFeePiastres,
    discountAmountPiastres,
    netAmountPiastres,
    recognizedAmountPiastres,
    commissionPercentageSnapshot,
    fixedFeeSnapshotPiastres,
    doctorEarnedPiastres,
    clinicSharePiastres,
    paymentStatusSnapshot,
    isFullyCollected,
    eventIds,
  ];
}


import '../../../../core/enums/payment_method.dart';
import '../../domain/helpers/money.dart';

class RefundTransactionModel {
  final String? id;
  final String? clientRequestId;
  final String? originalPaymentId;
  final String? shiftId;
  final String? branchId;
  final String? bookingId;
  final String? patientId;
  final int? refundAmountPiastres;
  final PaymentMethod? refundMethod;
  final String? reason;
  final String? authorizedByUserId;
  final String? authorizedByName;
  final DateTime? createdAt;

  const RefundTransactionModel({
    this.id,
    this.clientRequestId,
    this.originalPaymentId,
    this.shiftId,
    this.branchId,
    this.bookingId,
    this.patientId,
    this.refundAmountPiastres,
    this.refundMethod,
    this.reason,
    this.authorizedByUserId,
    this.authorizedByName,
    this.createdAt,
  });

  Money get refundAmountMoney => Money(refundAmountPiastres ?? 0);

  bool get isCash => refundMethod == PaymentMethod.cash;

  factory RefundTransactionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefundTransactionModel();
    return RefundTransactionModel(
      id: json['id'] as String?,
      clientRequestId: json['clientRequestId'] as String?,
      originalPaymentId: json['originalPaymentId'] as String?,
      shiftId: json['shiftId'] as String?,
      branchId: json['branchId'] as String?,
      bookingId: json['bookingId'] as String?,
      patientId: json['patientId'] as String?,
      refundAmountPiastres: json['refundAmountPiastres'] as int?,
      refundMethod: json['refundMethod'] != null
          ? PaymentMethod.fromValue(json['refundMethod']?.toString())
          : null,
      reason: json['reason'] as String?,
      authorizedByUserId: json['authorizedByUserId'] as String?,
      authorizedByName: json['authorizedByName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientRequestId != null) 'clientRequestId': clientRequestId,
      if (originalPaymentId != null) 'originalPaymentId': originalPaymentId,
      if (shiftId != null) 'shiftId': shiftId,
      if (branchId != null) 'branchId': branchId,
      if (bookingId != null) 'bookingId': bookingId,
      if (patientId != null) 'patientId': patientId,
      if (refundAmountPiastres != null)
        'refundAmountPiastres': refundAmountPiastres,
      if (refundMethod != null) 'refundMethod': refundMethod?.value,
      if (reason != null) 'reason': reason,
      if (authorizedByUserId != null)
        'authorizedByUserId': authorizedByUserId,
      if (authorizedByName != null) 'authorizedByName': authorizedByName,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  RefundTransactionModel copyWith({
    String? id,
    String? clientRequestId,
    String? originalPaymentId,
    String? shiftId,
    String? branchId,
    String? bookingId,
    String? patientId,
    int? refundAmountPiastres,
    PaymentMethod? refundMethod,
    String? reason,
    String? authorizedByUserId,
    String? authorizedByName,
    DateTime? createdAt,
  }) {
    return RefundTransactionModel(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      originalPaymentId: originalPaymentId ?? this.originalPaymentId,
      shiftId: shiftId ?? this.shiftId,
      branchId: branchId ?? this.branchId,
      bookingId: bookingId ?? this.bookingId,
      patientId: patientId ?? this.patientId,
      refundAmountPiastres: refundAmountPiastres ?? this.refundAmountPiastres,
      refundMethod: refundMethod ?? this.refundMethod,
      reason: reason ?? this.reason,
      authorizedByUserId: authorizedByUserId ?? this.authorizedByUserId,
      authorizedByName: authorizedByName ?? this.authorizedByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

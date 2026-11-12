import '../../../../core/enums/payment_method.dart';
import '../../domain/helpers/money.dart';

class PaymentTransactionModel {
  final String? id;
  final String? clientRequestId;
  final String? shiftId;
  final String? branchId;
  final String? bookingId;
  final String? patientId;
  final String? patientName;
  final int? amountPiastres;
  final PaymentMethod? paymentMethod;
  final String? referenceNumber;
  final String? cashierUserId;
  final String? cashierName;
  final DateTime? createdAt;
  final bool? isRefunded;
  final int? refundedAmountPiastres;
  final bool? isVoidedBySystem;
  final String? notes;

  const PaymentTransactionModel({
    this.id,
    this.clientRequestId,
    this.shiftId,
    this.branchId,
    this.bookingId,
    this.patientId,
    this.patientName,
    this.amountPiastres,
    this.paymentMethod,
    this.referenceNumber,
    this.cashierUserId,
    this.cashierName,
    this.createdAt,
    this.isRefunded,
    this.refundedAmountPiastres,
    this.isVoidedBySystem,
    this.notes,
  });

  Money get amountMoney => Money(amountPiastres ?? 0);
  Money get refundedAmountMoney => Money(refundedAmountPiastres ?? 0);
  Money get effectivePaidMoney =>
      Money((amountPiastres ?? 0) - (refundedAmountPiastres ?? 0));

  bool get isCash => paymentMethod == PaymentMethod.cash;
  bool get isCard => paymentMethod == PaymentMethod.card;
  bool get isBankTransfer => paymentMethod == PaymentMethod.bankTransfer;

  factory PaymentTransactionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PaymentTransactionModel();
    return PaymentTransactionModel(
      id: json['id'] as String?,
      clientRequestId: json['clientRequestId'] as String?,
      shiftId: json['shiftId'] as String?,
      branchId: json['branchId'] as String?,
      bookingId: json['bookingId'] as String?,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      amountPiastres: json['amountPiastres'] as int?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.fromValue(json['paymentMethod']?.toString())
          : null,
      referenceNumber: json['referenceNumber'] as String?,
      cashierUserId: json['cashierUserId'] as String?,
      cashierName: json['cashierName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isRefunded: json['isRefunded'] as bool?,
      refundedAmountPiastres: json['refundedAmountPiastres'] as int?,
      isVoidedBySystem: json['isVoidedBySystem'] as bool?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientRequestId != null) 'clientRequestId': clientRequestId,
      if (shiftId != null) 'shiftId': shiftId,
      if (branchId != null) 'branchId': branchId,
      if (bookingId != null) 'bookingId': bookingId,
      if (patientId != null) 'patientId': patientId,
      if (patientName != null) 'patientName': patientName,
      if (amountPiastres != null) 'amountPiastres': amountPiastres,
      if (paymentMethod != null) 'paymentMethod': paymentMethod?.value,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (cashierUserId != null) 'cashierUserId': cashierUserId,
      if (cashierName != null) 'cashierName': cashierName,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (isRefunded != null) 'isRefunded': isRefunded,
      if (refundedAmountPiastres != null)
        'refundedAmountPiastres': refundedAmountPiastres,
      if (isVoidedBySystem != null) 'isVoidedBySystem': isVoidedBySystem,
      if (notes != null) 'notes': notes,
    };
  }

  PaymentTransactionModel copyWith({
    String? id,
    String? clientRequestId,
    String? shiftId,
    String? branchId,
    String? bookingId,
    String? patientId,
    String? patientName,
    int? amountPiastres,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    String? cashierUserId,
    String? cashierName,
    DateTime? createdAt,
    bool? isRefunded,
    int? refundedAmountPiastres,
    bool? isVoidedBySystem,
    String? notes,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      shiftId: shiftId ?? this.shiftId,
      branchId: branchId ?? this.branchId,
      bookingId: bookingId ?? this.bookingId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      amountPiastres: amountPiastres ?? this.amountPiastres,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      cashierUserId: cashierUserId ?? this.cashierUserId,
      cashierName: cashierName ?? this.cashierName,
      createdAt: createdAt ?? this.createdAt,
      isRefunded: isRefunded ?? this.isRefunded,
      refundedAmountPiastres:
          refundedAmountPiastres ?? this.refundedAmountPiastres,
      isVoidedBySystem: isVoidedBySystem ?? this.isVoidedBySystem,
      notes: notes ?? this.notes,
    );
  }
}

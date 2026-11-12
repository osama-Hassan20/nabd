import '../../domain/helpers/money.dart';
import 'enums/cash_movement_type_enum.dart';

class CashMovementModel {
  final String? id;
  final String? clientRequestId;
  final String? shiftId;
  final String? branchId;
  final CashMovementTypeEnum? movementType;
  final int? amountPiastres;
  final String? reason;
  final String? recipientName;
  final String? performedByUserId;
  final DateTime? createdAt;

  const CashMovementModel({
    this.id,
    this.clientRequestId,
    this.shiftId,
    this.branchId,
    this.movementType,
    this.amountPiastres,
    this.reason,
    this.recipientName,
    this.performedByUserId,
    this.createdAt,
  });

  Money get amountMoney => Money(amountPiastres ?? 0);

  bool get isOutflow => movementType?.isOutflow ?? true;
  bool get isInflow => movementType?.isInflow ?? false;

  factory CashMovementModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CashMovementModel();
    return CashMovementModel(
      id: json['id'] as String?,
      clientRequestId: json['clientRequestId'] as String?,
      shiftId: json['shiftId'] as String?,
      branchId: json['branchId'] as String?,
      movementType: json['movementType'] != null
          ? CashMovementTypeEnum.fromValue(json['movementType']?.toString())
          : null,
      amountPiastres: json['amountPiastres'] as int?,
      reason: json['reason'] as String?,
      recipientName: json['recipientName'] as String?,
      performedByUserId: json['performedByUserId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (clientRequestId != null) 'clientRequestId': clientRequestId,
      if (shiftId != null) 'shiftId': shiftId,
      if (branchId != null) 'branchId': branchId,
      if (movementType != null) 'movementType': movementType?.value,
      if (amountPiastres != null) 'amountPiastres': amountPiastres,
      if (reason != null) 'reason': reason,
      if (recipientName != null) 'recipientName': recipientName,
      if (performedByUserId != null)
        'performedByUserId': performedByUserId,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  CashMovementModel copyWith({
    String? id,
    String? clientRequestId,
    String? shiftId,
    String? branchId,
    CashMovementTypeEnum? movementType,
    int? amountPiastres,
    String? reason,
    String? recipientName,
    String? performedByUserId,
    DateTime? createdAt,
  }) {
    return CashMovementModel(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      shiftId: shiftId ?? this.shiftId,
      branchId: branchId ?? this.branchId,
      movementType: movementType ?? this.movementType,
      amountPiastres: amountPiastres ?? this.amountPiastres,
      reason: reason ?? this.reason,
      recipientName: recipientName ?? this.recipientName,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

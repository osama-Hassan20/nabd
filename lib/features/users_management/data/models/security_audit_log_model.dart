import 'package:equatable/equatable.dart';

class SecurityAuditLogModel extends Equatable {
  final String? id;
  final String? eventType;
  final String? targetUserId;
  final String? performedByUserId;
  final String? branchId;
  final String? details;
  final DateTime? timestamp;

  const SecurityAuditLogModel({
    this.id,
    this.eventType,
    this.targetUserId,
    this.performedByUserId,
    this.branchId,
    this.details,
    this.timestamp,
  });

  SecurityAuditLogModel copyWith({
    String? id,
    String? eventType,
    String? targetUserId,
    String? performedByUserId,
    String? branchId,
    String? details,
    DateTime? timestamp,
  }) {
    return SecurityAuditLogModel(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      targetUserId: targetUserId ?? this.targetUserId,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      branchId: branchId ?? this.branchId,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SecurityAuditLogModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SecurityAuditLogModel();
    return SecurityAuditLogModel(
      id: json['id'] as String?,
      eventType: json['eventType'] as String?,
      targetUserId: json['targetUserId'] as String?,
      performedByUserId: json['performedByUserId'] as String?,
      branchId: json['branchId'] as String?,
      details: json['details'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventType': eventType,
      'targetUserId': targetUserId,
      'performedByUserId': performedByUserId,
      'branchId': branchId,
      'details': details,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        targetUserId,
        performedByUserId,
        branchId,
        details,
        timestamp,
      ];
}


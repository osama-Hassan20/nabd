import 'package:equatable/equatable.dart';

class SecurityAuditLogModel extends Equatable {
  final String? id;
  final String? eventType;
  final String? targetUserId;
  final String? targetUserName;
  final String? performedByUserId;
  final String? performedByUserName;
  final String? branchId;
  final String? branchName;
  final String? details;
  final String? ipAddress;
  final DateTime? timestamp;

  const SecurityAuditLogModel({
    this.id,
    this.eventType,
    this.targetUserId,
    this.targetUserName,
    this.performedByUserId,
    this.performedByUserName,
    this.branchId,
    this.branchName,
    this.details,
    this.ipAddress,
    this.timestamp,
  });

  SecurityAuditLogModel copyWith({
    String? id,
    String? eventType,
    String? targetUserId,
    String? targetUserName,
    String? performedByUserId,
    String? performedByUserName,
    String? branchId,
    String? branchName,
    String? details,
    String? ipAddress,
    DateTime? timestamp,
  }) {
    return SecurityAuditLogModel(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      performedByUserName: performedByUserName ?? this.performedByUserName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      details: details ?? this.details,
      ipAddress: ipAddress ?? this.ipAddress,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SecurityAuditLogModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SecurityAuditLogModel();
    return SecurityAuditLogModel(
      id: json['id'] as String?,
      eventType: json['eventType'] as String?,
      targetUserId: json['targetUserId'] as String?,
      targetUserName: json['targetUserName'] as String?,
      performedByUserId: json['performedByUserId'] as String?,
      performedByUserName: json['performedByUserName'] as String?,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      details: json['details'] as String?,
      ipAddress: json['ipAddress'] as String?,
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
      'targetUserName': targetUserName,
      'performedByUserId': performedByUserId,
      'performedByUserName': performedByUserName,
      'branchId': branchId,
      'branchName': branchName,
      'details': details,
      'ipAddress': ipAddress,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        eventType,
        targetUserId,
        targetUserName,
        performedByUserId,
        performedByUserName,
        branchId,
        branchName,
        details,
        ipAddress,
        timestamp,
      ];
}

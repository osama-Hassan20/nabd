import 'package:equatable/equatable.dart';

class ConflictRecord extends Equatable {
  final String conflictId;
  final String entityType;
  final String localId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> serverVersion;
  final DateTime detectedAt;
  final bool isResolved;
  final Map<String, dynamic>? resolvedPayload;

  const ConflictRecord({
    required this.conflictId,
    required this.entityType,
    required this.localId,
    required this.localVersion,
    required this.serverVersion,
    required this.detectedAt,
    this.isResolved = false,
    this.resolvedPayload,
  });

  ConflictRecord copyWith({
    String? conflictId,
    String? entityType,
    String? localId,
    Map<String, dynamic>? localVersion,
    Map<String, dynamic>? serverVersion,
    DateTime? detectedAt,
    bool? isResolved,
    Map<String, dynamic>? resolvedPayload,
  }) {
    return ConflictRecord(
      conflictId: conflictId ?? this.conflictId,
      entityType: entityType ?? this.entityType,
      localId: localId ?? this.localId,
      localVersion: localVersion ?? this.localVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      detectedAt: detectedAt ?? this.detectedAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedPayload: resolvedPayload ?? this.resolvedPayload,
    );
  }

  Map<String, dynamic> toJson() => {
        'conflictId': conflictId,
        'entityType': entityType,
        'localId': localId,
        'localVersion': localVersion,
        'serverVersion': serverVersion,
        'detectedAt': detectedAt.toIso8601String(),
        'isResolved': isResolved,
        'resolvedPayload': resolvedPayload,
      };

  factory ConflictRecord.fromJson(Map<String, dynamic> json) => ConflictRecord(
        conflictId: json['conflictId'] as String,
        entityType: json['entityType'] as String,
        localId: json['localId'] as String,
        localVersion: Map<String, dynamic>.from(json['localVersion'] as Map),
        serverVersion: Map<String, dynamic>.from(json['serverVersion'] as Map),
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        isResolved: json['isResolved'] as bool? ?? false,
        resolvedPayload: json['resolvedPayload'] != null
            ? Map<String, dynamic>.from(json['resolvedPayload'] as Map)
            : null,
      );

  @override
  List<Object?> get props => [
        conflictId,
        entityType,
        localId,
        localVersion,
        serverVersion,
        detectedAt,
        isResolved,
        resolvedPayload,
      ];
}

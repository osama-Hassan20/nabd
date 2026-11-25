import 'package:equatable/equatable.dart';
import 'sync_status.dart';

class OutboxEntry extends Equatable {
  final String operationId;
  final String entityType;
  final String localId;
  final OutboxOperationType operation;
  final Map<String, dynamic> payload;
  final int baseRevision;
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;
  final OutboxStatus status;
  final List<String> dependencyRefs;

  const OutboxEntry({
    required this.operationId,
    required this.entityType,
    required this.localId,
    required this.operation,
    required this.payload,
    required this.baseRevision,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.status = OutboxStatus.pending,
    this.dependencyRefs = const [],
  });

  OutboxEntry copyWith({
    String? operationId,
    String? entityType,
    String? localId,
    OutboxOperationType? operation,
    Map<String, dynamic>? payload,
    int? baseRevision,
    DateTime? createdAt,
    int? attemptCount,
    String? lastError,
    OutboxStatus? status,
    List<String>? dependencyRefs,
  }) {
    return OutboxEntry(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      localId: localId ?? this.localId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      baseRevision: baseRevision ?? this.baseRevision,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      dependencyRefs: dependencyRefs ?? this.dependencyRefs,
    );
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'entityType': entityType,
        'localId': localId,
        'operation': operation.name,
        'payload': payload,
        'baseRevision': baseRevision,
        'createdAt': createdAt.toIso8601String(),
        'attemptCount': attemptCount,
        'lastError': lastError,
        'status': status.name,
        'dependencyRefs': dependencyRefs,
      };

  factory OutboxEntry.fromJson(Map<String, dynamic> json) => OutboxEntry(
        operationId: json['operationId'] as String,
        entityType: json['entityType'] as String,
        localId: json['localId'] as String,
        operation: OutboxOperationType.values.byName(json['operation'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        baseRevision: json['baseRevision'] as int? ?? 1,
        createdAt: DateTime.parse(json['createdAt'] as String),
        attemptCount: json['attemptCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
        status: OutboxStatus.values.byName(json['status'] as String),
        dependencyRefs: (json['dependencyRefs'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        operationId,
        entityType,
        localId,
        operation,
        payload,
        baseRevision,
        createdAt,
        attemptCount,
        lastError,
        status,
        dependencyRefs,
      ];
}

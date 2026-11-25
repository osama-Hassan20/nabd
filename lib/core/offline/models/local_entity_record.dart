import 'package:equatable/equatable.dart';
import 'sync_status.dart';

class LocalEntityRecord extends Equatable {
  final String localId;
  final String entityType;
  final String? serverId;
  final String accountId;
  final String branchId;
  final Map<String, dynamic> payload;
  final int localRevision;
  final String? serverCursor;
  final SyncStatus syncStatus;
  final bool isProvisional;
  final bool isTombstone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalEntityRecord({
    required this.localId,
    required this.entityType,
    this.serverId,
    required this.accountId,
    required this.branchId,
    required this.payload,
    this.localRevision = 1,
    this.serverCursor,
    this.syncStatus = SyncStatus.synced,
    this.isProvisional = false,
    this.isTombstone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  LocalEntityRecord copyWith({
    String? localId,
    String? entityType,
    String? serverId,
    String? accountId,
    String? branchId,
    Map<String, dynamic>? payload,
    int? localRevision,
    String? serverCursor,
    SyncStatus? syncStatus,
    bool? isProvisional,
    bool? isTombstone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalEntityRecord(
      localId: localId ?? this.localId,
      entityType: entityType ?? this.entityType,
      serverId: serverId ?? this.serverId,
      accountId: accountId ?? this.accountId,
      branchId: branchId ?? this.branchId,
      payload: payload ?? this.payload,
      localRevision: localRevision ?? this.localRevision,
      serverCursor: serverCursor ?? this.serverCursor,
      syncStatus: syncStatus ?? this.syncStatus,
      isProvisional: isProvisional ?? this.isProvisional,
      isTombstone: isTombstone ?? this.isTombstone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'entityType': entityType,
        'serverId': serverId,
        'accountId': accountId,
        'branchId': branchId,
        'payload': payload,
        'localRevision': localRevision,
        'serverCursor': serverCursor,
        'syncStatus': syncStatus.name,
        'isProvisional': isProvisional,
        'isTombstone': isTombstone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalEntityRecord.fromJson(Map<String, dynamic> json) =>
      LocalEntityRecord(
        localId: json['localId'] as String,
        entityType: json['entityType'] as String,
        serverId: json['serverId'] as String?,
        accountId: json['accountId'] as String? ?? 'default',
        branchId: json['branchId'] as String? ?? 'branch_1',
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        localRevision: json['localRevision'] as int? ?? 1,
        serverCursor: json['serverCursor'] as String?,
        syncStatus: SyncStatus.values.byName(json['syncStatus'] as String),
        isProvisional: json['isProvisional'] as bool? ?? false,
        isTombstone: json['isTombstone'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  List<Object?> get props => [
        localId,
        entityType,
        serverId,
        accountId,
        branchId,
        payload,
        localRevision,
        serverCursor,
        syncStatus,
        isProvisional,
        isTombstone,
        createdAt,
        updatedAt,
      ];
}

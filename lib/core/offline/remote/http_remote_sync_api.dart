import 'package:dio/dio.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/remote/remote_sync_api.dart';

/// Real HTTP implementation of [RemoteSyncApi] backed by [ApiConsumer] (Dio).
///
/// Registered when `BACKEND_MODE=remote`.
class HttpRemoteSyncApi implements RemoteSyncApi {
  final ApiConsumer apiConsumer;

  HttpRemoteSyncApi({required this.apiConsumer});

  @override
  Future<SyncPushResult> pushOperation(OutboxEntry entry) async {
    final batch = await pushBatch([entry]);
    return batch.getResultFor(entry.operationId) ??
        SyncPushResult(
          success: batch.success,
          operationId: entry.operationId,
          errorMessage: batch.errorMessage,
        );
  }

  @override
  Future<BatchPushResult> pushBatch(List<OutboxEntry> operations) async {
    if (operations.isEmpty) {
      return const BatchPushResult(success: true, operationResults: []);
    }
    try {
      final response = await apiConsumer.post(
        path: 'sync/push',
        options: IdempotencyHelper.options(operations.first.operationId),
        body: {
          'operations': operations
              .map(
                (op) => {
                  'operationId': op.operationId,
                  'entityType': op.entityType,
                  'localId': op.localId,
                  'operation': op.operation.name,
                  'payload': op.payload,
                  'baseRevision': op.baseRevision,
                  'dependencyRefs': op.dependencyRefs,
                },
              )
              .toList(),
        },
      );

      final data = response is Map<String, dynamic>
          ? (response['data'] as Map<String, dynamic>? ?? response)
          : <String, dynamic>{};
      final rawResults = (data['results'] as List<dynamic>?) ?? const [];

      final results = rawResults.map((r) {
        final map = Map<String, dynamic>.from(r as Map);
        return SyncPushResult(
          success: map['success'] == true,
          operationId: (map['operationId'] ?? '').toString(),
          serverId: map['serverId'] as String?,
          serverCursor: map['serverCursor'] as String?,
          confirmedRevision: (map['confirmedRevision'] as num?)?.toInt(),
          hasConflict: map['hasConflict'] == true,
          serverConflictVersion: map['serverConflictVersion'] is Map
              ? Map<String, dynamic>.from(map['serverConflictVersion'] as Map)
              : null,
          errorMessage: map['errorMessage'] as String?,
          isRetryable: map['isRetryable'] != false,
        );
      }).toList();

      return BatchPushResult(
        success: true,
        operationResults: results,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final isPermanent = status == 400 || status == 422 || status == 409;
      return BatchPushResult(
        success: false,
        errorMessage: e.message ?? 'Sync HTTP error ($status)',
        operationResults: operations
            .map(
              (op) => SyncPushResult(
                success: false,
                operationId: op.operationId,
                hasConflict: status == 409,
                errorMessage: e.message ?? 'Sync HTTP error ($status)',
                isRetryable: !isPermanent,
              ),
            )
            .toList(),
      );
    }
  }

  @override
  Future<SyncPullResult> pullChanges({
    required String entityType,
    String? cursor,
  }) async {
    final response = await apiConsumer.get(
      path: 'sync/pull',
      queryParameters: {
        'entityType': entityType,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final data = response is Map<String, dynamic>
        ? (response['data'] as Map<String, dynamic>? ?? response)
        : <String, dynamic>{};
    final rawChanges = (data['changes'] as List<dynamic>?) ?? const [];

    final changes = rawChanges.map((c) {
      final map = Map<String, dynamic>.from(c as Map);
      return RemoteEntityChange(
        serverId: (map['serverId'] ?? '').toString(),
        localId: map['localId'] as String?,
        entityType: (map['entityType'] ?? entityType).toString(),
        revision: (map['revision'] as num?)?.toInt() ?? 0,
        isDeleted: map['isDeleted'] == true,
        payload: Map<String, dynamic>.from((map['payload'] as Map?) ?? {}),
      );
    }).toList();

    return SyncPullResult(
      success: true,
      newCursor: (data['newCursor'] ?? cursor ?? '').toString(),
      changes: changes,
    );
  }
}

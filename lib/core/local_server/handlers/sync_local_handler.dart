import 'package:eyadty/core/local_server/local_server_router.dart';

/// Local server simulation for `/sync/push` and `/sync/pull`.
///
/// Enforces:
/// - idempotency keyed by `operationId`
/// - `dependencyRefs` ordering & `skipped_dependency_failed`
/// - `baseRevision` 409 conflict detection
/// - opaque server-issued cursor (`cursor_N`)
/// - tombstones (`isDeleted: true`)
class SyncLocalHandler {
  SyncLocalHandler._();

  static int _cursorSeq = 1;

  static void register(LocalServerRouter router) {
    router.register('POST', 'sync/push', (req) async {
      final rawOps = (req.body['operations'] as List?) ?? const [];
      final ops = rawOps
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final processed = router.db.collection('syncProcessedOps');
      final entities = router.db.collection('syncEntities');
      final changelog = router.db.collection('syncChangelog');

      final failedEntities = <String>{};
      final results = <Map<String, dynamic>>[];

      for (final op in ops) {
        final operationId = (op['operationId'] ?? '').toString();
        final entityType = (op['entityType'] ?? '').toString();
        final localId = (op['localId'] ?? '').toString();
        final operation = (op['operation'] ?? 'create').toString();
        final baseRevision = (op['baseRevision'] as num?)?.toInt() ?? 1;
        final payload =
            Map<String, dynamic>.from((op['payload'] as Map?) ?? {});
        final deps = ((op['dependencyRefs'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();

        // 1. Idempotency replay by operationId
        final prevIdx =
            processed.indexWhere((p) => p['operationId'] == operationId);
        if (prevIdx != -1) {
          results.add(Map<String, dynamic>.from(
              processed[prevIdx]['result'] as Map));
          continue;
        }

        // 2. Dependency check
        final entityKey = '$entityType:$localId';
        final depFailed = deps.any((d) => failedEntities.contains(d));
        if (depFailed) {
          failedEntities.add(entityKey);
          results.add({
            'success': false,
            'operationId': operationId,
            'hasConflict': false,
            'errorMessage': 'skipped_dependency_failed',
            'isRetryable': false,
          });
          continue;
        }

        // 3. Conflict check against current server revision
        final existingIdx = entities.indexWhere(
          (e) =>
              e['entityType'] == entityType &&
              (e['localId'] == localId || e['serverId'] == localId),
        );
        if (existingIdx != -1) {
          final currentRev =
              (entities[existingIdx]['revision'] as num?)?.toInt() ?? 1;
          if (baseRevision < currentRev) {
            failedEntities.add(entityKey);
            final conflictRes = <String, dynamic>{
              'success': false,
              'operationId': operationId,
              'hasConflict': true,
              'serverConflictVersion': Map<String, dynamic>.from(
                  entities[existingIdx]['payload'] as Map? ?? {}),
              'errorMessage': 'Version conflict: Record was updated remotely',
              'isRetryable': false,
            };
            processed.add({
              'operationId': operationId,
              'result': conflictRes,
            });
            results.add(conflictRes);
            continue;
          }
        }

        // 4. Apply operation
        final serverId = existingIdx != -1
            ? (entities[existingIdx]['serverId'] ?? 'SRV-$localId').toString()
            : 'SRV-$localId';
        final confirmedRevision = baseRevision + 1;
        final seq = _cursorSeq++;
        final serverCursor = 'cursor_$seq';
        final isDeleted = operation == 'delete';

        final record = {
          'seq': seq,
          'serverId': serverId,
          'localId': localId,
          'entityType': entityType,
          'revision': confirmedRevision,
          'isDeleted': isDeleted,
          'payload': payload,
        };
        if (existingIdx != -1) {
          entities[existingIdx] = record;
        } else {
          entities.add(record);
        }
        changelog.add(record);

        final okRes = <String, dynamic>{
          'success': true,
          'operationId': operationId,
          'serverId': serverId,
          'serverCursor': serverCursor,
          'confirmedRevision': confirmedRevision,
          'hasConflict': false,
          'isRetryable': true,
        };
        processed.add({
          'operationId': operationId,
          'result': okRes,
        });
        results.add(okRes);
      }

      router.db.persist();
      return LocalServerRouter.ok({'results': results});
    });

    router.register('GET', 'sync/pull', (req) async {
      final entityType = req.queryParameters['entityType']?.toString() ?? '';
      final cursor = req.queryParameters['cursor']?.toString();
      final afterSeq = (cursor != null && cursor.startsWith('cursor_'))
          ? (int.tryParse(cursor.substring('cursor_'.length)) ?? 0)
          : 0;

      final changes = router.db.collection('syncChangelog').where((c) {
        if (entityType.isNotEmpty && c['entityType'] != entityType) {
          return false;
        }
        final seq = (c['seq'] as num?)?.toInt() ?? 0;
        return seq > afterSeq;
      }).toList();

      var maxSeq = afterSeq;
      for (final c in changes) {
        final seq = (c['seq'] as num?)?.toInt() ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
      final newCursor = maxSeq > 0 ? 'cursor_$maxSeq' : (cursor ?? 'cursor_0');

      return LocalServerRouter.ok({
        'newCursor': newCursor,
        'changes': changes,
      });
    });
  }
}

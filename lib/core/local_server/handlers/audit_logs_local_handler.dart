import 'package:eyadty/core/local_server/local_server_router.dart';

class AuditLogsLocalHandler {
  AuditLogsLocalHandler._();

  static List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> logs,
    Map<String, dynamic> qp,
  ) {
    var items = List<Map<String, dynamic>>.from(logs);
    final targetUserId = qp['targetUserId']?.toString();
    if (targetUserId != null && targetUserId.isNotEmpty) {
      items = items.where((l) => l['targetUserId'] == targetUserId).toList();
    }
    final performedBy = qp['performedByUserId']?.toString();
    if (performedBy != null && performedBy.isNotEmpty) {
      items = items.where((l) => l['performedByUserId'] == performedBy).toList();
    }
    final eventType = qp['eventType']?.toString();
    if (eventType != null && eventType.isNotEmpty) {
      items = items.where((l) => l['eventType'] == eventType).toList();
    }
    final branchId = qp['branchId']?.toString();
    if (branchId != null && branchId.isNotEmpty) {
      items = items.where((l) => l['branchId'] == branchId).toList();
    }
    final q = qp['searchQuery']?.toString().trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      items = items.where((l) {
        final d = (l['details'] ?? '').toString().toLowerCase();
        final e = (l['eventType'] ?? '').toString().toLowerCase();
        return d.contains(q) || e.contains(q);
      }).toList();
    }
    return items;
  }

  static void register(LocalServerRouter router) {
    router.register('GET', 'audit-logs', (req) async {
      final items = _filter(router.db.collection('auditLogs'), req.queryParameters);
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'audit-logs/export', (req) async {
      final items = _filter(router.db.collection('auditLogs'), req.queryParameters);
      final buf = StringBuffer('ID,Timestamp,EventType,Actor,Target,Branch,IP,Details\n');
      for (final l in items) {
        buf.writeln(
          '${l['id'] ?? ''},${l['timestamp'] ?? ''},${l['eventType'] ?? ''},${l['performedByUserName'] ?? l['performedByUserId'] ?? ''},${l['targetUserName'] ?? l['targetUserId'] ?? ''},${l['branchId'] ?? ''},${l['ipAddress'] ?? ''},${l['details'] ?? ''}',
        );
      }
      return LocalServerRouter.ok({'csv': buf.toString()});
    });

    router.register('GET', 'audit-logs/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('auditLogs').cast<Map<String, dynamic>?>().firstWhere(
            (l) => l!['id'] == id,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'audit_log_not_found');
      }
      return LocalServerRouter.ok(item);
    });
  }
}

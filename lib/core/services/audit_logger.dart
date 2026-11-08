import '../../features/users_management/data/models/security_audit_log_model.dart';
import '../utils/helpers/cairo_time_helper.dart';

abstract class AuditLogger {
  void log({
    required String eventType,
    String? targetUserId,
    String? performedByUserId,
    String? branchId,
    String? details,
  });

  List<SecurityAuditLogModel> getLogs({
    String? targetUserId,
    String? eventType,
  });
}

class InMemoryAuditLogger implements AuditLogger {
  final List<SecurityAuditLogModel> _logs = [];
  int _counter = 1;

  static final RegExp _sensitiveKeywords = RegExp(
    r'(password|passwd|token|jwt|secret|key|pin|bearer)\s*[:=]\s*([^\s,;]+)',
    caseSensitive: false,
  );

  @override
  void log({
    required String eventType,
    String? targetUserId,
    String? performedByUserId,
    String? branchId,
    String? details,
  }) {
    final sanitizedDetails = _sanitize(details);
    final entry = SecurityAuditLogModel(
      id: 'AUD-${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
      eventType: eventType,
      targetUserId: targetUserId,
      performedByUserId: performedByUserId,
      branchId: branchId,
      details: sanitizedDetails,
      timestamp: CairoTimeHelper.now(),
    );
    _logs.add(entry);
  }

  @override
  List<SecurityAuditLogModel> getLogs({
    String? targetUserId,
    String? eventType,
  }) {
    var result = List<SecurityAuditLogModel>.from(_logs);
    if (targetUserId != null) {
      result = result.where((e) => e.targetUserId == targetUserId).toList();
    }
    if (eventType != null) {
      result = result.where((e) => e.eventType == eventType).toList();
    }
    return List.unmodifiable(result);
  }

  String? _sanitize(String? input) {
    if (input == null) return null;
    return input.replaceAllMapped(_sensitiveKeywords, (match) {
      final key = match.group(1);
      return '$key=[REDACTED]';
    });
  }
}

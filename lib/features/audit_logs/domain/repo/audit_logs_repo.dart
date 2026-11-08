import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../users_management/data/models/security_audit_log_model.dart';

abstract class AuditLogsRepo {
  Future<Either<Failures, List<SecurityAuditLogModel>>> getAuditLogs({
    String? targetUserId,
    String? performedByUserId,
    String? eventType,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  });

  Future<Either<Failures, SecurityAuditLogModel>> getAuditLogById(String id);

  Future<Either<Failures, String>> exportAuditLogs({
    String? eventType,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  });
}


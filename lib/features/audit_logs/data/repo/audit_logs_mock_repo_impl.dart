import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../users_management/data/models/security_audit_log_model.dart';
import '../../domain/repo/audit_logs_repo.dart';

class AuditLogsMockRepoImpl implements AuditLogsRepo {
  final AuditLogger auditLogger;

  AuditLogsMockRepoImpl({required this.auditLogger});

  @override
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
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final logs = auditLogger.getLogs(
        targetUserId: targetUserId,
        performedByUserId: performedByUserId,
        eventType: eventType,
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery,
        limit: limit,
        offset: offset,
      );
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, SecurityAuditLogModel>> getAuditLogById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final logs = auditLogger.getLogs();
      final match = logs.where((e) => e.id == id).firstOrNull;
      if (match == null) {
        return const Left(ServerFailure(errMessage: 'audit_log_not_found'));
      }
      return Right(match);
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> exportAuditLogs({
    String? eventType,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final logs = auditLogger.getLogs(
        eventType: eventType,
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
      );
      final buffer = StringBuffer();
      buffer.writeln('ID,Timestamp,EventType,Actor,Target,Branch,IP,Details');
      for (final log in logs) {
        buffer.writeln(
          '${log.id},${log.timestamp?.toIso8601String()},${log.eventType},"${log.performedByUserName ?? ''}","${log.targetUserName ?? ''}","${log.branchName ?? ''}",${log.ipAddress ?? ''},"${log.details ?? ''}"',
        );
      }
      return Right(buffer.toString());
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}


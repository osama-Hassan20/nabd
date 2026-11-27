import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../users_management/data/models/security_audit_log_model.dart';
import '../../domain/repo/audit_logs_repo.dart';

class AuditLogsRepoImpl implements AuditLogsRepo {
  final ApiConsumer? _apiConsumer;
  final AuditLogger? auditLogger;

  AuditLogsRepoImpl({
    ApiConsumer? apiConsumer,
    this.auditLogger,
  }) : _apiConsumer = apiConsumer;

  bool get _hasApi => _apiConsumer != null || getIt.isRegistered<ApiConsumer>();
  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

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
      if (!_hasApi && auditLogger != null) {
        return Right(
          auditLogger!.getLogs(
            targetUserId: targetUserId,
            performedByUserId: performedByUserId,
            eventType: eventType,
            branchId: branchId,
            startDate: startDate,
            endDate: endDate,
            searchQuery: searchQuery,
            limit: limit,
            offset: offset,
          ),
        );
      }
      final res = await _api.get(
        path: 'audit-logs',
        queryParameters: {
          if (targetUserId != null) 'targetUserId': targetUserId,
          if (performedByUserId != null) 'performedByUserId': performedByUserId,
          if (eventType != null) 'eventType': eventType,
          if (branchId != null) 'branchId': branchId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (searchQuery != null) 'searchQuery': searchQuery,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => SecurityAuditLogModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, SecurityAuditLogModel>> getAuditLogById(String id) async {
    try {
      if (!_hasApi && auditLogger != null) {
        final logs = auditLogger!.getLogs();
        final match = logs.cast<SecurityAuditLogModel?>().firstWhere(
              (l) => l!.id == id,
              orElse: () => null,
            );
        if (match != null) return Right(match);
        return const Left(ServerFailure(errMessage: 'audit_log_not_found'));
      }
      final res = await _api.get(path: 'audit-logs/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(SecurityAuditLogModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
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
      if (!_hasApi && auditLogger != null) {
        final logs = auditLogger!.getLogs(
          eventType: eventType,
          branchId: branchId,
          startDate: startDate,
          endDate: endDate,
        );
        final buf = StringBuffer('ID,Timestamp,EventType,Actor,Target,Branch,IP,Details\n');
        for (final l in logs) {
          buf.writeln(
            '${l.id ?? ''},${l.timestamp?.toIso8601String() ?? ''},${l.eventType ?? ''},${l.performedByUserName ?? l.performedByUserId ?? ''},${l.targetUserName ?? l.targetUserId ?? ''},${l.branchId ?? ''},${l.ipAddress ?? ''},${l.details ?? ''}',
          );
        }
        return Right(buf.toString());
      }
      final res = await _api.get(
        path: 'audit-logs/export',
        queryParameters: {
          if (eventType != null) 'eventType': eventType,
          if (branchId != null) 'branchId': branchId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      if (data is Map && data['csv'] is String) {
        return Right(data['csv'] as String);
      }
      return Right(data.toString());
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

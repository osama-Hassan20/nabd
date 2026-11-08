import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../users_management/data/models/security_audit_log_model.dart';

class AuditLogsState extends Equatable {
  final RequestStatusEnum status;
  final List<SecurityAuditLogModel> logs;
  final SecurityAuditLogModel? selectedLog;
  final String searchQuery;
  final String selectedEventType;
  final String selectedBranchId;
  final DateTime? startDate;
  final DateTime? endDate;
  final RequestStatusEnum exportStatus;
  final String? exportData;
  final String? errorMessage;

  const AuditLogsState({
    this.status = RequestStatusEnum.initial,
    this.logs = const [],
    this.selectedLog,
    this.searchQuery = '',
    this.selectedEventType = 'all',
    this.selectedBranchId = 'all',
    this.startDate,
    this.endDate,
    this.exportStatus = RequestStatusEnum.initial,
    this.exportData,
    this.errorMessage,
  });

  AuditLogsState copyWith({
    RequestStatusEnum? status,
    List<SecurityAuditLogModel>? logs,
    SecurityAuditLogModel? selectedLog,
    bool clearSelectedLog = false,
    String? searchQuery,
    String? selectedEventType,
    String? selectedBranchId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
    RequestStatusEnum? exportStatus,
    String? exportData,
    String? errorMessage,
  }) {
    return AuditLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      selectedLog: clearSelectedLog ? null : (selectedLog ?? this.selectedLog),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEventType: selectedEventType ?? this.selectedEventType,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      exportStatus: exportStatus ?? this.exportStatus,
      exportData: exportData ?? this.exportData,
      errorMessage: errorMessage,
    );
  }

  List<SecurityAuditLogModel> get filteredLogs {
    var result = List<SecurityAuditLogModel>.from(logs);

    if (selectedEventType != 'all' && selectedEventType.isNotEmpty) {
      result = result.where((e) => e.eventType == selectedEventType).toList();
    }

    if (selectedBranchId != 'all' && selectedBranchId.isNotEmpty) {
      result = result.where((e) => e.branchId == selectedBranchId).toList();
    }

    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      result = result.where((e) {
        if (e.timestamp == null) return false;
        return e.timestamp!.isAfter(start) ||
            (e.timestamp!.year == start.year &&
                e.timestamp!.month == start.month &&
                e.timestamp!.day == start.day);
      }).toList();
    }

    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
      result = result.where((e) {
        if (e.timestamp == null) return false;
        return e.timestamp!.isBefore(end);
      }).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((e) {
        final idMatch = (e.id ?? '').toLowerCase().contains(query);
        final eventMatch = (e.eventType ?? '').toLowerCase().contains(query);
        final detailsMatch = (e.details ?? '').toLowerCase().contains(query);
        final userMatch = (e.performedByUserName ?? '').toLowerCase().contains(query);
        final targetMatch = (e.targetUserName ?? '').toLowerCase().contains(query);
        final branchMatch = (e.branchName ?? '').toLowerCase().contains(query);
        final ipMatch = (e.ipAddress ?? '').toLowerCase().contains(query);
        return idMatch || eventMatch || detailsMatch || userMatch || targetMatch || branchMatch || ipMatch;
      }).toList();
    }

    return result;
  }

  // Summary KPI Getters
  int get totalEventsCount => logs.length;
  int get securityEventsCount => logs.where((e) {
        final t = e.eventType ?? '';
        return t.contains('login') || t.contains('password') || t.contains('permission');
      }).length;
  int get patientAccessCount => logs.where((e) => e.eventType == 'view_patient_profile').length;
  int get branchOperationsCount => logs.where((e) => (e.eventType ?? '').contains('branch')).length;

  @override
  List<Object?> get props => [
        status,
        logs,
        selectedLog,
        searchQuery,
        selectedEventType,
        selectedBranchId,
        startDate,
        endDate,
        exportStatus,
        exportData,
        errorMessage,
      ];
}


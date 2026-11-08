import '../../../../core/base/safe_cubit.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../users_management/data/models/security_audit_log_model.dart';
import '../../domain/repo/audit_logs_repo.dart';
import 'audit_logs_state.dart';

class AuditLogsCubit extends SafeCubit<AuditLogsState> {
  final AuditLogsRepo repo;

  AuditLogsCubit({required this.repo}) : super(const AuditLogsState());

  Future<void> loadLogs() async {
    emit(state.copyWith(status: RequestStatusEnum.loading));

    final result = await repo.getAuditLogs();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errorMessage: failure.errMessage,
        ),
      ),
      (logs) => emit(
        state.copyWith(
          status: RequestStatusEnum.success,
          logs: logs,
        ),
      ),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setEventTypeFilter(String eventType) {
    emit(state.copyWith(selectedEventType: eventType));
  }

  void setBranchFilter(String branchId) {
    emit(state.copyWith(selectedBranchId: branchId));
  }

  void setDateRangeFilter(DateTime? start, DateTime? end) {
    emit(state.copyWith(startDate: start, endDate: end));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        selectedEventType: 'all',
        selectedBranchId: 'all',
        clearDateRange: true,
      ),
    );
  }

  void selectLog(SecurityAuditLogModel? log) {
    emit(state.copyWith(selectedLog: log, clearSelectedLog: log == null));
  }

  Future<bool> exportLogs() async {
    emit(state.copyWith(exportStatus: RequestStatusEnum.loading));

    final result = await repo.exportAuditLogs(
      eventType: state.selectedEventType != 'all' ? state.selectedEventType : null,
      branchId: state.selectedBranchId != 'all' ? state.selectedBranchId : null,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            exportStatus: RequestStatusEnum.failure,
            errorMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (csvData) {
        emit(
          state.copyWith(
            exportStatus: RequestStatusEnum.success,
            exportData: csvData,
          ),
        );
        return true;
      },
    );
  }
}


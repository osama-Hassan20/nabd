import 'package:dio/dio.dart';
import 'package:eyadty/core/errors/failures.dart';

class ConflictFailure extends ServerFailure {
  final Map<String, dynamic>? serverVersion;

  const ConflictFailure({
    required super.errMessage,
    this.serverVersion,
  });
}

class HttpFailureMapper {
  HttpFailureMapper._();

  static Failures fromError(Object error) {
    if (error is Failures) return error;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const ServerFailure(
          errMessage: 'تعذر الاتصال بالخادم، يرجى المحاولة مرة أخرى',
        );
      }

      final status = error.response?.statusCode;
      final data = error.response?.data;
      final errObj = data is Map ? (data['error'] as Map?) : null;
      final code = errObj?['code']?.toString();
      final message = errObj?['message']?.toString();
      final fields = errObj?['fields'];

      if (code == 'DUPLICATE_PHONE' && fields is Map) {
        final rawMatches = (fields['matchingPatients'] as List?) ?? const [];
        final matches = rawMatches
            .map(
              (m) => DuplicatePhonePatientInfo(
                id: (m['id'] ?? '').toString(),
                name: (m['name'] ?? '').toString(),
                fileNumber: (m['fileNumber'] ?? '').toString(),
                phone: (m['phone'] ?? '').toString(),
              ),
            )
            .toList();
        return DuplicatePhoneWarningFailure(
          matchingPatients: matches,
          errMessage: message ?? 'رقم الهاتف مسجل لمريض آخر بالفعل',
        );
      }

      if (code == 'CONFLICTING_BOOKINGS' && fields is Map) {
        return ConflictingBookingsFailure(
          conflictingCount: (fields['conflictingCount'] as num?)?.toInt() ?? 1,
          errMessage: message ?? 'يوجد حجوزات متعارضة في هذه الفترة',
        );
      }

      if (code == 'SLOT_CONFLICT') {
        final fMap = fields is Map ? fields : null;
        return SlotConflictFailure(
          conflictingPatientName: fMap?['conflictingPatientName'] as String?,
          conflictingBookingId: fMap?['conflictingBookingId'] as String?,
          errMessage: message ?? 'slot_already_booked_or_unavailable',
        );
      }

      if (code == 'BRANCH_NOT_FOUND') {
        return BranchNotFoundFailure(errMessage: message ?? 'branch_not_found');
      }

      if (code == 'INVALID_BRANCH_OPERATION') {
        return InvalidBranchOperationFailure(errMessage: message ?? 'invalid_branch_operation');
      }

      if (code == 'ACTIVE_BOOKINGS_EXIST') {
        final fMap = fields is Map ? fields : null;
        return ActiveBookingsWarningFailure(
          activeBookingsCount: (fMap?['activeBookingsCount'] as num?)?.toInt() ?? 1,
          errMessage: message ?? 'branch_has_future_bookings_warning',
        );
      }

      if (code == 'CANNOT_DEACTIVATE_MAIN_BRANCH') {
        return CannotDeactivateMainBranchFailure(
          errMessage: message ?? 'cannot_deactivate_main_branch',
        );
      }

      if (code == 'PRIVILEGE_ESCALATION') {
        return PrivilegeEscalationFailure(
          errMessage: message ?? 'staff_privilege_escalation_denied',
        );
      }

      if (code == 'LAST_ACTIVE_OWNER') {
        return LastActiveOwnerFailure(
          errMessage: message ?? 'last_owner_cannot_be_removed',
        );
      }

      if (code == 'SELF_DEACTIVATION') {
        return SelfDeactivationFailure(
          errMessage: message ?? 'cannot_deactivate_self',
        );
      }

      if (code == 'SELF_DELETION') {
        return SelfDeletionFailure(
          errMessage: message ?? 'cannot_delete_self',
        );
      }

      if (code == 'MUST_CHANGE_PASSWORD') {
        final fMap = fields is Map ? fields : null;
        return MustChangePasswordFailure(
          userId: fMap?['userId']?.toString() ?? '',
          errMessage: message ?? 'must_change_password',
        );
      }

      if (code == 'CANNOT_DEACTIVATE_LAST_ACTIVE_BRANCH') {
        return CannotDeactivateLastActiveBranchFailure(
          errMessage: message ?? 'cannot_deactivate_last_active_branch',
        );
      }

      switch (status) {
        case 401:
          return ServerFailure(
            errMessage: message ?? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
          );
        case 403:
          return PermissionDeniedFailure(
            errMessage: message ?? 'ليس لديك صلاحية لتنفيذ هذا الإجراء',
          );
        case 404:
          return ServerFailure(
            errMessage: message ?? 'السجل المطلوب غير موجود',
          );
        case 409:
          return ConflictFailure(
            errMessage: message ?? 'تعارض في البيانات مع الخادم، يرجى المراجعة',
            serverVersion: data is Map && data['serverVersion'] is Map
                ? Map<String, dynamic>.from(data['serverVersion'] as Map)
                : null,
          );
        case 422:
          return ValidationFailure(
            errMessage: message ?? 'يرجى التحقق من البيانات المدخلة',
          );
        default:
          if (status != null && status >= 500) {
            return const ServerFailure(
              errMessage: 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
            );
          }
      }
      return ServerFailure.fromDioException(dioException: error);
    }
    return const ServerFailure(
      errMessage: 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً',
    );
  }
}

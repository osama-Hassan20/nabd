import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_schedule_model.dart';
import 'package:eyadty/features/doctors/data/models/doctors_response_model.dart';
import 'package:eyadty/features/doctors/domain/repo/doctors_repo.dart';

class DoctorsRepoImpl implements DoctorsRepo {
  final ApiConsumer? _apiConsumer;
  final CurrentRoleProvider? roleProvider;
  final dynamic _bookingsRepo;

  DoctorsRepoImpl({
    ApiConsumer? apiConsumer,
    this.roleProvider,
    dynamic bookingsRepo,
    dynamic settingsRepo,
  })  : _apiConsumer = apiConsumer,
        _bookingsRepo = bookingsRepo;

  bool get _isAdmin =>
      roleProvider == null || roleProvider!.currentRole == UserRoleEnum.admin;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  dynamic _idempotentOptions([String? key]) =>
      IdempotencyHelper.options(key);

  @override
  Future<Either<Failures, DoctorsResponseModel>> getDoctors({
    required PaginationParams params,
  }) async {
    try {
      final res = await _api.get(
        path: 'doctors',
        queryParameters: params.toJson(),
      );
      final list = (res is Map ? (res['data'] as List?) : null) ?? const [];
      final meta = res is Map ? (res['meta'] as Map?) : null;
      final total = (meta?['total'] as num?)?.toInt() ?? list.length;
      final limit = (meta?['limit'] as num?)?.toInt() ?? (params.limit ?? 20);
      final page = (meta?['page'] as num?)?.toInt() ?? (params.page ?? 1);
      final pages = limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 999999) : 1;

      return right(
        DoctorsResponseModel(
          items: list
              .map((e) => DoctorModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
          totalCount: total,
          totalPages: pages,
          currentPage: page,
        ),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> getDoctorById({
    required String id,
  }) async {
    try {
      final res = await _api.get(path: 'doctors/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(DoctorModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> addDoctor({
    required DoctorModel doctor,
  }) async {
    try {
      final res = await _api.post(
        path: 'doctors',
        body: doctor.toJson(),
        options: _idempotentOptions(doctor.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(DoctorModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorModel>> updateDoctor({
    required DoctorModel doctor,
  }) async {
    try {
      final res = await _api.put(
        path: 'doctors/${doctor.id}',
        body: doctor.toJson(),
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(DoctorModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteDoctor({
    required String id,
  }) async {
    try {
      await _api.delete(path: 'doctors/$id', options: _idempotentOptions());
      return right(true);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorScheduleModel?>> getDoctorSchedule({
    required String doctorId,
  }) async {
    try {
      final res = await _api.get(path: 'doctors/$doctorId/schedule');
      final data = res is Map ? res['data'] : res;
      if (data == null) return right(null);
      return right(
        DoctorScheduleModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorScheduleModel>> saveDoctorSchedule({
    required DoctorScheduleModel schedule,
  }) async {
    if (!_isAdmin) {
      return left(const ValidationFailure(errMessage: 'غير مصرح بتعديل جدول الطبيب'));
    }
    try {
      final res = await _api.put(
        path: 'doctors/${schedule.doctorId}/schedule',
        body: schedule.toJson(),
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        DoctorScheduleModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<DoctorLeaveModel>>> getDoctorLeaves({
    required String doctorId,
  }) async {
    try {
      final res = await _api.get(path: 'doctors/$doctorId/leaves');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map((e) => DoctorLeaveModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, DoctorLeaveModel>> addDoctorLeave({
    required DoctorLeaveModel leave,
    bool force = false,
  }) async {
    if (!_isAdmin) {
      return left(const ValidationFailure(errMessage: 'غير مصرح بإضافة إجازة'));
    }
    if (!force && _bookingsRepo != null && leave.startDate != null && leave.endDate != null) {
      try {
        int conflicts = 0;
        final s = leave.startDate!;
        final e = leave.endDate!;
        final startDay = DateTime(s.year, s.month, s.day);
        final endDay = DateTime(e.year, e.month, e.day);
        for (var d = startDay; !d.isAfter(endDay); d = d.add(const Duration(days: 1))) {
          final res = await _bookingsRepo.getDoctorBookingsForDate(
            doctorId: leave.doctorId,
            date: d,
          );
          res.fold((_) {}, (list) {
            for (final b in (list as List)) {
              final st = b.status?.value?.toString() ?? b.status?.toString();
              if (st != 'cancelled' && st != 'completed') {
                conflicts++;
              }
            }
          });
        }
        if (conflicts > 0) {
          return left(ConflictingBookingsFailure(
            conflictingCount: conflicts,
            errMessage: 'يوجد $conflicts حجوزات متعارضة في هذه الفترة',
          ));
        }
      } catch (_) {}
    }
    try {
      final res = await _api.post(
        path: 'doctors/${leave.doctorId}/leaves',
        body: {...leave.toJson(), 'force': force},
        options: _idempotentOptions(leave.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        DoctorLeaveModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteDoctorLeave({
    required String leaveId,
  }) async {
    if (!_isAdmin) {
      return left(const ValidationFailure(errMessage: 'غير مصرح بحذف إجازة'));
    }
    try {
      await _api.delete(
        path: 'doctors/unknown/leaves/$leaveId',
        options: _idempotentOptions(),
      );
      return right(true);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, int>> countConflictingBookings({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _api.get(
        path: 'doctors/$doctorId/leaves/conflicts',
        queryParameters: {
          'from': startDate.toIso8601String(),
          'to': endDate.toIso8601String(),
        },
      );
      final data = res is Map ? (res['data'] as Map?) : null;
      return right((data?['count'] as num?)?.toInt() ?? 0);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }
}

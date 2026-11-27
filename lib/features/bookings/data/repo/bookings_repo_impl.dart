import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/bookings_response_model.dart';
import 'package:eyadty/features/bookings/domain/repo/bookings_repo.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/apply_discount_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/remove_discount_params.dart';

class BookingsRepoImpl implements BookingsRepo {
  final ApiConsumer? _apiConsumer;
  final List<BookingModel> _cachedBookings = [];

  List<BookingModel> get bookings => List.unmodifiable(_cachedBookings);

  BookingsRepoImpl({
    ApiConsumer? apiConsumer,
    dynamic doctorsRepo,
    dynamic settingsRepo,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  dynamic _idempotentOptions([String? key]) =>
      IdempotencyHelper.options(key);

  @override
  Future<Either<Failures, BookingSummaryModel>> getBookingSummary({
    DateTime? date,
    String? branchId,
  }) async {
    try {
      final res = await _api.get(
        path: 'bookings/summary',
        queryParameters: {
          if (date != null) 'date': date.toIso8601String(),
          if (branchId != null) 'branchId': branchId,
        },
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        BookingSummaryModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingsResponseModel>> getBookings(
    PaginationParams params,
  ) async {
    try {
      final res = await _api.get(
        path: 'bookings',
        queryParameters: params.toJson(),
      );
      final list = (res is Map ? (res['data'] as List?) : null) ?? const [];
      final meta = res is Map ? (res['meta'] as Map?) : null;
      final total = (meta?['total'] as num?)?.toInt() ?? list.length;
      final limit = (meta?['limit'] as num?)?.toInt() ?? (params.limit ?? 20);
      final page = (meta?['page'] as num?)?.toInt() ?? (params.page ?? 1);
      final pages = limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 999999) : 1;

      final parsed = list
          .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _cachedBookings
        ..clear()
        ..addAll(parsed);
      return right(
        BookingsResponseModel(
          bookings: parsed,
          pagination: PaginationModel(
            page: page,
            limit: limit,
            total: total,
            pages: pages,
          ),
        ),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> getBookingById(String id) async {
    try {
      final res = await _api.get(path: 'bookings/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(BookingModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> createBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    try {
      final res = await _api.post(
        path: 'bookings',
        body: {
          ...booking.toJson(),
          if (customNow != null) 'customNow': customNow.toIso8601String(),
        },
        options: _idempotentOptions(booking.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(BookingModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> updateBooking(
    BookingModel booking, {
    DateTime? customNow,
  }) async {
    try {
      final res = await _api.put(
        path: 'bookings/${booking.id}',
        body: {
          ...booking.toJson(),
          if (customNow != null) 'customNow': customNow.toIso8601String(),
        },
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(BookingModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> applyDiscount(
    ApplyDiscountParams params,
  ) async {
    try {
      final res = await _api.post(
        path: 'bookings/${params.bookingId}/discount',
        body: {
          'discountType': params.discountType?.value,
          'discountValue': params.discountValue,
          'reason': params.reason,
          if (params.approvedByUserId != null)
            'approvedByUserId': params.approvedByUserId,
        },
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(BookingModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, BookingModel>> removeDiscount(
    RemoveDiscountParams params,
  ) async {
    try {
      final res = await _api.delete(
        path: 'bookings/${params.bookingId}/discount',
        body: {'reason': params.reason},
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(BookingModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<BookingModel>>> getDoctorBookingsForDate({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _api.get(
        path: 'doctors/$doctorId/bookings',
        queryParameters: {'date': dateStr},
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> changeBookingStatus(
    ChangeBookingStatusParams params,
  ) async {
    try {
      await _api.patch(
        path: 'bookings/${params.bookingId}/status',
        body: {
          'status': params.newStatus.value,
          if (params.cancelReason != null) 'cancelReason': params.cancelReason,
          if (params.cancelledBy != null) 'cancelledBy': params.cancelledBy,
          if (params.rescheduledTo != null)
            'rescheduledTo': params.rescheduledTo!.toIso8601String(),
          if (params.postponeReason != null)
            'postponeReason': params.postponeReason,
        },
        options: _idempotentOptions(),
      );
      return right(unit);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> reassignTechnician(
    ReassignTechnicianParams params,
  ) async {
    try {
      await _api.patch(
        path: 'bookings/${params.bookingId}/technician',
        body: {
          'technicianIds': params.newTechnicianIds,
          if (params.newTechnicianId != null)
            'technicianId': params.newTechnicianId,
          if (params.newTechnicianName != null)
            'technicianName': params.newTechnicianName,
        },
        options: _idempotentOptions(),
      );
      return right(unit);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteBooking(String bookingId) async {
    try {
      await _api.delete(
        path: 'bookings/$bookingId',
        options: _idempotentOptions(),
      );
      return right(unit);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }
}

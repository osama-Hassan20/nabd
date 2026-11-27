import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/features/bookings/domain/contracts/active_visit_lookup.dart';
import 'package:eyadty/features/visits/data/models/consultation_queue_item_model.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_addendum_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/data/models/vitals_model.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';

class VisitsRepoImpl implements VisitsRepo, ActiveVisitLookup {
  final ApiConsumer? _apiConsumer;

  VisitsRepoImpl({ApiConsumer? apiConsumer, dynamic bookingsRepo})
      : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  dynamic _idempotentOptions([String? key]) =>
      IdempotencyHelper.options(key);

  @override
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId) async {
    final res = await getVisitByBookingId(bookingId: bookingId);
    return res.fold((_) => null, (v) => v?.status);
  }

  @override
  Future<Either<Failures, List<ConsultationQueueItemModel>>> getDoctorQueue({
    String? doctorId,
    required String branchId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final res = await _api.get(
        path: 'visits/queue',
        queryParameters: {
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          'branchId': branchId,
          'date': dateStr,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map(
              (e) => ConsultationQueueItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel?>> getVisitByBookingId({
    required String bookingId,
  }) async {
    try {
      final res = await _api.get(path: 'visits/by-booking/$bookingId');
      final data = res is Map ? res['data'] : res;
      if (data == null) return right(null);
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel?>> getVisitById({
    required String visitId,
  }) async {
    try {
      final res = await _api.get(path: 'visits/$visitId');
      final data = res is Map ? res['data'] : res;
      if (data == null) return right(null);
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<VisitModel>>> getVisitsByPatientId({
    required String patientId,
  }) async {
    try {
      final res = await _api.get(path: 'patients/$patientId/visits');
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map((e) => VisitModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel>> upsertConsultationStart({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
  }) async {
    try {
      final res = await _api.put(
        path: 'visits/consultation-start',
        body: {
          'bookingId': bookingId,
          'patientId': patientId,
          'branchId': branchId,
          'patientName': patientName,
          if (patientPhone != null) 'patientPhone': patientPhone,
          'doctorId': doctorId,
          'doctorName': doctorName,
          if (specialty != null) 'specialty': specialty,
        },
        options: _idempotentOptions('start_$bookingId'),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel>> saveVisitDraft({
    required VisitModel draft,
  }) async {
    try {
      final res = await _api.put(
        path: 'visits/${draft.id}/draft',
        body: draft.toJson(),
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel>> recordVitals({
    required String bookingId,
    required String patientId,
    required String branchId,
    required String patientName,
    String? patientPhone,
    required String doctorId,
    required String doctorName,
    String? specialty,
    required VitalsModel vitals,
  }) async {
    try {
      final res = await _api.post(
        path: 'visits/$bookingId/vitals',
        body: {
          'bookingId': bookingId,
          'patientId': patientId,
          'branchId': branchId,
          'patientName': patientName,
          if (patientPhone != null) 'patientPhone': patientPhone,
          'doctorId': doctorId,
          'doctorName': doctorName,
          if (specialty != null) 'specialty': specialty,
          'vitals': vitals.toJson(),
        },
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel>> finalizeVisit({
    required VisitModel finalContent,
  }) async {
    try {
      final res = await _api.post(
        path: 'visits/${finalContent.id}/finalize',
        body: finalContent.toJson(),
        options: _idempotentOptions('finalize_${finalContent.id}'),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, VisitModel>> addVisitAddendum({
    required String visitId,
    required VisitAddendumModel addendum,
  }) async {
    try {
      final res = await _api.post(
        path: 'visits/$visitId/addenda',
        body: addendum.toJson(),
        options: _idempotentOptions(addendum.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(VisitModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }
}

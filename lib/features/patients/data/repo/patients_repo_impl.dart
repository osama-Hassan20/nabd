import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/data/models/patient_treatment_plan_model.dart';
import 'package:eyadty/features/patients/data/models/patients_response_model.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';

class PatientsRepoImpl implements PatientsRepo {
  final ApiConsumer? _apiConsumer;

  PatientsRepoImpl({
    ApiConsumer? apiConsumer,
    dynamic bookingsRepo,
    dynamic roleProvider,
    dynamic balanceLookup,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  dynamic _idempotentOptions([String? key]) =>
      IdempotencyHelper.options(key);

  @override
  Future<Either<Failures, PatientsResponseModel>> getPatients({
    required PaginationParams params,
    String? search,
    GenderEnum? gender,
    BloodGroupEnum? bloodGroup,
    bool? hasDebt,
    bool isArchived = false,
  }) async {
    try {
      final res = await _api.get(
        path: 'patients',
        queryParameters: {
          'page': params.page ?? 1,
          'limit': params.limit ?? 20,
          'isArchived': isArchived,
          if (search != null && search.isNotEmpty) 'search': search,
          if (gender != null) 'gender': gender.value,
          if (bloodGroup != null) 'bloodGroup': bloodGroup.value,
          if (hasDebt != null) 'hasDebt': hasDebt,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : null) ?? const [];
      final meta = res is Map ? (res['meta'] as Map?) : null;
      final total = (meta?['total'] as num?)?.toInt() ?? list.length;
      final limit = (meta?['limit'] as num?)?.toInt() ?? (params.limit ?? 20);
      final page = (meta?['page'] as num?)?.toInt() ?? (params.page ?? 1);
      final pages = limit > 0 ? ((total + limit - 1) ~/ limit).clamp(1, 999999) : 1;

      return right(
        PatientsResponseModel(
          items: list
              .map((e) => PatientModel.fromJson(Map<String, dynamic>.from(e as Map)))
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
  Future<Either<Failures, PatientModel>> getPatientById({
    required String id,
  }) async {
    try {
      final res = await _api.get(path: 'patients/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(PatientModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> addPatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    try {
      final res = await _api.post(
        path: 'patients',
        body: {
          ...patient.toJson(),
          'allowDuplicatePhone': allowDuplicatePhone,
        },
        options: _idempotentOptions(patient.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(PatientModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientModel>> updatePatient({
    required PatientModel patient,
    bool allowDuplicatePhone = false,
  }) async {
    try {
      final res = await _api.put(
        path: 'patients/${patient.id}',
        body: {
          ...patient.toJson(),
          'allowDuplicatePhone': allowDuplicatePhone,
        },
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(PatientModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<PatientModel>>> findPatientsByPhone({
    required String phone,
    String? excludePatientId,
  }) async {
    try {
      final res = await _api.get(
        path: 'patients/search-by-phone',
        queryParameters: {
          'phone': phone,
          if (excludePatientId != null) 'excludePatientId': excludePatientId,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map((e) => PatientModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((p) => p.id != excludePatientId)
            .toList(),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, String>> archivePatient({
    required String id,
    String? reason,
  }) async {
    try {
      await _api.post(
        path: 'patients/$id/archive',
        body: {if (reason != null) 'reason': reason},
        options: _idempotentOptions(),
      );
      return right('تم أرشفة المريض بنجاح');
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, String>> unarchivePatient({
    required String id,
  }) async {
    try {
      await _api.post(
        path: 'patients/$id/unarchive',
        options: _idempotentOptions(),
      );
      return right('تم استعادة المريض بنجاح');
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, String>> deletePatient({
    required String id,
  }) async {
    try {
      await _api.delete(
        path: 'patients/$id',
        options: _idempotentOptions(),
      );
      return right('تم حذف المريض بنجاح');
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, bool>> checkDuplicate({
    String? phone,
    String? excludePatientId,
  }) async {
    try {
      final res = await _api.post(
        path: 'patients/check-duplicate',
        body: {
          if (phone != null) 'phone': phone,
          if (excludePatientId != null) 'excludeId': excludePatientId,
        },
      );
      final data = res is Map ? (res['data'] as Map?) : null;
      return right(data?['isDuplicate'] == true);
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> addTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    try {
      final res = await _api.post(
        path: 'patients/$patientId/treatment-plans',
        body: plan.toJson(),
        options: _idempotentOptions(plan.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        PatientTreatmentPlanModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> updateTreatmentPlan({
    required String patientId,
    required PatientTreatmentPlanModel plan,
  }) async {
    try {
      final res = await _api.put(
        path: 'patients/$patientId/treatment-plans/${plan.id}',
        body: plan.toJson(),
        options: _idempotentOptions(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        PatientTreatmentPlanModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentSession({
    required String patientId,
    required String planId,
    required TreatmentSessionRecordModel session,
  }) async {
    try {
      final res = await _api.post(
        path: 'patients/$patientId/treatment-plans/$planId/sessions',
        body: session.toJson(),
        options: _idempotentOptions(session.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        PatientTreatmentPlanModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, PatientTreatmentPlanModel>> recordTreatmentPayment({
    required String patientId,
    required String planId,
    required TreatmentPaymentRecordModel payment,
  }) async {
    try {
      final res = await _api.post(
        path: 'patients/$patientId/treatment-plans/$planId/payments',
        body: payment.toJson(),
        options: _idempotentOptions(payment.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        PatientTreatmentPlanModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }
}

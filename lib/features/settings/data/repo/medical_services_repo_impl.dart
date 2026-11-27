import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../../../core/cubits/session_cubit.dart';
import '../../../../core/enums/user_role_enum.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../bookings/domain/repo/bookings_repo.dart';
import '../../domain/repo/medical_services_repo.dart';
import '../models/medical_service_model.dart';

class MedicalServicesRepoImpl implements MedicalServicesRepo {
  final ApiConsumer? _apiConsumer;
  final CurrentRoleProvider? roleProvider;
  final BookingsRepo? bookingsRepo;

  MedicalServicesRepoImpl({
    ApiConsumer? apiConsumer,
    this.roleProvider,
    this.bookingsRepo,
  }) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  bool _canManage() {
    if (roleProvider != null) {
      return roleProvider!.currentRole == UserRoleEnum.admin;
    }
    return true;
  }

  @override
  Future<Either<Failures, List<MedicalServiceModel>>> getMedicalServices({
    bool? onlyActive,
    String? doctorId,
    String? query,
  }) async {
    try {
      final res = await _api.get(
        path: 'medical-services',
        queryParameters: {
          if (onlyActive != null) 'onlyActive': onlyActive,
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => MedicalServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> getMedicalServiceById(String id) async {
    try {
      final res = await _api.get(path: 'medical-services/$id');
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(MedicalServiceModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> addMedicalService(
    MedicalServiceModel service,
  ) async {
    if (!_canManage()) {
      return const Left(ServerFailure(errMessage: 'permission_denied'));
    }
    try {
      final res = await _api.post(
        path: 'medical-services',
        body: service.toJson(),
        options: IdempotencyHelper.options(service.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(MedicalServiceModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> updateMedicalService(
    MedicalServiceModel service,
  ) async {
    if (!_canManage()) {
      return const Left(ServerFailure(errMessage: 'permission_denied'));
    }
    try {
      final res = await _api.put(
        path: 'medical-services/${service.id}',
        body: service.toJson(),
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(MedicalServiceModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalServiceModel>> toggleServiceStatus(String id) async {
    if (!_canManage()) {
      return const Left(ServerFailure(errMessage: 'permission_denied'));
    }
    try {
      final res = await _api.patch(
        path: 'medical-services/$id/status',
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(MedicalServiceModel.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, Unit>> deleteMedicalService(String id) async {
    if (!_canManage()) {
      return const Left(ServerFailure(errMessage: 'permission_denied'));
    }
    if (bookingsRepo != null) {
      final bookingsResult = await bookingsRepo!.getBookings(
        const PaginationParams(page: 1, limit: 1000),
      );
      final isLinked = bookingsResult.fold(
        (_) => false,
        (response) => (response.bookings ?? []).any((b) => b.serviceId == id),
      );
      if (isLinked) {
        return const Left(
          ServerFailure(errMessage: 'cannot_delete_service_linked_to_bookings'),
        );
      }
    }
    try {
      await _api.delete(
        path: 'medical-services/$id',
        options: IdempotencyHelper.options(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../domain/repo/medical_catalogs_repo.dart';
import '../models/enums/medical_catalog_kind_enum.dart';
import '../models/medical_catalog_entry_model.dart';

class MedicalCatalogsRepoImpl implements MedicalCatalogsRepo {
  final ApiConsumer? _apiConsumer;

  MedicalCatalogsRepoImpl({ApiConsumer? apiConsumer})
      : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failures, List<MedicalCatalogEntryModel>>> getEntries({
    required MedicalCatalogKindEnum kind,
    String? query,
    String? category,
  }) async {
    try {
      final res = await _api.get(
        path: 'medical-catalogs/${kind.key}',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => MedicalCatalogEntryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> addEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    try {
      final kind = entry.kind.key;
      final res = await _api.post(
        path: 'medical-catalogs/$kind',
        body: entry.toJson(),
        options: IdempotencyHelper.options(entry.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        MedicalCatalogEntryModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> updateEntry(
    MedicalCatalogEntryModel entry,
  ) async {
    try {
      final kind = entry.kind.key;
      final res = await _api.put(
        path: 'medical-catalogs/$kind/${entry.id}',
        body: entry.toJson(),
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        MedicalCatalogEntryModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, bool>> deleteEntry(String id) async {
    try {
      await _api.delete(
        path: 'medical-catalogs/any/$id',
        options: IdempotencyHelper.options(),
      );
      return const Right(true);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, MedicalCatalogEntryModel>> toggleActive({
    required String id,
    required bool isActive,
  }) async {
    try {
      final res = await _api.patch(
        path: 'medical-catalogs/any/$id/active',
        body: {'isActive': isActive},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        MedicalCatalogEntryModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:eyadty/features/patients/domain/repo/medical_catalog_repo.dart';

class MedicalCatalogRepoImpl implements MedicalCatalogRepo {
  final ApiConsumer? _apiConsumer;

  MedicalCatalogRepoImpl({ApiConsumer? apiConsumer})
      : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failures, List<MedicalCatalogItemModel>>> getCatalogItems({
    required String type,
    String? query,
  }) async {
    try {
      final res = await _api.get(
        path: 'medical-catalog-items',
        queryParameters: {
          'type': type,
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return right(
        list
            .map(
              (e) => MedicalCatalogItemModel.fromJson(
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
  Future<Either<Failures, MedicalCatalogItemModel>> addCatalogItem({
    required String name,
    required String type,
  }) async {
    try {
      final res = await _api.post(
        path: 'medical-catalog-items',
        body: {'name': name, 'type': type},
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return right(
        MedicalCatalogItemModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return left(HttpFailureMapper.fromError(e));
    }
  }
}

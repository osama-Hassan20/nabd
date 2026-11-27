import 'package:dartz/dartz.dart';
import 'package:eyadty/core/api/api_consumer.dart';
import 'package:eyadty/core/api/idempotency_helper.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/errors/http_failure_mapper.dart';
import '../../domain/repo/inventory_repo.dart';
import '../models/inventory_item_model.dart';

class InventoryRepoImpl implements InventoryRepo {
  final ApiConsumer? _apiConsumer;

  InventoryRepoImpl({ApiConsumer? apiConsumer}) : _apiConsumer = apiConsumer;

  ApiConsumer get _api => _apiConsumer ?? getIt<ApiConsumer>();

  @override
  Future<Either<Failures, List<InventoryItemModel>>> getItems({
    String? query,
    String? category,
    bool onlyLowStock = false,
  }) async {
    try {
      final res = await _api.get(
        path: 'inventory/items',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null && category.isNotEmpty) 'category': category,
          if (onlyLowStock) 'onlyLowStock': true,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map((e) => InventoryItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> addItem(InventoryItemModel item) async {
    try {
      final res = await _api.post(
        path: 'inventory/items',
        body: item.toJson(),
        options: IdempotencyHelper.options(item.id),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        InventoryItemModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> updateItem(InventoryItemModel item) async {
    try {
      final res = await _api.put(
        path: 'inventory/items/${item.id}',
        body: item.toJson(),
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        InventoryItemModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, String>> deleteItem(String id) async {
    try {
      await _api.delete(
        path: 'inventory/items/$id',
        options: IdempotencyHelper.options(),
      );
      return Right(id);
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordConsumption({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? notes,
  }) async {
    try {
      final res = await _api.post(
        path: 'inventory/items/$itemId/consumption',
        body: {
          'quantity': quantity,
          'performedBy': performedBy,
          if (notes != null) 'notes': notes,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        InventoryItemModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, InventoryItemModel>> recordRestock({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? supplier,
    String? notes,
  }) async {
    try {
      final res = await _api.post(
        path: 'inventory/items/$itemId/restock',
        body: {
          'quantity': quantity,
          'performedBy': performedBy,
          if (supplier != null) 'supplier': supplier,
          if (notes != null) 'notes': notes,
        },
        options: IdempotencyHelper.options(),
      );
      final data = res is Map ? (res['data'] ?? res) : res;
      return Right(
        InventoryItemModel.fromJson(Map<String, dynamic>.from(data as Map)),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }

  @override
  Future<Either<Failures, List<InventoryTransactionModel>>> getTransactions({
    String? itemId,
  }) async {
    try {
      final res = await _api.get(
        path: 'inventory/transactions',
        queryParameters: {
          if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
        },
      );
      final list = (res is Map ? (res['data'] as List?) : res as List?) ?? const [];
      return Right(
        list
            .map(
              (e) => InventoryTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e) {
      return Left(HttpFailureMapper.fromError(e));
    }
  }
}

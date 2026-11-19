import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/inventory_item_model.dart';

abstract class InventoryRepo {
  Future<Either<Failures, List<InventoryItemModel>>> getItems({
    String? query,
    String? category,
    bool onlyLowStock = false,
  });

  Future<Either<Failures, InventoryItemModel>> addItem(InventoryItemModel item);

  Future<Either<Failures, InventoryItemModel>> updateItem(InventoryItemModel item);

  Future<Either<Failures, String>> deleteItem(String id);

  Future<Either<Failures, InventoryItemModel>> recordConsumption({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? notes,
  });

  Future<Either<Failures, InventoryItemModel>> recordRestock({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? supplier,
    String? notes,
  });

  Future<Either<Failures, List<InventoryTransactionModel>>> getTransactions({
    String? itemId,
  });
}

import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import '../../domain/repo/inventory_repo.dart';
import '../../data/models/inventory_item_model.dart';
import 'inventory_state.dart';

class InventoryCubit extends SafeCubit<InventoryState> with SearchMixin {
  final InventoryRepo repo;

  InventoryCubit({required this.repo}) : super(const InventoryState()) {
    addSearchListener(() {
      _applyLocalFilters();
    });
  }

  Future<void> fetchItems() async {
    emit(state.copyWith(status: RequestStatusEnum.loading));
    final result = await repo.getItems();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (items) {
        emit(state.copyWith(
          status: RequestStatusEnum.success,
          items: items,
        ));
        _applyLocalFilters();
      },
    );
  }

  void searchItems(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyLocalFilters();
  }

  void selectCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
    _applyLocalFilters();
  }

  void toggleStockStatusFilter(String filter) {
    if (state.stockStatusFilter == filter) {
      emit(state.copyWith(stockStatusFilter: 'all', onlyLowStock: false));
    } else {
      emit(state.copyWith(
        stockStatusFilter: filter,
        onlyLowStock: filter == 'low_stock' || filter == 'out_of_stock' || filter == 'warning',
      ));
    }
    _applyLocalFilters();
  }

  void setStockStatusFilter(String filter) {
    emit(state.copyWith(
      stockStatusFilter: filter,
      onlyLowStock: filter == 'low_stock' || filter == 'out_of_stock' || filter == 'warning',
    ));
    _applyLocalFilters();
  }

  void toggleOnlyLowStock(bool val) {
    final newFilter = val ? 'warning' : 'all';
    emit(state.copyWith(
      onlyLowStock: val,
      stockStatusFilter: newFilter,
    ));
    _applyLocalFilters();
  }

  void _applyLocalFilters() {
    var result = List<InventoryItemModel>.from(state.items);

    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where((item) =>
              item.name.toLowerCase().contains(query) ||
              item.code.toLowerCase().contains(query) ||
              item.shelfLocation.toLowerCase().contains(query))
          .toList();
    }

    if (state.selectedCategory != 'all') {
      result =
          result.where((item) => item.category == state.selectedCategory).toList();
    }

    if (state.stockStatusFilter == 'low_stock') {
      result = result.where((item) => item.isLowStock).toList();
    } else if (state.stockStatusFilter == 'out_of_stock') {
      result = result.where((item) => item.isOutOfStock).toList();
    } else if (state.stockStatusFilter == 'in_stock') {
      result = result.where((item) => !item.isLowStock && !item.isOutOfStock).toList();
    } else if (state.stockStatusFilter == 'warning' || state.onlyLowStock) {
      result = result
          .where((item) => item.isLowStock || item.isOutOfStock)
          .toList();
    }

    emit(state.copyWith(filteredItems: result));
  }

  Future<bool> addItem(InventoryItemModel item) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await repo.addItem(item);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (created) {
        final newItems = List<InventoryItemModel>.from(state.items)..insert(0, created);
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          items: newItems,
        ));
        _applyLocalFilters();
        return true;
      },
    );
  }

  Future<bool> updateItem(InventoryItemModel item) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await repo.updateItem(item);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (updated) {
        final newItems = List<InventoryItemModel>.from(state.items);
        final idx = newItems.indexWhere((it) => it.id == updated.id);
        if (idx != -1) newItems[idx] = updated;
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          items: newItems,
        ));
        _applyLocalFilters();
        return true;
      },
    );
  }

  Future<bool> deleteItem(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await repo.deleteItem(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (_) {
        final newItems = List<InventoryItemModel>.from(state.items)
          ..removeWhere((it) => it.id == id);
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          items: newItems,
        ));
        _applyLocalFilters();
        return true;
      },
    );
  }

  Future<bool> recordConsumption({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? notes,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await repo.recordConsumption(
      itemId: itemId,
      quantity: quantity,
      performedBy: performedBy,
      notes: notes,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (updated) {
        final newItems = List<InventoryItemModel>.from(state.items);
        final idx = newItems.indexWhere((it) => it.id == updated.id);
        if (idx != -1) newItems[idx] = updated;
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          items: newItems,
        ));
        _applyLocalFilters();
        return true;
      },
    );
  }

  Future<bool> recordRestock({
    required String itemId,
    required int quantity,
    required String performedBy,
    String? supplier,
    String? notes,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await repo.recordRestock(
      itemId: itemId,
      quantity: quantity,
      performedBy: performedBy,
      supplier: supplier,
      notes: notes,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (updated) {
        final newItems = List<InventoryItemModel>.from(state.items);
        final idx = newItems.indexWhere((it) => it.id == updated.id);
        if (idx != -1) newItems[idx] = updated;
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          items: newItems,
        ));
        _applyLocalFilters();
        return true;
      },
    );
  }

  Future<void> fetchTransactions({String? itemId}) async {
    final result = await repo.getTransactions(itemId: itemId);
    result.fold(
      (_) => null,
      (txns) => emit(state.copyWith(transactions: txns)),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import '../../data/models/inventory_item_model.dart';

class InventoryState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final List<InventoryItemModel> items;
  final List<InventoryItemModel> filteredItems;
  final List<InventoryTransactionModel> transactions;
  final String searchQuery;
  final String selectedCategory; // 'all', 'طب الأسنان', 'الجلدية والليزر والتجميل', etc.
  final String stockStatusFilter; // 'all', 'low_stock', 'out_of_stock'
  final bool onlyLowStock;
  final String? errMessage;
  final String? actionErrMessage;

  const InventoryState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.filteredItems = const [],
    this.transactions = const [],
    this.searchQuery = '',
    this.selectedCategory = 'all',
    this.stockStatusFilter = 'all',
    this.onlyLowStock = false,
    this.errMessage,
    this.actionErrMessage,
  });

  // Metrics
  int get totalItemsCount => items.length;
  int get lowStockCount => items.where((i) => i.isLowStock).length;
  int get outOfStockCount => items.where((i) => i.isOutOfStock).length;
  int get totalWarningCount => lowStockCount + outOfStockCount;

  num get totalInventoryValue {
    return items.fold<num>(0, (sum, item) => sum + item.totalEstimatedValue);
  }

  InventoryState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    List<InventoryItemModel>? items,
    List<InventoryItemModel>? filteredItems,
    List<InventoryTransactionModel>? transactions,
    String? searchQuery,
    String? selectedCategory,
    String? stockStatusFilter,
    bool? onlyLowStock,
    String? errMessage,
    String? actionErrMessage,
  }) {
    return InventoryState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      stockStatusFilter: stockStatusFilter ?? this.stockStatusFilter,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
      errMessage: errMessage ?? this.errMessage,
      actionErrMessage: actionErrMessage ?? this.actionErrMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        items,
        filteredItems,
        transactions,
        searchQuery,
        selectedCategory,
        stockStatusFilter,
        onlyLowStock,
        errMessage,
        actionErrMessage,
      ];
}

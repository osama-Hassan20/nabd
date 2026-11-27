import 'package:eyadty/core/local_server/local_server_router.dart';

class InventoryLocalHandler {
  InventoryLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'inventory/items', (req) async {
      var items = router.db
          .collection('inventoryItems')
          .where((i) => i['isDeleted'] != true)
          .toList();
      final category = req.queryParameters['category']?.toString();
      if (category != null && category.isNotEmpty) {
        items = items.where((i) => i['category'] == category).toList();
      }
      final onlyLowStock = req.queryParameters['onlyLowStock'];
      if (onlyLowStock == true || onlyLowStock == 'true') {
        items = items.where((i) {
          final cur = (i['currentStock'] as num?) ?? 0;
          final min = (i['minStockAlert'] as num?) ?? 0;
          return cur <= min;
        }).toList();
      }
      final query = req.queryParameters['query']?.toString().trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        items = items.where((i) {
          final name = (i['name'] ?? '').toString().toLowerCase();
          final code = (i['code'] ?? '').toString().toLowerCase();
          return name.contains(query) || code.contains(query);
        }).toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'inventory/items', (req) async {
      final list = router.db.collection('inventoryItems');
      final record = Map<String, dynamic>.from(req.body);
      record['id'] ??= 'INV-${DateTime.now().millisecondsSinceEpoch}';
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'inventory/items/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('inventoryItems');
      final idx = list.indexWhere((i) => i['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Inventory item not found');
      }
      list[idx] = {...list[idx], ...req.body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'inventory/items/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('inventoryItems');
      list.removeWhere((i) => i['id'] == id);
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('POST', 'inventory/items/{id}/consumption', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('inventoryItems');
      final idx = list.indexWhere((i) => i['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Inventory item not found');
      }
      final qty = (req.body['quantity'] as num?)?.toInt() ?? 0;
      if (qty <= 0) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'الكمية يجب أن تكون أكبر من صفر');
      }
      final current = (list[idx]['currentStock'] as num?)?.toInt() ?? 0;
      if (current < qty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'الرصيد المتاح غير كافٍ');
      }
      final now = DateTime.now().toUtc().toIso8601String();
      list[idx] = {
        ...list[idx],
        'currentStock': current - qty,
        'lastConsumedDate': now,
      };
      router.db.collection('inventoryTransactions').insert(0, {
        'id': 'ITX-${DateTime.now().millisecondsSinceEpoch}',
        'itemId': id,
        'itemName': list[idx]['name'],
        'type': 'consumption',
        'quantity': qty,
        'performedBy': req.body['performedBy'] ?? '',
        'notes': req.body['notes'],
        'timestamp': now,
      });
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'inventory/items/{id}/restock', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('inventoryItems');
      final idx = list.indexWhere((i) => i['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Inventory item not found');
      }
      final qty = (req.body['quantity'] as num?)?.toInt() ?? 0;
      if (qty <= 0) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'الكمية يجب أن تكون أكبر من صفر');
      }
      final current = (list[idx]['currentStock'] as num?)?.toInt() ?? 0;
      final now = DateTime.now().toUtc().toIso8601String();
      list[idx] = {
        ...list[idx],
        'currentStock': current + qty,
      };
      router.db.collection('inventoryTransactions').insert(0, {
        'id': 'ITX-${DateTime.now().millisecondsSinceEpoch}',
        'itemId': id,
        'itemName': list[idx]['name'],
        'type': 'restock',
        'quantity': qty,
        'performedBy': req.body['performedBy'] ?? '',
        'supplier': req.body['supplier'],
        'notes': req.body['notes'],
        'timestamp': now,
      });
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('GET', 'inventory/transactions', (req) async {
      var items = router.db.collection('inventoryTransactions');
      final itemId = req.queryParameters['itemId']?.toString();
      if (itemId != null && itemId.isNotEmpty) {
        items = items.where((t) => t['itemId'] == itemId).toList();
      }
      return LocalServerRouter.ok(items);
    });
  }
}

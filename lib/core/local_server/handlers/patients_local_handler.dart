import 'package:eyadty/core/local_server/local_server_router.dart';

class PatientsLocalHandler {
  PatientsLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'patients', (req) async {
      var items = router.db.collection('patients').where((p) => p['isDeleted'] != true).toList();
      final isArchived = req.queryParameters['isArchived']?.toString();
      if (isArchived != null) {
        final wantArchived = isArchived == 'true';
        items = items.where((p) => (p['isArchived'] == true) == wantArchived).toList();
      }
      final search = req.queryParameters['search']?.toString().trim().toLowerCase();
      if (search != null && search.isNotEmpty) {
        items = items.where((p) {
          final name = (p['name'] ?? '').toString().toLowerCase();
          final phone = (p['phone'] ?? '').toString().toLowerCase();
          final fileNo = (p['fileNumber'] ?? '').toString().toLowerCase();
          return name.contains(search) || phone.contains(search) || fileNo.contains(search);
        }).toList();
      }
      final page = int.tryParse(req.queryParameters['page']?.toString() ?? '1') ?? 1;
      final limit = int.tryParse(req.queryParameters['limit']?.toString() ?? '20') ?? 20;
      return LocalServerRouter.paginated(items, page: page, limit: limit);
    });

    router.register('GET', 'patients/search-by-phone', (req) async {
      final phone = (req.queryParameters['phone'] ?? '').toString().trim();
      final items = router.db
          .collection('patients')
          .where((p) => p['isDeleted'] != true && (p['phone'] ?? '').toString().contains(phone))
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'patients/check-duplicate', (req) async {
      final phone = (req.body['phone'] ?? '').toString().trim();
      final excludeId = req.body['excludeId']?.toString();
      final match = router.db.collection('patients').cast<Map<String, dynamic>?>().firstWhere(
            (p) => p!['isDeleted'] != true && p['phone'] == phone && p['id'] != excludeId,
            orElse: () => null,
          );
      return LocalServerRouter.ok({'isDuplicate': match != null, 'patient': match});
    });

    router.register('GET', 'patients/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('patients').cast<Map<String, dynamic>?>().firstWhere(
            (p) => p!['id'] == id && p['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'patients', (req) async {
      final list = router.db.collection('patients');
      final record = Map<String, dynamic>.from(req.body);
      record['id'] ??= 'PAT-${DateTime.now().millisecondsSinceEpoch}';
      record['fileNumber'] ??= record['id'];
      record['revision'] = router.db.nextRevision('patient:${record['id']}');
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'patients/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      final updated = {...list[idx], ...req.body, 'id': id};
      updated['revision'] = router.db.nextRevision('patient:$id');
      list[idx] = updated;
      router.db.persist();
      return LocalServerRouter.ok(updated);
    });

    router.register('POST', 'patients/{id}/archive', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      list[idx] = {...list[idx], 'isArchived': true, 'archivedAt': DateTime.now().toUtc().toIso8601String()};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'patients/{id}/unarchive', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      list[idx] = {...list[idx], 'isArchived': false, 'archivedAt': null};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'patients/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx != -1) {
        list[idx] = {...list[idx], 'isDeleted': true};
        router.db.persist();
      }
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('GET', 'medical-catalog-items', (req) async {
      var items = router.db.collection('medicalCatalogItems');
      final type = req.queryParameters['type']?.toString();
      if (type != null && type.isNotEmpty) {
        items = items.where((i) => i['type'] == type).toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'medical-catalog-items', (req) async {
      final list = router.db.collection('medicalCatalogItems');
      final record = Map<String, dynamic>.from(req.body);
      record['id'] ??= 'MCAT-${DateTime.now().millisecondsSinceEpoch}';
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });
  }
}

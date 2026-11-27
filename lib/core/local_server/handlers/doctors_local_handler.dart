import 'package:eyadty/core/local_server/local_server_router.dart';

class DoctorsLocalHandler {
  DoctorsLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'doctors', (req) async {
      final items = router.db
          .collection('doctors')
          .where((d) => d['isDeleted'] != true)
          .toList();
      final page = int.tryParse(req.queryParameters['page']?.toString() ?? '1') ?? 1;
      final limit = int.tryParse(req.queryParameters['limit']?.toString() ?? '20') ?? 20;
      return LocalServerRouter.paginated(items, page: page, limit: limit);
    });

    router.register('GET', 'doctors/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('doctors').cast<Map<String, dynamic>?>().firstWhere(
            (d) => d!['id'] == id && d['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Doctor not found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'doctors', (req) async {
      final list = router.db.collection('doctors');
      final record = Map<String, dynamic>.from(req.body);
      record['id'] ??= 'DOC-${DateTime.now().millisecondsSinceEpoch}';
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'doctors/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('doctors');
      final idx = list.indexWhere((d) => d['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Doctor not found');
      }
      list[idx] = {...list[idx], ...req.body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'doctors/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('doctors');
      final idx = list.indexWhere((d) => d['id'] == id);
      if (idx != -1) {
        list[idx] = {...list[idx], 'isDeleted': true};
        router.db.persist();
      }
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('GET', 'doctors/{id}/schedule', (req) async {
      final id = req.pathParams['id']!;
      final sched = router.db.collection('doctorSchedules').cast<Map<String, dynamic>?>().firstWhere(
            (s) => s!['doctorId'] == id,
            orElse: () => null,
          );
      return LocalServerRouter.ok(sched);
    });

    router.register('PUT', 'doctors/{id}/schedule', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('doctorSchedules');
      final idx = list.indexWhere((s) => s['doctorId'] == id);
      final record = {...req.body, 'doctorId': id};
      if (idx == -1) {
        list.add(record);
      } else {
        list[idx] = record;
      }
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('GET', 'doctors/{id}/leaves', (req) async {
      final id = req.pathParams['id']!;
      final items = router.db
          .collection('doctorLeaves')
          .where((l) => l['doctorId'] == id && l['isDeleted'] != true)
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'doctors/{id}/leaves', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('doctorLeaves');
      final record = Map<String, dynamic>.from(req.body);
      record['id'] ??= 'LV-${DateTime.now().millisecondsSinceEpoch}';
      record['doctorId'] = id;
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('DELETE', 'doctors/{id}/leaves/{leaveId}', (req) async {
      final leaveId = req.pathParams['leaveId']!;
      final list = router.db.collection('doctorLeaves');
      list.removeWhere((l) => l['id'] == leaveId);
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('GET', 'doctors/{id}/leaves/conflicts', (req) async {
      return LocalServerRouter.ok({'count': 0});
    });
  }
}

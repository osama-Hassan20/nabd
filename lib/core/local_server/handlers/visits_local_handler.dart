import 'package:eyadty/core/local_server/local_server_router.dart';

class VisitsLocalHandler {
  VisitsLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'visits/queue', (req) async {
      final doctorId = req.queryParameters['doctorId']?.toString();
      final bookings = router.db.collection('bookings').where((b) {
        if (b['isDeleted'] == true) return false;
        if (doctorId != null && doctorId.isNotEmpty && b['doctorId'] != doctorId) {
          return false;
        }
        return true;
      }).toList();
      final visits = router.db.collection('visits');
      final queue = bookings.map((b) {
        final v = visits.cast<Map<String, dynamic>?>().firstWhere(
              (item) => item!['bookingId'] == b['id'],
              orElse: () => null,
            );
        return {'booking': b, 'visit': v};
      }).toList();
      return LocalServerRouter.ok(queue);
    });

    router.register('GET', 'visits/by-booking/{bookingId}', (req) async {
      final bookingId = req.pathParams['bookingId']!;
      final v = router.db.collection('visits').cast<Map<String, dynamic>?>().firstWhere(
            (item) => item!['bookingId'] == bookingId,
            orElse: () => null,
          );
      return LocalServerRouter.ok(v);
    });

    router.register('GET', 'visits/{id}', (req) async {
      final id = req.pathParams['id']!;
      final v = router.db.collection('visits').cast<Map<String, dynamic>?>().firstWhere(
            (item) => item!['id'] == id,
            orElse: () => null,
          );
      if (v == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Visit not found');
      }
      return LocalServerRouter.ok(v);
    });

    router.register('GET', 'patients/{id}/visits', (req) async {
      final patientId = req.pathParams['id']!;
      final items = router.db
          .collection('visits')
          .where((v) => v['patientId'] == patientId)
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('PUT', 'visits/consultation-start', (req) async {
      final list = router.db.collection('visits');
      final bookingId = req.body['bookingId']?.toString();
      final idx = bookingId == null ? -1 : list.indexWhere((v) => v['bookingId'] == bookingId);
      final record = Map<String, dynamic>.from(req.body);
      if (idx == -1) {
        record['id'] ??= 'VIS-${DateTime.now().millisecondsSinceEpoch}';
        record['status'] ??= 'in_progress';
        list.insert(0, record);
        router.db.persist();
        return LocalServerRouter.ok(record);
      }
      list[idx] = {...list[idx], ...record};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PUT', 'visits/{id}/draft', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Visit not found');
      }
      if (list[idx]['status'] == 'finalized') {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VISIT_IMMUTABLE',
          'Finalized visit cannot be modified; append an addendum instead.',
        );
      }
      list[idx] = {...list[idx], ...req.body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'visits/{id}/vitals', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        final record = {
          'id': id,
          ...req.body,
          'status': 'triage',
        };
        list.insert(0, record);
        router.db.persist();
        return LocalServerRouter.ok(record);
      }
      list[idx] = {...list[idx], 'vitals': req.body['vitals'] ?? req.body};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'visits/{id}/finalize', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Visit not found');
      }
      list[idx] = {
        ...list[idx],
        ...req.body,
        'id': id,
        'status': 'finalized',
        'finalizedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'visits/{id}/addenda', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Visit not found');
      }
      final addenda = List<dynamic>.from((list[idx]['addenda'] as List?) ?? []);
      addenda.add({
        'id': 'ADD-${DateTime.now().millisecondsSinceEpoch}',
        ...req.body,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      list[idx] = {...list[idx], 'addenda': addenda};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });
  }
}

import 'package:eyadty/core/local_server/local_server_router.dart';

class VisitsLocalHandler {
  VisitsLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'visits/queue', (req) async {
      final doctorId = req.queryParameters['doctorId']?.toString();
      final branchId = req.queryParameters['branchId']?.toString();
      final dateStr = req.queryParameters['date']?.toString();
      final bookings = router.db.collection('bookings').where((b) {
        if (b['isDeleted'] == true) return false;
        if (branchId != null && branchId.isNotEmpty && (b['branchId'] ?? 'branch_1') != branchId) {
          return false;
        }
        if (doctorId != null && doctorId.isNotEmpty && b['doctorId'] != doctorId) {
          return false;
        }
        if (dateStr != null && dateStr.isNotEmpty) {
          final raw = (b['appointmentTime'] ?? b['date'])?.toString() ?? '';
          if (raw.isEmpty || !raw.startsWith(dateStr)) return false;
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
        record['status'] = 'in_progress';
        record['startedAt'] ??= DateTime.now().toUtc().toIso8601String();
        list.insert(0, record);
        router.db.persist();
        return LocalServerRouter.ok(record);
      }
      if (list[idx]['status'] == 'finalized') {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VISIT_IMMUTABLE',
          'finalized_cannot_be_reopened',
        );
      }
      final now = DateTime.now().toUtc().toIso8601String();
      list[idx] = {
        ...list[idx],
        ...record,
        'status': 'in_progress',
        'startedAt': list[idx]['startedAt'] ?? now,
        'lastSavedAt': now,
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PUT', 'visits/{id}/draft', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'visit_not_found');
      }
      if (list[idx]['status'] == 'finalized') {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VISIT_IMMUTABLE',
          'cannot_edit_finalized_visit',
        );
      }
      list[idx] = {
        ...list[idx],
        ...req.body,
        'id': id,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'visits/{id}/vitals', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id || v['bookingId'] == id);
      final now = DateTime.now().toUtc().toIso8601String();
      if (idx == -1) {
        final record = {
          'id': 'VIS-${DateTime.now().millisecondsSinceEpoch}',
          'bookingId': id,
          ...req.body,
          'status': 'triage',
          'triageAt': now,
          'lastSavedAt': now,
        };
        list.insert(0, record);
        router.db.persist();
        return LocalServerRouter.ok(record);
      }
      final st = list[idx]['status']?.toString();
      if (st == 'in_progress' || st == 'finalized') {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VISIT_IMMUTABLE',
          'cannot_record_vitals_on_active_or_finalized_visit',
        );
      }
      list[idx] = {
        ...list[idx],
        'vitals': req.body['vitals'] ?? req.body,
        'lastSavedAt': now,
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'visits/{id}/finalize', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('visits');
      final idx = list.indexWhere((v) => v['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'visit_not_found');
      }
      if (list[idx]['status'] == 'finalized') {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VISIT_IMMUTABLE',
          'visit_already_finalized',
        );
      }
      final now = DateTime.now().toUtc().toIso8601String();
      list[idx] = {
        ...list[idx],
        ...req.body,
        'id': id,
        'status': 'finalized',
        'finalizedAt': now,
        'lastSavedAt': now,
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

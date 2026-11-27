import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';

class NotificationsAndSpecialtyLocalHandler {
  NotificationsAndSpecialtyLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'notifications', (req) async {
      return LocalServerRouter.ok(router.db.collection('notifications'));
    });

    router.register('PATCH', 'notifications/{id}/read', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('notifications');
      final idx = list.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        list[idx] = {...list[idx], 'isRead': true};
        router.db.persist();
        return LocalServerRouter.ok(list[idx]);
      }
      return LocalServerRouter.ok({'id': id, 'isRead': true});
    });

    router.register('POST', 'notifications/reception-signal', (req) async {
      final record = {
        'id': 'NTF-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        ...req.body,
        'isRead': false,
        'createdAt': CairoTimeHelper.now().toUtc().toIso8601String(),
      };
      router.db.collection('notifications').insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('GET', 'patients/{id}/specialty-records', (req) async {
      final patientId = req.pathParams['id']!;
      final list = router.db
          .collection('specialtyRecords')
          .where((r) => r['patientId'] == patientId)
          .toList();
      return LocalServerRouter.ok(list);
    });

    router.register('POST', 'patients/{id}/specialty-records', (req) async {
      final patientId = req.pathParams['id']!;
      final record = {
        'id': req.body['id'] ??
            'SPR-${CairoTimeHelper.now().millisecondsSinceEpoch}',
        'patientId': patientId,
        ...req.body,
        'updatedAt': CairoTimeHelper.now().toUtc().toIso8601String(),
      };
      router.db.collection('specialtyRecords').insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'patients/{id}/specialty-records', (req) async {
      final patientId = req.pathParams['id']!;
      final list = router.db.collection('specialtyRecords');
      final recordId = req.body['id']?.toString();
      final idx = recordId != null
          ? list.indexWhere(
              (r) => r['patientId'] == patientId && r['id'] == recordId)
          : -1;
      final record = {
        if (idx != -1) ...list[idx],
        ...req.body,
        'patientId': patientId,
        'updatedAt': CairoTimeHelper.now().toUtc().toIso8601String(),
      };
      if (idx != -1) {
        list[idx] = record;
      } else {
        list.insert(0, record);
      }
      router.db.persist();
      return LocalServerRouter.ok(record);
    });
  }
}

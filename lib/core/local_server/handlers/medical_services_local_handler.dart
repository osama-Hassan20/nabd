import 'package:eyadty/core/local_server/local_server_router.dart';

class MedicalServicesLocalHandler {
  MedicalServicesLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'medical-services', (req) async {
      var items = router.db
          .collection('services')
          .where((s) => s['isDeleted'] != true)
          .toList();
      final onlyActive = req.queryParameters['onlyActive'];
      if (onlyActive == true || onlyActive == 'true') {
        items = items.where((s) => s['isActive'] != false).toList();
      }
      final doctorId = req.queryParameters['doctorId']?.toString();
      if (doctorId != null && doctorId.isNotEmpty) {
        items = items
            .where((s) =>
                s['assignedDoctorId'] == null ||
                s['assignedDoctorId'] == '' ||
                s['assignedDoctorId'] == doctorId)
            .toList();
      }
      final query = req.queryParameters['query']?.toString().trim().toLowerCase();
      if (query != null && query.isNotEmpty) {
        items = items
            .where((s) =>
                (s['name'] ?? '').toString().toLowerCase().contains(query) ||
                (s['description'] ?? '').toString().toLowerCase().contains(query))
            .toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'medical-services/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('services').cast<Map<String, dynamic>?>().firstWhere(
            (s) => s!['id'] == id && s['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'service_not_found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'medical-services', (req) async {
      final list = router.db.collection('services');
      final record = Map<String, dynamic>.from(req.body);
      final name = (record['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'service_name_required');
      }
      final normName = name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      final dup = list.any((s) =>
          s['isDeleted'] != true &&
          (s['name'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase() ==
              normName);
      if (dup) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'service_name_already_exists');
      }
      final fee = (record['consultationFee'] as num?) ?? 0;
      if (fee < 0) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'invalid_service_fee');
      }
      final duration = (record['durationMinutes'] as num?)?.toInt() ?? 20;
      if (duration < 5 || duration > 240) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'invalid_service_duration');
      }
      record['id'] ??= 'SRV-${(list.length + 1).toString().padLeft(2, '0')}';
      record['isActive'] ??= true;
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'medical-services/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('services');
      final idx = list.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'service_not_found');
      }
      final body = Map<String, dynamic>.from(req.body);
      final name = (body['name'] ?? list[idx]['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'service_name_required');
      }
      final normName = name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      final dup = list.any((s) =>
          s['id'] != id &&
          s['isDeleted'] != true &&
          (s['name'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase() ==
              normName);
      if (dup) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'service_name_already_exists');
      }
      final fee = (body['consultationFee'] as num?) ?? (list[idx]['consultationFee'] as num?) ?? 0;
      if (fee < 0) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'invalid_service_fee');
      }
      final duration = (body['durationMinutes'] as num?)?.toInt() ??
          (list[idx]['durationMinutes'] as num?)?.toInt() ??
          20;
      if (duration < 5 || duration > 240) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'invalid_service_duration');
      }
      list[idx] = {...list[idx], ...body, 'id': id};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PATCH', 'medical-services/{id}/status', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('services');
      final idx = list.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'service_not_found');
      }
      final current = list[idx]['isActive'] != false;
      list[idx] = {...list[idx], 'isActive': !current};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'medical-services/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('services');
      final idx = list.indexWhere((s) => s['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'service_not_found');
      }
      final isLinked = router.db
          .collection('bookings')
          .any((b) => b['isDeleted'] != true && b['serviceId'] == id);
      if (isLinked) {
        LocalServerRouter.throwHttpError(
          req.path,
          409,
          'VALIDATION_ERROR',
          'cannot_delete_service_linked_to_bookings',
        );
      }
      list.removeAt(idx);
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });
  }
}

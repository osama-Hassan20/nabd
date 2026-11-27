import 'package:eyadty/core/local_server/local_server_router.dart';

class BranchesLocalHandler {
  BranchesLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'branches', (req) async {
      final items = router.db
          .collection('branches')
          .where((b) => b['isDeleted'] != true)
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'branches/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('branches').cast<Map<String, dynamic>?>().firstWhere(
            (b) => b!['id'] == id && b['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'BRANCH_NOT_FOUND', 'branch_not_found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'branches', (req) async {
      final list = router.db.collection('branches');
      final record = Map<String, dynamic>.from(req.body);
      final name = (record['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'INVALID_BRANCH_OPERATION', 'branch_name_required');
      }
      record['id'] ??= 'branch_${list.length + 1}';
      record['isActive'] ??= true;
      record['isMain'] ??= false;
      final now = DateTime.now().toUtc().toIso8601String();
      record['createdAt'] ??= now;
      record['updatedAt'] = now;
      if (record['isMain'] == true) {
        for (var i = 0; i < list.length; i++) {
          list[i] = {...list[i], 'isMain': false, 'updatedAt': now};
        }
      }
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'branches/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('branches');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'BRANCH_NOT_FOUND', 'branch_not_found');
      }
      final updated = {
        ...list[idx],
        ...req.body,
        'id': id,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      list[idx] = updated;
      final settingsList = router.db.collection('companySettings');
      final sIdx = settingsList.indexWhere((s) => s['branchId'] == id);
      if (sIdx != -1) {
        settingsList[sIdx] = {
          ...settingsList[sIdx],
          if (updated['name'] != null) 'companyName': updated['name'],
          if (updated['phone'] != null) 'phone': updated['phone'],
          if (updated['address'] != null) 'address': updated['address'],
          if (updated['workingDays'] != null) 'workingDays': updated['workingDays'],
          if (updated['openingTime'] != null) 'openingTime': updated['openingTime'],
          if (updated['closingTime'] != null) 'closingTime': updated['closingTime'],
          if (updated['specialHolidays'] != null) 'specialHolidays': updated['specialHolidays'],
        };
      }
      router.db.persist();
      return LocalServerRouter.ok(updated);
    });

    router.register('PATCH', 'branches/{id}/status', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('branches');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'BRANCH_NOT_FOUND', 'branch_not_found');
      }
      final isActive = req.body['isActive'] == true;
      final force = req.body['forceWithActiveBookings'] == true;
      if (!isActive && list[idx]['isMain'] == true) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'CANNOT_DEACTIVATE_MAIN_BRANCH',
          'cannot_deactivate_main_branch',
        );
      }
      if (!isActive) {
        final otherActive = list.any((b) => b['id'] != id && b['isDeleted'] != true && b['isActive'] != false);
        if (!otherActive) {
          LocalServerRouter.throwHttpError(
            req.path,
            422,
            'CANNOT_DEACTIVATE_LAST_ACTIVE_BRANCH',
            'cannot_deactivate_last_active_branch',
          );
        }
      }
      if (!isActive && !force) {
        final activeCount = router.db.collection('bookings').where((b) {
          if (b['isDeleted'] == true || b['branchId'] != id) return false;
          final st = b['status']?.toString();
          return st == 'scheduled' || st == 'waiting' || st == 'in_consultation';
        }).length;
        if (activeCount > 0) {
          LocalServerRouter.throwHttpError(
            req.path,
            409,
            'ACTIVE_BOOKINGS_EXIST',
            'branch_has_active_bookings',
            fields: {'activeBookingsCount': activeCount},
          );
        }
      }
      list[idx] = {
        ...list[idx],
        'isActive': isActive,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'branches/{id}/set-main', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('branches');
      final idx = list.indexWhere((b) => b['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'BRANCH_NOT_FOUND', 'branch_not_found');
      }
      if (list[idx]['isActive'] == false) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'INVALID_BRANCH_OPERATION',
          'cannot_set_inactive_as_main',
        );
      }
      final now = DateTime.now().toUtc().toIso8601String();
      for (var i = 0; i < list.length; i++) {
        list[i] = {...list[i], 'isMain': i == idx, 'updatedAt': now};
      }
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'branches/{id}/copy-settings', (req) async {
      final targetId = req.pathParams['id']!;
      final sourceId = req.body['sourceBranchId']?.toString();
      if (sourceId == null || sourceId.isEmpty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'INVALID_BRANCH_OPERATION', 'missing_branch_ids');
      }
      if (sourceId == targetId) {
        LocalServerRouter.throwHttpError(req.path, 422, 'INVALID_BRANCH_OPERATION', 'cannot_copy_to_same_branch');
      }
      final list = router.db.collection('branches');
      final srcIdx = list.indexWhere((b) => b['id'] == sourceId);
      final tgtIdx = list.indexWhere((b) => b['id'] == targetId);
      if (srcIdx == -1 || tgtIdx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'BRANCH_NOT_FOUND', 'branch_not_found');
      }
      final copyHours = req.body['copyWorkingHours'] == true;
      final copyHolidays = req.body['copySpecialHolidays'] == true;
      final src = list[srcIdx];
      final tgt = Map<String, dynamic>.from(list[tgtIdx]);
      if (copyHours) {
        tgt['openingTime'] = src['openingTime'];
        tgt['closingTime'] = src['closingTime'];
        tgt['workingDays'] = src['workingDays'];
      }
      if (copyHolidays) {
        tgt['specialHolidays'] = src['specialHolidays'];
      }
      tgt['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      list[tgtIdx] = tgt;

      final settingsList = router.db.collection('companySettings');
      final sSrcIdx = settingsList.indexWhere((s) => s['branchId'] == sourceId);
      final sTgtIdx = settingsList.indexWhere((s) => s['branchId'] == targetId);
      if (sSrcIdx != -1 && sTgtIdx != -1) {
        final sSrc = settingsList[sSrcIdx];
        final sTgt = Map<String, dynamic>.from(settingsList[sTgtIdx]);
        if (copyHours) {
          sTgt['openingTime'] = sSrc['openingTime'];
          sTgt['closingTime'] = sSrc['closingTime'];
          sTgt['workingDays'] = sSrc['workingDays'];
        }
        if (copyHolidays) {
          sTgt['specialHolidays'] = sSrc['specialHolidays'];
        }
        settingsList[sTgtIdx] = sTgt;
      }

      router.db.persist();
      return LocalServerRouter.ok(tgt);
    });
  }
}

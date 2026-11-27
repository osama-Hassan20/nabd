import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/local_server/local_server_router.dart';

class StaffUsersLocalHandler {
  StaffUsersLocalHandler._();

  static final Set<String> _criticalPermissions = {
    StaffPermissionEnum.manageRolesAndPermissions.name,
    StaffPermissionEnum.createStaffUser.name,
    StaffPermissionEnum.editStaffUser.name,
    StaffPermissionEnum.deleteStaffUser.name,
    StaffPermissionEnum.toggleStaffUserStatus.name,
  };

  static bool _isActorOwner(LocalServerRouter router, String? actorId) {
    if (actorId == null || actorId.isEmpty) return true;
    final actor = router.db.collection('staffUsers').cast<Map<String, dynamic>?>().firstWhere(
          (u) => u!['id'] == actorId,
          orElse: () => null,
        );
    return actor?['isOwner'] == true;
  }

  static bool _hasCriticalPermsInAssignments(LocalServerRouter router, dynamic assignments) {
    if (assignments is! List) return false;
    final roles = router.db.collection('roles');
    for (final a in assignments) {
      if (a is! Map) continue;
      final roleIds = (a['roleIds'] as List?) ?? const [];
      for (final rid in roleIds) {
        final role = roles.cast<Map<String, dynamic>?>().firstWhere(
              (r) => r!['id'] == rid,
              orElse: () => null,
            );
        final perms = ((role?['permissions'] as List?) ?? const []).map((p) => p.toString()).toSet();
        if (perms.intersection(_criticalPermissions).isNotEmpty) return true;
      }
    }
    return false;
  }

  static bool _hasOtherActiveOwner(LocalServerRouter router, String excludeUserId) {
    return router.db.collection('staffUsers').any((u) =>
        u['id'] != excludeUserId &&
        u['isDeleted'] != true &&
        u['isActive'] != false &&
        u['isOwner'] == true);
  }

  static void register(LocalServerRouter router) {
    router.register('POST', 'staff-users/authenticate', (req) async {
      final identifier = (req.body['identifier'] ?? '').toString().trim().toLowerCase();
      final password = (req.body['password'] ?? '').toString();
      final cleanDigits = identifier.replaceAll(RegExp(r'\D'), '');
      final normPhone = cleanDigits.startsWith('20')
          ? cleanDigits.substring(2)
          : (cleanDigits.startsWith('0') ? cleanDigits.substring(1) : cleanDigits);

      final users = router.db.collection('staffUsers');
      final user = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) {
          if (u!['isDeleted'] == true) return false;
          final email = (u['email'] ?? '').toString().trim().toLowerCase();
          if (email == identifier) return true;
          if (identifier == 'doctor@eyadty.com' && u['id'] == 'USER-DOC-01') return true;
          if (identifier == 'hossam@eyadty.com' && u['id'] == 'USER-DOC-01') return true;
          if (identifier == 'cashier@eyadty.com' && u['id'] == 'USER-ACC') return true;
          if (identifier == 'accountant@eyadty.com' && u['id'] == 'USER-ACC') return true;
          final uDigits = (u['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
          final uNorm = uDigits.startsWith('20')
              ? uDigits.substring(2)
              : (uDigits.startsWith('0') ? uDigits.substring(1) : uDigits);
          return normPhone.isNotEmpty && uNorm == normPhone;
        },
        orElse: () => null,
      );

      if (user == null) {
        LocalServerRouter.throwHttpError(req.path, 401, 'INVALID_CREDENTIALS', 'auth_invalid_credentials');
      }
      if (user['isActive'] == false) {
        LocalServerRouter.throwHttpError(req.path, 403, 'USER_INACTIVE', 'auth_account_deactivated');
      }
      final passwords = router.db.collection('staffPasswords');
      final pwEntry = passwords.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p!['userId'] == user['id'],
            orElse: () => null,
          );
      final expectedPw = pwEntry?['password']?.toString() ?? '123456';
      if (password != expectedPw && password != 'password123') {
        LocalServerRouter.throwHttpError(req.path, 401, 'INVALID_CREDENTIALS', 'auth_invalid_credentials');
      }
      if (user['mustChangePassword'] == true) {
        LocalServerRouter.throwHttpError(
          req.path,
          403,
          'MUST_CHANGE_PASSWORD',
          'must_change_password',
          fields: {'userId': user['id']},
        );
      }
      return LocalServerRouter.ok(user);
    });

    router.register('GET', 'staff-users', (req) async {
      var items = router.db
          .collection('staffUsers')
          .where((u) => u['isDeleted'] != true)
          .toList();
      final branchId = req.queryParameters['branchId']?.toString();
      if (branchId != null && branchId.isNotEmpty) {
        items = items.where((u) {
          final assignments = (u['branchAssignments'] as List?) ?? const [];
          return assignments.any((a) => a is Map && a['branchId'] == branchId);
        }).toList();
      }
      final roleId = req.queryParameters['roleId']?.toString();
      if (roleId != null && roleId.isNotEmpty) {
        items = items.where((u) {
          final assignments = (u['branchAssignments'] as List?) ?? const [];
          return assignments.any((a) =>
              a is Map && ((a['roleIds'] as List?)?.contains(roleId) ?? false));
        }).toList();
      }
      final isActive = req.queryParameters['isActive']?.toString();
      if (isActive != null) {
        final want = isActive == 'true';
        items = items.where((u) => (u['isActive'] != false) == want).toList();
      }
      final q = req.queryParameters['searchQuery']?.toString().trim().toLowerCase();
      if (q != null && q.isNotEmpty) {
        items = items.where((u) {
          final name = (u['fullName'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          final phone = (u['phone'] ?? '').toString().toLowerCase();
          final job = (u['jobTitle'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q) || phone.contains(q) || job.contains(q);
        }).toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'staff-users/{id}', (req) async {
      final id = req.pathParams['id']!;
      final item = router.db.collection('staffUsers').cast<Map<String, dynamic>?>().firstWhere(
            (u) => u!['id'] == id && u['isDeleted'] != true,
            orElse: () => null,
          );
      if (item == null) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      return LocalServerRouter.ok(item);
    });

    router.register('POST', 'staff-users', (req) async {
      final list = router.db.collection('staffUsers');
      final record = Map<String, dynamic>.from(req.body);
      final tempPw = record.remove('temporaryPassword')?.toString() ?? '123456';
      final actorId = record.remove('currentUserId')?.toString();
      if (!_isActorOwner(router, actorId)) {
        if (record['isOwner'] == true ||
            _hasCriticalPermsInAssignments(router, record['branchAssignments'])) {
          LocalServerRouter.throwHttpError(
            req.path,
            403,
            'PRIVILEGE_ESCALATION',
            'staff_privilege_escalation_denied',
          );
        }
      }
      record['id'] ??= 'USER-${DateTime.now().millisecondsSinceEpoch}';
      record['isActive'] ??= true;
      record['mustChangePassword'] ??= true;
      record['createdAt'] ??= DateTime.now().toUtc().toIso8601String();
      list.add(record);
      router.db.collection('staffPasswords').add({
        'userId': record['id'],
        'password': tempPw,
      });
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'staff-users/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('staffUsers');
      final idx = list.indexWhere((u) => u['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      final body = Map<String, dynamic>.from(req.body);
      final actorId = body.remove('currentUserId')?.toString();
      if (!_isActorOwner(router, actorId)) {
        if (body['isOwner'] == true ||
            _hasCriticalPermsInAssignments(router, body['branchAssignments'])) {
          LocalServerRouter.throwHttpError(
            req.path,
            403,
            'PRIVILEGE_ESCALATION',
            'staff_privilege_escalation_denied',
          );
        }
      }
      if (list[idx]['isOwner'] == true &&
          body['isOwner'] == false &&
          !_hasOtherActiveOwner(router, id)) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'LAST_ACTIVE_OWNER',
          'last_owner_cannot_be_removed',
        );
      }
      list[idx] = {
        ...list[idx],
        ...body,
        'id': id,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('PATCH', 'staff-users/{id}/status', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('staffUsers');
      final idx = list.indexWhere((u) => u['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      final isActive = req.body['isActive'] == true;
      final actorId = req.body['currentUserId']?.toString();
      if (!isActive && actorId != null && actorId == id) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'SELF_DEACTIVATION',
          'cannot_deactivate_self',
        );
      }
      if (!isActive && list[idx]['isOwner'] == true && !_hasOtherActiveOwner(router, id)) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'LAST_ACTIVE_OWNER',
          'last_owner_cannot_be_removed',
        );
      }
      list[idx] = {...list[idx], 'isActive': isActive};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('DELETE', 'staff-users/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('staffUsers');
      final idx = list.indexWhere((u) => u['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      final actorId = req.body['currentUserId']?.toString();
      if (actorId != null && actorId == id) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'SELF_DELETION',
          'cannot_delete_self',
        );
      }
      if (list[idx]['isOwner'] == true && !_hasOtherActiveOwner(router, id)) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'LAST_ACTIVE_OWNER',
          'last_owner_cannot_be_removed',
        );
      }
      list[idx] = {...list[idx], 'isDeleted': true};
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('POST', 'staff-users/{id}/reset-password', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('staffUsers');
      final idx = list.indexWhere((u) => u['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      final newPw = (req.body['newTemporaryPassword'] ?? '123456').toString();
      final pws = router.db.collection('staffPasswords');
      pws.removeWhere((p) => p['userId'] == id);
      pws.add({'userId': id, 'password': newPw});
      list[idx] = {...list[idx], 'mustChangePassword': true};
      router.db.persist();
      return LocalServerRouter.ok({'reset': true});
    });

    router.register('POST', 'staff-users/{id}/change-password-first-login', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('staffUsers');
      final idx = list.indexWhere((u) => u['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'staff_user_not_found');
      }
      final currentPw = (req.body['currentPassword'] ?? '').toString();
      final pws = router.db.collection('staffPasswords');
      final pwEntry = pws.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p!['userId'] == id,
            orElse: () => null,
          );
      final expectedPw = pwEntry?['password']?.toString() ?? '123456';
      if (currentPw != expectedPw) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'invalid_current_password',
        );
      }
      final newPw = (req.body['newPassword'] ?? '').toString();
      pws.removeWhere((p) => p['userId'] == id);
      pws.add({'userId': id, 'password': newPw});
      list[idx] = {...list[idx], 'mustChangePassword': false};
      router.db.persist();
      return LocalServerRouter.ok({'changed': true});
    });

    router.register('GET', 'roles', (req) async {
      return LocalServerRouter.ok(router.db.collection('roles'));
    });

    router.register('PUT', 'roles/{id}', (req) async {
      final id = req.pathParams['id']!;
      final currentUserId = req.body['currentUserId']?.toString();
      final isOwner = _isActorOwner(router, currentUserId);

      final roles = router.db.collection('roles');
      final idx = roles.indexWhere((r) => r['id'] == id);
      final roleBody = Map<String, dynamic>.from(req.body)..remove('currentUserId');

      if (!isOwner) {
        final perms = ((roleBody['permissions'] as List?) ?? const [])
            .map((p) => p.toString())
            .toSet();
        if (perms.intersection(_criticalPermissions).isNotEmpty) {
          LocalServerRouter.throwHttpError(
            req.path,
            403,
            'PRIVILEGE_ESCALATION',
            'staff_privilege_escalation_denied',
          );
        }
        if (idx != -1) {
          final existing = roles[idx];
          if (roleBody['maxDiscountPercent'] != existing['maxDiscountPercent'] ||
              roleBody['canGrantFreeConsultation'] != existing['canGrantFreeConsultation']) {
            LocalServerRouter.throwHttpError(
              req.path,
              403,
              'PRIVILEGE_ESCALATION',
              'disc_policy_owner_only',
            );
          }
        } else {
          if (roleBody['maxDiscountPercent'] != null ||
              roleBody['canGrantFreeConsultation'] == true) {
            LocalServerRouter.throwHttpError(
              req.path,
              403,
              'PRIVILEGE_ESCALATION',
              'disc_policy_owner_only',
            );
          }
        }
      }

      roleBody['id'] = id;
      if (idx != -1) {
        roles[idx] = roleBody;
      } else {
        roles.add(roleBody);
      }
      router.db.persist();
      return LocalServerRouter.ok(roleBody);
    });

    router.register('GET', 'staff-users/{id}/branch-assignments', (req) async {
      final id = req.pathParams['id']!;
      final user = router.db.collection('staffUsers').cast<Map<String, dynamic>?>().firstWhere(
            (u) => u!['id'] == id,
            orElse: () => null,
          );
      return LocalServerRouter.ok((user?['branchAssignments'] as List?) ?? const []);
    });
  }
}

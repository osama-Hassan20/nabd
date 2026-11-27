import 'package:eyadty/core/local_server/local_server_router.dart';

class SettingsLocalHandler {
  SettingsLocalHandler._();

  static Map<String, dynamic> _findOrCreateBranchSettings(
    LocalServerRouter router,
    String branchId,
  ) {
    final list = router.db.collection('companySettings');
    final idx = list.indexWhere((s) => s['branchId'] == branchId);
    if (idx != -1) return list[idx];
    final created = {
      'id': 'SETT-$branchId',
      'branchId': branchId,
      'companyName': 'عيادتي',
      'logo': 'assets/icons/app_logo.png',
      'phone': '+20 2 2750 8800',
      'address': 'مصر',
      'defaultHourlyRate': 250,
      'workingDays': ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday'],
      'openingTime': '09:00',
      'closingTime': '22:00',
      'specialHolidays': <dynamic>[],
      'notificationEnabled': true,
      'reminderMinutesBefore': 60,
    };
    list.add(created);
    return created;
  }

  static void register(LocalServerRouter router) {
    router.register('GET', 'settings/company', (req) async {
      final branchId = req.queryParameters['branchId']?.toString() ?? 'branch_1';
      final settings = _findOrCreateBranchSettings(router, branchId);
      return LocalServerRouter.ok(settings);
    });

    router.register('PUT', 'settings/company', (req) async {
      final branchId = (req.queryParameters['branchId'] ?? req.body['branchId'] ?? 'branch_1').toString();
      final list = router.db.collection('companySettings');
      _findOrCreateBranchSettings(router, branchId);
      final idx = list.indexWhere((s) => s['branchId'] == branchId);
      list[idx] = {...list[idx], ...req.body, 'branchId': branchId};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'settings/special-holidays', (req) async {
      final branchId = (req.queryParameters['branchId'] ?? req.body['branchId'] ?? 'branch_1').toString();
      final list = router.db.collection('companySettings');
      _findOrCreateBranchSettings(router, branchId);
      final idx = list.indexWhere((s) => s['branchId'] == branchId);
      final holiday = Map<String, dynamic>.from(req.body)..remove('branchId');
      holiday['id'] ??= 'HOL-${DateTime.now().millisecondsSinceEpoch}';
      final holidays = List<dynamic>.from((list[idx]['specialHolidays'] as List?) ?? []);
      holidays.insert(0, holiday);
      list[idx] = {...list[idx], 'specialHolidays': holidays};
      router.db.persist();
      return LocalServerRouter.ok(holiday);
    });

    router.register('DELETE', 'settings/special-holidays/{id}', (req) async {
      final holidayId = req.pathParams['id']!;
      final branchId = (req.queryParameters['branchId'] ?? 'branch_1').toString();
      final list = router.db.collection('companySettings');
      final idx = list.indexWhere((s) => s['branchId'] == branchId);
      if (idx != -1) {
        final holidays = List<dynamic>.from((list[idx]['specialHolidays'] as List?) ?? []);
        holidays.removeWhere((h) => h is Map && h['id'] == holidayId);
        list[idx] = {...list[idx], 'specialHolidays': holidays};
        router.db.persist();
      }
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('PUT', 'users/change-password', (req) async {
      final current = (req.body['currentPassword'] ?? '').toString();
      if (current != 'password123' && current != '123456') {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'current_password_incorrect',
        );
      }
      return LocalServerRouter.ok({'changed': true});
    });
  }
}

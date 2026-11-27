import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';

class PatientsLocalHandler {
  PatientsLocalHandler._();

  static bool _isArchived(Map<String, dynamic> p) =>
      p['isArchived'] == true || p['is_archived'] == true;

  static String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digits.startsWith('+20')) {
      digits = '0${digits.substring(3)}';
    } else if (digits.startsWith('0020')) {
      digits = '0${digits.substring(4)}';
    }
    return digits;
  }

  static void register(LocalServerRouter router) {
    router.register('GET', 'patients', (req) async {
      var items = router.db.collection('patients').where((p) => p['isDeleted'] != true).toList();
      final isArchived = req.queryParameters['isArchived']?.toString();
      if (isArchived != null) {
        final wantArchived = isArchived == 'true';
        items = items.where((p) => _isArchived(p) == wantArchived).toList();
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
      final phone = _normalizePhone((req.queryParameters['phone'] ?? '').toString().trim());
      final items = router.db
          .collection('patients')
          .where((p) {
            if (p['isDeleted'] == true || _isArchived(p)) return false;
            final pPhone = _normalizePhone((p['phone'] ?? '').toString());
            return phone.isNotEmpty && pPhone.contains(phone);
          })
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'patients/check-duplicate', (req) async {
      final phone = _normalizePhone((req.body['phone'] ?? '').toString().trim());
      final excludeId = req.body['excludeId']?.toString();
      final match = router.db.collection('patients').cast<Map<String, dynamic>?>().firstWhere(
            (p) =>
                p!['isDeleted'] != true &&
                _normalizePhone((p['phone'] ?? '').toString()) == phone &&
                p['id'] != excludeId,
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
      final allowDuplicate = record.remove('allowDuplicatePhone') == true;
      final dobRaw = (record['dateOfBirth'] ?? record['date_of_birth'])?.toString();
      final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
      if (dob != null) {
        final now = DateTime.now();
        var age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        if (age < 18) {
          final gName = (record['guardianName'] ?? record['guardian_name'] ?? '').toString().trim();
          final gPhone = (record['guardianPhone'] ?? record['guardian_phone'] ?? '').toString().trim();
          if (gName.isEmpty || gPhone.isEmpty) {
            LocalServerRouter.throwHttpError(
              req.path,
              422,
              'VALIDATION_ERROR',
              'بيانات ولي الأمر (الاسم ورقم الهاتف) مطلوبة للمريض القاصر',
            );
          }
        }
      }
      final phone = _normalizePhone((record['phone'] ?? '').toString().trim());
      if (!allowDuplicate && phone.isNotEmpty) {
        final matches = list
            .where((p) =>
                p['isDeleted'] != true &&
                _normalizePhone((p['phone'] ?? '').toString().trim()) == phone)
            .toList();
        if (matches.isNotEmpty) {
          LocalServerRouter.throwHttpError(
            req.path,
            422,
            'DUPLICATE_PHONE',
            'رقم الهاتف مسجل لمريض آخر بالفعل',
            fields: {'matchingPatients': matches},
          );
        }
      }
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
      final patient = list[idx];
      final balance = (patient['outstandingBalance'] ?? patient['outstanding_balance'] ?? 0) as num;
      if (balance > 0) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'لا يمكن أرشفة مريض لديه مديونية مستحقة',
        );
      }
      final hasUpcoming = router.db.collection('bookings').any((b) {
        if (b['isDeleted'] == true || b['patientId'] != id) return false;
        final st = b['status']?.toString();
        return st == 'scheduled' || st == 'waiting' || st == 'in_progress';
      });
      if (hasUpcoming) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'لا يمكن أرشفة مريض لديه كشوفات قادمة أو حجوزات نشطة',
        );
      }
      list[idx] = {
        ...patient,
        'isArchived': true,
        'is_archived': true,
        'archivedAt': DateTime.now().toUtc().toIso8601String(),
      };
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
      list[idx] = {
        ...list[idx],
        'isArchived': false,
        'is_archived': false,
        'archivedAt': null,
      };
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
      final query = req.queryParameters['query']?.toString().trim();
      if (query != null && query.isNotEmpty) {
        items = items
            .where((i) => ArabicTextHelper.containsNormalized(
                (i['name'] ?? '').toString(), query))
            .toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'medical-catalog-items', (req) async {
      final list = router.db.collection('medicalCatalogItems');
      final rawName = (req.body['name'] ?? '').toString().trim();
      final type = (req.body['type'] ?? '').toString();
      if (rawName.isEmpty) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'اسم العنصر لا يمكن أن يكون فارغاً',
        );
      }
      final normNew = ArabicTextHelper.normalize(rawName);
      final existing = list.cast<Map<String, dynamic>?>().firstWhere(
            (i) =>
                i!['type'] == type &&
                ArabicTextHelper.normalize((i['name'] ?? '').toString()) ==
                    normNew,
            orElse: () => null,
          );
      if (existing != null) {
        return LocalServerRouter.ok(existing);
      }
      final prefix = type == 'allergy' ? 'CAT-ALL' : 'CAT-CHR';
      final record = {
        'id': '$prefix-${(list.length + 1).toString().padLeft(3, '0')}',
        'name': rawName,
        'type': type,
      };
      list.add(record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('POST', 'patients/{id}/treatment-plans', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      final plans = List<dynamic>.from((list[idx]['treatmentPlans'] as List?) ?? []);
      final plan = Map<String, dynamic>.from(req.body);
      plan['id'] ??= 'PLAN-${DateTime.now().millisecondsSinceEpoch}';
      plans.add(plan);
      list[idx] = {...list[idx], 'treatmentPlans': plans};
      router.db.persist();
      return LocalServerRouter.ok(plan);
    });

    router.register('PUT', 'patients/{id}/treatment-plans/{planId}', (req) async {
      final id = req.pathParams['id']!;
      final planId = req.pathParams['planId']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      final plans = List<dynamic>.from((list[idx]['treatmentPlans'] as List?) ?? []);
      final pIdx = plans.indexWhere((pl) => (pl as Map)['id'] == planId);
      if (pIdx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Plan not found');
      }
      plans[pIdx] = {...Map<String, dynamic>.from(plans[pIdx] as Map), ...req.body, 'id': planId};
      list[idx] = {...list[idx], 'treatmentPlans': plans};
      router.db.persist();
      return LocalServerRouter.ok(plans[pIdx]);
    });

    router.register('POST', 'patients/{id}/treatment-plans/{planId}/sessions', (req) async {
      final id = req.pathParams['id']!;
      final planId = req.pathParams['planId']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      final plans = List<dynamic>.from((list[idx]['treatmentPlans'] as List?) ?? []);
      final pIdx = plans.indexWhere((pl) => (pl as Map)['id'] == planId);
      if (pIdx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Plan not found');
      }
      final planMap = Map<String, dynamic>.from(plans[pIdx] as Map);
      final sessions = List<dynamic>.from((planMap['sessions'] as List?) ?? []);
      sessions.add(req.body);
      planMap['sessions'] = sessions;
      plans[pIdx] = planMap;
      list[idx] = {...list[idx], 'treatmentPlans': plans};
      router.db.persist();
      return LocalServerRouter.ok(planMap);
    });

    router.register('POST', 'patients/{id}/treatment-plans/{planId}/payments', (req) async {
      final id = req.pathParams['id']!;
      final planId = req.pathParams['planId']!;
      final list = router.db.collection('patients');
      final idx = list.indexWhere((p) => p['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Patient not found');
      }
      final plans = List<dynamic>.from((list[idx]['treatmentPlans'] as List?) ?? []);
      final pIdx = plans.indexWhere((pl) => (pl as Map)['id'] == planId);
      if (pIdx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Plan not found');
      }
      final planMap = Map<String, dynamic>.from(plans[pIdx] as Map);
      final payments = List<dynamic>.from((planMap['payments'] as List?) ?? []);
      payments.add(req.body);
      planMap['payments'] = payments;
      plans[pIdx] = planMap;
      list[idx] = {...list[idx], 'treatmentPlans': plans};
      router.db.persist();
      return LocalServerRouter.ok(planMap);
    });
  }
}

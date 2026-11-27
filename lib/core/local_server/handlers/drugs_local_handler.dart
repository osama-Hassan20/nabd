import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/drug_source_enum.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';

class DrugsLocalHandler {
  DrugsLocalHandler._();

  static void register(LocalServerRouter router) {
    router.register('GET', 'drugs', (req) async {
      var items = router.db
          .collection('drugs')
          .where((d) => d['isDeleted'] != true)
          .toList();
      final includeArchived = req.queryParameters['includeArchived'];
      if (includeArchived != true && includeArchived != 'true') {
        items = items.where((d) => d['isArchived'] != true && d['isActive'] != false).toList();
      }
      final categoryId = req.queryParameters['categoryId']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        items = items.where((d) => d['categoryId'] == categoryId).toList();
      }
      final reviewFilter = req.queryParameters['reviewFilter']?.toString();
      if (reviewFilter != null && reviewFilter.isNotEmpty) {
        items = items.where((d) => d['reviewStatus'] == reviewFilter).toList();
      }
      final q = req.queryParameters['query']?.toString().trim();
      if (q != null && q.isNotEmpty) {
        final direct = items.where((d) {
          final trade = (d['name'] ?? d['tradeName'] ?? '').toString();
          final sci = (d['scientificName'] ?? '').toString();
          final desc = (d['description'] ?? '').toString();
          return ArabicTextHelper.containsNormalized(trade, q) ||
              ArabicTextHelper.containsNormalized(sci, q) ||
              ArabicTextHelper.containsNormalized(desc, q);
        }).toList();
        if (direct.isNotEmpty) {
          items = direct;
        } else {
          final normQ = ArabicTextHelper.normalize(q);
          final searchTerms = <String>{q, normQ};
          for (final row in router.db.collection('allergyAliases')) {
            final aliases = ((row['aliases'] as List?) ?? const []).map((e) => e.toString()).toList();
            if (aliases.any((a) => ArabicTextHelper.containsNormalized(a, q) || ArabicTextHelper.normalize(a) == normQ)) {
              searchTerms.addAll(aliases);
            }
          }
          items = items.where((d) {
            final trade = (d['name'] ?? d['tradeName'] ?? '').toString();
            final sci = (d['scientificName'] ?? '').toString();
            final desc = (d['description'] ?? '').toString();
            return searchTerms.any((term) =>
                ArabicTextHelper.containsNormalized(trade, term) ||
                ArabicTextHelper.containsNormalized(sci, term) ||
                ArabicTextHelper.containsNormalized(desc, term));
          }).toList();
        }
      }
      return LocalServerRouter.ok(items);
    });

    router.register('GET', 'drug-categories', (req) async {
      return LocalServerRouter.ok(router.db.collection('drugCategories'));
    });

    router.register('POST', 'drugs', (req) async {
      final list = router.db.collection('drugs');
      final record = Map<String, dynamic>.from(req.body);
      final name = (record['name'] ?? record['tradeName'] ?? '').toString().trim();
      if (name.isEmpty) {
        LocalServerRouter.throwHttpError(req.path, 422, 'VALIDATION_ERROR', 'drug_name_required');
      }
      final nextNum = list.length + 1;
      record['id'] ??= 'DRUG-${nextNum.toString().padLeft(3, '0')}';
      record['isActive'] ??= true;
      record['isArchived'] ??= false;
      record['createdAt'] ??= DateTime.now().toUtc().toIso8601String();
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'drugs/allergy-aliases', (req) async {
      final catalogItemId = req.body['catalogItemId']?.toString() ?? '';
      final aliases = ((req.body['aliases'] as List?) ?? const []).map((e) => e.toString()).toList();
      final list = router.db.collection('allergyAliases');
      final idx = list.indexWhere((a) => a['catalogItemId'] == catalogItemId);
      if (idx == -1) {
        list.add({'catalogItemId': catalogItemId, 'aliases': aliases});
      } else {
        list[idx] = {'catalogItemId': catalogItemId, 'aliases': aliases};
      }
      router.db.persist();
      return LocalServerRouter.ok({'updated': true});
    });

    router.register('PUT', 'drugs/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('drugs');
      final idx = list.indexWhere((d) => d['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'drug_not_found');
      }
      list[idx] = {
        ...list[idx],
        ...req.body,
        'id': id,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'drugs/{id}/archive', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('drugs');
      final idx = list.indexWhere((d) => d['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'drug_not_found');
      }
      list[idx] = {...list[idx], 'isArchived': true, 'isActive': false};
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('POST', 'drugs/quick-add', (req) async {
      final list = router.db.collection('drugs');
      final now = DateTime.now().toUtc();
      final model = DrugModel(
        id: 'DRUG-QA-${now.millisecondsSinceEpoch}',
        name: (req.body['name'] ?? '').toString(),
        concentration: req.body['concentration']?.toString(),
        defaultDosage: req.body['dosage']?.toString(),
        defaultFrequency: req.body['frequency']?.toString(),
        defaultDuration: req.body['duration']?.toString(),
        source: DrugSourceEnum.quickAdd,
        reviewStatus: ReviewStatusEnum.pending,
        isQuickAdded: true,
        createdByUserId: req.body['doctorId']?.toString(),
        isActive: true,
        createdAt: now,
      );
      final record = model.toJson();
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('POST', 'drugs/{id}/review', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('drugs');
      final idx = list.indexWhere((d) => d['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'drug_not_found');
      }
      final decision = req.body['decision']?.toString();
      final isRejected = decision == 'rejected' || decision == ReviewStatusEnum.rejected.name;
      list[idx] = {
        ...list[idx],
        'reviewStatus': decision,
        'reviewedByUserId': req.body['reviewedByUserId'],
        'reviewedAt': DateTime.now().toUtc().toIso8601String(),
        if (isRejected) ...{'isActive': false, 'isArchived': true},
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });

    router.register('GET', 'drugs/allergy-aliases', (req) async {
      final list = router.db.collection('allergyAliases');
      final map = <String, List<String>>{};
      for (final row in list) {
        final key = row['catalogItemId']?.toString();
        if (key != null) {
          map[key] = ((row['aliases'] as List?) ?? const []).map((e) => e.toString()).toList();
        }
      }
      return LocalServerRouter.ok(map);
    });

    router.register('GET', 'doctors/{id}/prescription-templates', (req) async {
      final doctorId = req.pathParams['id']!;
      final items = router.db
          .collection('prescriptionTemplates')
          .where((t) => t['doctorId'] == doctorId && t['isDeleted'] != true)
          .toList();
      return LocalServerRouter.ok(items);
    });

    router.register('PUT', 'prescription-templates/{id}', (req) async {
      final id = req.pathParams['id']!;
      final name = (req.body['name'] ?? '').toString().trim();
      if (name.length < 2) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'template_validation_name_required',
        );
      }
      final items = req.body['items'];
      if (items is! List || items.isEmpty) {
        LocalServerRouter.throwHttpError(
          req.path,
          422,
          'VALIDATION_ERROR',
          'template_validation_items_required',
        );
      }
      final list = router.db.collection('prescriptionTemplates');
      final idx = list.indexWhere((t) => t['id'] == id);
      if (idx != -1 &&
          list[idx]['doctorId'] != null &&
          req.body['doctorId'] != null &&
          list[idx]['doctorId'] != req.body['doctorId']) {
        LocalServerRouter.throwHttpError(
          req.path,
          403,
          'FORBIDDEN',
          'template_unauthorized',
        );
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final record = {
        ...req.body,
        'id': id,
        'isActive': req.body['isActive'] ?? true,
        'createdAt': (idx != -1 ? list[idx]['createdAt'] : null) ?? req.body['createdAt'] ?? now,
        'updatedAt': now,
      };
      if (idx == -1) {
        list.insert(0, record);
      } else {
        list[idx] = record;
      }
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('DELETE', 'prescription-templates/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('prescriptionTemplates');
      final idx = list.indexWhere((t) => t['id'] == id);
      if (idx != -1 &&
          list[idx]['doctorId'] != null &&
          req.body['doctorId'] != null &&
          list[idx]['doctorId'] != req.body['doctorId']) {
        LocalServerRouter.throwHttpError(
          req.path,
          403,
          'FORBIDDEN',
          'template_unauthorized',
        );
      }
      if (idx != -1) {
        list[idx] = {...list[idx], 'isDeleted': true};
      }
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('POST', 'drugs/import', (req) async {
      final list = router.db.collection('drugs');
      final incoming = (req.body['drugs'] as List?) ?? const [];
      int count = 0;
      for (final d in incoming) {
        if (d is Map) {
          final m = Map<String, dynamic>.from(d);
          final name = (m['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final norm = ArabicTextHelper.normalize(name);
          final dup = list.any((existing) =>
              existing['isDeleted'] != true &&
              ArabicTextHelper.normalize((existing['name'] ?? '').toString()) == norm);
          if (dup) continue;
          m['id'] ??= 'DRUG-IMP-${DateTime.now().millisecondsSinceEpoch}-$count';
          m['isActive'] ??= true;
          list.insert(0, m);
          count++;
        }
      }
      router.db.persist();
      return LocalServerRouter.ok({'importedCount': count});
    });
  }
}

import 'package:eyadty/core/local_server/local_server_router.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';

class MedicalCatalogsLocalHandler {
  MedicalCatalogsLocalHandler._();

  static String _normKind(String k) => k.replaceAll('_', '').toLowerCase();

  static void register(LocalServerRouter router) {
    router.register('GET', 'medical-catalogs/{kind}', (req) async {
      final kind = _normKind(req.pathParams['kind']!);
      var items = router.db
          .collection('medicalCatalogs')
          .where((e) =>
              e['isDeleted'] != true &&
              _normKind((e['kind'] ?? '').toString()) == kind)
          .toList();
      final category = req.queryParameters['category']?.toString();
      if (category != null && category.isNotEmpty && category != 'الكل') {
        items = items.where((e) => e['category'] == category).toList();
      }
      final query = req.queryParameters['query']?.toString().trim();
      if (query != null && query.isNotEmpty) {
        items = items.where((e) {
          final name = (e['name'] ?? '').toString();
          final code = (e['code'] ?? '').toString();
          final cat = (e['category'] ?? '').toString();
          return ArabicTextHelper.containsNormalized(name, query) ||
              ArabicTextHelper.containsNormalized(code, query) ||
              ArabicTextHelper.containsNormalized(cat, query);
        }).toList();
      }
      return LocalServerRouter.ok(items);
    });

    router.register('POST', 'medical-catalogs/{kind}', (req) async {
      final kind = req.pathParams['kind']!;
      final list = router.db.collection('medicalCatalogs');
      final record = Map<String, dynamic>.from(req.body);
      record['kind'] ??= kind;
      record['id'] ??= 'MCAT-${DateTime.now().millisecondsSinceEpoch}';
      record['isActive'] ??= true;
      record['createdAt'] ??= DateTime.now().toUtc().toIso8601String();
      list.insert(0, record);
      router.db.persist();
      return LocalServerRouter.ok(record);
    });

    router.register('PUT', 'medical-catalogs/{kind}/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('medicalCatalogs');
      final idx = list.indexWhere((e) => e['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Catalog entry not found');
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

    router.register('DELETE', 'medical-catalogs/{kind}/{id}', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('medicalCatalogs');
      list.removeWhere((e) => e['id'] == id);
      router.db.persist();
      return LocalServerRouter.ok({'deleted': true});
    });

    router.register('PATCH', 'medical-catalogs/{kind}/{id}/active', (req) async {
      final id = req.pathParams['id']!;
      final list = router.db.collection('medicalCatalogs');
      final idx = list.indexWhere((e) => e['id'] == id);
      if (idx == -1) {
        LocalServerRouter.throwHttpError(req.path, 404, 'NOT_FOUND', 'Catalog entry not found');
      }
      list[idx] = {
        ...list[idx],
        'isActive': req.body['isActive'] == true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      router.db.persist();
      return LocalServerRouter.ok(list[idx]);
    });
  }
}

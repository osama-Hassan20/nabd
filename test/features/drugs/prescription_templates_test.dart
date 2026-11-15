import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_item_model.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/drugs/data/repo/drugs_mock_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrescriptionTemplateModel & Item Serialization Tests', () {
    test('1. Serializes and deserializes PrescriptionTemplateItemModel accurately', () {
      const item = PrescriptionTemplateItemModel(
        drugId: 'DRUG-001',
        drugName: 'Augmentin 1g',
        scientificName: 'Amoxicillin / Clavulanic Acid',
        concentration: '1g',
        dosage: 'قرص واحد',
        frequency: 'مرتان يومياً',
        duration: '7 أيام',
        instructions: 'بعد الأكل',
        orderIndex: 0,
      );

      final json = item.toJson();
      final fromJson = PrescriptionTemplateItemModel.fromJson(json);

      expect(fromJson, equals(item));
      expect(fromJson.props.length, 9);

      final copied = item.copyWith(dosage: 'قرصان');
      expect(copied.dosage, 'قرصان');
      expect(copied.drugId, 'DRUG-001');
    });

    test('2. Serializes and deserializes PrescriptionTemplateModel accurately', () {
      final now = CairoTimeHelper.now();
      final template = PrescriptionTemplateModel(
        id: 'TPL-TEST-01',
        doctorId: 'DOC-01',
        name: 'قالب تجريبي',
        description: 'وصف القالب التجريبي',
        items: const [
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-001',
            drugName: 'Augmentin 1g',
            dosage: 'قرص واحد',
          ),
        ],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = template.toJson();
      final fromJson = PrescriptionTemplateModel.fromJson(json);

      expect(fromJson.id, template.id);
      expect(fromJson.doctorId, template.doctorId);
      expect(fromJson.name, template.name);
      expect(fromJson.items?.length, 1);
      expect(fromJson.props.length, 8);

      final copied = template.copyWith(name: 'قالب محدث');
      expect(copied.name, 'قالب محدث');
      expect(copied.id, 'TPL-TEST-01');
    });
  });

  group('Doctor Privacy Isolation & Template CRUD Tests', () {
    late DrugsMockRepoImpl repo;

    setUp(() {
      repo = DrugsMockRepoImpl();
    });

    test('3. Doctor Privacy: DOC-01 retrieves only their own templates', () async {
      final res = await repo.getDoctorTemplates('DOC-01');
      expect(res.isRight(), isTrue);

      res.fold((_) => fail('should succeed'), (templates) {
        expect(templates.length, 2);
        expect(templates.any((t) => t.id == 'TPL-001'), isTrue);
        expect(templates.any((t) => t.id == 'TPL-002'), isTrue);
        for (final t in templates) {
          expect(t.doctorId, 'DOC-01');
        }
      });
    });

    test('4. Doctor Privacy: DOC-02 retrieves only their own templates', () async {
      final res = await repo.getDoctorTemplates('DOC-02');
      expect(res.isRight(), isTrue);

      res.fold((_) => fail('should succeed'), (templates) {
        expect(templates.length, 1);
        expect(templates.first.id, 'TPL-003');
        expect(templates.first.doctorId, 'DOC-02');
      });
    });

    test('5. Saves new template with auto-generated ID, timestamps, and active status', () async {
      const newTemplate = PrescriptionTemplateModel(
        doctorId: 'DOC-01',
        name: 'بروتوكول جديد',
        description: 'وصف جديد',
        items: [
          PrescriptionTemplateItemModel(
            drugId: 'DRUG-008',
            drugName: 'Cataflam 50mg',
            dosage: 'قرص واحد',
          ),
        ],
      );

      final res = await repo.savePrescriptionTemplate(newTemplate);
      expect(res.isRight(), isTrue);

      res.fold((_) => fail('should succeed'), (saved) {
        expect(saved.id, startsWith('TPL-'));
        expect(saved.name, 'بروتوكول جديد');
        expect(saved.isActive, isTrue);
        expect(saved.createdAt, isNotNull);
        expect(saved.updatedAt, isNotNull);
      });

      final allDoc1 = (await repo.getDoctorTemplates('DOC-01')).getOrElse(() => []);
      expect(allDoc1.length, 3);
    });

    test('6. Validates template name requirement (minimum 2 characters)', () async {
      const invalidNameTemplate = PrescriptionTemplateModel(
        doctorId: 'DOC-01',
        name: 'A',
        items: [
          PrescriptionTemplateItemModel(drugId: 'DRUG-001', drugName: 'Test'),
        ],
      );

      final res = await repo.savePrescriptionTemplate(invalidNameTemplate);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'template_validation_name_required'),
        (_) => fail('should fail'),
      );
    });

    test('7. Validates template items requirement (at least 1 item)', () async {
      const emptyItemsTemplate = PrescriptionTemplateModel(
        doctorId: 'DOC-01',
        name: 'قالب بلا أدوية',
        items: [],
      );

      final res = await repo.savePrescriptionTemplate(emptyItemsTemplate);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'template_validation_items_required'),
        (_) => fail('should fail'),
      );
    });

    test('8. Updates existing template information and updates updatedAt', () async {
      final existingTemplates = (await repo.getDoctorTemplates('DOC-01')).getOrElse(() => []);
      final target = existingTemplates.firstWhere((t) => t.id == 'TPL-001');

      final updated = target.copyWith(
        name: 'بروتوكول نزلة معوية معدل',
        description: 'وصف معدل',
      );

      final res = await repo.savePrescriptionTemplate(updated);
      expect(res.isRight(), isTrue);

      final reloaded = (await repo.getDoctorTemplates('DOC-01')).getOrElse(() => []);
      final modified = reloaded.firstWhere((t) => t.id == 'TPL-001');
      expect(modified.name, 'بروتوكول نزلة معوية معدل');
      expect(modified.description, 'وصف معدل');
    });

    test('9. Unauthorized update: doctor cannot update another doctor template', () async {
      // DOC-02 attempts to modify DOC-01's template TPL-001
      final attack = PrescriptionTemplateModel(
        id: 'TPL-001',
        doctorId: 'DOC-02',
        name: 'محاولة تعديل غير مصرح',
        items: const [
          PrescriptionTemplateItemModel(drugId: 'DRUG-001', drugName: 'Test'),
        ],
      );

      final res = await repo.savePrescriptionTemplate(attack);
      expect(res.isLeft(), isTrue);
      res.fold(
        (failure) => expect(failure.errMessage, 'template_unauthorized'),
        (_) => fail('should fail'),
      );
    });

    test('10. Deleting template soft-deletes and removes from active list', () async {
      final delRes = await repo.deletePrescriptionTemplate('TPL-002', 'DOC-01');
      expect(delRes.isRight(), isTrue);

      final doc1Templates = (await repo.getDoctorTemplates('DOC-01')).getOrElse(() => []);
      expect(doc1Templates.any((t) => t.id == 'TPL-002'), isFalse);
    });

    test('11. Unauthorized delete: doctor cannot delete another doctor template', () async {
      // DOC-01 attempts to delete DOC-02's template TPL-003
      final delRes = await repo.deletePrescriptionTemplate('TPL-003', 'DOC-01');
      expect(delRes.isLeft(), isTrue);
      delRes.fold(
        (failure) => expect(failure.errMessage, 'template_unauthorized'),
        (_) => fail('should fail'),
      );
    });

    test('12. Template items can identify and filter out archived medications', () async {
      // Archive DRUG-001
      await repo.archiveDrug('DRUG-001');

      final activeDrugs = (await repo.getDrugs()).getOrElse(() => []);
      final activeDrugIds = activeDrugs.map((d) => d.id).toSet();

      final tpl = (await repo.getDoctorTemplates('DOC-01'))
          .getOrElse(() => [])
          .firstWhere((t) => t.id == 'TPL-002');

      final items = tpl.items ?? [];
      final activeItems = items.where((i) => activeDrugIds.contains(i.drugId)).toList();
      final skippedCount = items.length - activeItems.length;

      expect(skippedCount, 1);
      expect(activeItems.length, 1);
      expect(activeItems.first.drugId, 'DRUG-022');
    });
  });
}

import 'dart:convert';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/domain/helpers/drug_allergy_matcher.dart';
import 'package:eyadty/features/visits/presentation/widgets/dialogs/allergy_warning_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAuditLogger auditLogger;

  setUp(() {
    auditLogger = InMemoryAuditLogger(seedInitialLogs: false);
  });

  Widget buildTestableDialog({
    required DrugModel drug,
    required AllergyMatchResult matchResult,
    required String visitId,
    String? patientId,
    String? branchId,
    String? performedByUserId,
    void Function(bool?)? onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                final result = await AllergyWarningDialog.show(
                  context: context,
                  drug: drug,
                  matchResult: matchResult,
                  visitId: visitId,
                  patientId: patientId,
                  branchId: branchId,
                  performedByUserId: performedByUserId,
                  auditLogger: auditLogger,
                );
                onResult?.call(result);
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  group('AllergyWarningDialog & Audit Security Tests (M-4)', () {
    testWidgets('1. Dialog appearance when allergy conflict is detected', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
        scientificName: 'Amoxicillin Trihydrate',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
        catalogItemId: 'CAT-ALL-001',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
        ),
      );

      // Tap to open
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AllergyWarningDialog), findsOneWidget);
      expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    });

    testWidgets('2. Doctor proceeds despite warning -> returns true', (tester) async {
      bool? dialogResult;
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
        catalogItemId: 'CAT-ALL-001',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
          onResult: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Proceed button
      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(find.byType(AllergyWarningDialog), findsNothing);
    });

    testWidgets('3. Doctor cancels dialog -> returns false', (tester) async {
      bool? dialogResult;
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
          onResult: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Cancel button
      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
      expect(find.byType(AllergyWarningDialog), findsNothing);
    });

    testWidgets('4. Audit event emitted when doctor proceeds is rx_allergy_warning_acknowledged', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
        catalogItemId: 'CAT-ALL-001',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
          patientId: 'PAT-555',
          branchId: 'branch_1',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.eventType, equals('rx_allergy_warning_acknowledged'));
    });

    testWidgets('5. 0 audit event emitted when doctor cancels', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      expect(logs, isEmpty);
    });

    testWidgets('6. Audit payload contains strictly whitelist keys', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-001',
        name: 'Amoxicillin 500mg',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
        catalogItemId: 'CAT-ALL-001',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-101',
          patientId: 'PAT-555',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      final detailsMap = jsonDecode(logs.first.details ?? '{}') as Map<String, dynamic>;

      const allowedKeys = {
        'visitId',
        'patientId',
        'drugId',
        'allergyCatalogItemId',
        'matchSource',
      };
      expect(detailsMap.keys.toSet().difference(allowedKeys), isEmpty);
    });

    testWidgets('7. matchSource: catalog_item when matched via catalog item', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-002',
        name: 'Augmentin 1g',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'بنسلين',
        catalogItemId: 'CAT-ALL-001',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-102',
          patientId: 'PAT-555',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      final detailsMap = jsonDecode(logs.first.details ?? '{}') as Map<String, dynamic>;

      expect(detailsMap['matchSource'], equals('catalog_item'));
      expect(detailsMap['allergyCatalogItemId'], equals('CAT-ALL-001'));
      expect(detailsMap['drugId'], equals('DRUG-002'));
    });

    testWidgets('8. matchSource: free_text and allergyCatalogItemId: null when matched via free text', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-003',
        name: 'Septrin',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'سلفا',
        catalogItemId: null,
        matchSource: 'free_text',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-103',
          patientId: 'PAT-777',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      final detailsMap = jsonDecode(logs.first.details ?? '{}') as Map<String, dynamic>;

      expect(detailsMap['matchSource'], equals('free_text'));
      expect(detailsMap['allergyCatalogItemId'], isNull);
    });

    testWidgets('9. Strict Security & Privacy Whitelist: 0 patient names, 0 drug names, 0 allergy text, 0 diagnosis text', (tester) async {
      const drug = DrugModel(
        id: 'DRUG-004',
        name: 'Flagyl 500mg (Sensitive Medical Trade Name)',
        scientificName: 'Metronidazole',
      );
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'حساسية مترونيدازول خطيرة',
        catalogItemId: 'CAT-ALL-099',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-104',
          patientId: 'PAT-SECRET-888',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      final rawDetails = logs.first.details ?? '';

      // Assert that none of the clinical / PHI strings leaked into details JSON
      expect(rawDetails.contains('Flagyl'), isFalse);
      expect(rawDetails.contains('Metronidazole'), isFalse);
      expect(rawDetails.contains('مترونيدازول'), isFalse);
      expect(rawDetails.contains('Sensitive'), isFalse);
    });

    testWidgets('10. Clinical disclaimer is displayed clearly in the dialog', (tester) async {
      const drug = DrugModel(id: 'DRUG-005', name: 'Aspirin');
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'أسبرين',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-105',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('rx_allergy_disclaimer'), findsOneWidget);
    });

    testWidgets('11. Non-blocking nature: Proceed button is prominent and allows override', (tester) async {
      bool proceedClicked = false;
      const drug = DrugModel(id: 'DRUG-006', name: 'Panadol');
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'باراسيتامول',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-106',
          onResult: (res) => proceedClicked = (res == true),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final proceedBtnFinder = find.text('rx_allergy_proceed_btn');
      expect(proceedBtnFinder, findsOneWidget);
      await tester.tap(proceedBtnFinder);
      await tester.pumpAndSettle();

      expect(proceedClicked, isTrue);
    });

    testWidgets('12. Multi-tenant context preservation: branchId and performedByUserId are correctly recorded', (tester) async {
      const drug = DrugModel(id: 'DRUG-007', name: 'Ketofan');
      const matchResult = AllergyMatchResult(
        hasConflict: true,
        matchedAllergy: 'كيتوبروفين',
        catalogItemId: 'CAT-ALL-005',
        matchSource: 'catalog_item',
      );

      await tester.pumpWidget(
        buildTestableDialog(
          drug: drug,
          matchResult: matchResult,
          visitId: 'VIS-107',
          patientId: 'PAT-900',
          branchId: 'branch_heliopolis',
          performedByUserId: 'USR-DOC-99',
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rx_allergy_proceed_btn'));
      await tester.pumpAndSettle();

      final logs = auditLogger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.branchId, equals('branch_heliopolis'));
      expect(logs.first.performedByUserId, equals('USR-DOC-99'));
    });
  });
}

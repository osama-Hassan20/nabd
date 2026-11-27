import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Translation Integrity & Zero-Missing-Keys Tests', () {
    late Map<String, dynamic> arMap;
    late Map<String, dynamic> enMap;

    setUpAll(() {
      final arFile = File('assets/translations/ar-EG.json');
      final enFile = File('assets/translations/en-US.json');

      expect(arFile.existsSync(), isTrue, reason: 'ar-EG.json must exist');
      expect(enFile.existsSync(), isTrue, reason: 'en-US.json must exist');

      arMap = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
      enMap = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('ar-EG.json and en-US.json have 100% key parity', () {
      final arKeys = arMap.keys.toSet();
      final enKeys = enMap.keys.toSet();

      final inArNotEn = arKeys.difference(enKeys);
      final inEnNotAr = enKeys.difference(arKeys);

      expect(
        inArNotEn,
        isEmpty,
        reason: 'Keys in ar-EG.json missing in en-US.json: $inArNotEn',
      );
      expect(
        inEnNotAr,
        isEmpty,
        reason: 'Keys in en-US.json missing in ar-EG.json: $inEnNotAr',
      );
    });

    test('All static .tr() keys referenced across lib/ exist in translations', () {
      final libDir = Directory('lib');
      final keyRegex1 = RegExp(r"'([a-zA-Z0-9_\-\.]+)'\.tr\(");
      final keyRegex2 = RegExp(r'"([a-zA-Z0-9_\-\.]+)"\.tr\(');

      final missingInAr = <String, Set<String>>{};
      final missingInEn = <String, Set<String>>{};

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          for (final match in keyRegex1.allMatches(content)) {
            final key = match.group(1)!;
            if (!arMap.containsKey(key)) {
              missingInAr.putIfAbsent(key, () => {}).add(entity.path);
            }
            if (!enMap.containsKey(key)) {
              missingInEn.putIfAbsent(key, () => {}).add(entity.path);
            }
          }
          for (final match in keyRegex2.allMatches(content)) {
            final key = match.group(1)!;
            if (!arMap.containsKey(key)) {
              missingInAr.putIfAbsent(key, () => {}).add(entity.path);
            }
            if (!enMap.containsKey(key)) {
              missingInEn.putIfAbsent(key, () => {}).add(entity.path);
            }
          }
        }
      }

      expect(
        missingInAr,
        isEmpty,
        reason: 'Keys referenced in lib/ but missing in ar-EG.json: $missingInAr',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys referenced in lib/ but missing in en-US.json: $missingInEn',
      );
    });

    test('No translation key contains empty value in ar-EG or en-US', () {
      for (final entry in arMap.entries) {
        expect(
          entry.value.toString().trim(),
          isNotEmpty,
          reason: 'Key "${entry.key}" in ar-EG.json has an empty value',
        );
      }
      for (final entry in enMap.entries) {
        expect(
          entry.value.toString().trim(),
          isNotEmpty,
          reason: 'Key "${entry.key}" in en-US.json has an empty value',
        );
      }
    });

    test('Neither ar-EG.json nor en-US.json contains duplicate keys', () {
      List<String> findDuplicateKeys(String rawJson) {
        final seen = <String>{};
        final duplicates = <String>[];
        final keyLineRegex = RegExp(r'^\s*"([^"\\]+)"\s*:', multiLine: true);
        for (final match in keyLineRegex.allMatches(rawJson)) {
          final key = match.group(1)!;
          if (!seen.add(key)) {
            duplicates.add(key);
          }
        }
        return duplicates;
      }

      final arDups = findDuplicateKeys(
        File('assets/translations/ar-EG.json').readAsStringSync(),
      );
      final enDups = findDuplicateKeys(
        File('assets/translations/en-US.json').readAsStringSync(),
      );

      expect(
        arDups,
        isEmpty,
        reason: 'Duplicate keys found in ar-EG.json: $arDups',
      );
      expect(
        enDups,
        isEmpty,
        reason: 'Duplicate keys found in en-US.json: $enDups',
      );
    });
  });
}

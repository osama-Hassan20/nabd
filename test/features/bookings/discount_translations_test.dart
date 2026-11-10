import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B-DISC Discount Translations Consistency Tests', () {
    late Map<String, dynamic> arJson;
    late Map<String, dynamic> enJson;
    late Set<String> arDiscKeys;
    late Set<String> enDiscKeys;

    setUpAll(() {
      final arFile = File('assets/translations/ar-EG.json');
      final enFile = File('assets/translations/en-US.json');

      expect(arFile.existsSync(), isTrue, reason: 'ar-EG.json must exist');
      expect(enFile.existsSync(), isTrue, reason: 'en-US.json must exist');

      arJson = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

      arDiscKeys = arJson.keys.where((k) => k.startsWith('disc_')).toSet();
      enDiscKeys = enJson.keys.where((k) => k.startsWith('disc_')).toSet();
    });

    test('ar-EG and en-US have 100% identical sets of disc_ keys', () {
      final missingInEn = arDiscKeys.difference(enDiscKeys);
      final missingInAr = enDiscKeys.difference(arDiscKeys);

      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys in ar-EG but missing in en-US: $missingInEn',
      );
      expect(
        missingInAr,
        isEmpty,
        reason: 'Keys in en-US but missing in ar-EG: $missingInAr',
      );
      expect(arDiscKeys.length, enDiscKeys.length);
      expect(arDiscKeys.length, greaterThanOrEqualTo(48));
    });

    test('All required discount keys exist and are non-empty', () {
      for (final key in arDiscKeys) {
        expect(
          (arJson[key] as String).trim(),
          isNotEmpty,
          reason: 'Key $key in ar-EG is empty',
        );
        expect(
          (enJson[key] as String).trim(),
          isNotEmpty,
          reason: 'Key $key in en-US is empty',
        );
      }
    });
  });
}

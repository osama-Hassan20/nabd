import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EYADTY_BACKEND_SCHEMA.json validation', () {
    late Map<String, dynamic> schema;

    setUpAll(() {
      final file = File('EYADTY_BACKEND_SCHEMA.json');
      expect(file.existsSync(), isTrue,
          reason: 'EYADTY_BACKEND_SCHEMA.json must exist at repo root');
      schema = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('contains required top-level contract sections', () {
      expect(schema['version'], isNotNull);
      expect(schema['baseUrl'], isNotNull);
      expect(schema['conventions'], isA<Map>());
      expect(schema['sync'], isA<Map>());
      expect(schema['endpoints'], isA<Map>());
      expect(schema['entities'], isA<Map>());
    });

    test('sync contract defines push and pull request/response shapes', () {
      final sync = schema['sync'] as Map<String, dynamic>;
      expect(sync['push'], isA<Map>());
      expect(sync['pull'], isA<Map>());
    });

    test('every endpoint entry has valid method, path, and non-empty group', () {
      final endpointsByGroup = schema['endpoints'] as Map<String, dynamic>;
      expect(endpointsByGroup.isNotEmpty, isTrue);

      const allowedMethods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};
      int totalEndpoints = 0;
      for (final entry in endpointsByGroup.entries) {
        expect(entry.key, isNotEmpty);
        final list = entry.value as List<dynamic>;
        for (final raw in list) {
          totalEndpoints++;
          final ep = raw as Map<String, dynamic>;
          final method = (ep['method'] ?? '').toString().toUpperCase();
          final path = (ep['path'] ?? '').toString();
          expect(allowedMethods.contains(method), isTrue,
              reason: 'Invalid HTTP method "$method" on endpoint $ep');
          expect(path, isNotEmpty, reason: 'Endpoint path must not be empty');
        }
      }
      expect(totalEndpoints, greaterThanOrEqualTo(100));
    });
  });
}

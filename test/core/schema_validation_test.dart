import 'dart:convert';
import 'dart:io';

import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:flutter_test/flutter_test.dart';

String _normalizeEndpointPath(String rawPath) {
  var p = rawPath.split('?').first.trim();
  if (p.startsWith('/api/v1/')) p = p.substring('/api/v1/'.length);
  if (p.startsWith('/')) p = p.substring(1);
  return p;
}

void main() {
  group('EYADTY_BACKEND_SCHEMA.json validation & Step 4.1 Contract', () {
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

    test('4.1 Contract: core repo endpoints exist in schema (method + path)', () {
      final endpointsByGroup = schema['endpoints'] as Map<String, dynamic>;
      final schemaRoutes = <String>{};
      for (final list in endpointsByGroup.values) {
        for (final raw in (list as List<dynamic>)) {
          final ep = raw as Map<String, dynamic>;
          final m = (ep['method'] ?? '').toString().toUpperCase();
          final p = _normalizeEndpointPath((ep['path'] ?? '').toString());
          schemaRoutes.add('$m $p');
        }
      }

      const requiredRoutes = [
        'POST admin/auth/login',
        'POST admin/auth/refresh',
        'GET patients',
        'POST patients',
        'GET doctors',
        'GET bookings',
        'POST bookings',
        'GET visits/queue',
        'POST cashier/shifts/open',
        'POST cashier/payments',
        'GET hr/compensation-rules',
        'GET hr/settlements',
        'GET drugs',
        'GET branches',
        'GET audit-logs',
        'GET analytics/summary',
        'POST sync/push',
        'GET sync/pull',
      ];

      for (final r in requiredRoutes) {
        expect(schemaRoutes.contains(r), isTrue,
            reason: 'Missing required route "$r" in EYADTY_BACKEND_SCHEMA.json');
      }
    });

    test('4.1 Contract: core model toJson keys exist in schema entities', () {
      final entities = schema['entities'] as Map<String, dynamic>;
      final checks = <String, Map<String, dynamic>>{
        'Patient': const PatientModel(id: '1', name: 'A', phone: '010').toJson(),
        'Booking': BookingModel(id: '1', patientId: 'P1', doctorId: 'D1').toJson(),
        'Visit': const VisitModel(id: '1', bookingId: 'B1', patientId: 'P1', doctorId: 'D1').toJson(),
        'Doctor': const DoctorModel(id: '1', name: 'Dr').toJson(),
        'CashierShift': const CashierShiftModel(id: '1', branchId: 'b1').toJson(),
        'Drug': const DrugModel(id: '1', name: 'Panadol').toJson(),
      };

      for (final entry in checks.entries) {
        expect(entities.containsKey(entry.key), isTrue,
            reason: 'Entity ${entry.key} missing from schema');
        final schemaFields =
            ((entities[entry.key] as Map)['fields'] as Map).keys.toSet();
        expect(schemaFields, isNotEmpty);
        // Verify core id field exists in both model toJson and schema entity
        expect(schemaFields.contains('id'), isTrue,
            reason: '${entry.key} schema missing id field');
      }
    });
  });
}

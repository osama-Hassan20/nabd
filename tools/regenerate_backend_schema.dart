import 'dart:convert';
import 'dart:io';

/// Repeatable script to enrich/validate `EYADTY_BACKEND_SCHEMA.json` and
/// generate `docs/openapi.json` from the schema endpoints & entities.
///
/// Run: `dart run tools/regenerate_backend_schema.dart`
Future<void> main() async {
  final schemaFile = File('EYADTY_BACKEND_SCHEMA.json');
  if (!schemaFile.existsSync()) {
    stderr.writeln('EYADTY_BACKEND_SCHEMA.json not found');
    exit(1);
  }

  final schema =
      jsonDecode(schemaFile.readAsStringSync()) as Map<String, dynamic>;

  // Ensure Step 5.1 contract metadata is present and up to date
  schema['money'] = {
    'unit': 'piastres',
    'type': 'integer',
    'note':
        '1 EGP = 100 piastres. Cashier shifts, payments, refunds, movements, HR rules, settlements, and analytics KPIs use integer piastres.',
  };

  schema['timezone'] = {
    'storage': 'UTC (ISO-8601)',
    'clinicTimezone': 'Africa/Cairo',
    'note':
        'All timestamps are persisted in UTC. Day boundaries, slot availability, and Friday weekly holiday checks are evaluated in Africa/Cairo.',
  };

  schema['constraints'] = {
    'unique': [
      {'table': 'patients', 'columns': ['accountId', 'phone']},
      {'table': 'patients', 'columns': ['accountId', 'branchId', 'fileNumber']},
      {
        'table': 'bookings',
        'columns': ['accountId', 'doctorId', 'appointmentTime'],
        'where': "status NOT IN ('cancelled', 'postponed', 'noShow')",
      },
      {'table': 'staff_users', 'columns': ['accountId', 'email']},
    ],
    'indexes': [
      {'table': 'patients', 'columns': ['accountId', 'branchId', 'name']},
      {'table': 'bookings', 'columns': ['accountId', 'branchId', 'date', 'doctorId']},
      {'table': 'visits', 'columns': ['accountId', 'bookingId']},
      {'table': 'cashier_payments', 'columns': ['accountId', 'shiftId', 'bookingId']},
      {'table': 'audit_logs', 'columns': ['accountId', 'branchId', 'timestamp']},
      {'table': 'sync_changelog', 'columns': ['accountId', 'entityType', 'seq']},
    ],
  };

  schema['rolePermissions'] = {
    'owner': ['* (all StaffPermissionEnum values)'],
    'branch_manager': [
      'manageBranches',
      'manageUsers',
      'viewAuditLogs',
      'createBooking',
      'editBooking',
      'cancelBooking',
      'reorderQueue',
      'accessPatients',
      'createPatient',
      'editPatient',
      'viewVisitsQueue',
      'viewMedicalRecordDiagnostics',
      'viewConsultationNotes',
      'viewAllDoctorsMedicalRecords',
      'accessDoctors',
      'manageDoctorSchedules',
      'manageDoctorLeaves',
      'approveLeavesAndReferrals',
      'viewClinicalPerformance',
      'accessCashier',
      'collectPayment',
      'refundPayment',
      'viewAnalytics',
    ],
    'doctor': [
      'viewVisitsQueue',
      'startConsultation',
      'viewMedicalRecordDiagnostics',
      'viewConsultationNotes',
      'editMedicalDiagnosis',
      'issuePrescription',
      'accessPatients',
      'viewClinicalPerformance',
    ],
    'nurse': [
      'viewVisitsQueue',
      'recordVitals',
      'accessPatients',
    ],
    'reception': [
      'createBooking',
      'editBooking',
      'cancelBooking',
      'reorderQueue',
      'accessPatients',
      'createPatient',
      'editPatient',
      'viewVisitsQueue',
      'accessCashier',
      'collectPayment',
    ],
    'accountant': [
      'accessCashier',
      'collectPayment',
      'refundPayment',
      'viewAnalytics',
    ],
    'hr': [
      'manageUsers',
      'accessDoctors',
      'manageDoctorSchedules',
      'manageDoctorLeaves',
      'approveLeavesAndReferrals',
    ],
  };

  // Pretty-write schema and validate round-trip parse
  const encoder = JsonEncoder.withIndent(' ');
  final updatedJson = encoder.convert(schema);
  schemaFile.writeAsStringSync('$updatedJson\n');
  jsonDecode(schemaFile.readAsStringSync());

  // Generate OpenAPI 3.0 export from schema
  final paths = <String, Map<String, dynamic>>{};
  final endpointsByGroup = schema['endpoints'] as Map<String, dynamic>;
  for (final groupEntry in endpointsByGroup.entries) {
    final tag = groupEntry.key;
    final list = groupEntry.value as List<dynamic>;
    for (final raw in list) {
      final ep = raw as Map<String, dynamic>;
      final method = (ep['method'] ?? 'GET').toString().toLowerCase();
      var path = (ep['path'] ?? '').toString().split('?').first;
      if (!path.startsWith('/')) path = '/$path';
      paths.putIfAbsent(path, () => {});
      paths[path]![method] = {
        'tags': [tag],
        'summary': ep['summary'] ?? '',
        if ((ep['clientMethod'] ?? '').toString().isNotEmpty)
          'operationId': ep['clientMethod'],
        'responses': {
          '200': {'description': 'Success envelope {data, meta?}'},
          '401': {'description': 'Unauthorized'},
          '403': {'description': 'Permission denied'},
          '409': {'description': 'Version / idempotency conflict'},
          '422': {'description': 'Validation error with fields map'},
        },
      };
    }
  }

  final openApi = {
    'openapi': '3.0.3',
    'info': {
      'title': 'Eyadty Clinic SaaS API',
      'version': schema['version'] ?? '1.0-draft',
    },
    'servers': [
      {'url': '{BASE_URL}', 'description': 'Configured BASE_URL'},
    ],
    'paths': paths,
  };

  final openApiFile = File('docs/openapi.json');
  openApiFile.parent.createSync(recursive: true);
  openApiFile.writeAsStringSync('${encoder.convert(openApi)}\n');

  stdout.writeln(
      'Regenerated EYADTY_BACKEND_SCHEMA.json and docs/openapi.json (${paths.length} paths).');
}

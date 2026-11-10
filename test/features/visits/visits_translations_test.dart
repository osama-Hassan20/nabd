import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Visits Translations Consistency Tests', () {
    late Map<String, dynamic> arJson;
    late Map<String, dynamic> enJson;
    late Set<String> arVisitsKeys;
    late Set<String> enVisitsKeys;

    setUpAll(() {
      final arFile = File('assets/translations/ar-EG.json');
      final enFile = File('assets/translations/en-US.json');

      expect(arFile.existsSync(), isTrue, reason: 'ar-EG.json must exist');
      expect(enFile.existsSync(), isTrue, reason: 'en-US.json must exist');

      arJson = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

      arVisitsKeys =
          arJson.keys.where((k) => k.startsWith('visits_')).toSet();
      enVisitsKeys =
          enJson.keys.where((k) => k.startsWith('visits_')).toSet();
    });

    test('ar-EG and en-US have 100% identical sets of visits_ keys', () {
      final missingInEn = arVisitsKeys.difference(enVisitsKeys);
      final missingInAr = enVisitsKeys.difference(arVisitsKeys);

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
      expect(arVisitsKeys.length, enVisitsKeys.length);
      expect(arVisitsKeys.length, greaterThanOrEqualTo(66));
    });

    test('All plan §7 required keys exist in translations', () {
      final requiredPlanKeys = [
        'visits_page_title',
        'visits_page_subtitle',
        'visits_start_consultation',
        'visits_continue_consultation',
        'visits_complete_vitals',
        'visits_finalize_visit',
        'visits_save_draft',
        'visits_auto_saved',
        'visits_record_vitals',
        'visits_ongoing_banner',
        'visits_status_triage',
        'visits_status_in_progress',
        'visits_status_finalized',
        'visits_chief_complaint',
        'visits_medical_history',
        'visits_physical_exam',
        'visits_diagnosis',
        'visits_treatment_plan',
        'visits_follow_up_notes',
        'visits_follow_up_days',
        'visits_vitals_title',
        'visits_systolic_bp',
        'visits_diastolic_bp',
        'visits_heart_rate',
        'visits_temperature',
        'visits_oxygen_saturation',
        'visits_weight_kg',
        'visits_height_cm',
        'visits_bmi',
        'visits_bmi_normal',
        'visits_bmi_overweight',
        'visits_bmi_obese',
        'visits_bmi_underweight',
        'visits_vitals_warn_bp_high',
        'visits_vitals_warn_bp_low',
        'visits_vitals_warn_hr_high',
        'visits_vitals_warn_hr_low',
        'visits_vitals_warn_temp_high',
        'visits_vitals_warn_temp_low',
        'visits_vitals_warn_spo2_high',
        'visits_vitals_warn_spo2_low',
        'visits_allergy_warning',
        'visits_no_allergies',
        'visits_chronic_diseases_title',
        'visits_finalize_confirm_title',
        'visits_finalize_confirm_body',
        'visits_finalize_success',
        'visits_locked_notice',
        'visits_no_active_visits',
        'visits_no_permission_queue',
        'visits_no_permission_consultation',
        'visits_start_error',
        'visits_start_not_your_patient',
        'visits_draft_saved',
        'visits_vitals_saved',
        'visits_filter_date',
        'visits_filter_status',
        'visits_filter_doctor',
        'visits_action_view',
        'visits_diagnosis_hint',
        'visits_booking_locked_error',
        'visits_save_error',
        'visits_finalize_error',
        'visits_finalize_missing_fields',
        'visits_vitals_error',
        'visits_vitals_finalized_error',
        'visits_vitals_wrong_status_error',
        'visits_load_error',
      ];

      for (final key in requiredPlanKeys) {
        expect(
          arVisitsKeys.contains(key),
          isTrue,
          reason: 'Key $key missing from ar-EG.json',
        );
        expect(
          enVisitsKeys.contains(key),
          isTrue,
          reason: 'Key $key missing from en-US.json',
        );
      }
    });

    test('All visits_ keys referenced in lib/features/visits code exist in translations', () {
      final visitsDir = Directory('lib/features/visits');
      final dartFiles = visitsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final referencedKeys = <String>{};
      final keyRegex = RegExp(r"'visits_[a-zA-Z0-9_]+'");

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final matches = keyRegex.allMatches(content);
        for (final m in matches) {
          final matched = m.group(0)!;
          // Strip quotes
          final key = matched.substring(1, matched.length - 1);
          referencedKeys.add(key);
        }
      }

      for (final key in referencedKeys) {
        expect(
          arVisitsKeys.contains(key),
          isTrue,
          reason: 'Referenced key $key missing from ar-EG.json',
        );
        expect(
          enVisitsKeys.contains(key),
          isTrue,
          reason: 'Referenced key $key missing from en-US.json',
        );
      }
    });
  });
}


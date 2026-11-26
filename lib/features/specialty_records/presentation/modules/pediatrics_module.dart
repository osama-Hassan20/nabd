import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/helpers/pediatrics_growth_and_vaccine_helper.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class PediatricsModule implements SpecialtyRecordModule {
  const PediatricsModule();

  @override
  MedicalSpecialty get specialty => MedicalSpecialty.pediatrics;

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'weightKg': null,
        'heightCm': null,
        'headCircumferenceCm': null,
        'bmi': null,
        'ageMonths': 0,
        'percentileBand': '',
        'feedingNotes': '',
        'milestonesNotes': '',
        'vaccinesGiven': <String, Map<String, dynamic>>{},
      };

  @override
  List<String> validate(Map<String, dynamic> entry) {
    final errors = <String>[];
    final w = entry['weightKg'] as num?;
    final h = entry['heightCm'] as num?;
    final hc = entry['headCircumferenceCm'] as num?;
    if (w != null && (w <= 0 || w > 120)) {
      errors.add('الوزن غير صالح');
    }
    if (h != null && (h <= 20 || h > 220)) {
      errors.add('الطول غير صالح');
    }
    if (hc != null && (hc <= 20 || hc > 70)) {
      errors.add('محيط الرأس غير صالح');
    }
    return errors;
  }

  @override
  Widget buildPatientTab(PatientModel patient) {
    return _PediatricsRecordWidget(
      patientId: patient.id ?? '',
      dob: patient.dateOfBirth,
      initialWeight: patient.weightKg?.toDouble(),
      initialHeight: patient.heightCm?.toDouble(),
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _PediatricsRecordWidget(
      patientId: visit.patientId ?? '',
      visitId: visit.id,
      initialWeight: visit.vitals?.weightKg?.toDouble(),
      initialHeight: visit.vitals?.heightCm?.toDouble(),
    );
  }
}

class _PediatricsRecordWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final DateTime? dob;
  final double? initialWeight;
  final double? initialHeight;

  const _PediatricsRecordWidget({
    required this.patientId,
    this.visitId,
    this.dob,
    this.initialWeight,
    this.initialHeight,
  });

  @override
  State<_PediatricsRecordWidget> createState() => _PediatricsRecordWidgetState();
}

class _PediatricsRecordWidgetState extends State<_PediatricsRecordWidget> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _hcCtrl = TextEditingController();
  final _feedingCtrl = TextEditingController();
  final _milestonesCtrl = TextEditingController();
  List<SpecialtyRecordEntryModel> _entries = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null) {
      _weightCtrl.text = widget.initialWeight.toString();
    }
    if (widget.initialHeight != null) {
      _heightCtrl.text = widget.initialHeight.toString();
    }
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: MedicalSpecialty.pediatrics,
    );
    res.fold((_) {}, (list) {
      if (mounted) setState(() => _entries = list);
    });
  }

  Future<void> _saveGrowthEntry() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    final hc = double.tryParse(_hcCtrl.text.trim());
    final bmi = PediatricsGrowthAndVaccineHelper.computeBmi(w, h);
    final ageMonths = widget.dob != null
        ? DateTime.now().difference(widget.dob!).inDays ~/ 30
        : 12;
    final percentile = w != null
        ? PediatricsGrowthAndVaccineHelper.estimateWeightPercentileBand(ageMonths, w)
        : '';

    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.pediatrics,
      kind: 'pediatrics_growth',
      data: {
        'weightKg': w,
        'heightCm': h,
        'headCircumferenceCm': hc,
        'bmi': bmi,
        'ageMonths': ageMonths,
        'percentileBand': percentile,
        'feedingNotes': _feedingCtrl.text.trim(),
        'milestonesNotes': _milestonesCtrl.text.trim(),
      },
      createdAt: DateTime.now(),
    );

    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  Future<void> _markVaccineGiven(PediatricsVaccineDose dose) async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.pediatrics,
      kind: 'pediatrics_vaccine',
      data: {
        'code': dose.code,
        'nameAr': dose.nameAr,
        'dateGiven': DateTime.now().toIso8601String(),
        'batchNumber': 'VAC-${DateTime.now().millisecondsSinceEpoch % 10000}',
      },
      createdAt: DateTime.now(),
    );
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _hcCtrl.dispose();
    _feedingCtrl.dispose();
    _milestonesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final givenMap = <String, Map<String, dynamic>>{};
    for (final e in _entries.where((e) => e.kind == 'pediatrics_vaccine')) {
      final code = e.data['code']?.toString();
      if (code != null) givenMap[code] = e.data;
    }
    final dob = widget.dob ?? DateTime.now().subtract(const Duration(days: 365));
    final schedule = PediatricsGrowthAndVaccineHelper.buildEgyptianSchedule(
      dob: dob,
      givenByCode: givenMap,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.child_care_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'سجل الأطفال والنمو (${PediatricsGrowthAndVaccineHelper.formatPediatricAge(widget.dob)})',
                style: CustomAppFontStyle.bold14,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            PediatricsGrowthAndVaccineHelper.medicalDisclaimer,
            style: CustomAppFontStyle.regular11.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الوزن (كجم)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الطول (سم)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hcCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'محيط الرأس (سم)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _feedingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'التغذية',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _milestonesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'تطور النمو (Milestones)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton.icon(
              onPressed: _saveGrowthEntry,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('حفظ قياسات النمو'),
            ),
          ),
          const Divider(height: 20),
          Text('جدول التطعيمات المصري (مرجعي):', style: CustomAppFontStyle.semiBold13),
          const SizedBox(height: 6),
          ...schedule.map((dose) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(dose.nameAr, style: CustomAppFontStyle.medium12),
                subtitle: Text(
                  dose.status == 'given'
                      ? 'تم التطعيم (${dose.batchNumber ?? ''})'
                      : (dose.status == 'overdue' ? 'متأخر' : 'مستحق'),
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: dose.status == 'given'
                        ? const Color(0xFF10B981)
                        : (dose.status == 'overdue' ? AppColors.error : AppColors.warning),
                  ),
                ),
                trailing: dose.status != 'given'
                    ? TextButton(
                        onPressed: () => _markVaccineGiven(dose),
                        child: const Text('تسجيل التطعيم'),
                      )
                    : const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
              )),
        ],
      ),
    );
  }
}

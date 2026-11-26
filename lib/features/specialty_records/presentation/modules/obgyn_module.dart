import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/domain/repo/patients_repo.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class ObstetricsGynecologyModule implements SpecialtyRecordModule {
  const ObstetricsGynecologyModule();

  @override
  MedicalSpecialty get specialty => MedicalSpecialty.obstetricsGynecology;

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'visitKind': 'antenatal',
        'weightKg': null,
        'bp': '',
        'fundalHeightCm': null,
        'fhrBpm': null,
        'presentation': 'cephalic',
        'edema': false,
        'urineProtein': 'negative',
        'ultrasoundGaWeeks': null,
        'efwGrams': null,
        'afiCm': null,
        'placenta': '',
        'notes': '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) {
    final errors = <String>[];
    final fhr = entry['fhrBpm'] as num?;
    if (fhr != null && (fhr < 60 || fhr > 220)) {
      errors.add('نبض الجنين خارج النطاق المعتاد');
    }
    return errors;
  }

  static String trimesterLabel(int weeks) {
    if (weeks < 14) return 'الثلث الأول';
    if (weeks < 28) return 'الثلث الثاني';
    return 'الثلث الثالث';
  }

  static String formatPregnancyCountdown(PatientModel? patient, {DateTime? now}) {
    if (patient == null || patient.isPregnant != true) {
      return 'لا يوجد حمل نشط مسجل';
    }
    final current = now ?? DateTime.now();
    final month = patient.gestationalMonth(customNow: current) ?? 1;
    final weeks = patient.gestationalWeeks(customNow: current) ?? 0;
    final remainingWeeks = (40 - weeks).clamp(0, 40);
    final monthsRemaining = (9 - month).clamp(0, 9);
    final edd = patient.computedEdd;
    final overdue = edd != null && current.isAfter(edd);
    final eddText = edd != null ? DateFormat('yyyy-MM-dd').format(edd) : '-';
    final base =
        'الشهر $month من 9 (${trimesterLabel(weeks)}) • الأسبوع $weeks • باقي $remainingWeeks أسبوع ($monthsRemaining أشهر) • EDD: $eddText';
    return overdue ? '$base • تحذير: تجاوز موعد الولادة المتوقع!' : base;
  }

  @override
  Widget buildPatientTab(PatientModel patient) {
    return _ObGynRecordWidget(
      patientId: patient.id ?? '',
      patient: patient,
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _ObGynRecordWidget(
      patientId: visit.patientId ?? '',
      visitId: visit.id,
    );
  }
}

class _ObGynRecordWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final PatientModel? patient;

  const _ObGynRecordWidget({
    required this.patientId,
    this.visitId,
    this.patient,
  });

  @override
  State<_ObGynRecordWidget> createState() => _ObGynRecordWidgetState();
}

class _ObGynRecordWidgetState extends State<_ObGynRecordWidget> {
  final _weightCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _fhrCtrl = TextEditingController();
  final _fundalCtrl = TextEditingController();
  final _usNotesCtrl = TextEditingController();
  PatientModel? _patient;
  List<SpecialtyRecordEntryModel> _entries = [];
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _load();
  }

  Future<void> _load() async {
    if (_patient == null &&
        widget.patientId.isNotEmpty &&
        getIt.isRegistered<PatientsRepo>()) {
      final pRes = await getIt<PatientsRepo>().getPatientById(id: widget.patientId);
      pRes.fold((_) {}, (p) {
        if (mounted) setState(() => _patient = p);
      });
    }
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: MedicalSpecialty.obstetricsGynecology,
    );
    res.fold((_) {}, (list) {
      if (mounted) setState(() => _entries = list);
    });
  }

  Future<void> _saveAntenatal() async {
    final hasAny = _weightCtrl.text.trim().isNotEmpty ||
        _bpCtrl.text.trim().isNotEmpty ||
        _fhrCtrl.text.trim().isNotEmpty ||
        _fundalCtrl.text.trim().isNotEmpty ||
        _usNotesCtrl.text.trim().isNotEmpty;
    if (!hasAny) {
      setState(() {
        _validationError = 'يرجى إدخال بيانات في حقل واحد على الأقل قبل الحفظ.';
      });
      return;
    }
    setState(() => _validationError = null);
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.obstetricsGynecology,
      kind: 'obgyn_antenatal',
      data: {
        'weightKg': double.tryParse(_weightCtrl.text.trim()),
        'bp': _bpCtrl.text.trim(),
        'fhrBpm': int.tryParse(_fhrCtrl.text.trim()),
        'fundalHeightCm': double.tryParse(_fundalCtrl.text.trim()),
        'ultrasoundNotes': _usNotesCtrl.text.trim(),
        'gestationalWeeks': _patient?.gestationalWeeks(),
      },
      createdAt: DateTime.now(),
    );
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  Future<void> _recordDeliveryOutcome() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.obstetricsGynecology,
      kind: 'obgyn_delivery',
      data: {
        'deliveryDate': DateTime.now().toIso8601String(),
        'mode': 'normal',
        'babyWeightKg': 3.2,
      },
      createdAt: DateTime.now(),
    );
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);

    if (_patient != null && getIt.isRegistered<PatientsRepo>()) {
      await getIt<PatientsRepo>().updatePatient(
        patient: _patient!.copyWith(
          isPregnant: false,
          isNursing: true,
          paraCount: (_patient!.paraCount ?? 0) + 1,
        ),
      );
    }
    await _load();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bpCtrl.dispose();
    _fhrCtrl.dispose();
    _fundalCtrl.dispose();
    _usNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_patient != null && _patient!.gender != GenderEnum.female) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ملف النساء والتوليد متاح للمريضات الإناث فقط.',
                style: CustomAppFontStyle.semiBold13.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }

    final countdown = ObstetricsGynecologyModule.formatPregnancyCountdown(_patient);
    final isOverdue = _patient?.isPregnant == true &&
        _patient?.computedEdd != null &&
        DateTime.now().isAfter(_patient!.computedEdd!);

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
              const Icon(Icons.pregnant_woman_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('ملف النساء والتوليد', style: CustomAppFontStyle.bold14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              countdown,
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: isOverdue ? AppColors.error : AppColors.primary,
              ),
            ),
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
                  controller: _bpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ضغط الدم',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fhrCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نبض الجنين',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fundalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ارتفاع الرحم (سم)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usNotesCtrl,
            decoration: const InputDecoration(
              labelText: 'ملاحظات السونار والتحاليل',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          if (_validationError != null) ...[
            Text(
              _validationError!,
              style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_patient?.isPregnant == true)
                TextButton(
                  onPressed: _recordDeliveryOutcome,
                  child: const Text('تسجيل ولادة (إنهاء الحمل)'),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _saveAntenatal,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('حفظ زيارة المتابعة'),
              ),
            ],
          ),
          if (_entries.isNotEmpty) ...[
            const Divider(height: 18),
            Text('سجل زيارات المتابعة (${_entries.length}):',
                style: CustomAppFontStyle.semiBold12),
            const SizedBox(height: 4),
            ..._entries.map((e) => Text(
                  '• وزن: ${e.data['weightKg'] ?? '-'} | ضغط: ${e.data['bp'] ?? '-'} | نبض الجنين: ${e.data['fhrBpm'] ?? '-'} | رحم: ${e.data['fundalHeightCm'] ?? '-'} | سونار: ${e.data['ultrasoundNotes'] ?? '-'}',
                  style: CustomAppFontStyle.regular12,
                )),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/specialty_records/presentation/widgets/sessions_and_packages_widget.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class ChronicCareModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;

  const ChronicCareModule(this.specialty);

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'bp': '',
        'glucoseMgDl': null,
        'hba1c': null,
        'heartRate': null,
        'ecgEchoNotes': '',
        'tshLevel': null,
        'medicationChanges': '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) =>
      _ChronicCareWidget(patientId: patient.id ?? '', specialty: specialty);

  @override
  Widget buildVisitSection(VisitModel visit) => _ChronicCareWidget(
        patientId: visit.patientId ?? '',
        visitId: visit.id,
        specialty: specialty,
      );
}

class _ChronicCareWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final MedicalSpecialty specialty;

  const _ChronicCareWidget({
    required this.patientId,
    this.visitId,
    required this.specialty,
  });

  @override
  State<_ChronicCareWidget> createState() => _ChronicCareWidgetState();
}

class _ChronicCareWidgetState extends State<_ChronicCareWidget> {
  final _bpCtrl = TextEditingController();
  final _field2Ctrl = TextEditingController();
  final _field3Ctrl = TextEditingController();
  final _medCtrl = TextEditingController();
  String? _validationError;

  Future<void> _save() async {
    final hasAny = _bpCtrl.text.trim().isNotEmpty ||
        _field2Ctrl.text.trim().isNotEmpty ||
        _field3Ctrl.text.trim().isNotEmpty ||
        _medCtrl.text.trim().isNotEmpty;
    if (!hasAny) {
      setState(() {
        _validationError = 'يرجى إدخال بيانات في حقل واحد على الأقل قبل الحفظ.';
      });
      return;
    }
    setState(() => _validationError = null);
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'chronic_followup',
        data: {
          'primaryMetric': _bpCtrl.text.trim(),
          'secondaryMetric': _field2Ctrl.text.trim(),
          'tertiaryMetric': _field3Ctrl.text.trim(),
          'medicationChanges': _medCtrl.text.trim(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _field2Ctrl.dispose();
    _field3Ctrl.dispose();
    _medCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCardio = widget.specialty == MedicalSpecialty.cardiology;
    final isEndo = widget.specialty == MedicalSpecialty.endocrinology;

    final title = isCardio
        ? 'متابعة القلب والأوعية الدموية'
        : (isEndo ? 'متابعة الغدد الصماء والسكر' : 'متابعة الباطنة والأمراض المزمنة');
    final label1 = isEndo ? 'السكر الصائم (مجم/دل)' : 'ضغط الدم (BP)';
    final label2 = isCardio
        ? 'معدل النبض (bpm)'
        : (isEndo ? 'السكر التراكمي (HbA1c)' : 'السكر (مجم/دل)');
    final label3 = isCardio
        ? 'نتائج ECG / الإيكو (EF%)'
        : (isEndo ? 'تحليل الغدة TSH' : 'فحص الأجهزة الحيوية');

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
          Text(title, style: CustomAppFontStyle.bold14),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _bpCtrl, decoration: InputDecoration(labelText: label1, border: const OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _field2Ctrl, decoration: InputDecoration(labelText: label2, border: const OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _field3Ctrl, decoration: InputDecoration(labelText: label3, border: const OutlineInputBorder(), isDense: true))),
            ],
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
            children: [
              Expanded(child: TextField(controller: _medCtrl, decoration: const InputDecoration(labelText: 'تعديلات الأدوية والجرعات', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _save, child: const Text('حفظ المتابعة')),
            ],
          ),
        ],
      ),
    );
  }
}

class MusculoskeletalModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;

  const MusculoskeletalModule(this.specialty);

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'affectedSite': '',
        'side': 'يمين',
        'injuryOrSurgeryDate': '',
        'diagnosis': '',
        'romNotes': '',
        'painScore': '',
        'castOrBraceDates': '',
        'imagingNotes': '',
        'physioReferral': false,
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) {
    return _OrthopedicsAndPhysioWidget(
      patientId: patient.id ?? '',
      patientName: patient.name,
      specialty: specialty,
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _OrthopedicsAndPhysioWidget(
      patientId: visit.patientId ?? '',
      patientName: visit.patientName,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      specialty: specialty,
    );
  }
}

class _OrthopedicsAndPhysioWidget extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? visitId;
  final String? doctorId;
  final String? doctorName;
  final MedicalSpecialty specialty;

  const _OrthopedicsAndPhysioWidget({
    required this.patientId,
    this.patientName,
    this.visitId,
    this.doctorId,
    this.doctorName,
    required this.specialty,
  });

  @override
  State<_OrthopedicsAndPhysioWidget> createState() =>
      _OrthopedicsAndPhysioWidgetState();
}

class _OrthopedicsAndPhysioWidgetState
    extends State<_OrthopedicsAndPhysioWidget> {
  final _siteCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _romCtrl = TextEditingController();
  final _castDatesCtrl = TextEditingController();
  final _imagingCtrl = TextEditingController();
  final _painScoreCtrl = TextEditingController();
  String _side = 'يمين';
  bool _physioReferral = false;
  String? _validationError;
  List<SpecialtyRecordEntryModel> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: widget.specialty,
    );
    res.fold((_) {}, (list) {
      if (mounted) {
        setState(() {
          _entries = list.where((e) => e.kind == 'ortho_assessment').toList();
        });
      }
    });
  }

  Future<void> _saveAssessment() async {
    final hasAny = _siteCtrl.text.trim().isNotEmpty ||
        _diagnosisCtrl.text.trim().isNotEmpty ||
        _romCtrl.text.trim().isNotEmpty ||
        _castDatesCtrl.text.trim().isNotEmpty ||
        _imagingCtrl.text.trim().isNotEmpty ||
        _painScoreCtrl.text.trim().isNotEmpty ||
        _physioReferral;
    if (!hasAny) {
      setState(() {
        _validationError = 'يرجى إدخال بيانات في حقل واحد على الأقل قبل الحفظ.';
      });
      return;
    }
    setState(() => _validationError = null);
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'ortho_assessment',
        data: {
          'affectedSite': _siteCtrl.text.trim(),
          'side': _side,
          'diagnosis': _diagnosisCtrl.text.trim(),
          'romNotes': _romCtrl.text.trim(),
          'painScore': _painScoreCtrl.text.trim(),
          'castOrBraceDates': _castDatesCtrl.text.trim(),
          'imagingNotes': _imagingCtrl.text.trim(),
          'physioReferral': _physioReferral,
        },
        createdAt: DateTime.now(),
      ),
    );
    await _load();
  }

  @override
  void dispose() {
    _siteCtrl.dispose();
    _diagnosisCtrl.dispose();
    _romCtrl.dispose();
    _castDatesCtrl.dispose();
    _imagingCtrl.dispose();
    _painScoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhysio = widget.specialty == MedicalSpecialty.physiotherapy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPhysio ? 'تقييم العلاج الطبيعي والتأهيل' : 'تقييم العظام والمفاصل',
                style: CustomAppFontStyle.bold14,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _siteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الموضع المصاب',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _side,
                      decoration: const InputDecoration(
                        labelText: 'الجانب',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const ['يمين', 'يسار', 'كلاهما']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _side = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _diagnosisCtrl,
                      decoration: InputDecoration(
                        labelText: isPhysio ? 'خطة الجلسات والتشخيص' : 'التشخيص / تاريخ الإصابة',
                        border: const OutlineInputBorder(),
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
                      controller: _romCtrl,
                      decoration: const InputDecoration(
                        labelText: 'المدى الحركي (ROM)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isPhysio)
                    Expanded(
                      child: TextField(
                        controller: _painScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مقياس الألم (0-10)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: TextField(
                        controller: _castDatesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تواريخ الجبس / الدعامة',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _imagingCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الأشعة والتقارير',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_validationError != null) ...[
                Text(
                  _validationError!,
                  style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                children: [
                  if (!isPhysio) ...[
                    Checkbox(
                      value: _physioReferral,
                      onChanged: (v) => setState(() => _physioReferral = v ?? false),
                    ),
                    const Text('تحويل إلى العلاج الطبيعي'),
                  ],
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _saveAssessment,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('حفظ التقييم'),
                  ),
                ],
              ),
              if (_entries.isNotEmpty) ...[
                const Divider(height: 16),
                ..._entries.take(3).map((e) => Text(
                      '• ${e.data['affectedSite'] ?? '-'} (${e.data['side'] ?? '-'}) | ${e.data['diagnosis'] ?? '-'}',
                      style: CustomAppFontStyle.regular12,
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SessionsAndPackagesWidget(
          patientId: widget.patientId,
          patientName: widget.patientName,
          visitId: widget.visitId,
          doctorId: widget.doctorId,
          doctorName: widget.doctorName,
          specialty: widget.specialty,
          title: isPhysio ? 'جلسات العلاج الطبيعي والتأهيل' : 'جلسات وباقات العظام',
          procedureOptions: const ['جلسة تأهيل حركي', 'علاج طبيعي كهربائي', 'متابعة إصابة'],
        ),
      ],
    );
  }
}

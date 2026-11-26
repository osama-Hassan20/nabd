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
        'weightKg': null,
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
  final _glucoseCtrl = TextEditingController();
  final _hba1cCtrl = TextEditingController();
  final _medCtrl = TextEditingController();

  Future<void> _save() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'chronic_followup',
        data: {
          'bp': _bpCtrl.text.trim(),
          'glucoseMgDl': num.tryParse(_glucoseCtrl.text.trim()),
          'hba1c': num.tryParse(_hba1cCtrl.text.trim()),
          'medicationChanges': _medCtrl.text.trim(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _glucoseCtrl.dispose();
    _hba1cCtrl.dispose();
    _medCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text('متابعة الأمراض المزمنة', style: CustomAppFontStyle.bold14),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _bpCtrl, decoration: const InputDecoration(labelText: 'ضغط الدم', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _glucoseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السكر (مجم/دل)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _hba1cCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السكر التراكمي', border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _medCtrl, decoration: const InputDecoration(labelText: 'تعديلات الأدوية', border: OutlineInputBorder(), isDense: true))),
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
  String _side = 'يمين';
  bool _physioReferral = false;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                widget.specialty == MedicalSpecialty.orthopedics
                    ? 'تقييم العظام والمفاصل'
                    : 'تقييم العلاج الطبيعي',
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
                      decoration: const InputDecoration(
                        labelText: 'التشخيص / تاريخ الإصابة',
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
                      controller: _romCtrl,
                      decoration: const InputDecoration(
                        labelText: 'المدى الحركي',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              Row(
                children: [
                  Checkbox(
                    value: _physioReferral,
                    onChanged: (v) => setState(() => _physioReferral = v ?? false),
                  ),
                  const Text('تحويل إلى العلاج الطبيعي'),
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
          title: widget.specialty == MedicalSpecialty.physiotherapy
              ? 'جلسات العلاج الطبيعي والتأهيل'
              : 'جلسات وباقات العظام',
          procedureOptions: const ['جلسة تأهيل حركي', 'علاج طبيعي كهربائي', 'متابعة إصابة'],
        ),
      ],
    );
  }
}

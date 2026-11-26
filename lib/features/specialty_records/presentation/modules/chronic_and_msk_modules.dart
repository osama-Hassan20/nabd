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
          Text('متابعة الأمراض المزمنة (${widget.specialty.value})', style: CustomAppFontStyle.bold14),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _bpCtrl, decoration: const InputDecoration(labelText: 'الضغط (BP)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _glucoseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السكر (mg/dL)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _hba1cCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'التراكمي HbA1c', border: OutlineInputBorder(), isDense: true))),
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
        'injuryArea': '',
        'painScore': 5,
        'romNotes': '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) {
    return SessionsAndPackagesWidget(
      patientId: patient.id ?? '',
      patientName: patient.name,
      specialty: specialty,
      title: specialty == MedicalSpecialty.physiotherapy
          ? 'جلسات العلاج الطبيعي والتأهيل'
          : 'متابعة العظام والمفاصل',
      procedureOptions: const ['جلسة تأهيل حركي', 'علاج طبيعي كهربائي', 'متابعة إصابة'],
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return SessionsAndPackagesWidget(
      patientId: visit.patientId ?? '',
      patientName: visit.patientName,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      specialty: specialty,
      title: specialty == MedicalSpecialty.physiotherapy
          ? 'جلسات العلاج الطبيعي'
          : 'سجل العظام والمدى الحركي',
      procedureOptions: const ['جلسة تأهيل حركي', 'علاج طبيعي كهربائي', 'متابعة إصابة'],
    );
  }
}

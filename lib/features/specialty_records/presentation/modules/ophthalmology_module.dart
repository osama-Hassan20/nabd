import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/widgets/patient_details_sections/patient_specialty_tracking_section.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class OphthalmologyModule implements SpecialtyRecordModule {
  const OphthalmologyModule();

  @override
  MedicalSpecialty get specialty => MedicalSpecialty.ophthalmology;

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'iopRight': null,
        'iopLeft': null,
        'vaRight': '6/6',
        'vaLeft': '6/6',
        'sphereRight': '0.00',
        'sphereLeft': '0.00',
        'cylinderRight': '0.00',
        'cylinderLeft': '0.00',
        'fundusNotes': '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OphthalmologyFormWidget(patientId: patient.id ?? ''),
        if (patient.eyeExams != null && patient.eyeExams!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const PatientSpecialtyTrackingSection(),
        ],
      ],
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _OphthalmologyFormWidget(
      patientId: visit.patientId ?? '',
      visitId: visit.id,
    );
  }
}

class _OphthalmologyFormWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  const _OphthalmologyFormWidget({required this.patientId, this.visitId});

  @override
  State<_OphthalmologyFormWidget> createState() => _OphthalmologyFormWidgetState();
}

class _OphthalmologyFormWidgetState extends State<_OphthalmologyFormWidget> {
  final _iopRCtrl = TextEditingController(text: '14');
  final _iopLCtrl = TextEditingController(text: '14');
  final _vaRCtrl = TextEditingController(text: '6/6');
  final _vaLCtrl = TextEditingController(text: '6/6');
  final _refractionCtrl = TextEditingController();

  Future<void> _save() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: MedicalSpecialty.ophthalmology,
        kind: 'ophthalmology_exam',
        data: {
          'iopRight': _iopRCtrl.text.trim(),
          'iopLeft': _iopLCtrl.text.trim(),
          'vaRight': _vaRCtrl.text.trim(),
          'vaLeft': _vaLCtrl.text.trim(),
          'glassesRx': _refractionCtrl.text.trim(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _iopRCtrl.dispose();
    _iopLCtrl.dispose();
    _vaRCtrl.dispose();
    _vaLCtrl.dispose();
    _refractionCtrl.dispose();
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
          Text('فحص العيون والانكسار (IOP / VA / Rx)', style: CustomAppFontStyle.bold14),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _iopRCtrl, decoration: const InputDecoration(labelText: 'IOP OD', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _iopLCtrl, decoration: const InputDecoration(labelText: 'IOP OS', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _vaRCtrl, decoration: const InputDecoration(labelText: 'VA OD', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _vaLCtrl, decoration: const InputDecoration(labelText: 'VA OS', border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _refractionCtrl, decoration: const InputDecoration(labelText: 'وصفة النظارة (Sph / Cyl / Axis)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _save, child: const Text('حفظ الفحص')),
            ],
          ),
        ],
      ),
    );
  }
}

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

class DentistryModule implements SpecialtyRecordModule {
  const DentistryModule();

  static const List<int> adultFdiTeeth = [
    18, 17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 28,
    48, 47, 46, 45, 44, 43, 42, 41, 31, 32, 33, 34, 35, 36, 37, 38,
  ];

  static const List<int> childFdiTeeth = [
    55, 54, 53, 52, 51, 61, 62, 63, 64, 65,
    85, 84, 83, 82, 81, 71, 72, 73, 74, 75,
  ];

  @override
  MedicalSpecialty get specialty => MedicalSpecialty.dentistry;

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'toothFdi': 16,
        'condition': 'caries',
        'procedure': 'حشو',
        'sessionIndex': 1,
        'totalSessions': 1,
        'materials': '',
        'anesthesia': 'Articaine',
        'cost': 500,
        'status': 'planned',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) {
    final errors = <String>[];
    final fdi = entry['toothFdi'] as int?;
    if (fdi == null || (!adultFdiTeeth.contains(fdi) && !childFdiTeeth.contains(fdi))) {
      errors.add('رقم السن (FDI) غير صالح');
    }
    return errors;
  }

  @override
  Widget buildPatientTab(PatientModel patient) {
    return _DentistryRecordWidget(
      patientId: patient.id ?? '',
      patientName: patient.name,
      isChild: patient.isChild(),
    );
  }

  @override
  Widget buildVisitSection(VisitModel visit) {
    return _DentistryRecordWidget(
      patientId: visit.patientId ?? '',
      patientName: visit.patientName,
      visitId: visit.id,
      doctorId: visit.doctorId,
      doctorName: visit.doctorName,
      isChild: false,
    );
  }
}

class _DentistryRecordWidget extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? visitId;
  final String? doctorId;
  final String? doctorName;
  final bool isChild;

  const _DentistryRecordWidget({
    required this.patientId,
    this.patientName,
    this.visitId,
    this.doctorId,
    this.doctorName,
    required this.isChild,
  });

  @override
  State<_DentistryRecordWidget> createState() => _DentistryRecordWidgetState();
}

class _DentistryRecordWidgetState extends State<_DentistryRecordWidget> {
  int _selectedTooth = 16;
  String _selectedProc = 'علاج عصب';
  List<SpecialtyRecordEntryModel> _toothEntries = [];

  @override
  void initState() {
    super.initState();
    _selectedTooth = widget.isChild ? 55 : 16;
    _load();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final res = await getIt<OfflineFirstSpecialtyRecordsRepo>().getEntriesForPatient(
      patientId: widget.patientId,
      specialty: MedicalSpecialty.dentistry,
    );
    res.fold((_) {}, (list) {
      if (mounted) {
        setState(() {
          _toothEntries = list.where((e) => e.kind == 'dentistry_tooth').toList();
        });
      }
    });
  }

  Future<void> _saveToothPlan() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    final entry = SpecialtyRecordEntryModel(
      id: '',
      patientId: widget.patientId,
      visitId: widget.visitId,
      specialty: MedicalSpecialty.dentistry,
      kind: 'dentistry_tooth',
      data: {
        'toothFdi': _selectedTooth,
        'procedure': _selectedProc,
        'sessionIndex': 1,
        'totalSessions': _selectedProc == 'علاج عصب' ? 3 : 1,
        'status': 'done',
      },
      createdAt: DateTime.now(),
    );
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(entry);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final teeth = widget.isChild
        ? DentistryModule.childFdiTeeth
        : DentistryModule.adultFdiTeeth;

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
                'مخطط الأسنان (FDI - ${teeth.length} سن)',
                style: CustomAppFontStyle.bold14,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: teeth.map((t) {
                  final hasWork = _toothEntries.any((e) => e.data['toothFdi'] == t);
                  final isSel = _selectedTooth == t;
                  return ChoiceChip(
                    label: Text('$t'),
                    selected: isSel,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: hasWork ? const Color(0xFFFEF3C7) : null,
                    onSelected: (_) => setState(() => _selectedTooth = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedProc,
                      decoration: const InputDecoration(
                        labelText: 'الإجراء للسن المحدد',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const ['حشو', 'علاج عصب', 'تلبيس', 'خلع', 'تنظيف']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedProc = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveToothPlan,
                    child: Text('تسجيل للسن $_selectedTooth'),
                  ),
                ],
              ),
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
          specialty: MedicalSpecialty.dentistry,
          title: 'جلسات وباقات الأسنان',
          procedureOptions: const ['علاج عصب', 'حشو تجميلي', 'تركيبات', 'تنظيف جير'],
        ),
      ],
    );
  }
}

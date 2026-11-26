import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/offline/repositories/offline_first_specialty_records_repo.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/specialty_records/data/models/specialty_record_entry_model.dart';
import 'package:eyadty/features/specialty_records/domain/specialty_record_module.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';

class StructuredGenericModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;
  final List<String> trendFieldLabels;

  const StructuredGenericModule({
    required this.specialty,
    required this.trendFieldLabels,
  });

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        'complaint': '',
        'findings': '',
        'diagnosis': '',
        'plan': '',
        'followUp': '',
        'trendValues': <String, String>{},
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) => _StructuredTemplateWidget(
        patientId: patient.id ?? '',
        specialty: specialty,
        trendFieldLabels: trendFieldLabels,
      );

  @override
  Widget buildVisitSection(VisitModel visit) => _StructuredTemplateWidget(
        patientId: visit.patientId ?? '',
        visitId: visit.id,
        specialty: specialty,
        trendFieldLabels: trendFieldLabels,
      );
}

class _StructuredTemplateWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final MedicalSpecialty specialty;
  final List<String> trendFieldLabels;

  const _StructuredTemplateWidget({
    required this.patientId,
    this.visitId,
    required this.specialty,
    required this.trendFieldLabels,
  });

  @override
  State<_StructuredTemplateWidget> createState() =>
      _StructuredTemplateWidgetState();
}

class _StructuredTemplateWidgetState extends State<_StructuredTemplateWidget> {
  final _complaintCtrl = TextEditingController();
  final _findingsCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _trend1Ctrl = TextEditingController();

  Future<void> _save() async {
    if (!getIt.isRegistered<OfflineFirstSpecialtyRecordsRepo>()) return;
    await getIt<OfflineFirstSpecialtyRecordsRepo>().saveEntry(
      SpecialtyRecordEntryModel(
        id: '',
        patientId: widget.patientId,
        visitId: widget.visitId,
        specialty: widget.specialty,
        kind: 'structured_visit',
        data: {
          'complaint': _complaintCtrl.text.trim(),
          'findings': _findingsCtrl.text.trim(),
          'plan': _planCtrl.text.trim(),
          if (widget.trendFieldLabels.isNotEmpty)
            widget.trendFieldLabels.first: _trend1Ctrl.text.trim(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _complaintCtrl.dispose();
    _findingsCtrl.dispose();
    _planCtrl.dispose();
    _trend1Ctrl.dispose();
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
          Row(
            children: [
              Icon(widget.specialty.icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('نموذج التخصص المنظم', style: CustomAppFontStyle.bold14),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _complaintCtrl,
            decoration: InputDecoration(
              labelText: 'specialty_complaint_findings'.tr(),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _planCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الخطة العلاجية والمتابعة',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (widget.trendFieldLabels.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _trend1Ctrl,
                    decoration: InputDecoration(
                      labelText: widget.trendFieldLabels.first,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('حفظ السجل التخصصي'),
            ),
          ),
        ],
      ),
    );
  }
}

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

class SpecialtyFieldDef {
  final String key;
  final String labelAr;
  const SpecialtyFieldDef(this.key, this.labelAr);
}

class StructuredGenericModule implements SpecialtyRecordModule {
  @override
  final MedicalSpecialty specialty;
  final List<SpecialtyFieldDef> fields;
  final String? customHeaderAr;
  final bool isGenericFallback;

  const StructuredGenericModule({
    required this.specialty,
    required this.fields,
    this.customHeaderAr,
    this.isGenericFallback = false,
  });

  @override
  String get tabLabelKey => specialty.labelKey;

  @override
  Map<String, dynamic> emptyEntry() => {
        for (final f in fields) f.key: '',
      };

  @override
  List<String> validate(Map<String, dynamic> entry) => const [];

  @override
  Widget buildPatientTab(PatientModel patient) => _StructuredTemplateWidget(
        patientId: patient.id ?? '',
        specialty: specialty,
        fields: fields,
        customHeaderAr: customHeaderAr,
        isGenericFallback: isGenericFallback,
      );

  @override
  Widget buildVisitSection(VisitModel visit) => _StructuredTemplateWidget(
        patientId: visit.patientId ?? '',
        visitId: visit.id,
        specialty: specialty,
        fields: fields,
        customHeaderAr: customHeaderAr,
        isGenericFallback: isGenericFallback,
      );
}

class _StructuredTemplateWidget extends StatefulWidget {
  final String patientId;
  final String? visitId;
  final MedicalSpecialty specialty;
  final List<SpecialtyFieldDef> fields;
  final String? customHeaderAr;
  final bool isGenericFallback;

  const _StructuredTemplateWidget({
    required this.patientId,
    this.visitId,
    required this.specialty,
    required this.fields,
    this.customHeaderAr,
    required this.isGenericFallback,
  });

  @override
  State<_StructuredTemplateWidget> createState() =>
      _StructuredTemplateWidgetState();
}

class _StructuredTemplateWidgetState extends State<_StructuredTemplateWidget> {
  late final Map<String, TextEditingController> _controllers;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.fields) f.key: TextEditingController(),
    };
  }

  Future<void> _save() async {
    final hasAny = _controllers.values.any((c) => c.text.trim().isNotEmpty);
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
        kind: 'structured_visit',
        data: {
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.customHeaderAr ??
        (widget.isGenericFallback
            ? 'نموذج عام للتخصص (${widget.specialty.labelKey.tr()})'
            : 'سجل ${widget.specialty.labelKey.tr()}');

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
              Text(header, style: CustomAppFontStyle.bold14),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.fields.map((f) {
              return SizedBox(
                width: 260,
                child: TextField(
                  controller: _controllers[f.key],
                  decoration: InputDecoration(
                    labelText: f.labelAr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (_validationError != null) ...[
            Text(
              _validationError!,
              style: CustomAppFontStyle.medium12.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 6),
          ],
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

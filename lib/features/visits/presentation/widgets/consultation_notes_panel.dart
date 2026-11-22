import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../manager/visit_form_state.dart';

class ConsultationNotesPanel extends StatefulWidget {
  final VisitFormState formState;
  final bool isReadOnly;
  final ValueChanged<String>? onChiefComplaintChanged;
  final ValueChanged<String>? onMedicalHistoryChanged;
  final ValueChanged<String>? onPhysicalExamChanged;
  final ValueChanged<String>? onDiagnosisChanged;
  final ValueChanged<String>? onTreatmentPlanChanged;
  final ValueChanged<String>? onFollowUpNotesChanged;
  final ValueChanged<int?>? onFollowUpDaysChanged;

  const ConsultationNotesPanel({
    super.key,
    required this.formState,
    this.isReadOnly = false,
    this.onChiefComplaintChanged,
    this.onMedicalHistoryChanged,
    this.onPhysicalExamChanged,
    this.onDiagnosisChanged,
    this.onTreatmentPlanChanged,
    this.onFollowUpNotesChanged,
    this.onFollowUpDaysChanged,
  });

  @override
  State<ConsultationNotesPanel> createState() => _ConsultationNotesPanelState();
}

class _ConsultationNotesPanelState extends State<ConsultationNotesPanel> {
  late final TextEditingController _chiefComplaintController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _physicalExamController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _treatmentPlanController;
  late final TextEditingController _followUpNotesController;
  late final TextEditingController _followUpDaysController;

  @override
  void initState() {
    super.initState();
    _chiefComplaintController = TextEditingController(
      text: widget.formState.chiefComplaint ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: widget.formState.medicalHistory ?? '',
    );
    _physicalExamController = TextEditingController(
      text: widget.formState.physicalExam ?? '',
    );
    _diagnosisController = TextEditingController(
      text: widget.formState.diagnosis ?? '',
    );
    _treatmentPlanController = TextEditingController(
      text: widget.formState.treatmentPlan ?? '',
    );
    _followUpNotesController = TextEditingController(
      text: widget.formState.followUpNotes ?? '',
    );
    _followUpDaysController = TextEditingController(
      text: widget.formState.followUpDays?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ConsultationNotesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formState != oldWidget.formState) {
      _syncTextIfDifferent(
        _chiefComplaintController,
        widget.formState.chiefComplaint,
      );
      _syncTextIfDifferent(
        _medicalHistoryController,
        widget.formState.medicalHistory,
      );
      _syncTextIfDifferent(
        _physicalExamController,
        widget.formState.physicalExam,
      );
      _syncTextIfDifferent(
        _diagnosisController,
        widget.formState.diagnosis,
      );
      _syncTextIfDifferent(
        _treatmentPlanController,
        widget.formState.treatmentPlan,
      );
      _syncTextIfDifferent(
        _followUpNotesController,
        widget.formState.followUpNotes,
      );
      _syncTextIfDifferent(
        _followUpDaysController,
        widget.formState.followUpDays?.toString(),
      );
    }
  }

  void _syncTextIfDifferent(TextEditingController controller, String? value) {
    final target = value ?? '';
    if (controller.text != target && !controller.value.isComposingRangeValid) {
      final oldSelection = controller.selection;
      final newOffset =
          oldSelection.end <= target.length ? oldSelection.end : target.length;
      controller.value = TextEditingValue(
        text: target,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _medicalHistoryController.dispose();
    _physicalExamController.dispose();
    _diagnosisController.dispose();
    _treatmentPlanController.dispose();
    _followUpNotesController.dispose();
    _followUpDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: colors.primary,
              ),
              Text(
                'visits_consultation_details_title'.tr(),
                style: CustomAppFontStyle.bold16.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (widget.isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'visits_finalized_read_only'.tr(),
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Chief Complaint (Required for finalize)
          CustomTextFormField(
            headerText: 'visits_chief_complaint'.tr(),
            isRequired: true,
            controller: _chiefComplaintController,
            isReadOnly: widget.isReadOnly,
            isEnabled: !widget.isReadOnly,
            maxLine: 2,
            minLine: 2,
            onChanged: (val) =>
                widget.onChiefComplaintChanged?.call(val ?? ''),
          ),
          const SizedBox(height: 14),

          // Medical History
          CustomTextFormField(
            headerText: 'visits_medical_history'.tr(),
            controller: _medicalHistoryController,
            isReadOnly: widget.isReadOnly,
            isEnabled: !widget.isReadOnly,
            maxLine: 2,
            minLine: 2,
            onChanged: (val) =>
                widget.onMedicalHistoryChanged?.call(val ?? ''),
          ),
          const SizedBox(height: 14),

          // Physical Exam
          CustomTextFormField(
            headerText: 'visits_physical_exam'.tr(),
            controller: _physicalExamController,
            isReadOnly: widget.isReadOnly,
            isEnabled: !widget.isReadOnly,
            maxLine: 2,
            minLine: 2,
            onChanged: (val) =>
                widget.onPhysicalExamChanged?.call(val ?? ''),
          ),
          const SizedBox(height: 14),

          // Diagnosis (Required for finalize)
          CustomTextFormField(
            headerText: 'visits_diagnosis'.tr(),
            isRequired: true,
            hintText: 'visits_diagnosis_hint'.tr(),
            controller: _diagnosisController,
            isReadOnly: widget.isReadOnly,
            isEnabled: !widget.isReadOnly,
            maxLine: 2,
            minLine: 2,
            onChanged: (val) => widget.onDiagnosisChanged?.call(val ?? ''),
          ),
          const SizedBox(height: 14),

          // Treatment Plan
          CustomTextFormField(
            headerText: 'visits_treatment_plan'.tr(),
            controller: _treatmentPlanController,
            isReadOnly: widget.isReadOnly,
            isEnabled: !widget.isReadOnly,
            maxLine: 3,
            minLine: 2,
            onChanged: (val) =>
                widget.onTreatmentPlanChanged?.call(val ?? ''),
          ),
          const SizedBox(height: 14),

          // Follow Up Days & Follow Up Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: CustomTextFormField(
                  headerText: 'visits_follow_up_days'.tr(),
                  controller: _followUpDaysController,
                  isReadOnly: widget.isReadOnly,
                  isEnabled: !widget.isReadOnly,
                  textInputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (val) {
                    final text = val?.trim() ?? '';
                    final days = int.tryParse(text);
                    widget.onFollowUpDaysChanged?.call(days);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: CustomTextFormField(
                  headerText: 'visits_follow_up_notes'.tr(),
                  controller: _followUpNotesController,
                  isReadOnly: widget.isReadOnly,
                  isEnabled: !widget.isReadOnly,
                  maxLine: 1,
                  onChanged: (val) =>
                      widget.onFollowUpNotesChanged?.call(val ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

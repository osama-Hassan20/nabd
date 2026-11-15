import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_toast.dart';
import '../../../../drugs/domain/helpers/drug_name_validator.dart';
import '../../../../drugs/domain/use_cases/quick_add_drug_use_case.dart';
import '../../../data/models/prescription_item_model.dart';
import '../../manager/visits_cubit.dart';

class DrugQuickAddModal extends StatefulWidget {
  final VisitsCubit cubit;
  final String visitId;
  final String doctorId;

  const DrugQuickAddModal({
    super.key,
    required this.cubit,
    required this.visitId,
    required this.doctorId,
  });

  static Future<void> show({
    required BuildContext context,
    required VisitsCubit cubit,
    required String visitId,
    required String doctorId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DrugQuickAddModal(
        cubit: cubit,
        visitId: visitId,
        doctorId: doctorId,
      ),
    );
  }

  @override
  State<DrugQuickAddModal> createState() => _DrugQuickAddModalState();
}

class _DrugQuickAddModalState extends State<DrugQuickAddModal> {
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? _nameError;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _concentrationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final name = _nameController.text.trim();
    final errorKey = DrugNameValidator.validate(name);

    if (errorKey != null) {
      setState(() {
        _nameError = errorKey.tr();
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    try {
      final quickAddUseCase = getIt<QuickAddDrugUseCase>();
      final res = await quickAddUseCase(
        QuickAddDrugParams(
          name: name,
          visitId: widget.visitId,
          doctorId: widget.doctorId,
          concentration: _concentrationController.text.trim().isEmpty
              ? null
              : _concentrationController.text.trim(),
          dosage: _dosageController.text.trim().isEmpty
              ? null
              : _dosageController.text.trim(),
          frequency: _frequencyController.text.trim().isEmpty
              ? null
              : _frequencyController.text.trim(),
          duration: _durationController.text.trim().isEmpty
              ? null
              : _durationController.text.trim(),
        ),
      );

      res.fold(
        (failure) {
          if (mounted) {
            setState(() => _isSaving = false);
            CustomToast(
              context: context,
              header: failure.errMessage.tr(),
            ).showTopToast();
          }
        },
        (savedDrug) {
          // Automatically add into prescription draft
          widget.cubit.addPrescriptionItem(
            PrescriptionItemModel(
              drugId: savedDrug.id,
              tradeName: savedDrug.name,
              scientificName: savedDrug.scientificName,
              concentration: savedDrug.concentration,
              dosage: savedDrug.defaultDosage,
              frequency: savedDrug.defaultFrequency,
              duration: savedDrug.defaultDuration,
              instructions: savedDrug.description,
            ),
          );

          if (mounted) {
            Navigator.of(context).pop();
            CustomToast(
              context: context,
              header: 'drugs_quick_added_badge'.tr(),
            ).showTopToast();
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_outlined,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'rx_quick_add_btn'.tr(),
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'drugs_quick_added_badge'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Drug Name (Trade)
                CustomTextFormField(
                  controller: _nameController,
                  headerText: 'drugs_trade_name'.tr(),
                  hintText: 'drugs_trade_name_hint'.tr(),
                  validator: (_) => _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Scientific Name & Concentration
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextFormField(
                        controller: _scientificController,
                        headerText: 'drugs_scientific_name'.tr(),
                        hintText: 'drugs_scientific_name_hint'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomTextFormField(
                        controller: _concentrationController,
                        headerText: 'drugs_concentration'.tr(),
                        hintText: 'drugs_concentration_hint'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dosage & Frequency
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _dosageController,
                        headerText: 'drugs_dosage'.tr(),
                        hintText: 'drugs_dosage_hint'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _frequencyController,
                        headerText: 'drugs_frequency'.tr(),
                        hintText: 'rx_freq_twice_daily'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration & Instructions
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _durationController,
                        headerText: 'drugs_duration'.tr(),
                        hintText: 'rx_duration_7_days'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _instructionsController,
                        headerText: 'rx_col_instructions'.tr(),
                        hintText: 'rx_freq_after_meals'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomPushButton(
                      height: 40,
                      width: 150,
                      backgroundColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isSaving,
                      onTap: _onSave,
                      child: Center(
                        child: Text(
                          'save'.tr(),
                          style: CustomAppFontStyle.bold13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

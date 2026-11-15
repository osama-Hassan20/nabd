import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_toast.dart';
import '../../../data/models/enums/addendum_change_type_enum.dart';
import '../../../data/models/prescription_item_model.dart';
import '../../../data/models/visit_model.dart';
import '../../../domain/use_cases/add_visit_addendum_use_case.dart';
import '../../helpers/effective_prescription_calculator.dart';
import '../../manager/visits_cubit.dart';

class AddVisitAddendumDialog extends StatefulWidget {
  final VisitsCubit cubit;
  final VisitModel visit;

  const AddVisitAddendumDialog({
    super.key,
    required this.cubit,
    required this.visit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required VisitsCubit cubit,
    required VisitModel visit,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddVisitAddendumDialog(
        cubit: cubit,
        visit: visit,
      ),
    );
  }

  @override
  State<AddVisitAddendumDialog> createState() => _AddVisitAddendumDialogState();
}

class _AddVisitAddendumDialogState extends State<AddVisitAddendumDialog> {
  final _reasonController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  // Medication fields if adding/editing
  final _tradeNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  AddendumChangeTypeEnum _selectedType = AddendumChangeTypeEnum.dose;
  String? _selectedItemId;
  String? _reasonError;
  String? _diagnosisError;
  bool _isSaving = false;

  late final List<PrescriptionItemModel> _effectiveItems;
  late final String? _currentDiagnosis;

  @override
  void initState() {
    super.initState();
    _effectiveItems =
        EffectivePrescriptionCalculator.calculateEffectivePrescription(
      visit: widget.visit,
    );
    _currentDiagnosis =
        EffectivePrescriptionCalculator.calculateEffectiveDiagnosis(
      visit: widget.visit,
    );

    if (_effectiveItems.isNotEmpty) {
      _selectedItemId = _effectiveItems.first.id;
      _populateItemFields(_effectiveItems.first);
    }
  }

  void _populateItemFields(PrescriptionItemModel item) {
    _tradeNameController.text = item.tradeName ?? '';
    _dosageController.text = item.dosage ?? '';
    _frequencyController.text = item.frequency ?? '';
    _durationController.text = item.duration ?? '';
    _instructionsController.text = item.instructions ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _tradeNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = 'addendum_reason_required'.tr());
      return;
    }

    if (_selectedType == AddendumChangeTypeEnum.diagnosis) {
      final newDiag = _diagnosisController.text.trim();
      if (newDiag.isEmpty || newDiag == (_currentDiagnosis ?? '').trim()) {
        setState(() => _diagnosisError = 'diagnosis_addendum_must_differ'.tr());
        return;
      }
    }

    setState(() {
      _reasonError = null;
      _diagnosisError = null;
      _isSaving = true;
    });

    PrescriptionItemModel? oldItem;
    PrescriptionItemModel? newItem;

    if (_selectedType != AddendumChangeTypeEnum.diagnosis &&
        _selectedType != AddendumChangeTypeEnum.add) {
      oldItem = _effectiveItems
          .where((i) => i.id == _selectedItemId)
          .firstOrNull;
    }

    if (_selectedType == AddendumChangeTypeEnum.add) {
      newItem = PrescriptionItemModel(
        id: 'RXI-ADD-${DateTime.now().millisecondsSinceEpoch}',
        tradeName: _tradeNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequencyController.text.trim(),
        duration: _durationController.text.trim(),
        instructions: _instructionsController.text.trim(),
      );
    } else if (_selectedType != AddendumChangeTypeEnum.discontinue &&
        _selectedType != AddendumChangeTypeEnum.diagnosis) {
      newItem = oldItem?.copyWith(
        dosage: _dosageController.text.trim(),
        frequency: _frequencyController.text.trim(),
        duration: _durationController.text.trim(),
        instructions: _instructionsController.text.trim(),
      );
    }

    final params = AddVisitAddendumParams(
      visitId: widget.visit.id!,
      reason: reason,
      changeType: _selectedType,
      affectedItemId: _selectedItemId,
      oldItemSnapshot: oldItem,
      newItemSnapshot: newItem,
      diagnosisBefore: _selectedType == AddendumChangeTypeEnum.diagnosis
          ? _currentDiagnosis
          : null,
      diagnosisAfter: _selectedType == AddendumChangeTypeEnum.diagnosis
          ? _diagnosisController.text.trim()
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final success = await widget.cubit.addAddendum(params);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
        CustomToast(
          context: context,
          header: 'visits_draft_saved'.tr(),
        ).showTopToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.post_add_rounded,
                        color: Color(0xFF16A34A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'addendum_add_btn'.tr(),
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            'addendum_title'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Change Type Selector
                Text(
                  'addendum_change_type'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('addendum_action_modify'.tr()),
                      selected: _selectedType == AddendumChangeTypeEnum.dose,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = AddendumChangeTypeEnum.dose);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('addendum_action_add'.tr()),
                      selected: _selectedType == AddendumChangeTypeEnum.add,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = AddendumChangeTypeEnum.add);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('addendum_action_remove'.tr()),
                      selected: _selectedType == AddendumChangeTypeEnum.discontinue,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = AddendumChangeTypeEnum.discontinue);
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('visits_diagnosis'.tr()),
                      selected: _selectedType == AddendumChangeTypeEnum.diagnosis,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = AddendumChangeTypeEnum.diagnosis);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason Field (Mandatory)
                CustomTextFormField(
                  controller: _reasonController,
                  headerText: 'addendum_reason_label'.tr(),
                  hintText: 'addendum_reason_hint'.tr(),
                  maxLine: 2,
                  validator: (_) => _reasonError,
                  onChanged: (_) {
                    if (_reasonError != null) {
                      setState(() => _reasonError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Diagnosis Fields if Diagnosis Change Type
                if (_selectedType == AddendumChangeTypeEnum.diagnosis) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'addendum_before_snapshot'.tr(),
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentDiagnosis ?? '',
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: _diagnosisController,
                    headerText: 'addendum_after_snapshot'.tr(),
                    hintText: 'visits_diagnosis_hint'.tr(),
                    maxLine: 2,
                    validator: (_) => _diagnosisError,
                    onChanged: (_) {
                      if (_diagnosisError != null) {
                        setState(() => _diagnosisError = null);
                      }
                    },
                  ),
                ] else ...[
                  // If modifying or discontinuing, pick the target medication
                  if (_selectedType != AddendumChangeTypeEnum.add) ...[
                    if (_effectiveItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'rx_no_items'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'rx_col_drug'.tr(),
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedItemId,
                        items: _effectiveItems.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.id,
                            child: Text('${item.tradeName ?? ''} (${item.dosage ?? ''})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedItemId = val;
                            final selected = _effectiveItems
                                .where((i) => i.id == val)
                                .firstOrNull;
                            if (selected != null) {
                              _populateItemFields(selected);
                            }
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (_selectedType == AddendumChangeTypeEnum.add ||
                      _selectedType == AddendumChangeTypeEnum.dose) ...[
                    const SizedBox(height: 12),
                    if (_selectedType == AddendumChangeTypeEnum.add)
                      CustomTextFormField(
                        controller: _tradeNameController,
                        headerText: 'drugs_trade_name'.tr(),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            controller: _dosageController,
                            headerText: 'rx_col_dosage'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _frequencyController,
                            headerText: 'rx_col_frequency'.tr(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            controller: _durationController,
                            headerText: 'rx_col_duration'.tr(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _instructionsController,
                            headerText: 'rx_col_instructions'.tr(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _notesController,
                  headerText: 'visits_follow_up_notes'.tr(),
                  maxLine: 2,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
                      backgroundColor: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isSaving,
                      onTap: _onSubmit,
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../data/models/drug_model.dart';
import '../../../domain/helpers/drug_name_validator.dart';
import '../../manager/drugs_cubit.dart';

class AddDrugDialog extends StatefulWidget {
  final DrugsCubit cubit;
  final DrugModel? initialDrug;

  const AddDrugDialog({
    super.key,
    required this.cubit,
    this.initialDrug,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugsCubit cubit,
    DrugModel? initialDrug,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddDrugDialog(
        cubit: cubit,
        initialDrug: initialDrug,
      ),
    );
  }

  @override
  State<AddDrugDialog> createState() => _AddDrugDialogState();
}

class _AddDrugDialogState extends State<AddDrugDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _scientificNameController;
  late final TextEditingController _concentrationController;
  late final TextEditingController _dosageController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _durationController;
  late final TextEditingController _manufacturerController;

  String? _selectedCategoryId;
  String? _nameError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDrug;
    _nameController = TextEditingController(text: d?.name ?? '');
    _scientificNameController =
        TextEditingController(text: d?.scientificName ?? '');
    _concentrationController =
        TextEditingController(text: d?.concentration ?? '');
    _dosageController = TextEditingController(text: d?.defaultDosage ?? '');
    _frequencyController =
        TextEditingController(text: d?.defaultFrequency ?? '');
    _durationController = TextEditingController(text: d?.defaultDuration ?? '');
    _manufacturerController =
        TextEditingController(text: d?.manufacturer ?? '');
    _selectedCategoryId = d?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _concentrationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final validationKey = DrugNameValidator.validate(name);
    if (validationKey != null) {
      setState(() => _nameError = validationKey);
      return;
    }

    setState(() {
      _nameError = null;
      _isSubmitting = true;
    });

    final isEditing = widget.initialDrug != null;
    final drugToSave = (widget.initialDrug ?? const DrugModel()).copyWith(
      name: name,
      scientificName: _scientificNameController.text.trim().isEmpty
          ? null
          : _scientificNameController.text.trim(),
      concentration: _concentrationController.text.trim().isEmpty
          ? null
          : _concentrationController.text.trim(),
      defaultDosage: _dosageController.text.trim().isEmpty
          ? null
          : _dosageController.text.trim(),
      defaultFrequency: _frequencyController.text.trim().isEmpty
          ? null
          : _frequencyController.text.trim(),
      defaultDuration: _durationController.text.trim().isEmpty
          ? null
          : _durationController.text.trim(),
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      categoryId: _selectedCategoryId,
    );

    final success = isEditing
        ? await widget.cubit.updateDrug(drugToSave)
        : await widget.cubit.addDrug(drugToSave);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialDrug != null;
    final categories = widget.cubit.state.categories;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing
                        ? 'drugs_edit_drug'.tr()
                        : 'drugs_add_drug'.tr(),
                    style: CustomAppFontStyle.bold18.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trade Name (required)
              CustomTextFormField(
                controller: _nameController,
                headerText: '${'drugs_trade_name'.tr()} *',
                hintText: 'drugs_trade_name_hint'.tr(),
                validator: (_) => _nameError?.tr(),
              ),
              const SizedBox(height: 12),

              // Scientific Name
              CustomTextFormField(
                controller: _scientificNameController,
                headerText: 'drugs_scientific_name'.tr(),
                hintText: 'drugs_scientific_name_hint'.tr(),
              ),
              const SizedBox(height: 12),

              // Category dropdown
              if (categories.isNotEmpty) ...[
                Text(
                  'drugs_category'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('drugs_filter_all'.tr()),
                    ),
                    ...categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.nameAr ?? c.nameEn ?? c.id ?? ''),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Concentration & Dosage row
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _concentrationController,
                      headerText: 'drugs_concentration'.tr(),
                      hintText: 'drugs_concentration_hint'.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextFormField(
                      controller: _dosageController,
                      headerText: 'drugs_dosage'.tr(),
                      hintText: 'drugs_dosage_hint'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Frequency & Duration row
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _frequencyController,
                      headerText: 'drugs_frequency'.tr(),
                      hintText: 'rx_freq_twice_daily'.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextFormField(
                      controller: _durationController,
                      headerText: 'drugs_duration'.tr(),
                      hintText: 'rx_duration_7_days'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Manufacturer
              CustomTextFormField(
                controller: _manufacturerController,
                headerText: 'drugs_manufacturer'.tr(),
                hintText: 'drugs_manufacturer_hint'.tr(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    backgroundColor: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    isLoading: _isSubmitting,
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
    );
  }
}

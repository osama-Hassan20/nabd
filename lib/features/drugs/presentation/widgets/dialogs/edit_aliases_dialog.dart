import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../patients/data/models/medical_catalog_item_model.dart';
import '../../manager/drugs_cubit.dart';

class EditAliasesDialog extends StatefulWidget {
  final DrugsCubit cubit;
  final MedicalCatalogItemModel item;

  const EditAliasesDialog({
    super.key,
    required this.cubit,
    required this.item,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugsCubit cubit,
    required MedicalCatalogItemModel item,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditAliasesDialog(
        cubit: cubit,
        item: item,
      ),
    );
  }

  @override
  State<EditAliasesDialog> createState() => _EditAliasesDialogState();
}

class _EditAliasesDialogState extends State<EditAliasesDialog> {
  final TextEditingController _inputController = TextEditingController();
  late List<String> _aliases;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.cubit.state.allergyAliasesMap[widget.item.id] ??
        widget.item.aliases ??
        [];
    _aliases = List<String>.from(existing);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addAlias() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty && !_aliases.contains(text)) {
      setState(() {
        _aliases.add(text);
        _inputController.clear();
      });
    }
  }

  void _removeAlias(String alias) {
    setState(() {
      _aliases.remove(alias);
    });
  }

  Future<void> _onSave() async {
    setState(() => _isSubmitting = true);

    final success = await widget.cubit.updateAliases(
      catalogItemId: widget.item.id!,
      aliases: _aliases,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'drugs_aliases_title'.tr(),
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.name ?? '',
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add alias row
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _inputController,
                      hintText: 'drugs_aliases_hint'.tr(),
                      onFieldSubmitted: (_) => _addAlias(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomPushButton(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: _addAlias,
                    child: const Icon(Icons.add, color: AppColors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chips area
              Container(
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _aliases.isEmpty
                    ? Center(
                        child: Text(
                          'drugs_no_aliases_yet'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _aliases.map((alias) {
                            return Chip(
                              label: Text(
                                alias,
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                              backgroundColor: const Color(0xFFEFF6FF),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              deleteIconColor: const Color(0xFF1D4ED8),
                              onDeleted: () => _removeAlias(alias),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Actions
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

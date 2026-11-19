import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import '../../data/models/enums/medical_catalog_kind_enum.dart';
import '../../data/models/medical_catalog_entry_model.dart';
import '../manager/medical_catalogs_cubit.dart';

class AddEditMedicalCatalogDialog extends StatefulWidget {
  final MedicalCatalogsCubit cubit;
  final MedicalCatalogKindEnum kind;
  final MedicalCatalogEntryModel? entry;

  const AddEditMedicalCatalogDialog({
    super.key,
    required this.cubit,
    required this.kind,
    this.entry,
  });

  static Future<bool?> show({
    required BuildContext context,
    required MedicalCatalogsCubit cubit,
    required MedicalCatalogKindEnum kind,
    MedicalCatalogEntryModel? entry,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditMedicalCatalogDialog(
        cubit: cubit,
        kind: kind,
        entry: entry,
      ),
    );
  }

  @override
  State<AddEditMedicalCatalogDialog> createState() =>
      _AddEditMedicalCatalogDialogState();
}

class _AddEditMedicalCatalogDialogState
    extends State<AddEditMedicalCatalogDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  bool get isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry?.name ?? '');
    _codeController = TextEditingController(text: widget.entry?.code ?? '');
    _categoryController = TextEditingController(
      text: widget.entry?.category ?? widget.kind.defaultCategories.first,
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    bool success;
    if (isEditing) {
      final updated = widget.entry!.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        category: _categoryController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      success = await widget.cubit.updateEntry(updated);
    } else {
      success = await widget.cubit.addEntry(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        category: _categoryController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grayE2E8F0, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomAssetImage(
                      path: widget.kind.iconPath,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'تعديل بيانات ${widget.kind.title}'
                              : 'إضافة إلى ${widget.kind.title}',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.kind.subtitle,
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        size: 20, color: AppColors.gray71717A),
                  ),
                ],
              ),
            ),

            // ─── Form Body ───────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      CustomTextFormField(
                        controller: _nameController,
                        headerText: 'الاسم الطبي / الفحص *',
                        hintText: 'مثال: ${widget.kind.defaultCategories.first}',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'يرجى إدخال الاسم';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Code & Category Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Code
                          Expanded(
                            child: CustomTextFormField(
                              controller: _codeController,
                              headerText: 'الكود / الرمز',
                              hintText: 'مثال: ${widget.kind.codePrefix}-01',
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Category Selector
                          Expanded(
                            child: CustomStackSelector<String>(
                              controller: _categoryController,
                              header: 'التصنيف الطبي *',
                              list: widget.kind.defaultCategories,
                              itemAsString: (s) => s,
                              displayStringForController: (s) => s,
                              hintText: 'اختر التصنيف',
                              enableSearch: true,
                              changeValue: (s) => _categoryController.text = s,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notes / Description
                      CustomTextFormField(
                        controller: _notesController,
                        headerText: 'ملاحظات وتفاصيل إضافية',
                        hintText: 'وصف مختصر أو إرشادات تحضيرية...',
                        maxLine: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Footer Actions ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.grayF8FAFC,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.grayE2E8F0, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 42,
                    backgroundColor: AppColors.grayE2E8F0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 42,
                    backgroundColor: AppColors.primary,
                    isLoading: _isSubmitting,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    borderRadius: BorderRadius.circular(10),
                    onTap: _isSubmitting ? null : _submit,
                    child: Text(
                      isEditing ? 'حفظ التعديلات' : 'إضافة الآن',
                      style: CustomAppFontStyle.bold13.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

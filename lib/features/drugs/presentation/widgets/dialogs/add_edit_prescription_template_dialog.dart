import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import '../../../data/models/drug_model.dart';
import '../../../data/models/prescription_template_item_model.dart';
import '../../../data/models/prescription_template_model.dart';
import '../../manager/drugs_cubit.dart';

class AddEditPrescriptionTemplateDialog extends StatefulWidget {
  final DrugsCubit cubit;
  final PrescriptionTemplateModel? template;

  const AddEditPrescriptionTemplateDialog({
    super.key,
    required this.cubit,
    this.template,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DrugsCubit cubit,
    PrescriptionTemplateModel? template,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditPrescriptionTemplateDialog(
        cubit: cubit,
        template: template,
      ),
    );
  }

  @override
  State<AddEditPrescriptionTemplateDialog> createState() =>
      _AddEditPrescriptionTemplateDialogState();
}

class _AddEditPrescriptionTemplateDialogState
    extends State<AddEditPrescriptionTemplateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  // Selected drugs list for this template
  final List<PrescriptionTemplateItemModel> _items = [];

  // Temporary controllers for adding a drug item
  DrugModel? _selectedDrug;
  final TextEditingController _drugSelectController = TextEditingController();
  final TextEditingController _dosageController =
      TextEditingController(text: 'قرص واحد');
  final TextEditingController _frequencyController =
      TextEditingController(text: '3 مرات يومياً');
  final TextEditingController _durationController =
      TextEditingController(text: '5 أيام');
  final TextEditingController _instructionsController = TextEditingController();

  bool _isSubmitting = false;

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.template?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.template?.description ?? '');

    if (widget.template?.items != null) {
      _items.addAll(widget.template!.items!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _drugSelectController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _addDrugItem() {
    if (_selectedDrug == null && _drugSelectController.text.trim().isEmpty) {
      return;
    }

    final drugName = _selectedDrug?.name ?? _drugSelectController.text.trim();
    final newItem = PrescriptionTemplateItemModel(
      drugId: _selectedDrug?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch}',
      drugName: drugName,
      scientificName: _selectedDrug?.scientificName,
      concentration: _selectedDrug?.concentration,
      dosage: _dosageController.text.trim().isNotEmpty
          ? _dosageController.text.trim()
          : 'قرص واحد',
      frequency: _frequencyController.text.trim().isNotEmpty
          ? _frequencyController.text.trim()
          : '3 مرات يومياً',
      duration: _durationController.text.trim().isNotEmpty
          ? _durationController.text.trim()
          : '5 أيام',
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      orderIndex: _items.length,
    );

    setState(() {
      _items.add(newItem);
      _selectedDrug = null;
      _drugSelectController.clear();
      _instructionsController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة دواء واحد على الأقل للوصفة الجاهزة')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final doctorId =
        widget.cubit.userProvider.currentUser?.linkedDoctorId ?? 'DOC-01';

    final template = PrescriptionTemplateModel(
      id: widget.template?.id ??
          'TPL-${DateTime.now().millisecondsSinceEpoch % 10000}',
      doctorId: doctorId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      items: _items,
      isActive: true,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await widget.cubit.saveTemplate(template);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDrugs = widget.cubit.state.drugs;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 680,
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
                    child: const Icon(
                      Icons.bookmark_add_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'تعديل الوصفة الطبية الجاهزة'
                              : 'إضافة وصفة طبية جاهزة جديدة',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'احفظ بروتوكولاً علاجياً جاهزاً لاستخدامه بنقرة واحدة أثناء الكشف',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
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
                      // Template Name
                      CustomTextFormField(
                        controller: _nameController,
                        headerText: 'اسم الوصفة الجاهزة *',
                        hintText: 'مثال: بروتوكول مغص معوي وتقلصات، علاج نزلة برد...',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'يرجى إدخال اسم الوصفة الجاهزة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description
                      CustomTextFormField(
                        controller: _descriptionController,
                        headerText: 'وصف أو تشخيص الحالة (اختياري)',
                        hintText: 'مثال: للحالات التي تعاني من آلام البطن والانتفاخ الحاد',
                        maxLine: 2,
                      ),
                      const SizedBox(height: 20),

                      // ─── Drugs In This Template Section ───────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medication_liquid_outlined,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'الأدوية المشمولة في الوصفة (${_items.length})',
                                style: CustomAppFontStyle.bold14.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Drug items list
                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grayF8FAFC,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.grayE2E8F0),
                          ),
                          child: Center(
                            child: Text(
                              'لم يتم إضافة أدوية بعد. اختر دواءً من الأسفل وأضفه للوصفة.',
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.grayF8FAFC,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: AppColors.grayE2E8F0),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      '${index + 1}',
                                      style:
                                          CustomAppFontStyle.bold11.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.drugName ?? '',
                                          style: CustomAppFontStyle.bold13
                                              .copyWith(
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                        Text(
                                          '${item.dosage ?? ''} • ${item.frequency ?? ''} • ${item.duration ?? ''}'
                                          '${item.instructions != null ? ' (${item.instructions})' : ''}',
                                          style: CustomAppFontStyle.regular11
                                              .copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),

                      // ─── Add Drug Sub-Form ────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إضافة دواء إلى الوصفة:',
                              style: CustomAppFontStyle.semiBold13.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Drug selector
                            CustomStackSelector<DrugModel>(
                              controller: _drugSelectController,
                              header: 'اختر الدواء من الكتالوج',
                              list: availableDrugs,
                              itemAsString: (d) =>
                                  '${d.name ?? ''} ${d.concentration != null ? "(${d.concentration})" : ""}',
                              displayStringForController: (d) => d.name ?? '',
                              hintText: 'ابحث باسم الدواء...',
                              enableSearch: true,
                              changeValue: (d) {
                                setState(() {
                                  _selectedDrug = d;
                                  if (d.defaultDosage != null) {
                                    _dosageController.text = d.defaultDosage!;
                                  }
                                  if (d.defaultFrequency != null) {
                                    _frequencyController.text =
                                        d.defaultFrequency!;
                                  }
                                  if (d.defaultDuration != null) {
                                    _durationController.text =
                                        d.defaultDuration!;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),

                            // Dosage, Frequency, Duration Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: _dosageController,
                                    headerText: 'الجرعة',
                                    hintText: 'قرص واحد',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: _frequencyController,
                                    headerText: 'التكرار',
                                    hintText: '3 مرات يومياً',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: _durationController,
                                    headerText: 'المدة',
                                    hintText: '5 أيام',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Instructions
                            CustomTextFormField(
                              controller: _instructionsController,
                              headerText: 'تعليمات الاستخدام (اختياري)',
                              hintText: 'مثال: قبل الأكل، مع كمية وفيرة من الماء...',
                            ),
                            const SizedBox(height: 12),

                            // Add drug button
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: CustomPushButton(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                backgroundColor: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                onTap: _addDrugItem,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'إدراج الدواء في الوصفة',
                                      style:
                                          CustomAppFontStyle.bold12.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      isEditing ? 'حفظ التعديلات' : 'حفظ الوصفة الجاهزة',
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

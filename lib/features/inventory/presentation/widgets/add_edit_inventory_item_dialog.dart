import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class AddEditInventoryItemDialog extends StatefulWidget {
  final InventoryCubit cubit;
  final InventoryItemModel? item;

  const AddEditInventoryItemDialog({
    super.key,
    required this.cubit,
    this.item,
  });

  static Future<void> show(
    BuildContext context, {
    required InventoryCubit cubit,
    InventoryItemModel? item,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddEditInventoryItemDialog(
        cubit: cubit,
        item: item,
      ),
    );
  }

  @override
  State<AddEditInventoryItemDialog> createState() =>
      _AddEditInventoryItemDialogState();
}

class _AddEditInventoryItemDialogState
    extends State<AddEditInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _categorySelectorController;
  late final TextEditingController _unitController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minAlertController;
  late final TextEditingController _costController;
  late final TextEditingController _locationController;
  late final TextEditingController _descController;

  static const List<String> _categories = [
    'طب الأسنان',
    'الجلدية والليزر والتجميل',
    'الجراحة والعمليات الصغرى',
    'مستهلكات عامة ومطهرات',
  ];

  String _chosenCategory = 'طب الأسنان';

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _chosenCategory = item?.category ?? 'طب الأسنان';

    _nameController = TextEditingController(text: item?.name ?? '');
    _codeController = TextEditingController(text: item?.code ?? '');
    _categorySelectorController =
        TextEditingController(text: _chosenCategory);
    _unitController =
        TextEditingController(text: item?.unit ?? 'علبة');
    _currentStockController = TextEditingController(
      text: item != null ? item.currentStock.toString() : '10',
    );
    _minAlertController = TextEditingController(
      text: item != null ? item.minStockAlert.toString() : '5',
    );
    _costController = TextEditingController(
      text: item != null ? item.unitCost.toString() : '0',
    );
    _locationController =
        TextEditingController(text: item?.shelfLocation ?? '');
    _descController =
        TextEditingController(text: item?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categorySelectorController.dispose();
    _unitController.dispose();
    _currentStockController.dispose();
    _minAlertController.dispose();
    _costController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final unit = _unitController.text.trim();
    final currentStock = int.tryParse(_currentStockController.text.trim()) ?? 0;
    final minAlert = int.tryParse(_minAlertController.text.trim()) ?? 5;
    final cost = num.tryParse(_costController.text.trim()) ?? 0;
    final location = _locationController.text.trim();
    final desc = _descController.text.trim();

    final isEdit = widget.item != null;
    final id = isEdit ? widget.item!.id : 'INV-${DateTime.now().millisecondsSinceEpoch}';

    final model = InventoryItemModel(
      id: id,
      name: name,
      code: code.isNotEmpty ? code : 'MED-${DateTime.now().millisecondsSinceEpoch % 10000}',
      category: _chosenCategory,
      unit: unit.isNotEmpty ? unit : 'قطعة',
      currentStock: currentStock,
      minStockAlert: minAlert,
      unitCost: cost,
      shelfLocation: location,
      description: desc,
    );

    final success = isEdit
        ? await widget.cubit.updateItem(model)
        : await widget.cubit.addItem(model);

    if (mounted) {
      Navigator.of(context).pop();
      if (success) {
        CustomToast(
          context: context,
          header: isEdit
              ? 'تم تعديل بيانات الصنف بنجاح'
              : 'تمت إضافة الصنف إلى المخزون بنجاح',
        ).showTopToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grayE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'تعديل بيانات الصنف بالمخزون' : 'إضافة صنف / مستلزم طبي جديد',
                        style: CustomAppFontStyle.semiBold16.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: AppColors.gray71717A),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        CustomTextFormField(
                          controller: _nameController,
                          isRequired: true,
                          headerText: 'اسم الصنف / المستلزم الطبي',
                          hintText: 'مثال: كاربولات بنج موضعي 2% / أسطوانة كرايو ليزر',
                          validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 14),

                        // Code & Category
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextFormField(
                                controller: _codeController,
                                headerText: 'كود الصنف / SKU',
                                hintText: 'مثال: DEN-ANES-01',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: CustomStackSelector<String>(
                                controller: _categorySelectorController,
                                header: 'التخصص / الفئة الطبية',
                                hintText: 'اختر التخصص',
                                list: _categories,
                                itemAsString: (c) => c,
                                changeValue: (c) {
                                  _chosenCategory = c;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Unit & Unit Cost
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextFormField(
                                controller: _unitController,
                                isRequired: true,
                                headerText: 'وحدة الصرف / الاستهلاك',
                                hintText: 'مثال: أمبولة، علبة، شفرة، أسطوانة، قطعة',
                                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: CustomTextFormField(
                                controller: _costController,
                                headerText: 'سعر التكلفة التقديرية (ج.م)',
                                hintText: '0',
                                textInputType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Current Stock & Min Alert Threshold
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextFormField(
                                controller: _currentStockController,
                                isRequired: true,
                                headerText: 'الرصيد الحالي المتوفر بالعيادة',
                                hintText: 'الكمية الموجودة حالياً',
                                textInputType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: CustomTextFormField(
                                controller: _minAlertController,
                                isRequired: true,
                                headerText: 'حد التنبيه (نقطة إعادة الطلب)',
                                hintText: 'يتم إشعار العيادة فور وصول الرصيد له',
                                textInputType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Shelf Location
                        CustomTextFormField(
                          controller: _locationController,
                          headerText: 'موقع التخزين والرف في العيادة',
                          hintText: 'مثال: دولاب عيادة 1 رف 2 / ثلاجة الأدوية / غرفة الليزر',
                        ),
                        const SizedBox(height: 14),

                        // Notes/Desc
                        CustomTextFormField(
                          controller: _descController,
                          headerText: 'ملاحظات وتفاصيل إضافية',
                          hintText: 'ملاحظات الاستخدام أو المورد...',
                          maxLine: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.grayE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomPushButton(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: AppColors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'إلغاء',
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CustomPushButton(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        backgroundColor: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        onTap: _handleSubmit,
                        child: Text(
                          isEdit ? 'حفظ التعديلات' : 'إضافة الصنف',
                          style: CustomAppFontStyle.semiBold14.copyWith(
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class RecordConsumptionDialog extends StatefulWidget {
  final InventoryCubit cubit;
  final InventoryItemModel item;

  const RecordConsumptionDialog({
    super.key,
    required this.cubit,
    required this.item,
  });

  static Future<void> show(
    BuildContext context, {
    required InventoryCubit cubit,
    required InventoryItemModel item,
  }) {
    return showDialog(
      context: context,
      builder: (_) => RecordConsumptionDialog(
        cubit: cubit,
        item: item,
      ),
    );
  }

  @override
  State<RecordConsumptionDialog> createState() =>
      _RecordConsumptionDialogState();
}

class _RecordConsumptionDialogState extends State<RecordConsumptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  late final TextEditingController _userController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
    _userController = TextEditingController(text: 'د. طارق المنشاوي');
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _userController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    final user = _userController.text.trim();
    final reason = _reasonController.text.trim();

    final ok = await widget.cubit.recordConsumption(
      itemId: widget.item.id,
      quantity: qty,
      performedBy: user.isNotEmpty ? user : 'طبيب العيادة',
      notes: reason.isNotEmpty ? reason : 'سحب مستلزمات طبية',
    );

    if (mounted) {
      Navigator.of(context).pop();
      if (ok) {
        CustomToast(
          context: context,
          header: 'تم تسجيل سحب $qty ${widget.item.unit} وتحديث الرصيد',
        ).showTopToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سحب / استهلاك مستلزمات طبية',
                            style: CustomAppFontStyle.semiBold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            widget.item.name,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20, color: AppColors.gray71717A),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Current stock indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الرصيد الحالي المتوفر:',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                      Text(
                        '${widget.item.currentStock} ${widget.item.unit}',
                        style: CustomAppFontStyle.bold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity
                CustomTextFormField(
                  controller: _qtyController,
                  isRequired: true,
                  headerText: 'الكمية المراد سحبها (${widget.item.unit})',
                  hintText: '1',
                  textInputType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    final val = int.tryParse(v) ?? 0;
                    if (val <= 0) return 'يجب إدخال كمية أكبر من صفر';
                    if (val > widget.item.currentStock) {
                      return 'الكمية المطلوبة تتجاوز الرصيد المتوفر (${widget.item.currentStock})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Performed By
                CustomTextFormField(
                  controller: _userController,
                  isRequired: true,
                  headerText: 'اسم الطبيب / المساعد القائم بالسحب',
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 14),

                // Reason / Notes
                CustomTextFormField(
                  controller: _reasonController,
                  headerText: 'سبب السحب أو الإجراء الطبي المنفذ',
                  hintText: 'مثال: لحالة خلع ضرس عقل / جلسة ليزر / كوي زوائد...',
                  maxLine: 2,
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPushButton(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: AppColors.surfaceLevel1,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: CustomAppFontStyle.medium13),
                    ),
                    const SizedBox(width: 10),
                    CustomPushButton(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      backgroundColor: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(8),
                      onTap: _handleSubmit,
                      child: Text(
                        'تأكيد السحب',
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: AppColors.white,
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

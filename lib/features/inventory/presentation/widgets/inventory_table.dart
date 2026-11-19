import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';

import '../../../../core/layout_adaptive/widgets/cutom_table.dart';

class InventoryTable extends StatelessWidget {
  final List<InventoryItemModel> items;
  final InventoryCubit cubit;
  final void Function(InventoryItemModel item) onEdit;
  final void Function(InventoryItemModel item) onDelete;
  final void Function(InventoryItemModel item) onConsume;
  final void Function(InventoryItemModel item) onRestock;

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(50), // #
    1: FixedColumnWidth(260), // Name & SKU
    2: FixedColumnWidth(140), // Category
    3: FixedColumnWidth(180), // Stock & status
    4: FixedColumnWidth(120), // Min alert
    5: FixedColumnWidth(110), // Cost
    6: FixedColumnWidth(180), // Shelf Location
    7: FixedColumnWidth(160), // Actions
  };

  const InventoryTable({
    super.key,
    required this.items,
    required this.cubit,
    required this.onEdit,
    required this.onDelete,
    required this.onConsume,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.grayMid,
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد أصناف مطابقة لخيارات البحث أو الفلتر',
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'جرب تغيير كلمة البحث أو إلغاء فلتر النواقص الحرجة',
                style: CustomAppFontStyle.regular12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomTable(
      minWidth: 1110,
      columnWidths: columnWidths,
      headers: const [
        '#',
        'اسم المستلزم الطبي والكود',
        'التخصص',
        'الرصيد المتوفر',
        'حد التنبيه',
        'التكلفة التقديرية',
        'موقع التخزين في العيادة',
        'الإجراءات والعمليات',
      ],
      rows: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;

        return [
          // 1. #
          Text(
            '$index',
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.gray71717A,
            ),
          ),

          // 2. Name & SKU
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.darkText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'كود: ${item.code}',
                style: CustomAppFontStyle.regular11.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
            ],
          ),

          // 3. Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.category,
              style: CustomAppFontStyle.medium12.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),

          // 4. Current Stock & Alert Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.currentStock} ${item.unit}',
                style: CustomAppFontStyle.bold13.copyWith(
                  color: item.isOutOfStock
                      ? AppColors.error
                      : (item.isLowStock
                          ? Colors.orange.shade800
                          : AppColors.darkText),
                ),
              ),
              if (item.isOutOfStock) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'نفد تماماً',
                    style: CustomAppFontStyle.bold11.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ] else if (item.isLowStock) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    'أوشك على النفاد',
                    style: CustomAppFontStyle.bold11.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 5. Min Stock Alert
          Text(
            '${item.minStockAlert} ${item.unit}',
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.gray71717A,
            ),
          ),

          // 6. Unit Cost
          Text(
            '${item.unitCost} ج.م',
            style: CustomAppFontStyle.medium13.copyWith(
              color: AppColors.darkText,
            ),
          ),

          // 7. Shelf Location
          Text(
            item.shelfLocation.isNotEmpty ? item.shelfLocation : 'غير محدد',
            style: CustomAppFontStyle.regular12.copyWith(
              color: AppColors.gray71717A,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // 8. Actions (سحب استهلاك، توريد، تعديل، حذف)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Consume button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.orange),
                tooltip: 'سحب / استهلاك للعيادة',
                onPressed: item.currentStock > 0 ? () => onConsume(item) : null,
              ),
              // Restock button
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.teal),
                tooltip: 'توريد / إضافة رصيد',
                onPressed: () => onRestock(item),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                tooltip: 'تعديل',
                onPressed: () => onEdit(item),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                tooltip: 'حذف',
                onPressed: () => onDelete(item),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}

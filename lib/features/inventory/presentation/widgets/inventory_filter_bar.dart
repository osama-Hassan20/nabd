import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class InventoryFilterBar extends StatelessWidget {
  final InventoryCubit cubit;
  final InventoryState state;
  final VoidCallback onAddItem;
  final VoidCallback onViewTransactions;

  const InventoryFilterBar({
    super.key,
    required this.cubit,
    required this.state,
    required this.onAddItem,
    required this.onViewTransactions,
  });

  static const List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'كافة التخصصات'},
    {'key': 'طب الأسنان', 'label': 'طب الأسنان'},
    {'key': 'الجلدية والليزر والتجميل', 'label': 'الجلدية والليزر'},
    {'key': 'الجراحة والعمليات الصغرى', 'label': 'الجراحة والعمليات'},
    {'key': 'مستهلكات عامة ومطهرات', 'label': 'مستهلكات عامة'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildCategoryChips(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildLowStockFilterChip()),
              const SizedBox(width: 8),
              _buildAddButton(compact: true),
            ],
          ),
        ],
      );
    }

    return CustomContainer(
      backGroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.grayE2E8F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Search + Low Stock Filter + Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildSearchField(),
                ),
              ),
              const SizedBox(width: 12),
              _buildLowStockFilterChip(),
              const Spacer(),
              // View transactions
              CustomPushButton(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: AppColors.surfaceLevel1,
                boxBorder: Border.all(color: AppColors.grayE2E8F0),
                borderRadius: BorderRadius.circular(8),
                onTap: onViewTransactions,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 16, color: AppColors.darkText),
                    const SizedBox(width: 6),
                    Text(
                      'سجل الحركات',
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Add Item Button
              _buildAddButton(compact: false),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom Row: Category Chips
          _buildCategoryChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return CustomTextFormField(
      hintText: 'بحث باسم المستلزم، الكود، أو موقع التخزين...',
      isDense: true,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      prefixWidget: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: CustomAssetImage(
          path: AppIcons.search,
          width: 18,
          height: 18,
          color: AppColors.grayMid,
        ),
      ),
      onChanged: (val) => cubit.searchItems(val ?? ''),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final isSelected = state.selectedCategory == c['key'];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => cubit.selectCategory(c['key']!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  c['label']!,
                  style: isSelected
                      ? CustomAppFontStyle.semiBold13.copyWith(color: AppColors.white)
                      : CustomAppFontStyle.regular13.copyWith(color: AppColors.gray),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLowStockFilterChip() {
    final active = state.onlyLowStock;
    return InkWell(
      onTap: () => cubit.toggleOnlyLowStock(!active),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.orange.shade50 : AppColors.surfaceLevel1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? Colors.orange.shade600 : AppColors.grayE2E8F0,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: active ? Colors.orange.shade800 : AppColors.gray71717A,
            ),
            const SizedBox(width: 6),
            Text(
              'النواقص والتنبيهات الحرجة فقط (${state.totalWarningCount})',
              style: CustomAppFontStyle.medium12.copyWith(
                color: active ? Colors.orange.shade900 : AppColors.darkText,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton({required bool compact}) {
    return CustomPushButton(
      height: 40,
      width: compact ? 40 : null,
      padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      onTap: onAddItem,
      child: Center(
        child: compact
            ? const Icon(Icons.add, color: AppColors.white, size: 20)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'إضافة صنف جديد',
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

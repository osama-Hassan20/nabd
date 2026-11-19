import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:eyadty/shared/widgets/custom_cards/summary_card.dart';

class InventorySummaryCards extends StatelessWidget {
  const InventorySummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      buildWhen: (prev, curr) =>
          prev.items != curr.items ||
          prev.stockStatusFilter != curr.stockStatusFilter,
      builder: (context, state) {
        final cubit = context.read<InventoryCubit>();

        final items = [
          // 1. Total (إجمالي الأصناف بالمخزون)
          SummaryCard(
            title: '${state.totalItemsCount}',
            subTitle: 'إجمالي الأصناف بالمخزون',
            iconPath: AppIcons.totalOrders,
            gradient: AppGradient.primaryGradient,
            activeBorderColor: AppColors.white,
            isSelected: state.stockStatusFilter == 'all',
            onTap: () => cubit.setStockStatusFilter('all'),
          ),

          // 2. Low Stock (أوشكت على النفاد)
          SummaryCard(
            title: '${state.lowStockCount}',
            subTitle: 'أوشكت على النفاد (تنبيه حرج)',
            iconPath: AppIcons.warning,
            gradient: const LinearGradient(
              colors: [Color(0xFFE89A24), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: state.stockStatusFilter == 'low_stock',
            onTap: () => cubit.toggleStockStatusFilter('low_stock'),
          ),

          // 3. Out of Stock (نفدت بالكامل من العيادة)
          SummaryCard(
            title: '${state.outOfStockCount}',
            subTitle: 'نفدت بالكامل من العيادة',
            iconPath: AppIcons.cancelledBooking,
            gradient: const LinearGradient(
              colors: [Color(0xFFE54848), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: state.stockStatusFilter == 'out_of_stock',
            onTap: () => cubit.toggleStockStatusFilter('out_of_stock'),
          ),

          // 4. In Stock / Inventory Value (القيمة التقديرية للمستلزمات)
          SummaryCard(
            title: '${state.totalInventoryValue} ج.م',
            subTitle: 'القيمة التقديرية للمستلزمات',
            iconPath: AppIcons.wallet,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E9A68), Color(0xFF15803D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: state.stockStatusFilter == 'in_stock',
            onTap: () => cubit.toggleStockStatusFilter('in_stock'),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 820) {
              return SizedBox(
                height: 98,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => SizedBox(
                    width: 220,
                    child: items[index],
                  ),
                ),
              );
            }

            return Row(
              children: items
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: SizedBox(
                          height: 98,
                          child: card,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

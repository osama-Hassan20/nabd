import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/data/models/inventory_item_model.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:eyadty/features/inventory/presentation/widgets/add_edit_inventory_item_dialog.dart';
import 'package:eyadty/features/inventory/presentation/widgets/inventory_filter_bar.dart';
import 'package:eyadty/features/inventory/presentation/widgets/inventory_summary_cards.dart';
import 'package:eyadty/features/inventory/presentation/widgets/inventory_table.dart';
import 'package:eyadty/features/inventory/presentation/widgets/inventory_transactions_dialog.dart';
import 'package:eyadty/features/inventory/presentation/widgets/record_consumption_dialog.dart';
import 'package:eyadty/features/inventory/presentation/widgets/record_restock_dialog.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InventoryCubit>()..fetchItems(),
      child: const _InventoryView(),
    );
  }
}

class _InventoryView extends StatelessWidget {
  const _InventoryView();

  void _showDeleteDialog(BuildContext context, InventoryCubit cubit, InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.themeColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeColors.borderSubtle),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'حذف الصنف من المخزون',
                    style: CustomAppFontStyle.semiBold16.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'هل أنت متأكد من رغبتك في حذف "${item.name}" من سجلات المستلزمات الطبية؟',
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomPushButton(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: context.themeColors.surfaceLevel1,
                        boxBorder: Border.all(color: context.themeColors.borderSubtle),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(dlgContext).pop(),
                        child: Text(
                          'إلغاء',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: context.themeColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CustomPushButton(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        backgroundColor: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          Navigator.of(dlgContext).pop();
                          final ok = await cubit.deleteItem(item.id);
                          if (ok && context.mounted) {
                            CustomToast(
                              context: context,
                              header: 'تم حذف الصنف من المخزون',
                            ).showTopToast();
                          }
                        },
                        child: Text(
                          'تأكيد الحذف',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InventoryCubit>();
    final colors = context.themeColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      body: BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
          final isLoading = state.status == RequestStatusEnum.loading;

          return RefreshIndicator(
            onRefresh: () => cubit.fetchItems(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المخزون والمستلزمات الطبية',
                              style: CustomAppFontStyle.bold20.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'إدارة مستهلكات الأسنان، أجهزة ومواد الليزر والجلدية، ونواقص العيادات وتنبيهات إعادة الطلب',
                              style: CustomAppFontStyle.regular13.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Summary Metric Cards ────────────────────────────────
                  const InventorySummaryCards(),
                  const SizedBox(height: 16),

                  // ─── Filter Bar ──────────────────────────────────────────
                  InventoryFilterBar(
                    cubit: cubit,
                    state: state,
                    onAddItem: () => AddEditInventoryItemDialog.show(
                      context,
                      cubit: cubit,
                    ),
                    onViewTransactions: () =>
                        InventoryTransactionsDialog.show(context, cubit: cubit),
                  ),
                  const SizedBox(height: 16),

                  // ─── Table ───────────────────────────────────────────────
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    InventoryTable(
                      items: state.filteredItems,
                      cubit: cubit,
                      onEdit: (item) => AddEditInventoryItemDialog.show(
                        context,
                        cubit: cubit,
                        item: item,
                      ),
                      onDelete: (item) =>
                          _showDeleteDialog(context, cubit, item),
                      onConsume: (item) => RecordConsumptionDialog.show(
                        context,
                        cubit: cubit,
                        item: item,
                      ),
                      onRestock: (item) => RecordRestockDialog.show(
                        context,
                        cubit: cubit,
                        item: item,
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

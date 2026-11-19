import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:eyadty/features/inventory/presentation/cubit/inventory_state.dart';

class InventoryTransactionsDialog extends StatelessWidget {
  final InventoryCubit cubit;

  const InventoryTransactionsDialog({super.key, required this.cubit});

  static Future<void> show(BuildContext context, {required InventoryCubit cubit}) {
    cubit.fetchTransactions();
    return showDialog(
      context: context,
      builder: (_) => InventoryTransactionsDialog(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      bloc: cubit,
      builder: (context, state) {
        final txns = state.transactions;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grayE2E8F0),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'سجل حركات المخزون (سحب وتوريد المستلزمات)',
                            style: CustomAppFontStyle.semiBold16.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: AppColors.gray71717A),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.grayE2E8F0),

                  Flexible(
                    child: txns.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Text(
                                'لا توجد حركات مسجلة حتى الآن',
                                style: CustomAppFontStyle.regular13.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: txns.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final t = txns[i];
                              final isConsume = t.isConsumption;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLevel1,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isConsume
                                        ? Colors.orange.shade200
                                        : Colors.teal.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isConsume
                                            ? Colors.orange.shade100
                                            : Colors.teal.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isConsume
                                            ? Icons.remove
                                            : Icons.add,
                                        size: 18,
                                        color: isConsume
                                            ? Colors.orange.shade900
                                            : Colors.teal.shade900,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.itemName,
                                            style: CustomAppFontStyle.semiBold13.copyWith(
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'بواسطة: ${t.performedBy} ${t.notes.isNotEmpty ? " • ${t.notes}" : ""}',
                                            style: CustomAppFontStyle.regular11.copyWith(
                                              color: AppColors.gray71717A,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isConsume ? "-" : "+"}${t.quantity}',
                                          style: CustomAppFontStyle.bold15.copyWith(
                                            color: isConsume
                                                ? Colors.orange.shade800
                                                : Colors.teal.shade800,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('yyyy/MM/dd HH:mm').format(t.date),
                                          style: CustomAppFontStyle.regular11.copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/cashier/data/models/cashier_shift_model.dart';
import 'package:eyadty/features/cashier/data/models/cashier_summary_metrics_model.dart';
import 'package:eyadty/features/cashier/domain/helpers/money.dart';

class CashierMetricsSection extends StatelessWidget {
  final CashierSummaryMetricsModel? summaryMetrics;
  final CashierShiftModel? activeShift;

  const CashierMetricsSection({
    super.key,
    this.summaryMetrics,
    this.activeShift,
  });

  @override
  Widget build(BuildContext context) {
    // If summaryMetrics is null, extract metrics from activeShift if present
    final openingBalance = activeShift?.openingBalancePiastres ?? 0;
    final cashCollected = summaryMetrics?.cashCollectedPiastres ??
        activeShift?.totalCashCollectedPiastres ??
        0;
    final cardCollected = summaryMetrics?.cardCollectedPiastres ??
        activeShift?.totalCardCollectedPiastres ??
        0;
    final transferCollected = summaryMetrics?.bankTransferPiastres ??
        activeShift?.totalBankTransferPiastres ??
        0;
    final totalExpenses = summaryMetrics?.totalExpensesPiastres ??
        activeShift?.totalExpensesPiastres ??
        0;
    final totalRefunds = summaryMetrics?.totalRefundsPiastres ??
        activeShift?.totalRefundsPiastres ??
        0;
    final expectedCash = summaryMetrics?.expectedCashPiastres ??
        activeShift?.expectedCashPiastres ??
        (openingBalance + cashCollected - totalExpenses - totalRefunds);

    final cards = [
      _MetricItem(
        title: 'cashier_expected_cash'.tr(),
        amount: Money(expectedCash).formatEgp(),
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.08),
      ),
      _MetricItem(
        title: 'cashier_cash_collected'.tr(),
        amount: Money(cashCollected).formatEgp(),
        icon: Icons.payments_rounded,
        accentColor: const Color(0xff007834),
        bgColor: const Color(0xff007834).withValues(alpha: 0.08),
      ),
      _MetricItem(
        title: 'cashier_card_collected'.tr(),
        amount: Money(cardCollected).formatEgp(),
        icon: Icons.credit_card_rounded,
        accentColor: const Color(0xff0284C7),
        bgColor: const Color(0xff0284C7).withValues(alpha: 0.08),
      ),
      _MetricItem(
        title: 'cashier_transfer_collected'.tr(),
        amount: Money(transferCollected).formatEgp(),
        icon: Icons.account_balance_rounded,
        accentColor: const Color(0xff6366F1),
        bgColor: const Color(0xff6366F1).withValues(alpha: 0.08),
      ),
      _MetricItem(
        title: 'cashier_total_expenses'.tr(),
        amount: Money(totalExpenses).formatEgp(),
        icon: Icons.shopping_bag_outlined,
        accentColor: const Color(0xffF59E0B),
        bgColor: const Color(0xffF59E0B).withValues(alpha: 0.08),
      ),
      _MetricItem(
        title: 'cashier_total_refunds'.tr(),
        amount: Money(totalRefunds).formatEgp(),
        icon: Icons.replay_rounded,
        accentColor: AppColors.red,
        bgColor: AppColors.red.withValues(alpha: 0.08),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 6
            : constraints.maxWidth > 750
                ? 3
                : 2;

        return GridView.builder(
          physics: const NeverScrollableScrollUri(),
          shrinkWrap: true,
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) {
            final c = cards[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.grayE2E8F0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.icon, color: c.accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.title,
                          style: CustomAppFontStyle.regular11.copyWith(
                            color: AppColors.gray71717A,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.amount,
                          style: CustomAppFontStyle.bold15.copyWith(
                            color: AppColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class NeverScrollableScrollUri extends ScrollPhysics {
  const NeverScrollableScrollUri({super.parent});

  @override
  NeverScrollableScrollUri applyTo(ScrollPhysics? ancestor) {
    return NeverScrollableScrollUri(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;
}

class _MetricItem {
  final String title;
  final String amount;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  const _MetricItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });
}

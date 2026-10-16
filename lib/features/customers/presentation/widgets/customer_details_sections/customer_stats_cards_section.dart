import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_cubit.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/responsive_helper/screen_width_breakpoints.dart';

class CustomerStatsCardsSection extends StatelessWidget {
  const CustomerStatsCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      buildWhen: (prev, curr) =>
          prev.customerTotalBookingsCount != curr.customerTotalBookingsCount ||
          prev.customerOneTimeBookingsCount !=
              curr.customerOneTimeBookingsCount ||
          prev.customerActiveRecurringCount !=
              curr.customerActiveRecurringCount ||
          prev.customerTotalSpentAmount != curr.customerTotalSpentAmount,
      builder: (context, state) {
        final cards = [
          _StatCardItem(
            title: 'total_bookings'.tr(),
            value: '${state.customerTotalBookingsCount}',
            icon: AppIcons.totalBooking,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'one_time_visits'.tr(),
            value: '${state.customerOneTimeBookingsCount}',
            icon: AppIcons.calendar,
            color: AppColors.cyan,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'active_recurring'.tr(),
            value: '${state.customerActiveRecurringCount}',
            icon: AppIcons.change,
            color: AppColors.success,
            bgColor: AppColors.secondaryLight,
          ),
          _StatCardItem(
            title: 'total_spent'.tr(),
            value:
                "${MonyHelper.formatMoney(state.customerTotalSpentAmount)} ${'qar_currency'.tr()}",
            icon: AppIcons.wallet,
            color: AppColors.secondary,
            bgColor: AppColors.secondaryLight,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final int crossAxisCount;
            if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth >= ScreenWidthBreakpoints.tablet) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final card = cards[index];
                return CustomContainer(
                  backGroundColor: AppColors.white,
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grayE2E8F0),
                  enableShadow: true,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: card.bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomAssetImage(
                            path: card.icon,
                            width: 22,
                            height: 22,
                            color: card.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomAppFontStyle.bold16.copyWith(
                                color: AppColors.darkText,
                              ),
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
      },
    );
  }
}

class _StatCardItem {
  final String title;
  final String value;
  final String icon;
  final Color color;
  final Color bgColor;

  const _StatCardItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

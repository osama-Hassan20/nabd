import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/responsive_helper/screen_width_breakpoints.dart';

class TechnicianStatsCardsSection extends StatelessWidget {
  const TechnicianStatsCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TechniciansCubit, TechniciansState>(
      buildWhen: (prev, curr) =>
          prev.selectedTechnician != curr.selectedTechnician ||
          prev.technicianBookings.length != curr.technicianBookings.length ||
          prev.technicianLeaves.length != curr.technicianLeaves.length,
      builder: (context, state) {
        final tech = state.selectedTechnician;
        final leavesCount = state.technicianLeaves.length;

        final cards = [
          _StatCardItem(
            title: 'today_tasks'.tr(),
            value: '${tech?.todayTasksCount ?? 0}',
            icon: AppIcons.calendar,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'upcoming_bookings'.tr(),
            value: '${tech?.upcomingBookingsCount ?? 0}',
            icon: AppIcons.calendar,
            color: AppColors.cyan,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'completed_bookings'.tr(),
            value: '${tech?.completedBookingsCount ?? 0}',
            icon: AppIcons.checkmarkCircle,
            color: AppColors.success,
            bgColor: AppColors.secondaryLight,
          ),
          _StatCardItem(
            title: 'leaves'.tr(),
            value: '$leavesCount',
            icon: AppIcons.cancelledBooking,
            color: AppColors.warning,
            bgColor: AppColors.yellowLight,
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
                final item = cards[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomAssetImage(
                          path: item.icon,
                          width: 20,
                          height: 20,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray7A828E,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomAppFontStyle.bold18.copyWith(
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

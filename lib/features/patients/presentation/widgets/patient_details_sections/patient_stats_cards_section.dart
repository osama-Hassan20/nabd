import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/responsive_helper/screen_width_breakpoints.dart';

class PatientStatsCardsSection extends StatelessWidget {
  const PatientStatsCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      buildWhen: (prev, curr) =>
          prev.patientTotalBookingsCount != curr.patientTotalBookingsCount ||
          prev.patientUpcomingBookingsCount !=
              curr.patientUpcomingBookingsCount ||
          prev.patientCompletedBookingsCount !=
              curr.patientCompletedBookingsCount ||
          prev.patientTotalSpentAmount != curr.patientTotalSpentAmount,
      builder: (context, state) {
        final cards = [
          _StatCardItem(
            title: 'total_bookings'.tr(),
            value: '${state.patientTotalBookingsCount}',
            icon: AppIcons.totalBooking,
            color: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'upcoming_bookings'.tr(),
            value: '${state.patientUpcomingBookingsCount}',
            icon: AppIcons.comingBooking,
            color: AppColors.cyan,
            bgColor: AppColors.primaryLight,
          ),
          _StatCardItem(
            title: 'completed'.tr(),
            value: '${state.patientCompletedBookingsCount}',
            icon: AppIcons.completedBooking,
            color: AppColors.success,
            bgColor: AppColors.secondaryLight,
          ),
          _StatCardItem(
            title: 'total_spent'.tr(),
            value:
                "${MonyHelper.formatMoney(state.patientTotalSpentAmount)} ${'currency'.tr()}",
            icon: AppIcons.wallet,
            color: AppColors.secondary,
            bgColor: AppColors.secondaryLight,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final int columns;
            if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
              columns = 4;
            } else if (constraints.maxWidth >=
                ScreenWidthBreakpoints.tablet) {
              columns = 2;
            } else {
              columns = 1;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 92,
              ),
              itemBuilder: (context, index) {
                final item = cards[index];
                return CustomContainer(
                  backGroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grayE2E8F0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomAssetImage(
                            path: item.icon,
                            width: 22,
                            height: 22,
                            color: item.color,
                          ),
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
                                color: AppColors.gray71717A,
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


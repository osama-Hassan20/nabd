import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';
import 'package:eyadty/shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import 'technicians_table.dart';

class AdaptiveTechniciansShimmer extends StatelessWidget {
  const AdaptiveTechniciansShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
          return CustomTableShimmer(
            headers: [
              '#',
              'name'.tr(),
              'phone'.tr(),
              'gender'.tr(),
              'status'.tr(),
              'today_tasks'.tr(),
              'upcoming_bookings'.tr(),
              'actions'.tr(),
            ],
            columnWidths: TechniciansTable.columnWidths,
          );
        }

        final int columns =
            constraints.maxWidth >= ScreenWidthBreakpoints.tablet ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 180,
          ),
          itemCount: 6,
          itemBuilder: (_, _) => const CustomShimmerContainer(
            borderRadius: 12,
            height: 180,
            width: double.infinity,
          ),
        );
      },
    );
  }
}

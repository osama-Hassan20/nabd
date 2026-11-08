import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import 'package:eyadty/shared/widgets/custom_shimmer_container.dart';

import 'patients_table.dart';

class AdaptivePatientsShimmer extends StatelessWidget {
  const AdaptivePatientsShimmer({super.key});

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
              'address'.tr(),
              'total_bookings'.tr(),
              'upcoming_bookings'.tr(),
              'total_spent'.tr(),
              'actions'.tr(),
            ],
            columnWidths: PatientsTable.columnWidths,
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
            mainAxisExtent: 190,
          ),
          itemCount: 6,
          itemBuilder: (_, _) => const CustomShimmerContainer(
            borderRadius: 12,
            height: 190,
            width: double.infinity,
          ),
        );
      },
    );
  }
}


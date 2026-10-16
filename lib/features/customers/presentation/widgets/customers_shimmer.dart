import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:purexo/shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import 'package:purexo/shared/widgets/custom_shimmer_container.dart';

import 'customers_table.dart';

class AdaptiveCustomersShimmer extends StatelessWidget {
  const AdaptiveCustomersShimmer({super.key});

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
              'actions'.tr(),
            ],
            columnWidths: CustomersTable.columnWidths,
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

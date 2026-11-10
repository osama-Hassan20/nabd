import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../shared/widgets/custom_shimmer_container.dart';
import '../../../../shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import 'consultation_queue_table.dart';

class VisitsShimmer extends StatelessWidget {
  const VisitsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= ScreenWidthBreakpoints.tablet;

        if (isDesktop) {
          return CustomTableShimmer(
            headers: [
              'visits_patient_queue_num'.tr(),
              'visits_patient_name'.tr(),
              'visits_assigned_doctor'.tr(),
              'visits_booking_time'.tr(),
              'visits_filter_status'.tr(),
              'visits_actions'.tr(),
            ],
            columnWidths: ConsultationQueueTable.columnWidths,
            rowCount: 5,
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CustomShimmerContainer(
                height: 140,
                width: double.infinity,
                borderRadius: 12,
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/responsive_helper/screen_width_breakpoints.dart';
import '../../data/models/consultation_queue_item_model.dart';
import 'consultation_queue_card.dart';
import 'consultation_queue_table.dart';

class AdaptiveVisitsView extends StatelessWidget {
  final List<ConsultationQueueItemModel> items;
  final PermissionEvaluator evaluator;
  final ValueChanged<ConsultationQueueItemModel>? onStartConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onContinueConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onRecordVitals;
  final ValueChanged<ConsultationQueueItemModel>? onViewConsultation;

  const AdaptiveVisitsView({
    super.key,
    required this.items,
    required this.evaluator,
    this.onStartConsultation,
    this.onContinueConsultation,
    this.onRecordVitals,
    this.onViewConsultation,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 48,
                color: AppColors.gray.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'visits_no_active_visits'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet =
            constraints.maxWidth >= ScreenWidthBreakpoints.tablet;

        if (isDesktopOrTablet) {
          return ConsultationQueueTable(
            items: items,
            evaluator: evaluator,
            onStartConsultation: onStartConsultation,
            onContinueConsultation: onContinueConsultation,
            onRecordVitals: onRecordVitals,
            onViewConsultation: onViewConsultation,
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ConsultationQueueCard(
              item: items[index],
              evaluator: evaluator,
              onStartConsultation: onStartConsultation,
              onContinueConsultation: onContinueConsultation,
              onRecordVitals: onRecordVitals,
              onViewConsultation: onViewConsultation,
            );
          },
        );
      },
    );
  }
}

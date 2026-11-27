import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../helpers/consultation_action_helper.dart';
import 'visit_status_badge.dart';

class ConsultationQueueTable extends StatelessWidget {
  final List<ConsultationQueueItemModel> items;
  final PermissionEvaluator evaluator;
  final bool isLoading;
  final ValueChanged<ConsultationQueueItemModel>? onStartConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onContinueConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onRecordVitals;
  final ValueChanged<ConsultationQueueItemModel>? onViewConsultation;

  const ConsultationQueueTable({
    super.key,
    required this.items,
    required this.evaluator,
    this.isLoading = false,
    this.onStartConsultation,
    this.onContinueConsultation,
    this.onRecordVitals,
    this.onViewConsultation,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(70), // Queue #
    1: FlexColumnWidth(2.4), // Patient Name & Phone
    2: FlexColumnWidth(2.0), // Assigned Doctor
    3: FixedColumnWidth(105), // Time
    4: FixedColumnWidth(165), // Visit Status
    5: FixedColumnWidth(260), // Actions
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
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
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'visits_no_active_visits'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'لإدخال العلامات الحيوية أو بدء الكشف، يرجى إنشاء حجز للمريض أولاً من قائمة الحجوزات.',
                style: CustomAppFontStyle.regular12.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomTable(
      minWidth: 920,
      columnWidths: columnWidths,
      headers: [
        'visits_patient_queue_num'.tr(),
        'visits_patient_name'.tr(),
        'visits_assigned_doctor'.tr(),
        'visits_booking_time'.tr(),
        'visits_filter_status'.tr(),
        'visits_actions'.tr(),
      ],
      rows: items.map((item) => _buildRow(context, item)).toList(),
    );
  }

  List<Widget> _buildRow(
    BuildContext context,
    ConsultationQueueItemModel item,
  ) {
    final booking = item.booking;
    final visit = item.visit;

    final colors = context.themeColors;

    // 0: Queue Number Badge
    final cell0 = Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '#${booking?.queueNumber ?? '—'}',
            style: CustomAppFontStyle.bold12.copyWith(
              color: colors.primary,
            ),
          ),
        ),
      ),
    );

    // 1: Patient Name & Phone (tapping opens vitals for nurse or primary consultation action)
    final VoidCallback? rowPrimaryTap = _resolveRowPrimaryTap(item);
    final cell1 = InkWell(
      onTap: isLoading ? null : rowPrimaryTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            booking?.patientName ?? '—',
            style: CustomAppFontStyle.bold14.copyWith(
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (booking?.patientPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              booking!.patientPhone!,
              style: CustomAppFontStyle.regular12.copyWith(
                color: colors.textSecondary,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ],
      ),
    );

    // 2: Doctor & Specialty
    final cell2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          booking?.doctorName ?? '—',
          style: CustomAppFontStyle.medium14.copyWith(
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (booking?.specialty != null) ...[
          const SizedBox(height: 2),
          Text(
            booking!.specialty!,
            style: CustomAppFontStyle.regular12.copyWith(
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    // 3: Time
    final appointmentTime = booking?.appointmentTime;
    final timeStr = appointmentTime != null
        ? DateFormat('hh:mm a', 'ar').format(appointmentTime)
        : '—';
    final cell3 = Center(
      child: Text(
        timeStr,
        style: CustomAppFontStyle.medium12.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );

    // 4: Status Badge
    final cell4 = Center(
      child: VisitStatusBadge(status: visit?.status),
    );

    // 5: Actions
    final cell5 = Center(
      child: _buildActionButtons(context, item),
    );

    return [cell0, cell1, cell2, cell3, cell4, cell5];
  }

  Widget _buildActionButtons(
    BuildContext context,
    ConsultationQueueItemModel item,
  ) {
    final booking = item.booking;
    final visit = item.visit;

    final canStart = ConsultationActionHelper.canStartConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    );

    final canContinue = ConsultationActionHelper.canContinueConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    );

    final canVitals = ConsultationActionHelper.canRecordVitals(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    );

    final canView = ConsultationActionHelper.canViewConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    );

    // Case 1: Finalized visit -> View button
    if (canView) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : () => onViewConsultation?.call(item),
        icon: const Icon(Icons.visibility_outlined, size: 14),
        label: Text('visits_action_view'.tr()),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: CustomAppFontStyle.medium12,
        ),
      );
    }

    // Case 2: Ongoing consultation -> Continue button (doctor only)
    if (canContinue) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : () => onContinueConsultation?.call(item),
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: Text('visits_continue_consultation'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8), // Blue 700
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: CustomAppFontStyle.bold12,
        ),
      );
    }

    // Case 3: Waiting -> Start/Complete consultation and/or Record/Update vitals
    final buttons = <Widget>[];

    if (canStart) {
      final isTriage = visit?.status == VisitStatusEnum.triage;
      final labelKey = ConsultationActionHelper.getConsultationButtonKey(
        booking: booking,
        visit: visit,
      );
      buttons.add(
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => onStartConsultation?.call(item),
          icon: Icon(
            isTriage ? Icons.check_circle_outline : Icons.play_arrow_rounded,
            size: 14,
          ),
          label: Text(labelKey.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isTriage ? const Color(0xFFB45309) : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.bold12,
          ),
        ),
      );
    }

    if (canVitals) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 6));
      }
      final isTriage = visit?.status == VisitStatusEnum.triage;
      buttons.add(
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => onRecordVitals?.call(item),
          icon: Icon(
            isTriage ? Icons.edit_outlined : Icons.monitor_heart_outlined,
            size: 14,
          ),
          label: Text('visits_record_vitals'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: isTriage
                ? const Color(0xFFB45309)
                : AppColors.primary,
            side: BorderSide(
              color: isTriage ? const Color(0xFFF59E0B) : AppColors.primary,
              width: 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.medium12,
          ),
        ),
      );
    }

    if (buttons.isNotEmpty) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: buttons,
      );
    }

    return const SizedBox.shrink();
  }

  VoidCallback? _resolveRowPrimaryTap(ConsultationQueueItemModel item) {
    final booking = item.booking;
    final visit = item.visit;
    if (ConsultationActionHelper.canContinueConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    )) {
      return onContinueConsultation != null ? () => onContinueConsultation!(item) : null;
    }
    if (ConsultationActionHelper.canStartConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    )) {
      return onStartConsultation != null ? () => onStartConsultation!(item) : null;
    }
    if (ConsultationActionHelper.canRecordVitals(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    )) {
      return onRecordVitals != null ? () => onRecordVitals!(item) : null;
    }
    if (ConsultationActionHelper.canViewConsultation(
      booking: booking,
      visit: visit,
      evaluator: evaluator,
    )) {
      return onViewConsultation != null ? () => onViewConsultation!(item) : null;
    }
    return null;
  }
}

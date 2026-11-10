import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/enums/visit_status_enum.dart';
import '../helpers/consultation_action_helper.dart';
import 'visit_status_badge.dart';

class ConsultationQueueCard extends StatelessWidget {
  final ConsultationQueueItemModel item;
  final PermissionEvaluator evaluator;
  final bool isLoading;
  final ValueChanged<ConsultationQueueItemModel>? onStartConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onContinueConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onRecordVitals;
  final ValueChanged<ConsultationQueueItemModel>? onViewConsultation;

  const ConsultationQueueCard({
    super.key,
    required this.item,
    required this.evaluator,
    this.isLoading = false,
    this.onStartConsultation,
    this.onContinueConsultation,
    this.onRecordVitals,
    this.onViewConsultation,
  });

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final visit = item.visit;

    final appointmentTime = booking?.appointmentTime;
    final timeStr = appointmentTime != null
        ? DateFormat('hh:mm a', 'ar').format(appointmentTime)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Queue Number, Time, Status ─────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${booking?.queueNumber ?? '—'}',
                    style: CustomAppFontStyle.bold12.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: AppColors.gray,
                ),
              ),
              const Spacer(),
              VisitStatusBadge(status: visit?.status),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Patient Info ───────────────────────────────────────────
          Text(
            booking?.patientName ?? '—',
            style: CustomAppFontStyle.bold16.copyWith(
              color: AppColors.darkText,
            ),
          ),
          if (booking?.patientPhone != null) ...[
            const SizedBox(height: 2),
            Text(
              booking!.patientPhone!,
              style: CustomAppFontStyle.regular12.copyWith(
                color: AppColors.gray,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
          const SizedBox(height: 8),

          // ─── Doctor & Specialty ─────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 14,
                color: AppColors.gray,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${booking?.doctorName ?? '—'}${booking?.specialty != null ? ' • ${booking!.specialty!}' : ''}',
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: AppColors.gray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Action Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _buildCardAction(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction(BuildContext context) {
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

    if (canView) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : () => onViewConsultation?.call(item),
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: Text('visits_action_view'.tr()),
      );
    }

    if (canContinue) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : () => onContinueConsultation?.call(item),
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text('visits_continue_consultation'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
        ),
      );
    }

    final buttons = <Widget>[];

    if (canStart) {
      final isTriage = visit?.status == VisitStatusEnum.triage;
      final labelKey = ConsultationActionHelper.getConsultationButtonKey(
        booking: booking,
        visit: visit,
      );
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => onStartConsultation?.call(item),
            icon: Icon(
              isTriage ? Icons.check_circle_outline : Icons.play_arrow_rounded,
              size: 16,
            ),
            label: Text(labelKey.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isTriage ? const Color(0xFFB45309) : AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    if (canVitals) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      final isTriage = visit?.status == VisitStatusEnum.triage;
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : () => onRecordVitals?.call(item),
            icon: Icon(
              isTriage ? Icons.edit_outlined : Icons.monitor_heart_outlined,
              size: 16,
            ),
            label: Text('visits_record_vitals'.tr()),
          ),
        ),
      );
    }

    if (buttons.isNotEmpty) {
      return Row(children: buttons);
    }

    return const SizedBox.shrink();
  }
}

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/enums/staff_permission_enum.dart';
import '../../../../core/layout_adaptive/widgets/cutom_table.dart';
import '../../../../core/services/permission_evaluator.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../bookings/data/models/enums/booking_status_enum.dart';
import '../../data/models/consultation_queue_item_model.dart';
import '../../data/models/enums/visit_status_enum.dart';
import 'visit_status_badge.dart';

class ConsultationQueueTable extends StatelessWidget {
  final List<ConsultationQueueItemModel> items;
  final PermissionEvaluator evaluator;
  final ValueChanged<ConsultationQueueItemModel>? onStartConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onContinueConsultation;
  final ValueChanged<ConsultationQueueItemModel>? onRecordVitals;
  final ValueChanged<ConsultationQueueItemModel>? onViewConsultation;

  const ConsultationQueueTable({
    super.key,
    required this.items,
    required this.evaluator,
    this.onStartConsultation,
    this.onContinueConsultation,
    this.onRecordVitals,
    this.onViewConsultation,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(70), // Queue #
    1: FlexColumnWidth(2.5), // Patient Name & Phone
    2: FlexColumnWidth(2.2), // Assigned Doctor
    3: FixedColumnWidth(110), // Time
    4: FixedColumnWidth(130), // Visit Status
    5: FixedColumnWidth(190), // Actions
  };

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

    return CustomTable(
      minWidth: 850,
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

    // 0: Queue Number Badge
    final cell0 = Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
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
    );

    // 1: Patient Name & Phone
    final cell1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          booking?.patientName ?? '—',
          style: CustomAppFontStyle.bold14.copyWith(
            color: AppColors.darkText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      ],
    );

    // 2: Doctor & Specialty
    final cell2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          booking?.doctorName ?? '—',
          style: CustomAppFontStyle.medium14.copyWith(
            color: AppColors.darkText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (booking?.specialty != null) ...[
          const SizedBox(height: 2),
          Text(
            booking!.specialty!,
            style: CustomAppFontStyle.regular12.copyWith(
              color: AppColors.gray,
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
          color: AppColors.gray,
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
    final user = evaluator.userProvider.currentUser;
    final isAssignedDoctor = user != null &&
        user.isPracticingDoctor &&
        user.linkedDoctorId == booking?.doctorId;

    final canStartConsultation = isAssignedDoctor &&
        evaluator.can(
          StaffPermissionEnum.startConsultation,
          branchId: booking?.branchId,
          patientDoctorIds:
              booking?.doctorId != null ? {booking!.doctorId!} : null,
        );

    final canNurseRecord = evaluator.can(
      StaffPermissionEnum.recordVitals,
      branchId: booking?.branchId,
    );

    final canViewNotes = evaluator.can(
      StaffPermissionEnum.viewConsultationNotes,
      branchId: booking?.branchId,
    );

    final isWaiting = booking?.status == BookingStatusEnum.waiting;
    final isFinalized = visit?.status == VisitStatusEnum.finalized ||
        booking?.status == BookingStatusEnum.completed;
    final isInProgress = visit?.status == VisitStatusEnum.inProgress ||
        booking?.status == BookingStatusEnum.inConsultation;
    final isTriage = visit?.status == VisitStatusEnum.triage;

    // Case 4: Finalized
    if (isFinalized) {
      if (canViewNotes) {
        return OutlinedButton.icon(
          onPressed: () => onViewConsultation?.call(item),
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
      return const SizedBox.shrink();
    }

    // Case 3: In Consultation (Ongoing)
    if (isInProgress) {
      if (canStartConsultation) {
        return ElevatedButton.icon(
          onPressed: () => onContinueConsultation?.call(item),
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
      return const SizedBox.shrink();
    }

    // Case 2: Waiting with Triage visit
    if (isWaiting && isTriage) {
      if (canStartConsultation) {
        return ElevatedButton.icon(
          onPressed: () => onStartConsultation?.call(item),
          icon: const Icon(Icons.check_circle_outline, size: 14),
          label: Text('visits_complete_vitals'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB45309), // Amber 700
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.bold12,
          ),
        );
      }
      if (canNurseRecord) {
        return OutlinedButton.icon(
          onPressed: () => onRecordVitals?.call(item),
          icon: const Icon(Icons.edit_outlined, size: 14),
          label: Text('visits_record_vitals'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB45309),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.medium12,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Case 1: Waiting without visit
    if (isWaiting) {
      if (canStartConsultation) {
        return ElevatedButton.icon(
          onPressed: () => onStartConsultation?.call(item),
          icon: const Icon(Icons.play_arrow_rounded, size: 16),
          label: Text('visits_start_consultation'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.bold12,
          ),
        );
      }
      if (canNurseRecord) {
        return OutlinedButton.icon(
          onPressed: () => onRecordVitals?.call(item),
          icon: const Icon(Icons.monitor_heart_outlined, size: 14),
          label: Text('visits_record_vitals'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            textStyle: CustomAppFontStyle.medium12,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Fail-closed default
    return const SizedBox.shrink();
  }
}

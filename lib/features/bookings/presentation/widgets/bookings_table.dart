import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/visits/presentation/helpers/consultation_action_helper.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_actions_menu.dart';
import 'package:eyadty/features/bookings/presentation/widgets/free_booking_badge.dart';

class BookingsTable extends StatelessWidget {
  final List<BookingModel> bookings;
  final void Function(BookingModel booking)? onViewDetails;
  final void Function(BookingModel booking) onEdit;
  final void Function(BookingModel booking) onChangeStatus;
  final void Function(BookingModel booking) onReassignTechnician;
  final void Function(BookingModel booking) onDelete;
  final void Function(BookingModel booking)? onCallPatient;
  final void Function(BookingModel booking)? onStartConsultation;
  final void Function(BookingModel booking)? onRecordVitals;
  final void Function(BookingModel booking)? onCollectPayment;
  final void Function(BookingModel booking)? onRefundPayment;

  const BookingsTable({
    super.key,
    required this.bookings,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
    this.onCallPatient,
    this.onStartConsultation,
    this.onRecordVitals,
    this.onCollectPayment,
    this.onRefundPayment,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(44),   // Queue Number
    1: FixedColumnWidth(150),  // Patient Name & Phone
    2: FixedColumnWidth(140),  // Doctor & Clinic Room
    3: IntrinsicColumnWidth(), // Queue Status (compact chip, never truncated)
    4: IntrinsicColumnWidth(), // Actions (primary icon + 3-dot menu)
    5: IntrinsicColumnWidth(), // Arrival & Est. Wait
    6: IntrinsicColumnWidth(), // Visit Type
    7: IntrinsicColumnWidth(), // Fee & Payment Status
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 760,
      columnWidths: columnWidths,
      headers: [
        'queue_number'.tr(),
        'patient'.tr(),
        'doctor_and_clinic'.tr(),
        'queue_status'.tr(),
        'actions_label'.tr(),
        'arrival_and_wait'.tr(),
        'visit_type'.tr(),
        'fee_and_payment'.tr(),
      ],
      rows: bookings
          .map(
            (booking) =>
                _buildRow(context, booking, bookings.indexOf(booking) + 1),
          )
          .toList(),
    );
  }

  List<Widget> _buildRow(BuildContext context, BookingModel item, int index) {
    final colors = context.themeColors;

    // 0: Queue # (Prominent Squircle/Circle Pill)
    final cell0 = Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '#${item.queueNumber ?? index}',
            style: CustomAppFontStyle.bold14.copyWith(
              color: colors.primary,
            ),
          ),
        ),
      ),
    );

    PermissionEvaluator? evaluator;
    try {
      evaluator = getIt<PermissionEvaluator>();
    } catch (_) {
      evaluator = null;
    }

    final canStart = evaluator != null &&
        ConsultationActionHelper.canStartConsultation(
          booking: item,
          visit: null,
          evaluator: evaluator,
        );
    final canContinue = evaluator != null &&
        ConsultationActionHelper.canContinueConsultation(
          booking: item,
          visit: null,
          evaluator: evaluator,
        );
    final canVitals = evaluator != null &&
        ConsultationActionHelper.canRecordVitals(
          booking: item,
          visit: null,
          evaluator: evaluator,
        );

    // 1: Patient (Name + Phone + File Number)
    // Nurse opens vitals dialog on row tap; other roles open booking details.
    final VoidCallback? rowTap =
        (canVitals && !canStart && !canContinue && onRecordVitals != null)
            ? () => onRecordVitals!(item)
            : (onViewDetails != null ? () => onViewDetails!(item) : null);

    final patientDisplayName =
        item.patientName ?? item.customerName ?? 'patient_unassigned'.tr();
    final cell1 = InkWell(
      onTap: rowTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            patientDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.patientPhone ?? ''} ${item.fileNumber != null ? '• #${item.fileNumber}' : ''}'.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: CustomAppFontStyle.regular12.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );

    // 2: Doctor & Clinic Room
    final cell2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.doctorName ?? item.technicianName ?? 'doctor_unassigned'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CustomAppFontStyle.medium14.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.specialty ?? 'عيادة عامة'} • ${item.clinicRoom ?? 'عيادة 1'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CustomAppFontStyle.regular12.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );

    // 3: Visit Type Badge (New, Revisit, Emergency)
    final visitType = item.visitType ?? BookingTypeEnum.newVisit;
    final cell3 = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: visitType.backgroundColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          visitType.label,
          style: CustomAppFontStyle.medium12.copyWith(
            color: visitType.color,
          ),
        ),
      ),
    );

    // 4: Arrival Time & Estimated Wait Remaining / Delay Info
    final isWalkIn = item.bookingType == BookingTypeEnum.emergency ||
        item.visitType == BookingTypeEnum.emergency;
    final timingInfo = CairoTimeHelper.evaluateBookingTiming(
      date: item.appointmentTime ?? item.date,
      startTime: item.startTime,
      endTime: item.endTime,
      durationMinutes: item.durationMinutes,
      isWalkIn: isWalkIn,
    );

    Widget waitOrStatusDetail;
    if (item.status == BookingStatusEnum.noShow) {
      final delayMinutes = CairoTimeHelper.calculateDelayMinutes(
        item.appointmentTime ?? item.date,
        item.startTime,
      );
      waitOrStatusDetail = Text(
        delayMinutes > 0
            ? CairoTimeHelper.formatDelayArabic(delayMinutes)
            : BookingStatusEnum.noShow.label,
        style: CustomAppFontStyle.semiBold11.copyWith(
          color: AppColors.error,
        ),
      );
    } else if (item.status == BookingStatusEnum.cancelled) {
      final cancelledByText = item.cancelledBy == 'clinic'
          ? 'cancelled_by_clinic'.tr()
          : 'cancelled_by_patient'.tr();
      waitOrStatusDetail = Text(
        item.cancelReason != null && item.cancelReason!.isNotEmpty
            ? '$cancelledByText: ${item.cancelReason}'
            : cancelledByText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CustomAppFontStyle.regular11.copyWith(
          color: AppColors.error,
        ),
      );
    } else if (item.status == BookingStatusEnum.postponed && item.rescheduledTo != null) {
      final r = item.rescheduledTo!;
      final dateStr = '${r.year}/${r.month.toString().padLeft(2, '0')}/${r.day.toString().padLeft(2, '0')}';
      waitOrStatusDetail = Text(
        'إلى: $dateStr',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CustomAppFontStyle.medium11.copyWith(
          color: AppColors.secondary,
        ),
      );
    } else {
      final bookingDate = item.appointmentTime ?? item.date;
      final nowCairo = CairoTimeHelper.now();
      final isToday = bookingDate != null &&
          bookingDate.year == nowCairo.year &&
          bookingDate.month == nowCairo.month &&
          bookingDate.day == nowCairo.day;
      if (bookingDate != null && !isToday) {
        final dateStr =
            '${bookingDate.year}/${bookingDate.month.toString().padLeft(2, '0')}/${bookingDate.day.toString().padLeft(2, '0')}';
        waitOrStatusDetail = Text(
          dateStr,
          style: CustomAppFontStyle.regular11.copyWith(
            color: AppColors.secondary,
          ),
        );
      } else if (item.arrivalTime != null ||
          item.status == BookingStatusEnum.completed ||
          item.status == BookingStatusEnum.inConsultation) {
        waitOrStatusDetail = Text(
          item.status?.label ?? '',
          style: CustomAppFontStyle.regular11.copyWith(
            color: colors.textSecondary,
          ),
        );
      } else {
        waitOrStatusDetail = Text(
          timingInfo.label,
          style: CustomAppFontStyle.semiBold11.copyWith(
            color: timingInfo.isLateOrExpired
                ? AppColors.error
                : AppColors.statusWarning,
          ),
        );
      }
    }

    final cell4 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 13,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              item.startTime ?? '--:--',
              style: CustomAppFontStyle.medium13.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        waitOrStatusDetail,
      ],
    );

    // 5: Consultation Fee & Payment Status
    final cell5 = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.isFreeConsultation
              ? '0 ${'currency'.tr()}'
              : '${MonyHelper.formatMoney(item.netAmount)} ${'currency'.tr()}',
          style: CustomAppFontStyle.semiBold14.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        if (item.status == BookingStatusEnum.cancelled &&
            (item.paidAmount ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xffFEF3C7),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xffF59E0B)),
            ),
            child: Text(
              'cashier_needs_refund'.tr(),
              style: CustomAppFontStyle.medium10.copyWith(
                color: const Color(0xffB45309),
              ),
            ),
          )
        else if (item.isFreeConsultation)
          const FreeBookingBadge(
            fontSize: 10,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: (item.effectivePaymentStatus).backgroundColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              (item.effectivePaymentStatus).label,
              style: CustomAppFontStyle.medium10.copyWith(
                color: (item.effectivePaymentStatus).color,
              ),
            ),
          ),
      ],
    );

    // Status Badge (compact chip with icon + short label + Tooltip, intrinsic width)
    final status = item.status ?? BookingStatusEnum.waiting;
    final statusIcon = switch (status) {
      BookingStatusEnum.waiting => Icons.schedule_outlined,
      BookingStatusEnum.inConsultation => Icons.medical_services_outlined,
      BookingStatusEnum.completed => Icons.check_circle_outline,
      BookingStatusEnum.cancelled => Icons.cancel_outlined,
      BookingStatusEnum.noShow => Icons.person_off_outlined,
      BookingStatusEnum.postponed => Icons.event_repeat_outlined,
    };
    final cellStatus = Center(
      child: Tooltip(
        message: status.label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status.backgroundColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 13, color: status.color),
              const SizedBox(width: 4),
              Text(
                status.label,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: status.color,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );

    // Actions: primary icon button + 3-dot popup menu
    final showConsultation =
        (canStart || canContinue) && onStartConsultation != null;
    final consultationKey = ConsultationActionHelper.getConsultationButtonKey(
      booking: item,
      visit: null,
    );

    final canEditBooking = evaluator == null ||
        evaluator.can(StaffPermissionEnum.editBooking, branchId: item.branchId);
    final canCancelBooking = evaluator == null ||
        evaluator.can(StaffPermissionEnum.cancelBooking, branchId: item.branchId);
    final canReorderQueue = evaluator == null ||
        evaluator.can(StaffPermissionEnum.reorderQueue, branchId: item.branchId);
    final canCollectPerm = evaluator == null ||
        evaluator.can(StaffPermissionEnum.collectPayment, branchId: item.branchId);
    final canRefundPerm = evaluator == null ||
        evaluator.can(StaffPermissionEnum.refundPayment, branchId: item.branchId);

    final canCollect = canCollectPerm &&
        !item.isFreeConsultation &&
        item.status != BookingStatusEnum.cancelled &&
        (item.netAmount > (item.paidAmount ?? 0));
    final canRefund = canRefundPerm && (item.paidAmount ?? 0) > 0;

    Widget? primaryActionIcon;
    if (canVitals && !canStart && !canContinue && onRecordVitals != null) {
      primaryActionIcon = IconButton(
        tooltip: 'visits_record_vitals'.tr(),
        icon: const Icon(Icons.monitor_heart_outlined, size: 18),
        color: colors.primary,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
        onPressed: () => onRecordVitals!(item),
      );
    } else if (showConsultation) {
      primaryActionIcon = IconButton(
        tooltip: consultationKey.tr(),
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        color: colors.primary,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
        onPressed: () => onStartConsultation!(item),
      );
    } else if (canCollect && onCollectPayment != null) {
      primaryActionIcon = IconButton(
        tooltip: 'cashier_collect_btn'.tr(),
        icon: const Icon(Icons.payments_outlined, size: 18),
        color: colors.primary,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
        onPressed: () => onCollectPayment!(item),
      );
    }

    final cellActions = Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (primaryActionIcon != null) primaryActionIcon,
          BookingActionsMenu(
            onViewDetails: onViewDetails != null
                ? () => onViewDetails!(item)
                : null,
            onEdit: canEditBooking ? () => onEdit(item) : null,
            onChangeStatus: (canEditBooking || canCancelBooking)
                ? () => onChangeStatus(item)
                : null,
            onReassignTechnician:
                canReorderQueue ? () => onReassignTechnician(item) : null,
            onDelete: canCancelBooking ? () => onDelete(item) : null,
            onCallPatient:
                (canEditBooking || canReorderQueue) && onCallPatient != null
                    ? () => onCallPatient!(item)
                    : null,
            onStartConsultation:
                showConsultation ? () => onStartConsultation!(item) : null,
            onRecordVitals: canVitals && onRecordVitals != null
                ? () => onRecordVitals!(item)
                : null,
            consultationButtonKey: consultationKey,
            onCollectPayment: canCollect && onCollectPayment != null
                ? () => onCollectPayment!(item)
                : null,
            onRefundPayment: canRefund && onRefundPayment != null
                ? () => onRefundPayment!(item)
                : null,
          ),
        ],
      ),
    );

    return [cell0, cell1, cell2, cellStatus, cellActions, cell4, cell3, cell5];
  }
}

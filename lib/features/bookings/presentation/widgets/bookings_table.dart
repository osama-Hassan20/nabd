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
    this.onCollectPayment,
    this.onRefundPayment,
  });

  static const Map<int, TableColumnWidth> columnWidths = {
    0: FixedColumnWidth(55),  // Queue Number
    1: FixedColumnWidth(130), // Patient Name & Phone
    2: FixedColumnWidth(130), // Doctor & Clinic Room
    3: FixedColumnWidth(100), // Visit Type
    4: FixedColumnWidth(125), // Arrival & Est. Wait
    5: FixedColumnWidth(95),  // Fee & Payment Status
    6: FixedColumnWidth(110), // Queue Status
    7: FixedColumnWidth(35),  // Actions
  };

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 950,
      columnWidths: columnWidths,
      headers: [
        'queue_number'.tr(),
        'patient'.tr(),
        'doctor_and_clinic'.tr(),
        'visit_type'.tr(),
        'arrival_and_wait'.tr(),
        'fee_and_payment'.tr(),
        'queue_status'.tr(),
        'actions_label'.tr(),
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

    // 1: Patient (Name + Phone + File Number)
    final cell1 = InkWell(
      onTap: () => onViewDetails?.call(item),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.patientName ?? item.customerName ?? 'patient_unassigned'.tr(),
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
    final delayMinutes = CairoTimeHelper.calculateDelayMinutes(
      item.appointmentTime ?? item.date,
      item.startTime,
    );
    final isDelayed = delayMinutes > 0 && item.arrivalTime == null &&
        (item.status == BookingStatusEnum.noShow || item.status == BookingStatusEnum.waiting);

    Widget waitOrStatusDetail;
    if (item.status == BookingStatusEnum.noShow || isDelayed) {
      waitOrStatusDetail = Text(
        CairoTimeHelper.formatDelayArabic(delayMinutes),
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
      waitOrStatusDetail = Text(
        '${item.estimatedWaitMinutes ?? 15} ${'estimated_wait_min'.tr()}',
        style: CustomAppFontStyle.regular11.copyWith(
          color: AppColors.statusWarning,
        ),
      );
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

    // 6: Queue Status Badge (With Pulsing/Solid Status Dot)
    final status = item.status ?? BookingStatusEnum.waiting;
    final cell6 = Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: status.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // 7: Actions Popup Menu
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
    final showConsultation =
        (canStart || canContinue) && onStartConsultation != null;
    final consultationKey = ConsultationActionHelper.getConsultationButtonKey(
      booking: item,
      visit: null,
    );

    final canCollect = !item.isFreeConsultation &&
        item.status != BookingStatusEnum.cancelled &&
        (item.netAmount > (item.paidAmount ?? 0));
    final canRefund = (item.paidAmount ?? 0) > 0;

    final cell7 = Center(
      child: BookingActionsMenu(
        onViewDetails: onViewDetails != null
            ? () => onViewDetails!(item)
            : null,
        onEdit: () => onEdit(item),
        onChangeStatus: () => onChangeStatus(item),
        onReassignTechnician: () => onReassignTechnician(item),
        onDelete: () => onDelete(item),
        onCallPatient: onCallPatient != null ? () => onCallPatient!(item) : null,
        onStartConsultation:
            showConsultation ? () => onStartConsultation!(item) : null,
        consultationButtonKey: consultationKey,
        onCollectPayment: canCollect && onCollectPayment != null
            ? () => onCollectPayment!(item)
            : null,
        onRefundPayment: canRefund && onRefundPayment != null
            ? () => onRefundPayment!(item)
            : null,
      ),
    );

    return [cell0, cell1, cell2, cell3, cell4, cell5, cell6, cell7];
  }
}

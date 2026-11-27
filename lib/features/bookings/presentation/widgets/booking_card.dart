import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/visits/presentation/helpers/consultation_action_helper.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_actions_menu.dart';
import 'package:eyadty/features/bookings/presentation/widgets/free_booking_badge.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onReassignTechnician;
  final VoidCallback onDelete;
  final VoidCallback? onCallPatient;
  final VoidCallback? onStartConsultation;
  final VoidCallback? onRecordVitals;

  const BookingCard({
    super.key,
    required this.booking,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
    this.onCallPatient,
    this.onStartConsultation,
    this.onRecordVitals,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final status = booking.status ?? BookingStatusEnum.waiting;
    final visitType = booking.visitType ?? BookingTypeEnum.newVisit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Queue Number + Status + Call Action + Menu ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#${booking.queueNumber ?? 1}',
                        style: CustomAppFontStyle.bold14.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? status.color.withValues(alpha: 0.16)
                          : status.backgroundColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status.label,
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (onCallPatient != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: onCallPatient,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.volume_up_rounded,
                              size: 14,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'call_patient'.tr(),
                              style: CustomAppFontStyle.semiBold11.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (booking.isFreeConsultation)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: FreeBookingBadge(),
                    ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      PermissionEvaluator? evaluator;
                      try {
                        evaluator = getIt<PermissionEvaluator>();
                      } catch (_) {
                        evaluator = null;
                      }

                      final canStart = evaluator != null &&
                          ConsultationActionHelper.canStartConsultation(
                            booking: booking,
                            visit: null,
                            evaluator: evaluator,
                          );
                      final canContinue = evaluator != null &&
                          ConsultationActionHelper.canContinueConsultation(
                            booking: booking,
                            visit: null,
                            evaluator: evaluator,
                          );
                      final canVitals = evaluator != null &&
                          ConsultationActionHelper.canRecordVitals(
                            booking: booking,
                            visit: null,
                            evaluator: evaluator,
                          );
                      final showConsultation = (canStart || canContinue) &&
                          onStartConsultation != null;
                      final consultationKey =
                          ConsultationActionHelper.getConsultationButtonKey(
                        booking: booking,
                        visit: null,
                      );

                      final canEditBooking = evaluator == null ||
                          evaluator.can(StaffPermissionEnum.editBooking,
                              branchId: booking.branchId);
                      final canCancelBooking = evaluator == null ||
                          evaluator.can(StaffPermissionEnum.cancelBooking,
                              branchId: booking.branchId);
                      final canReorderQueue = evaluator == null ||
                          evaluator.can(StaffPermissionEnum.reorderQueue,
                              branchId: booking.branchId);

                      return BookingActionsMenu(
                        onViewDetails: onViewDetails,
                        onEdit: canEditBooking ? onEdit : null,
                        onChangeStatus:
                            (canEditBooking || canCancelBooking) ? onChangeStatus : null,
                        onReassignTechnician:
                            canReorderQueue ? onReassignTechnician : null,
                        onDelete: canCancelBooking ? onDelete : null,
                        onCallPatient:
                            (canEditBooking || canReorderQueue) ? onCallPatient : null,
                        onStartConsultation:
                            showConsultation ? onStartConsultation : null,
                        onRecordVitals:
                            canVitals ? onRecordVitals : null,
                        consultationButtonKey: consultationKey,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Patient Information ──────────────────────────────────────────
          InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primaryLight.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName ?? booking.customerName ?? 'patient_unassigned'.tr(),
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${booking.patientPhone ?? ''} ${booking.fileNumber != null ? '• #${booking.fileNumber}' : ''}'.trim(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.isFreeConsultation
                          ? '0 ${'currency'.tr()}'
                          : '${MonyHelper.formatMoney(booking.netAmount)} ${'currency'.tr()}',
                      style: CustomAppFontStyle.bold15.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (booking.status == BookingStatusEnum.cancelled &&
                        (booking.paidAmount ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colors.isDark
                              ? Colors.amber.shade900.withValues(alpha: 0.25)
                              : const Color(0xffFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'مسترد: ${MonyHelper.formatMoney(booking.paidAmount ?? 0)} ${'currency'.tr()}',
                          style: CustomAppFontStyle.medium11.copyWith(
                            color: colors.isDark ? Colors.amber.shade200 : const Color(0xff92400E),
                          ),
                        ),
                      )
                    else
                      Builder(
                        builder: (context) {
                          final payStatus =
                              booking.paymentStatus ?? PaymentStatusEnum.unpaid;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.isDark
                                  ? payStatus.color.withValues(alpha: 0.16)
                                  : payStatus.backgroundColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payStatus.label,
                              style: CustomAppFontStyle.medium11.copyWith(
                                color: payStatus.color,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 12),

          // ─── Service + Doctor + Clinic + Visit Type ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${booking.doctorName ?? 'doctor_unassigned'.tr()} (${booking.clinicRoom ?? 'عيادة 1'})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.isDark
                      ? visitType.color.withValues(alpha: 0.16)
                      : visitType.backgroundColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  visitType.label,
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: visitType.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── Arrival Time & Estimated Wait / Delay / Postpone Details ──────
          Builder(
            builder: (context) {
              final isWalkIn = booking.bookingType == BookingTypeEnum.emergency ||
                  booking.visitType == BookingTypeEnum.emergency;
              final timingInfo = CairoTimeHelper.evaluateBookingTiming(
                date: booking.appointmentTime ?? booking.date,
                startTime: booking.startTime,
                endTime: booking.endTime,
                durationMinutes: booking.durationMinutes,
                isWalkIn: isWalkIn,
              );

              Widget detailWidget;
              if (booking.status == BookingStatusEnum.noShow) {
                final delayMinutes = CairoTimeHelper.calculateDelayMinutes(
                  booking.appointmentTime ?? booking.date,
                  booking.startTime,
                );
                detailWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    delayMinutes > 0
                        ? CairoTimeHelper.formatDelayArabic(delayMinutes)
                        : BookingStatusEnum.noShow.label,
                    style: CustomAppFontStyle.semiBold11.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              } else if (booking.status == BookingStatusEnum.cancelled) {
                final text = booking.cancelledBy == 'clinic'
                    ? 'cancelled_by_clinic'.tr()
                    : 'cancelled_by_patient'.tr();
                detailWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    booking.cancelReason != null && booking.cancelReason!.isNotEmpty
                        ? '$text: ${booking.cancelReason}'
                        : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              } else if (booking.status == BookingStatusEnum.postponed &&
                  booking.rescheduledTo != null) {
                final r = booking.rescheduledTo!;
                final dateStr =
                    '${r.year}/${r.month.toString().padLeft(2, '0')}/${r.day.toString().padLeft(2, '0')}';
                detailWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'موعد جديد: $dateStr',
                    style: CustomAppFontStyle.medium11.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                );
              } else {
                final bookingDate = booking.appointmentTime ?? booking.date;
                final nowCairo = CairoTimeHelper.now();
                final isToday = bookingDate != null &&
                    bookingDate.year == nowCairo.year &&
                    bookingDate.month == nowCairo.month &&
                    bookingDate.day == nowCairo.day;
                if (bookingDate != null && !isToday) {
                  final dateStr =
                      '${bookingDate.year}/${bookingDate.month.toString().padLeft(2, '0')}/${bookingDate.day.toString().padLeft(2, '0')}';
                  detailWidget = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      dateStr,
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                } else {
                  detailWidget = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: timingInfo.isLateOrExpired
                          ? AppColors.error.withValues(alpha: 0.12)
                          : (colors.isDark
                              ? Colors.amber.shade900.withValues(alpha: 0.2)
                              : AppColors.statusWarningLight),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      timingInfo.label,
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: timingInfo.isLateOrExpired
                            ? AppColors.error
                            : (colors.isDark ? Colors.amber.shade200 : AppColors.statusWarning),
                      ),
                    ),
                  );
                }
              }

              return Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${'arrival_time'.tr()}: ${booking.startTime ?? '--:--'}',
                      overflow: TextOverflow.ellipsis,
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  detailWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

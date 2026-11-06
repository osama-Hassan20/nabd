import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:eyadty/core/network/mony_helper.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_actions_menu.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onReassignTechnician;
  final VoidCallback onDelete;
  final VoidCallback? onCallPatient;

  const BookingCard({
    super.key,
    required this.booking,
    this.onViewDetails,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassignTechnician,
    required this.onDelete,
    this.onCallPatient,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking.status ?? BookingStatusEnum.waiting;
    final visitType = booking.visitType ?? BookingTypeEnum.newVisit;
    final paymentStatus = booking.paymentStatus ?? PaymentStatusEnum.unpaid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grayE2E8F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#${booking.queueNumber ?? 1}',
                        style: CustomAppFontStyle.bold14.copyWith(
                          color: AppColors.primary,
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
                      color: status.backgroundColor,
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
                          color: AppColors.primary,
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
                  const SizedBox(width: 4),
                  BookingActionsMenu(
                    onViewDetails: onViewDetails,
                    onEdit: onEdit,
                    onChangeStatus: onChangeStatus,
                    onReassignTechnician: onReassignTechnician,
                    onDelete: onDelete,
                    onCallPatient: onCallPatient,
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
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
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
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${booking.patientPhone ?? ''} ${booking.fileNumber != null ? '• #${booking.fileNumber}' : ''}'.trim(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
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
                      '${MonyHelper.formatMoney(booking.consultationFee ?? booking.totalPrice ?? 0)} ${'currency'.tr()}',
                      style: CustomAppFontStyle.bold15.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: paymentStatus.backgroundColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        paymentStatus.label,
                        style: CustomAppFontStyle.medium10.copyWith(
                          color: paymentStatus.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ─── Doctor, Clinic Room & Visit Type ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${booking.doctorName ?? 'doctor_unassigned'.tr()} (${booking.clinicRoom ?? 'عيادة 1'})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: AppColors.darkText,
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
                  color: visitType.backgroundColor,
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
              final delayMinutes = CairoTimeHelper.calculateDelayMinutes(
                booking.appointmentTime ?? booking.date,
                booking.startTime,
              );
              final isDelayed = delayMinutes > 0 &&
                  booking.arrivalTime == null &&
                  (booking.status == BookingStatusEnum.noShow ||
                      booking.status == BookingStatusEnum.waiting);

              Widget detailWidget;
              if (booking.status == BookingStatusEnum.noShow || isDelayed) {
                detailWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red1A,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    CairoTimeHelper.formatDelayArabic(delayMinutes),
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
                    color: AppColors.red1A,
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
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'موعد جديد: $dateStr',
                    style: CustomAppFontStyle.medium11.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                );
              } else {
                detailWidget = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarningLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${booking.estimatedWaitMinutes ?? 15} ${'estimated_wait_min'.tr()}',
                    style: CustomAppFontStyle.medium11.copyWith(
                      color: AppColors.statusWarning,
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.gray71717A,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'arrival_time'.tr()}: ${booking.startTime ?? '--:--'}',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                  const Spacer(),
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

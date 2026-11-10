import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/features/visits/presentation/helpers/consultation_action_helper.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class BookingDetailsTopBar extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onReassign;
  final VoidCallback onDelete;
  final VoidCallback? onStartConsultation;

  const BookingDetailsTopBar({
    super.key,
    required this.booking,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onReassign,
    required this.onDelete,
    this.onStartConsultation,
  });

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.bookings);
    }
  }

  void _copyBookingId(BuildContext context) {
    final id = booking.id;
    if (id != null && id.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: id));
      CustomToast(
        context: context,
        header: 'copied_to_clipboard'.tr(),
      ).showTopToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status ?? BookingStatusEnum.scheduled;
    final bookingType = booking.bookingType;
    final paymentStatus = booking.paymentStatus;
    final isMobile = AdaptiveLayout.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Back button, ID, and Badges
          Row(
            children: [
              // Back Button
              InkWell(
                onTap: () => _onBack(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf6,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_ios_new,
                        size: 14,
                        color: AppColors.darkText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'back_to_bookings'.tr(),
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Booking ID Pill with Copy button
              InkWell(
                onTap: () => _copyBookingId(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        booking.id ?? '#',
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.copy,
                        size: 13,
                        color: AppColors.gray71717A,
                      ),
                    ],
                  ),
                ),
              ),

              if (!isMobile) ...[
                const Spacer(),
                // Badges
                _buildBadges(status, bookingType, paymentStatus),
              ],
            ],
          ),

          if (isMobile) ...[
            const SizedBox(height: 12),
            _buildBadges(status, bookingType, paymentStatus),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 14),

          // Action Buttons Bar
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
              final showConsultation =
                  (canStart || canContinue) && onStartConsultation != null;
              final consultationKey =
                  ConsultationActionHelper.getConsultationButtonKey(
                booking: booking,
                visit: null,
              );

              return Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  // Start/Continue Consultation Button
                  if (showConsultation)
                    CustomPushButton(
                      height: 42,
                      width: isMobile ? double.infinity : 160,
                      backgroundColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: onStartConsultation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 16,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            consultationKey.tr(),
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
              // Change Status Button
              CustomPushButton(
                height: 42,
                width: isMobile ? double.infinity : 150,
                backgroundColor: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: BorderSide(color: AppColors.grayE2E8F0),
                onTap: onChangeStatus,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.change,
                      width: 14,
                      height: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'change_status'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // Reassign Technician Button
              CustomPushButton(
                height: 42,
                width: isMobile ? double.infinity : 160,
                backgroundColor: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: BorderSide(color: AppColors.grayE2E8F0),
                onTap: onReassign,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.team,
                      width: 14,
                      height: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'reassign_technician'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Booking Button
              CustomPushButton(
                height: 42,
                width: isMobile ? double.infinity : 130,
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: onEdit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.edit,
                      width: 14,
                      height: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'edit'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete Booking Button
              CustomPushButton(
                height: 42,
                width: isMobile ? double.infinity : 120,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
                onTap: onDelete,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.delete,
                      width: 14,
                      height: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'delete'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  ),
);
  }

  Widget _buildBadges(
    BookingStatusEnum status,
    BookingTypeEnum? bookingType,
    PaymentStatusEnum? paymentStatus,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: status.backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomAssetImage(
                path: status.icon,
                width: 12,
                height: 12,
                color: status.color,
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

        // Booking Type Badge
        if (bookingType != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bookingType.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              bookingType.label,
              style: CustomAppFontStyle.medium12.copyWith(
                color: bookingType.color,
              ),
            ),
          ),

        // Payment Status Badge
        if (paymentStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: paymentStatus.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              paymentStatus.label,
              style: CustomAppFontStyle.medium12.copyWith(
                color: paymentStatus.color,
              ),
            ),
          ),
      ],
    );
  }
}

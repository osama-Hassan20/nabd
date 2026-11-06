import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class ChangeBookingStatusDialog extends StatefulWidget {
  final BookingStatusEnum selectedStatus;
  final bool isLoading;
  final ValueChanged<BookingStatusEnum> onSelectStatus;
  final VoidCallback onConfirm;

  // Postponement state
  final DateTime? postponeDate;
  final String? postponeTime;
  final String? postponeReason;
  final ValueChanged<DateTime>? onPickPostponeDate;
  final ValueChanged<String>? onPickPostponeTime;
  final ValueChanged<String>? onPostponeReasonChanged;

  // Cancellation state
  final String? cancelReason;
  final String cancelledBy;
  final ValueChanged<String>? onCancelReasonChanged;
  final ValueChanged<String>? onCancelledByChanged;

  const ChangeBookingStatusDialog({
    super.key,
    required this.selectedStatus,
    required this.isLoading,
    required this.onSelectStatus,
    required this.onConfirm,
    this.postponeDate,
    this.postponeTime,
    this.postponeReason,
    this.onPickPostponeDate,
    this.onPickPostponeTime,
    this.onPostponeReasonChanged,
    this.cancelReason,
    this.cancelledBy = 'patient',
    this.onCancelReasonChanged,
    this.onCancelledByChanged,
  });

  @override
  State<ChangeBookingStatusDialog> createState() =>
      _ChangeBookingStatusDialogState();
}

class _ChangeBookingStatusDialogState extends State<ChangeBookingStatusDialog> {
  late final TextEditingController _postponeReasonController;
  late final TextEditingController _cancelReasonController;

  @override
  void initState() {
    super.initState();
    _postponeReasonController =
        TextEditingController(text: widget.postponeReason ?? '');
    _cancelReasonController =
        TextEditingController(text: widget.cancelReason ?? '');
  }

  @override
  void dispose() {
    _postponeReasonController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickPostponeDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.postponeDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      widget.onPickPostponeDate?.call(picked);
    }
  }

  Future<void> _pickPostponeTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      widget.onPickPostponeTime?.call('$hh:$mm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'change_status'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const CloseButton(),
                  ],
                ),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                const SizedBox(height: 16),

                // Status Choices
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: BookingStatusEnum.values.map((status) {
                    final isSelected = widget.selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => widget.onSelectStatus(status),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? status.color.withValues(alpha: 0.12)
                                : AppColors.grayf2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? status.color
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomAssetImage(
                                path: status.icon,
                                width: 18,
                                height: 18,
                                color: status.color,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  status.label,
                                  style: CustomAppFontStyle.medium14.copyWith(
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: status.color,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // ─── Postponed Fields (Mandatory New Date/Time + Optional Reason) ───
                if (widget.selectedStatus == BookingStatusEnum.postponed) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'new_appointment_date_label'.tr(),
                              style: CustomAppFontStyle.semiBold14.copyWith(
                                color: const Color(0xFF0D9488),
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Date Picker
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _pickPostponeDate(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const CustomAssetImage(
                                        path: AppIcons.calendar,
                                        width: 16,
                                        height: 16,
                                        color: Color(0xFF0D9488),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.postponeDate != null
                                              ? BookingTimeFormatter
                                                  .formatCompactDate(
                                                  widget.postponeDate!,
                                                  context,
                                                )
                                              : 'select_new_date'.tr(),
                                          style: CustomAppFontStyle.medium13
                                              .copyWith(
                                            color: widget.postponeDate != null
                                                ? AppColors.darkText
                                                : AppColors.grayMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Time Picker
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () => _pickPostponeTime(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const CustomAssetImage(
                                        path: AppIcons.clock,
                                        width: 16,
                                        height: 16,
                                        color: Color(0xFF0D9488),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.postponeTime != null
                                              ? BookingTimeFormatter
                                                  .formatSingleTime(
                                                  widget.postponeTime!,
                                                  context,
                                                )
                                              : 'select_new_time'.tr(),
                                          style: CustomAppFontStyle.medium13
                                              .copyWith(
                                            color: widget.postponeTime != null
                                                ? AppColors.darkText
                                                : AppColors.grayMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormField(
                          controller: _postponeReasonController,
                          headerText: 'postpone_reason_label'.tr(),
                          hintText: 'postpone_reason_hint'.tr(),
                        ),
                      ],
                    ),
                  ),
                ],

                // ─── Cancelled Fields (Source + Reason) ──────────────────────
                if (widget.selectedStatus == BookingStatusEnum.cancelled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'cancelled_by_label'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => widget.onCancelledByChanged
                                    ?.call('patient'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.cancelledBy == 'patient'
                                        ? AppColors.error.withValues(alpha: 0.15)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.cancelledBy == 'patient'
                                          ? AppColors.error
                                          : AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'cancelled_by_patient'.tr(),
                                      style:
                                          CustomAppFontStyle.medium13.copyWith(
                                        color: widget.cancelledBy == 'patient'
                                            ? AppColors.error
                                            : AppColors.darkText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => widget.onCancelledByChanged
                                    ?.call('clinic'),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.cancelledBy == 'clinic'
                                        ? AppColors.error.withValues(alpha: 0.15)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.cancelledBy == 'clinic'
                                          ? AppColors.error
                                          : AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'cancelled_by_clinic'.tr(),
                                      style:
                                          CustomAppFontStyle.medium13.copyWith(
                                        color: widget.cancelledBy == 'clinic'
                                            ? AppColors.error
                                            : AppColors.darkText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormField(
                          controller: _cancelReasonController,
                          headerText: 'cancel_reason_label'.tr(),
                          hintText: 'cancel_reason_hint'.tr(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPushButton(
                      height: 40,
                      width: 100,
                      backgroundColor: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.pop(),
                      child: Center(
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.grayMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPushButton(
                        height: 40,
                        width: 120,
                        backgroundColor: AppColors.primary,
                        isLoading: widget.isLoading,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (widget.selectedStatus ==
                              BookingStatusEnum.postponed) {
                            widget.onPostponeReasonChanged?.call(
                              _postponeReasonController.text.trim(),
                            );
                          } else if (widget.selectedStatus ==
                              BookingStatusEnum.cancelled) {
                            widget.onCancelReasonChanged?.call(
                              _cancelReasonController.text.trim(),
                            );
                          }
                          widget.onConfirm();
                        },
                        child: Center(
                          child: Text(
                            'save'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

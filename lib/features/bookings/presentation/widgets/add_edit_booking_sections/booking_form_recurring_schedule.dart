import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class BookingFormRecurringSchedule extends StatelessWidget {
  final TextEditingController dateController;
  final VoidCallback onPickDate;
  final void Function(String dayKey, bool isStart, String currentTimeStr)
      onPickRecurringTime;

  const BookingFormRecurringSchedule({
    super.key,
    required this.dateController,
    required this.onPickDate,
    required this.onPickRecurringTime,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.formState?.isOngoing != curr.formState?.isOngoing ||
          prev.formState?.recurrenceEndDate !=
              curr.formState?.recurrenceEndDate ||
          prev.formState?.recurringSchedules !=
              curr.formState?.recurringSchedules,
      builder: (context, state) {
        final form = state.formState;
        final isOngoing = form?.isOngoing ?? true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recurring: Start Date
            CustomTextFormField(
              controller: dateController,
              headerText: 'recurring_start_date'.tr(),
              hintText: 'اختر تاريخ بدء الاشتراك...',
              isReadOnly: true,
              isRequired: true,
              onTap: onPickDate,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'field_required'.tr();
                }
                return null;
              },
              prefixWidget: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: CustomAssetImage(
                  path: AppIcons.calendar,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Recurrence End Option ───────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.calendar,
                      width: 16,
                      height: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'recurrence_end_option'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Ongoing until cancelled
                    Expanded(
                      child: InkWell(
                        onTap: () => cubit.updateRecurrenceOngoing(true),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOngoing
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.grayf6,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isOngoing
                                  ? AppColors.primary
                                  : AppColors.grayE2E8F0,
                              width: isOngoing ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOngoing
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 18,
                                color: isOngoing
                                    ? AppColors.primary
                                    : AppColors.gray71717A,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ongoing_until_cancelled'.tr(),
                                  style:
                                      CustomAppFontStyle.medium12.copyWith(
                                    color: isOngoing
                                        ? AppColors.primary
                                        : AppColors.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ends on specific date
                    Expanded(
                      child: InkWell(
                        onTap: () => cubit.updateRecurrenceOngoing(false),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !isOngoing
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.grayf6,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isOngoing
                                  ? AppColors.primary
                                  : AppColors.grayE2E8F0,
                              width: !isOngoing ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                !isOngoing
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 18,
                                color: !isOngoing
                                    ? AppColors.primary
                                    : AppColors.gray71717A,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ends_on_specific_date'.tr(),
                                  style:
                                      CustomAppFontStyle.medium12.copyWith(
                                    color: !isOngoing
                                        ? AppColors.primary
                                        : AppColors.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // End Date Picker (shown only when NOT ongoing)
                if (!isOngoing) ...[
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: TextEditingController(
                      text: form?.recurrenceEndDate != null
                          ? BookingTimeFormatter.formatCompactDate(
                              form!.recurrenceEndDate!,
                              context,
                            )
                          : '',
                    ),
                    headerText: 'recurrence_end_date'.tr(),
                    hintText: 'اختر تاريخ انتهاء الاشتراك...',
                    isReadOnly: true,
                    isRequired: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: form?.recurrenceEndDate ??
                            DateTime.now().add(const Duration(days: 90)),
                        firstDate: form?.date ?? DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 3),
                        ),
                      );
                      if (picked != null) {
                        cubit.updateRecurrenceEndDate(picked);
                      }
                    },
                    validator: (val) {
                      if (!isOngoing && (val == null || val.trim().isEmpty)) {
                        return 'field_required'.tr();
                      }
                      return null;
                    },
                    prefixWidget: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: CustomAssetImage(
                        path: AppIcons.calendar,
                        width: 18,
                        height: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Recurring Days Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.calendar,
                      width: 16,
                      height: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'recurring_days'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'select_recurring_days_hint'.tr(),
                  style: CustomAppFontStyle.regular12.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                const SizedBox(height: 12),

                // Day chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DayOfWeekOption.all.map((opt) {
                    final isSelected = form?.recurringSchedules
                            .any((s) => s.day == opt.key) ??
                        false;
                    return InkWell(
                      onTap: () => cubit.toggleRecurringDay(opt.key),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grayE2E8F0,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              opt.getName(context),
                              style: isSelected
                                  ? CustomAppFontStyle.semiBold13.copyWith(
                                      color: AppColors.white,
                                    )
                                  : CustomAppFontStyle.regular13.copyWith(
                                      color: AppColors.darkText,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Day schedule items with separate time slots
                if (form != null && form.recurringSchedules.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: form.recurringSchedules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sched = form.recurringSchedules[index];
                      final dayOpt = DayOfWeekOption.fromKey(sched.day);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.grayf6,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.grayE2E8F0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Day badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dayOpt.getName(context),
                                style: CustomAppFontStyle.semiBold12.copyWith(
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Start Time Button
                            Expanded(
                              child: InkWell(
                                onTap: () => onPickRecurringTime(
                                  sched.day,
                                  true,
                                  sched.startTime,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          sched.startTime.isNotEmpty
                                              ? BookingTimeFormatter
                                                  .formatSingleTime(
                                                  sched.startTime,
                                                  context,
                                                )
                                              : 'start_time'.tr(),
                                          style: CustomAppFontStyle.medium12
                                              .copyWith(
                                            color: AppColors.darkText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: AppColors.gray71717A,
                              ),
                            ),

                            // End Time Button
                            Expanded(
                              child: InkWell(
                                onTap: () => onPickRecurringTime(
                                  sched.day,
                                  false,
                                  sched.endTime,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.grayE2E8F0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.access_time_filled,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          sched.endTime.isNotEmpty
                                              ? BookingTimeFormatter
                                                  .formatSingleTime(
                                                  sched.endTime,
                                                  context,
                                                )
                                              : 'end_time'.tr(),
                                          style: CustomAppFontStyle.medium12
                                              .copyWith(
                                            color: AppColors.darkText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Remove Day Button
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () =>
                                  cubit.toggleRecurringDay(sched.day),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grayf6,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.grayE2E8F0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'recurring_days_empty_error'.tr(),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

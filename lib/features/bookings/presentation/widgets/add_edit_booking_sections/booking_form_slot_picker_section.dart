import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/enums/slot_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/time_slot_model.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_availability_enum.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_availability_helper.dart';
import 'package:eyadty/features/doctors/presentation/widgets/dialogs/doctor_schedule_editor_dialog.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/app_date_time_picker.dart';

class BookingFormSlotPickerSection extends StatelessWidget {
  const BookingFormSlotPickerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.formState != curr.formState ||
          prev.slotsStatus != curr.slotsStatus ||
          prev.availableSlots != curr.availableSlots ||
          prev.selectedDayAvailability != curr.selectedDayAvailability ||
          prev.hasPatientTimeConflict != curr.hasPatientTimeConflict ||
          prev.hasPatientSameDayNotice != curr.hasPatientSameDayNotice ||
          prev.isPatientConflictConfirmed != curr.isPatientConflictConfirmed,
      builder: (context, state) {
        final cubit = context.read<BookingsCubit>();
        final form = state.formState;
        final hasDoctor =
            form != null && form.technicians.isNotEmpty;
        final hasService =
            form != null && form.serviceId != null && form.serviceId!.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── عنوان القسم ───────────────────────────────────────────────
            Row(
              children: [
                const CustomAssetImage(
                  path: AppIcons.calendar,
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'slot_picker_title'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: context.themeColors.textPrimary,
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

            // ─── شريط الأيام (14 يوم قادم) ──────────────────────────────────
            _buildDaysStrip(
              context,
              cubit,
              state,
              isEnabled: hasDoctor && hasService,
            ),
            const SizedBox(height: 14),

            // ─── تنبيهات توجيهية (طبيب / دوام / تعارض) ─────────────
            if (hasDoctor &&
                hasService &&
                state.selectedDayAvailability ==
                    DoctorAvailabilityEnum.noSchedule)
              _buildNoScheduleBanner(context, cubit, state)
            else if (hasDoctor && hasService) ...[
              // تنبيه تعارض موعد المريض
              if (state.hasPatientTimeConflict)
                _buildPatientConflictWarning(context, cubit, state)
              else if (state.hasPatientSameDayNotice)
                _buildPatientSameDayNotice(context, state),

              const SizedBox(height: 10),

              // ─── شبكة الفترات (صباحي / مسائي) ───────────────────────────
              _buildSlotsContent(context, cubit, state),
            ],

            // ─── ملخص الموعد المختار ────────────────────────────────────────
            if (form != null && form.startTime.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildSelectedSlotSummary(context, form),
            ],
          ],
        );
      },
    );
  }

  // ─── 1. شريط الأيام ────────────────────────────────────────────────────────
  Widget _buildDaysStrip(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state, {
    required bool isEnabled,
  }) {
    final colors = context.themeColors;
    if (!isEnabled) {
      return Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: colors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'select_doctor_and_service_first_hint'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final today = DoctorAvailabilityHelper.getTodayCairo();
    final next14Days = List.generate(14, (i) => today.add(Duration(days: i)));
    final selectedDate = state.formState?.date ?? today;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: next14Days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = next14Days[index];
                  final isSelected =
                      CairoTimeHelper.isSameDay(date, selectedDate);

                  final availability =
                      DoctorAvailabilityHelper.getDayAvailability(
                    schedule: state.currentDoctorSchedule,
                    leaves: state.currentDoctorLeaves,
                    holidays: state.facilityHolidays,
                    date: date,
                  );

                  return _buildDayCard(
                    context: context,
                    date: date,
                    isSelected: isSelected,
                    availability: availability,
                    onTap: () => cubit.updateFormDate(date),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // زر اختيار تاريخ مخصص
          Tooltip(
            message: 'pick_another_date'.tr(),
            child: InkWell(
              onTap: () async {
                final picked = await showAppDatePicker(
                  context,
                  initial: selectedDate,
                  firstDate: today,
                  lastDate: today.add(const Duration(days: 90)),
                  title: 'اختيار موعد الحجز',
                  allowFuture: true,
                );
                if (picked != null) {
                  cubit.updateFormDate(picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 82,
                decoration: BoxDecoration(
                  color: context.themeColors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.themeColors.borderSubtle),
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: context.themeColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required DateTime date,
    required bool isSelected,
    required DoctorAvailabilityEnum availability,
    required VoidCallback onTap,
  }) {
    final colors = context.themeColors;
    final isAvailable = availability == DoctorAvailabilityEnum.available;

    Color badgeBg;
    Color badgeText;
    String badgeKey;

    switch (availability) {
      case DoctorAvailabilityEnum.available:
        badgeBg = AppColors.success.withValues(alpha: 0.12);
        badgeText = AppColors.success;
        badgeKey = 'slot_available';
        break;
      case DoctorAvailabilityEnum.onLeave:
        badgeBg = AppColors.warning.withValues(alpha: 0.15);
        badgeText = AppColors.warning;
        badgeKey = 'on_leave';
        break;
      case DoctorAvailabilityEnum.facilityHoliday:
        badgeBg = AppColors.lightBlue;
        badgeText = AppColors.blue;
        badgeKey = 'facility_holiday';
        break;
      case DoctorAvailabilityEnum.notWorkingDay:
        badgeBg = colors.surfaceLevel1;
        badgeText = colors.textSecondary;
        badgeKey = 'off_day';
        break;
      case DoctorAvailabilityEnum.noSchedule:
        badgeBg = AppColors.warning.withValues(alpha: 0.1);
        badgeText = AppColors.warning;
        badgeKey = 'no_schedule';
        break;
    }

    final dayName = BookingTimeFormatter.formatDayName(date, context);
    final dayNum = '${date.day}';

    final card = InkWell(
      onTap: isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : (isAvailable ? colors.borderSubtle : colors.borderSubtle.withValues(alpha: 0.5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomAppFontStyle.medium11.copyWith(
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: CustomAppFontStyle.bold14.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeKey.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomAppFontStyle.semiBold10.copyWith(
                  color: badgeText,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!isAvailable) {
      return Tooltip(
        message: badgeKey.tr(),
        child: Opacity(opacity: 0.6, child: card),
      );
    }

    return card;
  }

  // ─── 2. شبكة الفترات ──────────────────────────────────────────────────────
  Widget _buildSlotsContent(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    if (state.slotsStatus == RequestStatusEnum.loading) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (state.slotsStatus == RequestStatusEnum.failure) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.slotsErrMessage ?? 'slot_already_booked_or_unavailable'.tr(),
                style: CustomAppFontStyle.regular12.copyWith(color: AppColors.error),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.error),
              onPressed: () => cubit.loadSlotsForCurrentForm(forceRefresh: true),
            ),
          ],
        ),
      );
    }

    final slots = state.availableSlots;
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.grayf6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'no_available_slots_on_day'.tr(),
          style: CustomAppFontStyle.medium13.copyWith(
            color: AppColors.gray71717A,
          ),
        ),
      );
    }

    final morningSlots = slots.where((s) => s.isMorning == true).toList();
    final eveningSlots = slots.where((s) => s.isMorning != true).toList();
    final selectedStartTime = state.formState?.startTime ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (morningSlots.isNotEmpty) ...[
          _buildTimeGroupHeader(
            context,
            title: 'morning_slots'.tr(),
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 8),
          _buildSlotGrid(context, cubit, morningSlots, selectedStartTime),
          const SizedBox(height: 14),
        ],
        if (eveningSlots.isNotEmpty) ...[
          _buildTimeGroupHeader(
            context,
            title: 'evening_slots'.tr(),
            icon: Icons.nightlight_outlined,
          ),
          const SizedBox(height: 8),
          _buildSlotGrid(context, cubit, eveningSlots, selectedStartTime),
          const SizedBox(height: 12),
        ],

        // مفتاح الألوان (Legend)
        _buildLegend(context),
      ],
    );
  }

  Widget _buildTimeGroupHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: CustomAppFontStyle.semiBold12.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotGrid(
    BuildContext context,
    BookingsCubit cubit,
    List<TimeSlotModel> slots,
    String selectedStartTime,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = slot.startTime == selectedStartTime;
        return _buildSlotChip(
          context: context,
          slot: slot,
          isSelected: isSelected,
          onTap: () => cubit.selectTimeSlot(slot),
        );
      }).toList(),
    );
  }

  Widget _buildSlotChip({
    required BuildContext context,
    required TimeSlotModel slot,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.themeColors;
    final status = slot.status ?? SlotStatusEnum.available;
    final isClickable = slot.isAvailable || slot.isCurrentBookingSlot == true;

    Color bg;
    Color border;
    Color text;
    Widget? icon;
    String tooltipMsg = '';

    if (isSelected) {
      bg = colors.primary;
      border = colors.primary;
      text = Colors.white;
      icon = const Icon(Icons.check, size: 14, color: Colors.white);
      tooltipMsg = 'selected_slot_summary'.tr();
    } else if (slot.isCurrentBookingSlot == true) {
      bg = colors.primary.withValues(alpha: 0.12);
      border = colors.primary;
      text = colors.primary;
      tooltipMsg = 'current_appointment'.tr();
    } else {
      switch (status) {
        case SlotStatusEnum.available:
          bg = colors.surfaceLevel1;
          border = colors.borderSubtle;
          text = colors.textPrimary;
          tooltipMsg = 'slot_available'.tr();
          break;
        case SlotStatusEnum.booked:
          bg = colors.cardBackground;
          border = colors.borderSubtle;
          text = colors.textSecondary.withValues(alpha: 0.6);
          icon = Icon(Icons.lock_outline, size: 12, color: colors.textSecondary);
          tooltipMsg = '${'slot_booked'.tr()}: ${slot.bookedPatientName ?? ''}';
          break;
        case SlotStatusEnum.past:
          bg = colors.cardBackground;
          border = colors.borderSubtle.withValues(alpha: 0.5);
          text = colors.textSecondary.withValues(alpha: 0.4);
          icon = Icon(Icons.history, size: 12, color: colors.textSecondary);
          tooltipMsg = 'slot_past'.tr();
          break;
        case SlotStatusEnum.breakTime:
          bg = AppColors.warning.withValues(alpha: 0.12);
          border = AppColors.warning.withValues(alpha: 0.3);
          text = AppColors.warning;
          icon = const Icon(Icons.coffee_outlined, size: 12, color: AppColors.warning);
          tooltipMsg = 'slot_break_time'.tr();
          break;
        case SlotStatusEnum.insufficientTime:
          bg = colors.cardBackground;
          border = colors.borderSubtle;
          text = colors.textSecondary.withValues(alpha: 0.4);
          icon = Icon(Icons.hourglass_empty, size: 12, color: colors.textSecondary);
          tooltipMsg = 'slot_insufficient_time'.tr();
          break;
      }
    }

    final formattedTime =
        BookingTimeFormatter.formatSingleTime(slot.startTime, context);

    final chip = InkWell(
      onTap: isClickable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 4),
            ],
            Text(
              formattedTime,
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: text,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (slot.isCurrentBookingSlot == true && !isSelected) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'current_appointment'.tr(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Tooltip(
      message: tooltipMsg,
      child: chip,
    );
  }

  // ─── 3. مفتاح الألوان (Legend) ─────────────────────────────────────────────
  Widget _buildLegend(BuildContext context) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _buildLegendItem('slot_available'.tr(), AppColors.success, colors),
          _buildLegendItem('slot_booked'.tr(), colors.textSecondary, colors),
          _buildLegendItem('slot_break_time'.tr(), AppColors.warning, colors),
          _buildLegendItem('slot_past'.tr(), colors.borderSubtle, colors),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, AppThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: CustomAppFontStyle.regular10.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  // ─── 4. ملخص الموعد المختار ────────────────────────────────────────────────
  Widget _buildSelectedSlotSummary(
    BuildContext context,
    BookingFormState form,
  ) {
    final startTimeStr =
        BookingTimeFormatter.formatSingleTime(form.startTime, context);
    final endTimeStr =
        BookingTimeFormatter.formatSingleTime(form.endTime, context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$startTimeStr - $endTimeStr',
                style: CustomAppFontStyle.bold13.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${form.durationMinutes} ${'minutes'.tr()}',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: context.themeColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${form.consultationFee} ${'currency'.tr()}',
                style: CustomAppFontStyle.bold13.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. تنبيه عدم تحديد دوام مع اختصار للمدير ──────────────────────────────
  Widget _buildNoScheduleBanner(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    final session = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().state
        : null;
    final isAdmin = session?.currentRole == UserRoleEnum.admin;
    final doctorId =
        state.formState?.technicians.isNotEmpty == true
            ? state.formState!.technicians.first.id
            : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'doctor_no_schedule_hint'.tr(),
              style: CustomAppFontStyle.medium12.copyWith(color: context.themeColors.textPrimary),
            ),
          ),
          if (isAdmin && doctorId != null) ...[
            const SizedBox(width: 8),
            CustomPushButton(
              onTap: () {
                DoctorScheduleEditorDialog.show(
                  context: context,
                  doctorId: doctorId,
                  doctorName: state.formState?.technicians.first.name ?? '',
                );
              },
              backgroundColor: AppColors.primary,
              height: 32,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'configure_doctor_schedule'.tr(),
                  style: CustomAppFontStyle.semiBold11.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 6. تنبيهات تعارض المريض ───────────────────────────────────────────────
  Widget _buildPatientConflictWarning(
    BuildContext context,
    BookingsCubit cubit,
    BookingsState state,
  ) {
    final b = state.patientConflictingBooking;
    final docName = b?.doctorName ?? '';
    final timeStr = b != null
        ? '${BookingTimeFormatter.formatSingleTime(b.startTime, context)} - ${BookingTimeFormatter.formatSingleTime(b.endTime, context)}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${'patient_time_conflict_warning'.tr()} ($docName $timeStr)',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: state.isPatientConflictConfirmed,
                onChanged: (val) {
                  if (val == true) {
                    cubit.confirmPatientTimeConflict();
                  } else {
                    cubit.clearPatientTimeConflict();
                  }
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  'confirm_conflict_and_proceed'.tr(),
                  style: CustomAppFontStyle.medium11.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSameDayNotice(
    BuildContext context,
    BookingsState state,
  ) {
    final b = state.patientSameDayBooking;
    final docName = b?.doctorName ?? '';
    final timeStr = b != null
        ? BookingTimeFormatter.formatSingleTime(b.startTime, context)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${'patient_same_day_notice'.tr()} ($docName $timeStr)',
              style: CustomAppFontStyle.medium11.copyWith(color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

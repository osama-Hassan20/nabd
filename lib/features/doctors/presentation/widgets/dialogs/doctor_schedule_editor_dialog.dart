import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/doctors/data/models/doctor_break_time_model.dart';
import 'package:eyadty/features/doctors/data/models/enums/week_day_enum.dart';
import 'package:eyadty/features/doctors/domain/helpers/doctor_schedule_validator.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class DoctorScheduleEditorDialog extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final bool isFullScreen;
  final DoctorsCubit doctorsCubit;

  const DoctorScheduleEditorDialog({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.isFullScreen = false,
    required this.doctorsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String doctorId,
    required String doctorName,
    DoctorsCubit? doctorsCubit,
  }) async {
    DoctorsCubit? cubit = doctorsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<DoctorsCubit>();
      } catch (_) {
        cubit = getIt<DoctorsCubit>();
      }
    }

    await cubit.initScheduleForm(doctorId);

    if (!context.mounted) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: DoctorScheduleEditorDialog(
            doctorId: doctorId,
            doctorName: doctorName,
            isFullScreen: isMobile,
            doctorsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 860,
              maxHeight: 740,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<DoctorScheduleEditorDialog> createState() =>
      _DoctorScheduleEditorDialogState();
}

class _DoctorScheduleEditorDialogState
    extends State<DoctorScheduleEditorDialog> {
  late final TextEditingController _slotController;
  late final TextEditingController _bufferController;

  @override
  void initState() {
    super.initState();
    final form = widget.doctorsCubit.state.scheduleFormState;
    _slotController = TextEditingController(
      text: AppFormatterHelper.formatMinutes(form?.slotDurationMinutes ?? 20),
    );
    _bufferController = TextEditingController(
      text: AppFormatterHelper.formatMinutes(form?.bufferDurationMinutes ?? 5),
    );
  }

  @override
  void dispose() {
    _slotController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DoctorsCubit, DoctorsState>(
      listenWhen: (prev, curr) =>
          prev.scheduleActionStatus != curr.scheduleActionStatus ||
          prev.errMessage != curr.errMessage,
      listener: (context, state) {
        if (state.scheduleActionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: 'schedule_saved_successfully'.tr(),
          ).showTopToast();
          context.pop(true);
        } else if (state.scheduleActionStatus == RequestStatusEnum.failure) {
          final msg = state.errMessage != null
              ? state.errMessage!.tr()
              : 'error_occurred'.tr();
          CustomToast(
            context: context,
            header: msg,
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final form = state.scheduleFormState;
        final cubit = context.read<DoctorsCubit>();

        return PopScope(
          canPop: form == null || !form.hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _confirmDiscard(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.circular(widget.isFullScreen ? 0 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, form),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                if (form == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopControls(context, cubit, form),
                          const SizedBox(height: 24),
                          _buildWorkDaysSection(context, cubit, form),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 1, color: AppColors.grayE2E8F0),
                _buildFooter(context, cubit, form, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DoctorScheduleFormState? form) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.calendar,
              width: 18,
              height: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'edit_schedule'.tr(),
                  style: CustomAppFontStyle.semiBold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.doctorName,
                  style: CustomAppFontStyle.regular13.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (form != null && form.hasUnsavedChanges) {
                _confirmDiscard(context);
              } else {
                context.pop();
              }
            },
            icon: const Icon(Icons.close, color: AppColors.gray71717A),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    DoctorsCubit cubit,
    DoctorScheduleFormState form,
  ) {
    final slotOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120];
    final bufferOptions = [0, 5, 10, 15, 20, 30];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grayf6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Slot Duration
          SizedBox(
            width: 220,
            child: CustomStackSelector<int>(
              header: 'slot_duration'.tr(),
              controller: _slotController,
              list: slotOptions,
              itemAsString: (v) =>
                  AppFormatterHelper.formatMinutes(v, context: context),
              changeValue: (val) {
                cubit.updateScheduleSlotDuration(val);
                _slotController.text =
                    AppFormatterHelper.formatMinutes(val, context: context);
              },
            ),
          ),

          // Buffer Duration
          SizedBox(
            width: 220,
            child: CustomStackSelector<int>(
              header: 'buffer_duration'.tr(),
              controller: _bufferController,
              list: bufferOptions,
              itemAsString: (v) =>
                  AppFormatterHelper.formatMinutes(v, context: context),
              changeValue: (val) {
                cubit.updateScheduleBufferDuration(val);
                _bufferController.text =
                    AppFormatterHelper.formatMinutes(val, context: context);
              },
            ),
          ),

          // Walk-in Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'accepts_walk_ins'.tr(),
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: form.isAcceptingWalkIns,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => cubit.updateScheduleWalkIns(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDaysSection(
    BuildContext context,
    DoctorsCubit cubit,
    DoctorScheduleFormState form,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'work_days'.tr(),
              style: CustomAppFontStyle.semiBold16.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${'saturday'.tr()} ← ${'friday'.tr()})',
              style: CustomAppFontStyle.regular12.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 7 Day rows in Egyptian week order: Saturday -> Friday
        ...WeekDayEnum.values.map((day) {
          final dayState = form.workDays[day] ??
              WorkDayFormState(dayOfWeek: day);
          return _buildDayRow(context, cubit, form, day, dayState);
        }),
      ],
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    DoctorsCubit cubit,
    DoctorScheduleFormState form,
    WeekDayEnum day,
    WorkDayFormState dayState,
  ) {
    final isWorking = dayState.isWorking;
    final hasError = dayState.errorMessage != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWorking ? AppColors.white : AppColors.grayf6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isWorking ? AppColors.primary.withValues(alpha: 0.25) : AppColors.grayE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Switch: Day on/off
              Switch(
                value: isWorking,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => cubit.toggleDayWorking(day, val),
              ),
              const SizedBox(width: 10),
              // Day Name
              SizedBox(
                width: 90,
                child: Text(
                  day.translationKey.tr(),
                  style: CustomAppFontStyle.semiBold15.copyWith(
                    color: isWorking ? AppColors.darkText : AppColors.gray71717A,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              if (isWorking) ...[
                // Start Time
                _buildTimeButton(
                  context: context,
                  label: 'from'.tr(),
                  time24: dayState.startTime,
                  onPicked: (newTime) {
                    cubit.updateDayHours(day, newTime, dayState.endTime);
                  },
                ),
                const SizedBox(width: 8),
                // End Time
                _buildTimeButton(
                  context: context,
                  label: 'to'.tr(),
                  time24: dayState.endTime,
                  onPicked: (newTime) {
                    cubit.updateDayHours(day, dayState.startTime, newTime);
                  },
                ),
                const Spacer(),

                // Copy this day to other working days button
                CustomPushButton(
                  height: 32,
                  backgroundColor: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  onTap: () {
                    cubit.copyDayToOtherWorkDays(day);
                    CustomToast(
                      context: context,
                      header: 'day_copied_successfully'.tr(),
                    ).showTopToast();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'copy_to_other_days'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayE2E8F0,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'off_day'.tr(),
                    style: CustomAppFontStyle.medium12.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Working day breaks section
          if (isWorking) ...[
            const SizedBox(height: 10),
            _buildBreaksSubSection(context, cubit, day, dayState),
          ],

          // Error message banner if any
          if (hasError) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 15,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dayState.errorMessage!.tr(),
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton({
    required BuildContext context,
    required String label,
    required String time24,
    required void Function(String) onPicked,
  }) {
    final displayTime = BookingTimeFormatter.formatSingleTime(time24, context);

    return InkWell(
      onTap: () => _pickTime(
        context: context,
        initialTime: time24,
        onPicked: onPicked,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.grayf6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: CustomAppFontStyle.regular12.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
            Text(
              displayTime,
              style: CustomAppFontStyle.semiBold13.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(width: 4),
            const CustomAssetImage(
              path: AppIcons.clock,
              width: 14,
              height: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreaksSubSection(
    BuildContext context,
    DoctorsCubit cubit,
    WeekDayEnum day,
    WorkDayFormState dayState,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.grayf6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'breaks'.tr(),
                style: CustomAppFontStyle.medium12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(width: 8),
              if (dayState.breaks.isNotEmpty)
                Text(
                  '(${dayState.breaks.length})',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              const Spacer(),
              CustomPushButton(
                height: 26,
                backgroundColor: AppColors.white,
                borderRadius: BorderRadius.circular(6),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onTap: () => _showAddBreakDialog(context, cubit, day, dayState),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.add,
                      width: 11,
                      height: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'add_break'.tr(),
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dayState.breaks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < dayState.breaks.length; i++)
                  _buildBreakChip(context, cubit, day, i, dayState.breaks[i]),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakChip(
    BuildContext context,
    DoctorsCubit cubit,
    WeekDayEnum day,
    int index,
    DoctorBreakTimeModel b,
  ) {
    final rangeStr = BookingTimeFormatter.formatTimeRange(
      b.startTime,
      b.endTime,
      context,
    );
    final nameStr = (b.name != null && b.name!.isNotEmpty)
        ? '${b.name} ($rangeStr)'
        : rangeStr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.coffee_outlined,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            nameStr,
            style: CustomAppFontStyle.medium12.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => cubit.removeDayBreak(day, index),
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    DoctorsCubit cubit,
    DoctorScheduleFormState? form,
    DoctorsState state,
  ) {
    final isValid = form?.isValid ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomPushButton(
            height: 42,
            width: 100,
            backgroundColor: AppColors.grayf2,
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (form != null && form.hasUnsavedChanges) {
                _confirmDiscard(context);
              } else {
                context.pop();
              }
            },
            child: Text(
              'cancel'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CustomPushButton(
            height: 42,
            width: 140,
            backgroundColor: isValid ? AppColors.primary : AppColors.grayE2E8F0,
            isLoading: state.scheduleActionStatus == RequestStatusEnum.loading,
            borderRadius: BorderRadius.circular(8),
            onTap: isValid ? () => cubit.saveSchedule() : null,
            child: Text(
              'save'.tr(),
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: isValid ? AppColors.white : AppColors.gray71717A,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required String initialTime,
    required void Function(String newTime) onPicked,
  }) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPicked('$h:$m');
    }
  }

  void _showAddBreakDialog(
    BuildContext context,
    DoctorsCubit cubit,
    WeekDayEnum day,
    WorkDayFormState dayState,
  ) {
    String start = dayState.startTime;
    // Default break: 1 hour inside day
    final startMin = DoctorScheduleValidator.timeToMinutes(start) ?? 540;
    final bStartMin = startMin + 180; // 3 hours in
    final bEndMin = bStartMin + 60;   // 1 hour break

    final bStartH = (bStartMin ~/ 60).toString().padLeft(2, '0');
    final bStartM = (bStartMin % 60).toString().padLeft(2, '0');
    final bEndH = (bEndMin ~/ 60).toString().padLeft(2, '0');
    final bEndM = (bEndMin % 60).toString().padLeft(2, '0');

    String chosenStart = '$bStartH:$bStartM';
    String chosenEnd = '$bEndH:$bEndM';
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'add_break'.tr(),
                style: CustomAppFontStyle.semiBold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'break_name'.tr(),
                      hintText: 'break_name_hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _pickTime(
                              context: dialogCtx,
                              initialTime: chosenStart,
                              onPicked: (t) {
                                setModalState(() => chosenStart = t);
                              },
                            );
                          },
                          child: Text(
                            '${'from'.tr()}: ${BookingTimeFormatter.formatSingleTime(chosenStart, context)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _pickTime(
                              context: dialogCtx,
                              initialTime: chosenEnd,
                              onPicked: (t) {
                                setModalState(() => chosenEnd = t);
                              },
                            );
                          },
                          child: Text(
                            '${'to'.tr()}: ${BookingTimeFormatter.formatSingleTime(chosenEnd, context)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    cubit.addDayBreak(
                      day,
                      DoctorBreakTimeModel(
                        name: nameController.text.trim().isEmpty
                            ? null
                            : nameController.text.trim(),
                        startTime: chosenStart,
                        endTime: chosenEnd,
                      ),
                    );
                  },
                  child: Text(
                    'add_item'.tr(),
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDiscard(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'unsaved_changes_warning'.tr(),
          style: CustomAppFontStyle.semiBold16.copyWith(
            color: AppColors.darkText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: Text(
              'discard'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

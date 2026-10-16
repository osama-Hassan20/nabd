import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class WorkingScheduleTab extends StatefulWidget {
  final SettingsCubit settingsCubit;

  const WorkingScheduleTab({super.key, required this.settingsCubit});

  @override
  State<WorkingScheduleTab> createState() => _WorkingScheduleTabState();
}

class _WorkingScheduleTabState extends State<WorkingScheduleTab> {
  late String _openingTime;
  late String _closingTime;

  static const List<String> _daysList = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  void initState() {
    super.initState();
    final state = widget.settingsCubit.state;
    _openingTime = state.openingTime;
    _closingTime = state.closingTime;
  }

  @override
  void didUpdateWidget(covariant WorkingScheduleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = widget.settingsCubit.state;
    _openingTime = state.openingTime;
    _closingTime = state.closingTime;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _displayTime(BuildContext context, String timeStr) {
    final time = _parseTime(timeStr);
    return time.format(context);
  }

  Future<void> _pickTime({
    required bool isOpening,
    required BuildContext context,
  }) async {
    final initial = _parseTime(isOpening ? _openingTime : _closingTime);
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
      setState(() {
        if (isOpening) {
          _openingTime = _formatTimeOfDay(picked);
        } else {
          _closingTime = _formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _handleSave() async {
    final success = await widget.settingsCubit.saveWorkingSchedule(
      openingTime: _openingTime,
      closingTime: _closingTime,
    );

    if (mounted) {
      if (success) {
        CustomToast(
          context: context,
          header: 'settings_saved_successfully'.tr(),
        ).showTopToast();
      } else {
        CustomToast(
          context: context,
          header: 'failed_to_load'.tr(),
        ).showErrorToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Weekly Working Days Section ──────────────────────────────
              CustomContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const CustomAssetImage(
                            path: AppIcons.calendar,
                            width: 20,
                            height: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'working_days'.tr(),
                          style: CustomAppFontStyle.semiBold18.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'working_days_desc'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grayE2E8F0),
                    const SizedBox(height: 20),

                    // Days Chips Grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _daysList.map((dayKey) {
                        final isSelected = state.workingDays.contains(dayKey);
                        return InkWell(
                          onTap: () =>
                              widget.settingsCubit.toggleWorkingDay(dayKey),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.grayf6,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grayE2E8F0,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.gray7A828E,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dayKey.tr(),
                                  style: CustomAppFontStyle.semiBold14.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Daily Working Hours Section ──────────────────────────────
              CustomContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const CustomAssetImage(
                            path: AppIcons.hours24,
                            width: 20,
                            height: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'working_hours'.tr(),
                          style: CustomAppFontStyle.semiBold18.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grayE2E8F0),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeTile(
                            context: context,
                            label: 'opening_time'.tr(),
                            timeStr: _openingTime,
                            onTap: () =>
                                _pickTime(isOpening: true, context: context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimeTile(
                            context: context,
                            label: 'closing_time'.tr(),
                            timeStr: _closingTime,
                            onTap: () =>
                                _pickTime(isOpening: false, context: context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: CustomPushButton(
                          height: 44,
                          backgroundColor: AppColors.primary,
                          isLoading: isLoading,
                          borderRadius: BorderRadius.circular(8),
                          onTap: isLoading ? null : _handleSave,
                          child: Center(
                            child: Text(
                              'save_changes'.tr(),
                              style: CustomAppFontStyle.semiBold14.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required String label,
    required String timeStr,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CustomAppFontStyle.semiBold14.copyWith(
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.clock,
                      width: 18,
                      height: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _displayTime(context, timeStr),
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

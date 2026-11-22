import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class NotificationsTab extends StatefulWidget {
  final SettingsCubit settingsCubit;

  const NotificationsTab({super.key, required this.settingsCubit});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late bool _enabled;
  late int _reminderMinutes;

  static const List<int> _reminderOptions = [15, 30, 60, 120, 240];

  @override
  void initState() {
    super.initState();
    final state = widget.settingsCubit.state;
    _enabled = state.notificationEnabled;
    _reminderMinutes = state.reminderMinutesBefore;
  }

  @override
  void didUpdateWidget(covariant NotificationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = widget.settingsCubit.state;
    _enabled = state.notificationEnabled;
    _reminderMinutes = state.reminderMinutesBefore;
  }

  Future<void> _handleSave() async {
    final success = await widget.settingsCubit.saveNotificationSettings(
      enabled: _enabled,
      reminderMinutes: _reminderMinutes,
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
    final colors = context.themeColors;
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: CustomContainer(
            padding: const EdgeInsets.all(24),
            backGroundColor: colors.cardBackground,
            border: Border.all(color: colors.borderSubtle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomAssetImage(
                        path: AppIcons.notification,
                        width: 20,
                        height: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'tab_notifications'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'enable_booking_reminders_desc'.tr(),
                  style: CustomAppFontStyle.regular14.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: colors.borderSubtle),
                const SizedBox(height: 24),

                // Switch Row
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'enable_booking_reminders'.tr(),
                              style: CustomAppFontStyle.semiBold16.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'إرسال إشعار تلقائي قبل موعد الزيارة المحدد في الحجز.',
                              style: CustomAppFontStyle.regular13.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        activeThumbColor: colors.primary,
                        onChanged: (val) {
                          setState(() {
                            _enabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (_enabled) ...[
                  const SizedBox(height: 24),
                  Text(
                    'reminder_lead_time'.tr(),
                    style: CustomAppFontStyle.semiBold14.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _reminderOptions.map((minutes) {
                      final isSelected = _reminderMinutes == minutes;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _reminderMinutes = minutes;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryLight
                                : colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$minutes ${'minutes'.tr()}',
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: isSelected
                                  ? colors.primary
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 32),

                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: colors.primary,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: isLoading ? null : _handleSave,
                      child: Center(
                        child: Text(
                          'save_changes'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

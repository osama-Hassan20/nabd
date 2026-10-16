import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/settings/data/models/special_holiday_model.dart';
import 'package:purexo/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:purexo/features/settings/presentation/cubit/settings_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_toast.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';

class DeleteHolidayDialog extends StatelessWidget {
  final SpecialHolidayModel holiday;
  final bool isFullScreen;
  final SettingsCubit settingsCubit;

  const DeleteHolidayDialog({
    super.key,
    required this.holiday,
    this.isFullScreen = false,
    required this.settingsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required SpecialHolidayModel holiday,
    SettingsCubit? settingsCubit,
  }) {
    SettingsCubit? cubit = settingsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<SettingsCubit>();
      } catch (_) {
        cubit = getIt<SettingsCubit>();
      }
    }
    cubit.initDeleteHoliday(holiday);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: DeleteHolidayDialog(
            holiday: holiday,
            isFullScreen: isMobile,
            settingsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: settingsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isFullScreen ? 0 : 16),
            border: isFullScreen
                ? null
                : Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize: isFullScreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.red1A,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CustomAssetImage(
                          path: AppIcons.delete,
                          width: 24,
                          height: 24,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'delete_holiday'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: AppColors.darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'confirm_delete_holiday'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: AppColors.gray7A828E,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (holiday.name != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grayf6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          holiday.name!,
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: AppColors.grayf2,
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Text(
                            'cancel'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.grayMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: AppColors.error,
                        isLoading: isLoading,
                        borderRadius: BorderRadius.circular(8),
                        onTap: isLoading
                            ? null
                            : () async {
                                final success = await settingsCubit
                                    .confirmDeleteHoliday();
                                if (context.mounted) {
                                  if (success) {
                                    CustomToast(
                                      context: context,
                                      header: 'holiday_deleted_successfully'
                                          .tr(),
                                    ).showTopToast();
                                    Navigator.of(context).pop(true);
                                  } else {
                                    CustomToast(
                                      context: context,
                                      header: 'failed_to_load'.tr(),
                                    ).showErrorToast();
                                  }
                                }
                              },
                        child: Center(
                          child: Text(
                            'delete'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.white,
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

        if (isFullScreen) {
          return Scaffold(backgroundColor: AppColors.white, body: content);
        }

        return content;
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_cubit.dart';
import 'package:eyadty/core/cubits/local_passcode/local_passcode_state.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import '../dialogs/local_passcode_dialogs.dart';

class SecurityPrivacyTab extends StatelessWidget {
  const SecurityPrivacyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalPasscodeCubit, LocalPasscodeState>(
      bloc: getIt<LocalPasscodeCubit>(),
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section Title
                Text(
                  'tab_security_privacy'.tr(),
                  style: CustomAppFontStyle.bold18.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'local_passcode_desc'.tr(),
                  style: CustomAppFontStyle.regular14.copyWith(
                    color: AppColors.gray71717A,
                  ),
                ),
                const SizedBox(height: 20),

                // Security Card
                CustomContainer(
                  padding: const EdgeInsets.all(20),
                  border: Border.all(color: AppColors.grayE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  backGroundColor: AppColors.white,
                  child: Column(
                    children: [
                      // Local Passcode Row
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (state.isEnabled) {
                            ManageLocalPasscodeDialog.show(context);
                          } else {
                            CreateLocalPasscodeDialog.show(context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: state.isEnabled
                                      ? AppColors.primaryLight
                                      : AppColors.fillDisableColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  state.isEnabled
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  color: state.isEnabled
                                      ? AppColors.primary
                                      : AppColors.gray71717A,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'local_passcode_title'.tr(),
                                      style: CustomAppFontStyle.semiBold16.copyWith(
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'create_local_passcode_desc'.tr(),
                                      style: CustomAppFontStyle.regular12.copyWith(
                                        color: AppColors.gray71717A,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: state.isEnabled
                                      ? const Color(0xFFDCFCE7) // Soft Green
                                      : AppColors.fillDisableColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  state.isEnabled
                                      ? 'local_passcode_status_on'.tr()
                                      : 'local_passcode_status_off'.tr(),
                                  style: CustomAppFontStyle.semiBold13.copyWith(
                                    color: state.isEnabled
                                        ? const Color(0xFF15803D)
                                        : AppColors.gray71717A,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: AppColors.gray71717A,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

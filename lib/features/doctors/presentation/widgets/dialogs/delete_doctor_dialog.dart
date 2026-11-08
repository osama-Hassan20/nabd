import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class DeleteDoctorDialog extends StatelessWidget {
  final DoctorModel doctor;
  final bool isFullScreen;
  final DoctorsCubit doctorsCubit;

  const DeleteDoctorDialog({
    super.key,
    required this.doctor,
    this.isFullScreen = false,
    required this.doctorsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    required DoctorModel doctor,
    DoctorsCubit? doctorsCubit,
  }) {
    DoctorsCubit? cubit = doctorsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<DoctorsCubit>();
      } catch (_) {
        cubit = getIt<DoctorsCubit>();
      }
    }

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: DeleteDoctorDialog(
            doctor: doctor,
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

  Future<void> _handleDelete(BuildContext context) async {
    final success = await doctorsCubit.deleteDoctor(doctor.id ?? '');

    if (!context.mounted) return;

    if (success) {
      CustomToast(
        context: context,
        header: 'doctor_deleted_successfully'.tr(),
      ).showTopToast();
      Navigator.of(context).pop(true);
    } else {
      final err = doctorsCubit.state.errMessage;
      CustomToast(
        context: context,
        header: err != null ? err.tr() : 'failed_to_load'.tr(),
      ).showErrorToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveBookings =
        (doctor.upcomingBookingsCount ?? 0) > 0 ||
        (doctor.todayTasksCount ?? 0) > 0;

    return BlocBuilder<DoctorsCubit, DoctorsState>(
      bloc: doctorsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isFullScreen ? 0 : 16),
            border: isFullScreen ? null : Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize: isFullScreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasActiveBookings
                          ? AppColors.warning.withValues(alpha: .1)
                          : AppColors.red1A,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomAssetImage(
                      path: hasActiveBookings ? AppIcons.warning : AppIcons.delete,
                      width: 22,
                      height: 22,
                      color: hasActiveBookings ? AppColors.warning : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'delete_doctor'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),
              if (hasActiveBookings) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.warning,
                        width: 18,
                        height: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'doctor_has_active_bookings_warning'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'delete_doctor_confirmation_desc'.tr(
                  namedArgs: {'name': doctor.name ?? ''},
                ),
                style: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray7A828E,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
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
                    flex: 2,
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: AppColors.error,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: isLoading ? null : () => _handleDelete(context),
                      child: Center(
                        child: Text(
                          'confirm_delete'.tr(),
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
        );

        if (isFullScreen) {
          return Scaffold(backgroundColor: AppColors.white, body: content);
        }

        return content;
      },
    );
  }
}


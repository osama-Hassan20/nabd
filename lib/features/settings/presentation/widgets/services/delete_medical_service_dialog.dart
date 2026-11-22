import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_state.dart';

class DeleteMedicalServiceDialog extends StatelessWidget {
  final MedicalServiceModel service;
  final MedicalServicesCubit cubit;

  const DeleteMedicalServiceDialog({
    super.key,
    required this.service,
    required this.cubit,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicalServiceModel service,
    required MedicalServicesCubit cubit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => DeleteMedicalServiceDialog(
        service: service,
        cubit: cubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<MedicalServicesCubit, MedicalServicesState>(
        listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == RequestStatusEnum.success) {
            CustomToast(
              context: context,
              header: 'service_deleted_successfully'.tr(),
            ).showTopToast();
            context.pop();
          } else if (state.actionStatus == RequestStatusEnum.failure) {
            final msg = state.errMessage != null && state.errMessage!.isNotEmpty
                ? state.errMessage!.tr()
                : 'cannot_delete_service_linked_to_bookings'.tr();
            CustomToast(
              context: context,
              header: msg,
            ).showErrorToast();
          }
        },
        builder: (context, state) {
          final isLoading = state.actionStatus == RequestStatusEnum.loading;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const CustomAssetImage(
                        path: AppIcons.delete,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'confirm_delete_medical_service_title'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'confirm_delete_medical_service_desc'.tr()}\n(${service.name ?? ''})',
                      textAlign: TextAlign.center,
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? Colors.amber.shade900.withValues(alpha: 0.2)
                            : AppColors.yellowPale,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.isDark
                              ? Colors.amber.shade700.withValues(alpha: 0.4)
                              : AppColors.yellowLight,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomAssetImage(
                            path: AppIcons.warning,
                            width: 16,
                            height: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'cannot_delete_service_linked_to_bookings'.tr(),
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: colors.isDark
                                    ? Colors.amber.shade200
                                    : AppColors.darkGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 40,
                          width: 100,
                          backgroundColor: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.pop(),
                          child: Center(
                            child: Text(
                              'cancel'.tr(),
                              style: CustomAppFontStyle.medium14.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomPushButton(
                          height: 40,
                          width: 110,
                          backgroundColor: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                          onTap: isLoading || service.id == null
                              ? () {}
                              : () => cubit.deleteService(service.id!),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    'delete'.tr(),
                                    style: CustomAppFontStyle.medium14.copyWith(
                                      color: AppColors.white,
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
          );
        },
      ),
    );
  }
}

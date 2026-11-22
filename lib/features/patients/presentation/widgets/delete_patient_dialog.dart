import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class DeletePatientDialog extends StatefulWidget {
  final PatientModel patient;

  const DeletePatientDialog({super.key, required this.patient});

  static Future<bool?> show({
    required BuildContext context,
    required PatientModel patient,
    PatientsCubit? patientsCubit,
  }) {
    PatientsCubit? cubit = patientsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<PatientsCubit>();
      } catch (_) {
        cubit = getIt<PatientsCubit>();
      }
    }
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit!,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DeletePatientDialog(patient: patient),
          ),
        ),
      ),
    );
  }

  @override
  State<DeletePatientDialog> createState() => _DeletePatientDialogState();
}

class _DeletePatientDialogState extends State<DeletePatientDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final hasActiveBookings = (patient.upcomingBookings ?? 0) > 0;
    final hasDebt = (patient.outstandingBalance ?? 0) > 0;

    return BlocConsumer<PatientsCubit, PatientsState>(
      listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: 'patient_deleted_successfully'.tr(),
          ).showTopToast();
          context.pop(true);
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: state.actionErrMessage ?? 'error_occurred'.tr(),
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;
        final colors = context.themeColors;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.red1A,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CustomAssetImage(
                        path: AppIcons.delete,
                        width: 22,
                        height: 22,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'archive_patient'.tr(),
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patient.name ?? '-',
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 16),

              Text(
                'archive_patient_confirm'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Reason input
              CustomTextFormField(
                controller: _reasonController,
                headerText: 'archive_reason_label'.tr(),
                hintText: 'archive_reason_hint'.tr(),
                isRequired: false,
              ),

              if (hasDebt) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red1A,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.money_off_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'cannot_archive_debt'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (hasActiveBookings) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.warning,
                        width: 16,
                        height: 16,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'cannot_archive_upcoming'.tr(),
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 42,
                    width: 100,
                    backgroundColor: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(false),
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
                    height: 42,
                    width: 130,
                    backgroundColor: AppColors.error,
                    isLoading: isLoading,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (patient.id != null) {
                        context.read<PatientsCubit>().archivePatient(
                          patient.id!,
                          reason: _reasonController.text.trim().isNotEmpty
                              ? _reasonController.text.trim()
                              : null,
                        );
                      }
                    },
                    child: Center(
                      child: Text(
                        'archive_patient'.tr(),
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

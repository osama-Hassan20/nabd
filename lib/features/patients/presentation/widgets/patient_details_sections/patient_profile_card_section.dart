import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/patients/data/models/enums/blood_group_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/function/launch_phone_whats_app.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import '../add_edit_patient_dialog.dart';
import '../delete_patient_dialog.dart';

class PatientProfileCardSection extends StatelessWidget {
  const PatientProfileCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);

    return BlocBuilder<PatientsCubit, PatientsState>(
      buildWhen: (prev, curr) =>
          prev.selectedPatient != curr.selectedPatient,
      builder: (context, state) {
        final patient = state.selectedPatient;
        if (patient == null) return const SizedBox.shrink();
        final colors = context.themeColors;

        final age = patient.calculateAgeYears();
        final genderText = patient.gender == GenderEnum.female
            ? 'gender_female'.tr()
            : (patient.gender == GenderEnum.male ? 'gender_male'.tr() : '');
        final hasBlood = patient.bloodGroup != null &&
            patient.bloodGroup != BloodGroupEnum.unknown;

        return CustomContainer(
          backGroundColor: colors.cardBackground,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: CustomAssetImage(
                        path: AppIcons.user,
                        width: 26,
                        height: 26,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                patient.name ?? '',
                                style: CustomAppFontStyle.bold18.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (hasBlood) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.red1A,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    patient.bloodGroup!.value,
                                    style:
                                        CustomAppFontStyle.semiBold12.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (patient.hasIncompleteProfile) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'incomplete_profile_badge'.tr(),
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: AppColors.amber,
                                  ),
                                ),
                              ),
                            ],
                            if (patient.isArchived == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grayf2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'archived_patient_badge'.tr(),
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: AppColors.gray71717A,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (patient.fileNumber != null) ...[
                              Text(
                                '${'file_number'.tr()}: ${patient.fileNumber}',
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const CustomAssetImage(
                              path: AppIcons.calendar,
                              width: 13,
                              height: 13,
                              color: AppColors.gray71717A,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${'patient_since'.tr()} ${patient.createdAt != null ? '${patient.createdAt!.year}/${patient.createdAt!.month.toString().padLeft(2, '0')}/${patient.createdAt!.day.toString().padLeft(2, '0')}' : '-'}",
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!isMobile) _buildActionButtons(context, state),
                ],
              ),

              if (isMobile) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context, state),
              ],

              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 16),

              // Contact, Location, and Clinical Info Chips
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  // Phone
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomAssetImage(
                          path: AppIcons.phone,
                          width: 14,
                          height: 14,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'patient_phone'.tr(),
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                EgyptianPhoneHelper.formatDisplay(patient.phone),
                                textDirection: TextDirection.ltr,
                                style: CustomAppFontStyle.medium13.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (patient.phoneHasWhatsapp == true) ...[
                                const SizedBox(width: 4),
                                const Tooltip(
                                  message: 'واتساب متوفر',
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Age & Gender
                  if (age != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'age'.tr(),
                              style: CustomAppFontStyle.regular11.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '$age ${'age_years'.tr()}${genderText.isNotEmpty ? ' • $genderText' : ''}',
                              style: CustomAppFontStyle.medium13.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Address
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomAssetImage(
                          path: AppIcons.location,
                          width: 14,
                          height: 14,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'patient_address'.tr(),
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            patient.address ?? '-',
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, PatientsState state) {
    final patient = state.selectedPatient;
    if (patient == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // WhatsApp (if patient has WhatsApp)
        if (patient.phoneHasWhatsapp == true)
          CustomPushButton(
            height: 38,
            backgroundColor: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            onTap: () {
              if (patient.phone != null && patient.phone!.isNotEmpty) {
                launchWhatsAppCall(
                  context: context,
                  phoneNumber: patient.phone!,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'whatsapp'.tr(),
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

        // New Booking for this patient
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            await AddEditBookingDialog.show(
              context: context,
              booking: BookingModel(
                patientId: patient.id,
                patientName: patient.name,
                patientPhone: patient.phone,
              ),
            );
            if (patient.id != null && context.mounted) {
              context.read<PatientsCubit>().fetchPatientDetails(patient.id!);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.add,
                width: 14,
                height: 14,
                color: AppColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'create_booking_for_patient'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),

        // Edit Patient
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            final cubit = context.read<PatientsCubit>();
            final updated = await AddEditPatientDialog.show(
              context: context,
              patient: patient,
              patientsCubit: cubit,
            );
            if (updated == true && patient.id != null) {
              cubit.fetchPatientDetails(patient.id!);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.edit,
                width: 14,
                height: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'edit_patient'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Archive Patient
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.red1A,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            final cubit = context.read<PatientsCubit>();
            final deleted = await DeletePatientDialog.show(
              context: context,
              patient: patient,
              patientsCubit: cubit,
            );
            if (deleted == true && context.mounted) {
              context.go(AppRouter.patients);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.archive_outlined,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                'archive_patient'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

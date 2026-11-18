import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/enums/user_role_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';

class BookingFormTechniciansSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(List<BookingTechnicianOption>) onSyncController;

  const BookingFormTechniciansSection({
    super.key,
    required this.controller,
    required this.onSyncController,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.technicians != curr.technicians ||
          prev.clinicType != curr.clinicType ||
          prev.formState?.technicians != curr.formState?.technicians,
      builder: (context, state) {
        final form = state.formState;
        final selectedTechs = form?.technicians ?? [];

        // ── Single Doctor Clinic Mode ──────────────────────────────────
        if (state.isSingleDoctorMode && selectedTechs.isNotEmpty) {
          final doctor = selectedTechs.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'doctor_label'.tr(),
                    style: CustomAppFontStyle.bold14,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'عيادة فردية',
                          style: CustomAppFontStyle.medium11.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.name,
                            style: CustomAppFontStyle.bold14.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'طبيب المنشأة المعتمد - يتم تحديد المواعيد والأسعار تلقائياً',
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // ── Multi-Doctor Polyclinic Mode ──────────────────────────────
        final session = context.read<SessionCubit>();
        final currentUser = session.state.currentUser;
        final currentRole = session.currentRole;
        final isDoctor = currentUser?.isPracticingDoctor == true ||
            (currentUser?.linkedDoctorId != null &&
                currentUser!.linkedDoctorId!.isNotEmpty) ||
            currentRole == UserRoleEnum.doctor;
        final isReception = currentRole == UserRoleEnum.reception;

        Widget? besideWidget;
        if (selectedTechs.isNotEmpty) {
          besideWidget = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              isDoctor
                  ? 'طبيبك الافتراضي (يمكنك التحويل)'
                  : (selectedTechs.length == 1
                      ? selectedTechs.first.name
                      : '${selectedTechs.length} أطباء'),
              style: CustomAppFontStyle.medium11.copyWith(
                color: AppColors.primary,
              ),
            ),
          );
        } else if (isReception) {
          besideWidget = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'إلزامي لتحديد الخدمة والموعد',
              style: CustomAppFontStyle.medium11.copyWith(
                color: AppColors.warning,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomStackSelector<BookingTechnicianOption>(
              header: 'doctor_label'.tr(),
              closeOnSelect: false,
              besideHeader: besideWidget,
              controller: controller,
              list: state.technicians,
              itemAsString: (t) => t.name,
              hintText: 'select_doctor_hint'.tr(),
              enableSearch: true,
              itemBuilder: (ctx, t) {
                final isSelected = selectedTechs.any((s) => s.id == t.id);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray71717A,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.name,
                          style: isSelected
                              ? CustomAppFontStyle.medium14.copyWith(
                                  color: AppColors.primary,
                                )
                              : CustomAppFontStyle.regular14,
                        ),
                      ),
                    ],
                  ),
                );
              },
              changeValue: (t) {
                cubit.toggleFormTechnician(t);
                final updatedTechs = cubit.state.formState?.technicians ?? [];
                onSyncController(updatedTechs);
              },
            ),
            if (selectedTechs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTechs.map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomAssetImage(
                          path: AppIcons.user,
                          width: 14,
                          height: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tech.name,
                          style: CustomAppFontStyle.medium12.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            cubit.removeFormTechnician(tech.id);
                            final remaining = (cubit.state.formState?.technicians ?? [])
                                .where((t) => t.id != tech.id)
                                .toList();
                            onSyncController(remaining);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class ReassignTechnicianDialog extends StatelessWidget {
  final List<BookingTechnicianOption> technicians;
  final Set<String> selectedIds;
  final String? currentDoctorId;
  final bool isLoading;
  final ValueChanged<String> onToggleTechnician;
  final VoidCallback onConfirm;

  const ReassignTechnicianDialog({
    super.key,
    required this.technicians,
    required this.selectedIds,
    this.currentDoctorId,
    required this.isLoading,
    required this.onToggleTechnician,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Exclude current doctor from reassignment candidate list
    final candidateDoctors = technicians.where((t) => t.id != currentDoctorId).toList();
    final availableDoctorsCount = candidateDoctors.where((t) => t.isAvailable).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'transfer_doctor'.tr(),
                        style: CustomAppFontStyle.semiBold18.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$availableDoctorsCount متاح',
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const CloseButton(),
                ],
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),
              if (candidateDoctors.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'no_technicians_found'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.grayMuted,
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: candidateDoctors.map((tech) {
                        final isSelected = selectedIds.contains(tech.id);
                        final isAvailable = tech.isAvailable;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: isAvailable
                                ? () => onToggleTechnician(tech.id)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: isAvailable ? 1.0 : 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : (isAvailable ? AppColors.grayf2 : AppColors.grayE2E8F0.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CustomAssetImage(
                                      path: AppIcons.team,
                                      width: 18,
                                      height: 18,
                                      color: isAvailable ? AppColors.primary : AppColors.gray71717A,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tech.name,
                                            style: CustomAppFontStyle.medium14.copyWith(
                                              color: isAvailable
                                                  ? AppColors.darkText
                                                  : AppColors.gray71717A,
                                            ),
                                          ),
                                          if (!isAvailable && tech.unavailableReason != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              tech.unavailableReason!,
                                              style: CustomAppFontStyle.regular12.copyWith(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isAvailable)
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.gray71717A,
                                        size: 20,
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.grayE2E8F0,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'doctor_not_available'.tr(),
                                          style: CustomAppFontStyle.regular11.copyWith(
                                            color: AppColors.gray71717A,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 40,
                    width: 100,
                    backgroundColor: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(),
                    child: Center(
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.grayMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 40,
                      width: 120,
                      backgroundColor: AppColors.primary,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: onConfirm,
                      child: Center(
                        child: Text(
                          'save'.tr(),
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
        ),
      ),
    );
  }
}

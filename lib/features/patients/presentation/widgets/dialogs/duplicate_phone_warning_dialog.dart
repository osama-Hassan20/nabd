import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class DuplicatePhoneWarningDialog extends StatelessWidget {
  final List<DuplicatePhonePatientInfo> matchingPatients;
  final VoidCallback onContinueWithSharedPhone;
  final ValueChanged<DuplicatePhonePatientInfo> onSelectExistingPatient;
  final VoidCallback onCancel;

  const DuplicatePhoneWarningDialog({
    super.key,
    required this.matchingPatients,
    required this.onContinueWithSharedPhone,
    required this.onSelectExistingPatient,
    required this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required List<DuplicatePhonePatientInfo> matchingPatients,
    required VoidCallback onContinueWithSharedPhone,
    required ValueChanged<DuplicatePhonePatientInfo> onSelectExistingPatient,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final dialogChild = DuplicatePhoneWarningDialog(
          matchingPatients: matchingPatients,
          onContinueWithSharedPhone: () {
            Navigator.of(dialogCtx).pop();
            onContinueWithSharedPhone();
          },
          onSelectExistingPatient: (patient) {
            Navigator.of(dialogCtx).pop();
            onSelectExistingPatient(patient);
          },
          onCancel: () {
            Navigator.of(dialogCtx).pop();
            onCancel();
          },
        );

        if (isMobile) {
          return Dialog.fullscreen(child: dialogChild);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: dialogChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header Alert ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.phone_in_talk_outlined,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'duplicate_phone_alert_title'.tr(),
                      style: CustomAppFontStyle.semiBold18.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'shared_family_phone_notice'.tr(),
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.gray71717A,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          const SizedBox(height: 16),

          // ─── Matching Patients List ─────────────────────────────────────
          Text(
            'existing_registered_patients'.tr(),
            style: CustomAppFontStyle.medium14.copyWith(
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: matchingPatients.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = matchingPatients[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grayE2E8F0.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.grayE2E8F0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
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
                              p.name ?? '',
                              style: CustomAppFontStyle.medium14.copyWith(
                                color: AppColors.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.fileNumber != null && p.fileNumber!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${'file_number'.tr()}: ${p.fileNumber}',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: AppColors.gray71717A,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomPushButton(
                        height: 32,
                        backgroundColor: AppColors.white,
                        border: const BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => onSelectExistingPatient(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Text(
                              'patient_select_registered'.tr(),
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ─── Action Buttons ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomPushButton(
                  height: 44,
                  backgroundColor: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                  onTap: onContinueWithSharedPhone,
                  child: Center(
                    child: Text(
                      'continue_with_shared_phone'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.white,
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
                  backgroundColor: AppColors.white,
                  border: const BorderSide(color: AppColors.grayE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                  onTap: onCancel,
                  child: Center(
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.gray71717A,
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
  }
}

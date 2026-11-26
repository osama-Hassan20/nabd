import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';

class PatientClinicalAlertsBanner extends StatelessWidget {
  final PatientModel? patient;

  const PatientClinicalAlertsBanner({super.key, this.patient});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final currentPatient =
        patient ?? context.watch<PatientsCubit>().state.selectedPatient;
    if (currentPatient == null) return const SizedBox.shrink();

    final hasAllergies =
        currentPatient.allergies != null && currentPatient.allergies!.isNotEmpty;
    final hasChronic = currentPatient.chronicDiseases != null &&
        currentPatient.chronicDiseases!.isNotEmpty;
    final hasMeds = currentPatient.activeMedications != null &&
        currentPatient.activeMedications!.isNotEmpty;

    return CustomContainer(
      backGroundColor: colors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.borderSubtle),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الملف الصحي والتنبيهات السريرية الحرجة',
                      style: CustomAppFontStyle.bold15.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الحساسيات الدوائية، الأمراض المزمنة، والأدوية الحالية المستمرة للمريض',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 14),

          if (currentPatient.isPregnant == true ||
              currentPatient.isNursing == true ||
              currentPatient.hasPregnancyAllergyWarning == true) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentPatient.isPregnant == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEC4899)),
                    ),
                    child: Text(
                      currentPatient.gestationalWeeks() != null
                          ? 'حامل - الأسبوع ${currentPatient.gestationalWeeks()}'
                          : 'حامل',
                      style: CustomAppFontStyle.bold12.copyWith(
                        color: const Color(0xFFBE185D),
                      ),
                    ),
                  ),
                if (currentPatient.isNursing == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Text(
                      currentPatient.nursingBabyAgeMonths != null
                          ? 'مرضع (عمر الرضيع ${currentPatient.nursingBabyAgeMonths} شهر)'
                          : 'مرضع',
                      style: CustomAppFontStyle.bold12.copyWith(
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                if (currentPatient.hasPregnancyAllergyWarning == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      'تحذير حساسية أثناء الحمل',
                      style: CustomAppFontStyle.bold12.copyWith(color: AppColors.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // 1. Allergies Warning Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasAllergies
                  ? AppColors.error.withValues(alpha: 0.08)
                  : colors.surfaceLevel1,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasAllergies
                    ? AppColors.error.withValues(alpha: 0.3)
                    : colors.borderSubtle,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: hasAllergies ? AppColors.error : colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحساسية الدوائية والغذائية:',
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: hasAllergies ? AppColors.error : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasAllergies)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: currentPatient.allergies!.map((a) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                a,
                                style: CustomAppFontStyle.bold12.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'لا توجد حساسيات دوائية أو غذائية مسجلة حتى الآن.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Chronic Diseases & Active Medications Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chronic Diseases
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasChronic
                        ? Colors.amber.shade900.withValues(alpha: 0.08)
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasChronic
                          ? Colors.amber.shade700.withValues(alpha: 0.3)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            color: hasChronic ? Colors.amber.shade800 : colors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'الأمراض المزمنة:',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: hasChronic ? Colors.amber.shade900 : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasChronic)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: currentPatient.chronicDiseases!.map((cd) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.amber.shade400.withValues(alpha: 0.8)),
                              ),
                              child: Text(
                                cd,
                                style: CustomAppFontStyle.bold12.copyWith(
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'لا توجد أمراض مزمنة مسجلة.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Active Medications
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasMeds
                        ? colors.primary.withValues(alpha: 0.08)
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasMeds
                          ? colors.primary.withValues(alpha: 0.3)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            color: hasMeds ? colors.primary : colors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'الأدوية المستمرة (الحالية):',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: hasMeds ? colors.primary : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasMeds)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: currentPatient.activeMedications!.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${m.medicationName} (${m.dosage} - ${m.frequency})',
                                      style: CustomAppFontStyle.medium12.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'لا توجد أدوية مستمرة مسجلة.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
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

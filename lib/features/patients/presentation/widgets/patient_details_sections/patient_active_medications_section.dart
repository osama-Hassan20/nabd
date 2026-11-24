import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/clinical_record_models.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class PatientActiveMedicationsSection extends StatelessWidget {
  final PatientModel? patient;

  const PatientActiveMedicationsSection({super.key, this.patient});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final currentPatient =
        patient ?? context.watch<PatientsCubit>().state.selectedPatient;
    if (currentPatient == null) return const SizedBox.shrink();

    final medications = currentPatient.activeMedications ?? [];
    final allergies = currentPatient.allergies ?? [];
    final chronic = currentPatient.chronicDiseases ?? [];

    return CustomContainer(
      backGroundColor: colors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.borderSubtle),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأدوية الحالية المستمرة والحساسيات السريرية',
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'علاجات الأمراض المزمنة التي يتناولها المريض بانتظام وتنبيهات الأمان الدوائي',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              CustomPushButton(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: colors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showAddMedicationDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'إضافة دواء مستمر',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: Colors.white,
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

          // 1. Allergies & Chronic Summary
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: allergies.isNotEmpty
                        ? AppColors.error.withValues(alpha: 0.08)
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: allergies.isNotEmpty
                          ? AppColors.error.withValues(alpha: 0.3)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16,
                              color: allergies.isNotEmpty
                                  ? AppColors.error
                                  : colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'الحساسيات الدوائية والغذائية (${allergies.length}):',
                            style: CustomAppFontStyle.bold12.copyWith(
                              color: allergies.isNotEmpty
                                  ? AppColors.error
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (allergies.isNotEmpty)
                        Text(
                          allergies.join('  •  '),
                          style: CustomAppFontStyle.semiBold12.copyWith(
                            color: AppColors.error,
                          ),
                        )
                      else
                        Text(
                          'لا توجد حساسيات مسجلة للمريض.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: chronic.isNotEmpty
                        ? Colors.amber.shade900.withValues(alpha: 0.08)
                        : colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: chronic.isNotEmpty
                          ? Colors.amber.shade700.withValues(alpha: 0.3)
                          : colors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_outline,
                              size: 16,
                              color: chronic.isNotEmpty
                                  ? Colors.amber.shade800
                                  : colors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'الأمراض المزمنة الموثقة (${chronic.length}):',
                            style: CustomAppFontStyle.bold12.copyWith(
                              color: chronic.isNotEmpty
                                  ? Colors.amber.shade900
                                  : colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (chronic.isNotEmpty)
                        Text(
                          chronic.join('  •  '),
                          style: CustomAppFontStyle.bold12.copyWith(
                            color: Colors.amber.shade900,
                          ),
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
            ],
          ),
          const SizedBox(height: 16),

          // 2. Active Medications List
          Text(
            'قائمة الأدوية والعلاجات المستمرة:',
            style: CustomAppFontStyle.semiBold14.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          if (medications.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'لا توجد أدوية مستمرة مسجلة حالياً. يمكنك إضافة علاج مستمر بالضغط على الزر أعلاه.',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final med = medications[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.medication_rounded,
                            size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  med.medicationName,
                                  style: CustomAppFontStyle.bold13.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.cardBackground,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: colors.borderSubtle),
                                  ),
                                  child: Text(
                                    med.frequency,
                                    style: CustomAppFontStyle.medium11.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الجرعة: ${med.dosage} ${med.prescribedFor != null ? '• دواعي الاستعمال: ${med.prescribedFor}' : ''}',
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            if (med.instructions != null &&
                                med.instructions!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'إرشادات: ${med.instructions}',
                                style: CustomAppFontStyle.regular11.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final colors = context.themeColors;
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إضافة دواء مستمر لملف المريض',
                      style: CustomAppFontStyle.bold15.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(dlgCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: nameCtrl,
                  headerText: 'اسم الدواء والتركيز',
                  hintText: 'مثال: Concor 5mg',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: doseCtrl,
                        headerText: 'الجرعة',
                        hintText: 'مثال: قرص واحد',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextFormField(
                        controller: freqCtrl,
                        headerText: 'التكرار والموعد',
                        hintText: 'مثال: مرة يومياً صباحاً',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: reasonCtrl,
                  headerText: 'دواعي الاستعمال',
                  hintText: 'مثال: لتنظيم ضغط الدم',
                ),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: notesCtrl,
                  headerText: 'تعليمات وإرشادات الطبيب',
                  hintText: 'مثال: قبل الإفطار بنصف ساعة',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dlgCtx),
                      child: Text('إلغاء',
                          style: TextStyle(color: colors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    CustomPushButton(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final newMed = ActiveMedicationModel(
                          id: 'MED-${DateTime.now().millisecondsSinceEpoch}',
                          medicationName: nameCtrl.text.trim(),
                          dosage: doseCtrl.text.trim().isEmpty
                              ? 'حسب الإرشاد'
                              : doseCtrl.text.trim(),
                          frequency: freqCtrl.text.trim().isEmpty
                              ? 'يومياً'
                              : freqCtrl.text.trim(),
                          prescribedFor: reasonCtrl.text.trim(),
                          instructions: notesCtrl.text.trim(),
                          startDate: DateTime.now(),
                        );
                        context.read<PatientsCubit>().addActiveMedication(newMed);
                        Navigator.pop(dlgCtx);
                        CustomToast(
                          context: context,
                          header: 'تمت إضافة الدواء المستمر لملف المريض بنجاح',
                        ).showTopToast();
                      },
                      child: const Text('حفظ الدواء',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/features/visits/data/models/enums/visit_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/presentation/helpers/prescription_pdf_generator.dart';
import 'package:eyadty/features/visits/presentation/widgets/visit_status_badge.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class PatientConsultationsHistorySection extends StatelessWidget {
  final List<VisitModel>? visits;
  final PatientModel? patient;

  const PatientConsultationsHistorySection({
    super.key,
    this.visits,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        final currentPatient = patient ?? state.selectedPatient;
        if (currentPatient == null) return const SizedBox.shrink();

        final currentVisits = visits ?? state.patientVisits;

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
                          Icons.history_edu_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سجل الكشوفات والروشتات السريرية السابقة',
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'تاريخ الفحوصات، قياسات العلامات الحيوية، التشخيص، وتفاصيل الروشتات الصادرة',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceLevel1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Text(
                      '${currentVisits.length} كشف مسجل',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 16),
              if (currentVisits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد كشوفات أو زيارات سريرية سابقة مسجلة للمريض حتى الآن',
                        style: CustomAppFontStyle.medium13.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentVisits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, idx) {
                    final visit = currentVisits[idx];
                    return _buildConsultationCard(
                        context, visit, currentPatient);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsultationCard(
      BuildContext context, VisitModel visit, PatientModel currentPatient) {
    final colors = context.themeColors;
    final date = visit.finalizedAt ?? visit.startedAt;
    final formattedDate = date != null
        ? '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} - ${DateFormat('hh:mm a', 'ar').format(date)}'
        : 'كشف حالي';

    final vitals = visit.vitals;
    final hasVitals = vitals != null &&
        (vitals.systolicBp != null ||
            vitals.weightKg != null ||
            vitals.temperature != null);
    final prescriptions = visit.prescriptionItems ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visit.status == VisitStatusEnum.inProgress
              ? colors.primary
              : colors.borderSubtle,
          width: visit.status == VisitStatusEnum.inProgress ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Visit Header: Doctor, Specialty, Date & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_pin_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            visit.doctorName ?? 'الطبيب المعالج',
                            style: CustomAppFontStyle.bold14.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (visit.specialty != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: Text(
                                visit.specialty!,
                                style: CustomAppFontStyle.medium11.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (visit.status != null)
                    VisitStatusBadge(status: visit.status!),
                  if (visit.status == VisitStatusEnum.inProgress) ...[
                    const SizedBox(width: 8),
                    CustomPushButton(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        if (visit.id != null && visit.id!.isNotEmpty) {
                          context.go(
                            AppRouter.visitDetails
                                .replaceAll(':id', visit.id!),
                          );
                        }
                      },
                      child: Text(
                        'متابعة الكشف الآن',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Vitals Measured During This Specific Visit
          if (hasVitals) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monitor_heart_outlined,
                          size: 15, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'العلامات الحيوية المقاسة:',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (vitals.systolicBp != null && vitals.diastolicBp != null)
                    _buildVitalBadge(
                      label: 'الضغط',
                      value: '${vitals.systolicBp}/${vitals.diastolicBp} mmHg',
                      color: vitals.systolicBp! > 140
                          ? AppColors.error
                          : colors.primary,
                    ),
                  if (vitals.weightKg != null)
                    _buildVitalBadge(
                      label: 'الوزن',
                      value: '${vitals.weightKg} كجم',
                      color: colors.textPrimary,
                    ),
                  if (vitals.heightCm != null)
                    _buildVitalBadge(
                      label: 'الطول',
                      value: '${vitals.heightCm} سم',
                      color: colors.textPrimary,
                    ),
                  if (vitals.heartRate != null)
                    _buildVitalBadge(
                      label: 'النبض',
                      value: '${vitals.heartRate} bpm',
                      color: colors.textPrimary,
                    ),
                  if (vitals.temperature != null)
                    _buildVitalBadge(
                      label: 'الحرارة',
                      value: '${vitals.temperature}°C',
                      color: vitals.temperature! > 37.5
                          ? AppColors.error
                          : colors.textPrimary,
                    ),
                ],
              ),
            ),
          ],

          // 3. Chief Complaint & Clinical Diagnosis
          if (visit.chiefComplaint != null &&
              visit.chiefComplaint!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شكوى المريض الرئيسية: ',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    visit.chiefComplaint!,
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (visit.diagnosis != null && visit.diagnosis!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التشخيص السريري المعتمد: ',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    visit.diagnosis!,
                    style: CustomAppFontStyle.bold12.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 4. Clinical Prescriptions / Treatments Prescribed
          if (prescriptions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_outlined,
                        size: 16, color: AppColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'الروشتة والعلاج الدوائي الموصوف (${prescriptions.length} صنف):',
                      style: CustomAppFontStyle.semiBold12.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                CustomPushButton(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: colors.cardBackground,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    try {
                      final pdfBytes = await PrescriptionPdfGenerator.generate(
                        visit: visit,
                        patient: currentPatient,
                      );
                      await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => pdfBytes,
                        name: 'Prescription_${visit.id}',
                      );
                    } catch (_) {
                      CustomToast(
                        context: context,
                        header: 'تم إنشاء نسخة الروشتة للطباعة بنجاح',
                      ).showTopToast();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'طباعة الروشتة',
                        style: CustomAppFontStyle.medium11.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescriptions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: colors.borderSubtle),
                itemBuilder: (context, rxIdx) {
                  final rx = prescriptions[rxIdx];
                  final displayName = rx.tradeName ?? rx.scientificName ?? 'علاج موصوف';
                  final details = [
                    if (rx.dosage != null && rx.dosage!.isNotEmpty) rx.dosage,
                    if (rx.frequency != null && rx.frequency!.isNotEmpty) rx.frequency,
                    if (rx.duration != null && rx.duration!.isNotEmpty) 'لمدة ${rx.duration}',
                  ].join(' • ');

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${rxIdx + 1}',
                            style: CustomAppFontStyle.bold11.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: CustomAppFontStyle.bold12.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  details,
                                  style: CustomAppFontStyle.medium11.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                              if (rx.instructions != null &&
                                  rx.instructions!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'تعليمات الاستخدام: ${rx.instructions}',
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: CustomAppFontStyle.regular11.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: CustomAppFontStyle.bold12.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

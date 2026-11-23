import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/patient_treatment_plan_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/domain/repo/medical_services_repo.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class PatientTreatmentPlansSection extends StatelessWidget {
  const PatientTreatmentPlansSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      buildWhen: (prev, curr) =>
          prev.selectedPatient?.treatmentPlans !=
          curr.selectedPatient?.treatmentPlans,
      builder: (context, state) {
        final plans = state.selectedPatient?.treatmentPlans ?? [];
        final cubit = context.read<PatientsCubit>();
        final colors = context.themeColors;

        return CustomContainer(
          backGroundColor: colors.cardBackground,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Section Header ──────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: CustomAssetImage(
                      path: AppIcons.service,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الخدمات والخطط العلاجية المستمرة',
                          style: CustomAppFontStyle.bold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'متابعة باقات الليزر، تقويم وزراعة الأسنان، وجلسات العلاج بنظام الدفعات المرنة',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CustomPushButton(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showAddPlanDialog(context, cubit),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: AppColors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'إضافة خطة / باقة',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Content ─────────────────────────────────────────────────
              if (plans.isEmpty)
                _buildEmptyState(context, cubit)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _buildPlanCard(context, cubit, plan);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, PatientsCubit cubit) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.surfaceLevel1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Center(
        child: Column(
          children: [
            CustomAssetImage(
              path: AppIcons.service,
              width: 48,
              height: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد خطط علاجية أو باقات مستمرة لهذا المريض حالياً',
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'يمكن للطبيب إضافة باقة ليزر، تقويم، علاج عصب، أو علاج طبيعي وتحديد الدفعات وتعديل الأسعار حسب الحالة',
              style: CustomAppFontStyle.regular12.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: colors.primary,
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showAddPlanDialog(context, cubit),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'بدء خطة علاجية جديدة',
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    PatientsCubit cubit,
    PatientTreatmentPlanModel plan,
  ) {
    final isMobile = AdaptiveLayout.isMobile(context);
    final isCompleted = plan.isCompleted;
    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? colors.borderSubtle : colors.primary.withValues(alpha: 0.3),
          width: isCompleted ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Category Tag, Plan Name & Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.category,
                  style: CustomAppFontStyle.medium12.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.serviceName,
                  style: CustomAppFontStyle.bold15.copyWith(
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? colors.surfaceLevel1
                      : colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCompleted ? colors.borderSubtle : colors.primary,
                  ),
                ),
                child: Text(
                  isCompleted ? 'مكتملة' : 'جارية',
                  style: CustomAppFontStyle.semiBold12.copyWith(
                    color: isCompleted ? colors.textSecondary : colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Doctor and Start Date info
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'الطبيب: ${plan.doctorName.isNotEmpty ? plan.doctorName : 'طبيب العيادة'}',
                style: CustomAppFontStyle.regular12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today_outlined, size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'تاريخ البدء: ${DateFormat('yyyy/MM/dd').format(plan.startDate)}',
                style: CustomAppFontStyle.regular12.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (plan.notes.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'ملاحظات: ${plan.notes}',
                    style: CustomAppFontStyle.regular12.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Sessions Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الجلسات المنفذة: ${plan.completedSessions} من أصل ${plan.totalSessions} جلسة',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${(plan.progressRatio * 100).toInt()}%',
                    style: CustomAppFontStyle.bold13.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: plan.progressRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLevel1,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.teal : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 4: Financial Metrics (Total Cost with Edit, Paid, Remaining, Payment Mode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceLevel1,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                // Total Cost with Doctor Edit Icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإجمالي المتفق عليه: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${plan.totalAgreedPrice} ج.م',
                      style: CustomAppFontStyle.bold14.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showEditPriceDialog(context, cubit, plan),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 13,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Paid Amount
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المدفوع: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${plan.totalPaidAmount} ج.م',
                      style: CustomAppFontStyle.bold14.copyWith(
                        color: Colors.teal.shade400,
                      ),
                    ),
                  ],
                ),

                // Remaining Balance
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المتبقي: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${plan.remainingBalance} ج.م',
                      style: CustomAppFontStyle.bold14.copyWith(
                        color: plan.remainingBalance > 0
                            ? Colors.red.shade400
                            : Colors.teal.shade400,
                      ),
                    ),
                  ],
                ),

                // Payment Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    plan.paymentMode == 'perSession'
                        ? 'الدفع لكل جلسة'
                        : (plan.paymentMode == 'upfront'
                            ? 'سداد كامل مقدماً'
                            : 'دفعات وأقساط مرنة'),
                    style: CustomAppFontStyle.medium11.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Row 5: Action Buttons (+ Add Session, + Add Payment, View History)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.end,
            children: [
              // View Sessions and Payments History
              CustomPushButton(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: colors.surfaceLevel1,
                boxBorder: Border.all(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showHistoryDialog(context, plan),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 15,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'السجل والتفاصيل (${plan.sessions.length} جلسات / ${plan.payments.length} دفعات)',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            

              // Record Payment Button
              if (plan.remainingBalance > 0)
                CustomPushButton(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showAddPaymentDialog(context, cubit, plan),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 15, color: AppColors.white),
                      const SizedBox(width: 6),
                      Text(
                        'تحصيل دفعة / قسط',
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // Record Session Button
              if (!isCompleted)
                CustomPushButton(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showAddSessionDialog(context, cubit, plan),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 15, color: AppColors.white),
                      const SizedBox(width: 6),
                      Text(
                        'تسجيل جلسة اليوم (جلسة ${plan.completedSessions + 1})',
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  // 1. Add New Treatment Plan Dialog
  static Future<void> _showAddPlanDialog(
    BuildContext context,
    PatientsCubit cubit,
  ) async {
    List<MedicalServiceModel> services = [];
    try {
      final res = await getIt<MedicalServicesRepo>().getMedicalServices(
        onlyActive: true,
      );
      services = res.fold((_) => [], (list) => list);
    } catch (_) {}

    if (!context.mounted) return;

    final formKey = GlobalKey<FormState>();
    final serviceSelectorController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final sessionsController = TextEditingController(text: '6');
    final categoryController = TextEditingController(text: 'جلدية وليزر');
    final doctorController = TextEditingController(text: 'د. طارق المنشاوي (المالك)');
    final initialPaymentController = TextEditingController();
    final notesController = TextEditingController();

    MedicalServiceModel? selectedService;
    String paymentMode = 'flexibleInstallments';

    final paymentModes = [
      {'key': 'flexibleInstallments', 'title': 'أقساط ودفعات مرنة (حسب قدرة المريض)'},
      {'key': 'perSession', 'title': 'سداد مستقل لكل جلسة'},
      {'key': 'upfront', 'title': 'سداد كامل مقدماً'},
    ];
    final paymentModeSelectorController = TextEditingController(
      text: 'أقساط ودفعات مرنة (حسب قدرة المريض)',
    );

    await showDialog(
      context: context,
      builder: (dlgContext) {
        final dlgColors = dlgContext.themeColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                color: dlgColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dlgColors.borderSubtle),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: dlgColors.borderSubtle)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'بدء خدمة / خطة علاجية متعددة الجلسات',
                            style: CustomAppFontStyle.semiBold16.copyWith(
                              color: dlgColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dlgContext).pop(),
                            icon: Icon(Icons.close, size: 20, color: dlgColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pick from existing medical services catalog
                            CustomStackSelector<MedicalServiceModel>(
                              controller: serviceSelectorController,
                              header: 'اختيار الخدمة الطبية من الدليل',
                              hintText: 'اختر باقة أو خدمة...',
                              list: services,
                              itemAsString: (s) => '${s.name ?? ''} (${s.consultationFee ?? 0} ج.م)',
                              changeValue: (s) {
                                selectedService = s;
                                nameController.text = s.name ?? '';
                                priceController.text = (s.consultationFee ?? 0).toString();
                                if (s.sessionsCount != null && s.sessionsCount! > 0) {
                                  sessionsController.text = s.sessionsCount.toString();
                                }
                                if (s.category != null && s.category!.isNotEmpty) {
                                  categoryController.text = s.category!;
                                }
                                if (s.assignedDoctorName != null && s.assignedDoctorName!.isNotEmpty) {
                                  doctorController.text = s.assignedDoctorName!;
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            // Plan Name (Can be edited by doctor)
                            CustomTextFormField(
                              controller: nameController,
                              isRequired: true,
                              headerText: 'اسم الخطة أو الباقة العلاجية',
                              hintText: 'مثال: باقة ليزر 6 جلسات / تقويم أسنان / علاج جذور',
                              validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 14),

                            // Agreed Price & Sessions Count (2 Columns)
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: priceController,
                                    isRequired: true,
                                    headerText: 'المبلغ الإجمالي المتفق عليه (ج.م)',
                                    hintText: 'يمكن تعديله حسب الحالة',
                                    textInputType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'مطلوب';
                                      if ((num.tryParse(val) ?? 0) <= 0) return 'قيمة غير صالحة';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: sessionsController,
                                    isRequired: true,
                                    headerText: 'إجمالي عدد الجلسات',
                                    hintText: 'مثال: 6',
                                    textInputType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'مطلوب';
                                      if ((int.tryParse(val) ?? 0) <= 0) return 'أدخل عدداً صحيحاً';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Category & Doctor Name (2 Columns)
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: categoryController,
                                    headerText: 'التخصص الطبي',
                                    hintText: 'مثال: طب الأسنان / جلدية وليزر',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: doctorController,
                                    headerText: 'الطبيب المعالج',
                                    hintText: 'اسم الطبيب المشرف',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Payment Mode Selector
                            CustomStackSelector<Map<String, String>>(
                              controller: paymentModeSelectorController,
                              header: 'نظام الدفع والتحصيل المعتمد للمريض',
                              hintText: 'اختر نظام الدفع',
                              list: paymentModes,
                              itemAsString: (m) => m['title'] ?? '',
                              changeValue: (m) {
                                paymentMode = m['key'] ?? 'flexibleInstallments';
                              },
                            ),
                            const SizedBox(height: 14),

                            // Initial Down Payment
                            CustomTextFormField(
                              controller: initialPaymentController,
                              headerText: 'الدفعة الأولى المحصلة الآن (اختياري)',
                              hintText: 'اتركه فارغاً إذا لم يدفع دفعة مقدمة',
                              textInputType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 14),

                            // Notes
                            CustomTextFormField(
                              controller: notesController,
                              headerText: 'ملاحظات الطبيب وخطة العمل',
                              hintText: 'مثال: يشمل رتوش مجانية بعد الجلسة الرابعة / علاج قنوات منحنية...',
                              maxLine: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: dlgColors.borderSubtle)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomPushButton(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: dlgColors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(dlgContext).pop(),
                            child: Text(
                              'إلغاء',
                              style: CustomAppFontStyle.medium14.copyWith(
                                color: dlgColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomPushButton(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              if (!formKey.currentState!.validate()) return;
                              final price = num.parse(priceController.text.trim());
                              final sessions = int.parse(sessionsController.text.trim());
                              final initPay = num.tryParse(initialPaymentController.text.trim()) ?? 0;
                              final now = CairoTimeHelper.now();

                              final newPlan = PatientTreatmentPlanModel(
                                id: 'TRP-${DateTime.now().millisecondsSinceEpoch}',
                                patientId: cubit.state.selectedPatient?.id ?? '',
                                serviceId: selectedService?.id,
                                serviceName: nameController.text.trim(),
                                category: categoryController.text.trim().isNotEmpty
                                    ? categoryController.text.trim()
                                    : 'عام',
                                doctorName: doctorController.text.trim(),
                                totalAgreedPrice: price,
                                totalPaidAmount: initPay,
                                totalSessions: sessions,
                                completedSessions: 0,
                                paymentMode: paymentMode,
                                status: 'active',
                                startDate: now,
                                notes: notesController.text.trim(),
                                payments: initPay > 0
                                    ? [
                                        TreatmentPaymentRecordModel(
                                          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                                          amount: initPay,
                                          date: now,
                                          paymentMethod: 'نقدي',
                                          notes: 'دفعة أولى عند فتح الخطة العلاجية',
                                        ),
                                      ]
                                    : [],
                              );

                              final ok = await cubit.addTreatmentPlan(newPlan);
                              if (dlgContext.mounted) {
                                Navigator.of(dlgContext).pop();
                                if (ok) {
                                  CustomToast(
                                    context: context,
                                    header: 'تم إنشاء الخطة العلاجية بنجاح',
                                  ).showTopToast();
                                }
                              }
                            },
                            child: Text(
                              'حفظ وبدء الخطة',
                              style: CustomAppFontStyle.semiBold14.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 2. Record Session Dialog
  static Future<void> _showAddSessionDialog(
    BuildContext context,
    PatientsCubit cubit,
    PatientTreatmentPlanModel plan,
  ) async {
    final sessionNum = plan.completedSessions + 1;
    final notesController = TextEditingController();
    final doctorController = TextEditingController(
      text: plan.doctorName.isNotEmpty ? plan.doctorName : 'طبيب العيادة',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dlgContext) {
        final dlgColors = dlgContext.themeColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: dlgColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dlgColors.borderSubtle),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تسجيل إنجاز جلسة (جلسة رقم $sessionNum)',
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: dlgColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الخطة: ${plan.serviceName}',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: dlgColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: doctorController,
                      isRequired: true,
                      headerText: 'الطبيب / الأخصائي المنفذ للجلسة',
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextFormField(
                      controller: notesController,
                      isRequired: true,
                      headerText: 'ملاحظات الإجراء الطبي المنفذ اليوم',
                      hintText: 'مثال: تم ضبط مقاس السلك وتثبيت الحاصرات / جلسة ليزر طاقة 18 جول بدون مضاعفات...',
                      maxLine: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب تدوين ما تم إنجازه' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: AppColors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(dlgContext).pop(),
                          child: Text('إلغاء', style: CustomAppFontStyle.medium13),
                        ),
                        const SizedBox(width: 10),
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          backgroundColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (!formKey.currentState!.validate()) return;
                            final record = TreatmentSessionRecordModel(
                              id: 'SES-${DateTime.now().millisecondsSinceEpoch}',
                              sessionNumber: sessionNum,
                              date: CairoTimeHelper.now(),
                              doctorNotes: notesController.text.trim(),
                              performedBy: doctorController.text.trim(),
                            );
                            final ok = await cubit.recordTreatmentSession(
                              planId: plan.id,
                              session: record,
                            );
                            if (dlgContext.mounted) {
                              Navigator.of(dlgContext).pop();
                              if (ok) {
                                CustomToast(
                                  context: context,
                                  header: 'تم تسجيل الجلسة بنجاح وتحديث تقدم الخطة',
                                ).showTopToast();
                              }
                            }
                          },
                          child: Text(
                            'تأكيد إنجاز الجلسة',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 3. Record Payment Dialog
  static Future<void> _showAddPaymentDialog(
    BuildContext context,
    PatientsCubit cubit,
    PatientTreatmentPlanModel plan,
  ) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final methods = ['نقدي', 'بطاقة بنكية', 'إنستاباي', 'فودافون كاش'];
    final methodController = TextEditingController(text: 'نقدي');
    String chosenMethod = 'نقدي';

    await showDialog(
      context: context,
      builder: (dlgContext) {
        final dlgColors = dlgContext.themeColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: dlgColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dlgColors.borderSubtle),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تحصيل دفعة مالية / قسط مرن',
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: dlgColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المبلغ المتبقي على المريض: ${plan.remainingBalance} ج.م',
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: amountController,
                      isRequired: true,
                      headerText: 'قيمة الدفعة المحصلة (ج.م)',
                      hintText: 'أدخل أي مبلغ يدفعه المريض حالياً',
                      textInputType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        final val = num.tryParse(v) ?? 0;
                        if (val <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
                        if (val > plan.remainingBalance) {
                          return 'المبلغ يتجاوز المتبقي (${plan.remainingBalance} ج.م)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomStackSelector<String>(
                      controller: methodController,
                      header: 'طريقة الدفع',
                      hintText: 'اختر طريقة الدفع',
                      list: methods,
                      itemAsString: (m) => m,
                      changeValue: (m) {
                        chosenMethod = m;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextFormField(
                      controller: notesController,
                      headerText: 'ملاحظات الإيصال / السداد',
                      hintText: 'مثال: دفعة عشوائية تحت الحساب / سداد جلسة اليوم',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: AppColors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(dlgContext).pop(),
                          child: Text('إلغاء', style: CustomAppFontStyle.medium13),
                        ),
                        const SizedBox(width: 10),
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          backgroundColor: Colors.teal.shade600,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (!formKey.currentState!.validate()) return;
                            final amount = num.parse(amountController.text.trim());
                            final payment = TreatmentPaymentRecordModel(
                              id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                              amount: amount,
                              date: CairoTimeHelper.now(),
                              paymentMethod: chosenMethod,
                              notes: notesController.text.trim(),
                            );
                            final ok = await cubit.recordTreatmentPayment(
                              planId: plan.id,
                              payment: payment,
                            );
                            if (dlgContext.mounted) {
                              Navigator.of(dlgContext).pop();
                              if (ok) {
                                CustomToast(
                                  context: context,
                                  header: 'تم تحصيل الدفعة بنجاح وتحديث الرصيد المتبقي',
                                ).showTopToast();
                              }
                            }
                          },
                          child: Text(
                            'تأكيد استلام الدفعة',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 4. Edit Price Dialog (as user requested: doctor sees extra procedure and updates price)
  static Future<void> _showEditPriceDialog(
    BuildContext context,
    PatientsCubit cubit,
    PatientTreatmentPlanModel plan,
  ) async {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
      text: plan.totalAgreedPrice.toString(),
    );
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dlgContext) {
        final dlgColors = dlgContext.themeColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: dlgColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dlgColors.borderSubtle),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تعديل إجمالي سعر الخطة العلاجية',
                      style: CustomAppFontStyle.semiBold16.copyWith(
                        color: dlgColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ميزة مخصصة للطبيب: في حال استجد إجراء إضافي أثناء العلاج (مثل قناة عصب إضافية أو جلسة رتوش مكثفة)',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: dlgColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: priceController,
                      isRequired: true,
                      headerText: 'السعر الإجمالي الجديد (ج.م)',
                      textInputType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        final val = num.tryParse(v) ?? 0;
                        if (val < plan.totalPaidAmount) {
                          return 'لا يمكن أن يكون السعر أقل من المدفوع بالفعل (${plan.totalPaidAmount} ج.م)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextFormField(
                      controller: reasonController,
                      headerText: 'سبب التعديل أو تفاصيل الإجراء الإضافي',
                      hintText: 'مثال: تم فتح قناة عصب رابعة / إضافة نبضات ليزر لمنطقة إضافية',
                      maxLine: 2,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: AppColors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(dlgContext).pop(),
                          child: Text('إلغاء', style: CustomAppFontStyle.medium13),
                        ),
                        const SizedBox(width: 10),
                        CustomPushButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          backgroundColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (!formKey.currentState!.validate()) return;
                            final newPrice = num.parse(priceController.text.trim());
                            final reason = reasonController.text.trim();
                            final newNotes = reason.isNotEmpty
                                ? '${plan.notes.isNotEmpty ? "${plan.notes}\n" : ""}[تعديل سعر]: $reason'
                                : plan.notes;

                            final updatedPlan = plan.copyWith(
                              totalAgreedPrice: newPrice,
                              notes: newNotes,
                            );

                            final ok = await cubit.updateTreatmentPlan(updatedPlan);
                            if (dlgContext.mounted) {
                              Navigator.of(dlgContext).pop();
                              if (ok) {
                                CustomToast(
                                  context: context,
                                  header: 'تم تعديل سعر الخطة العلاجية بنجاح',
                                ).showTopToast();
                              }
                            }
                          },
                          child: Text(
                            'حفظ التعديل',
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 5. History Dialog (Sessions & Payments timeline)
  static Future<void> _showHistoryDialog(
    BuildContext context,
    PatientTreatmentPlanModel plan,
  ) async {
    await showDialog(
      context: context,
      builder: (dlgContext) {
        final dlgColors = dlgContext.themeColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              decoration: BoxDecoration(
                color: dlgColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dlgColors.borderSubtle),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سجل الجلسات والدفعات المحصلة',
                              style: CustomAppFontStyle.bold16.copyWith(
                                color: dlgColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan.serviceName,
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: dlgColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dlgContext).pop(),
                        icon: Icon(Icons.close, size: 20, color: dlgColors.textSecondary),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: dlgColors.borderSubtle),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sessions Section
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: dlgColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'الجلسات المنفذة (${plan.sessions.length} جلسة)',
                                style: CustomAppFontStyle.semiBold14.copyWith(
                                  color: dlgColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (plan.sessions.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'لم يتم تسجيل جلسات منفذة بعد',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: dlgColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plan.sessions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final s = plan.sessions[i];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: dlgColors.surfaceLevel1,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: dlgColors.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'الجلسة #${s.sessionNumber} - المنفذ: ${s.performedBy}',
                                            style: CustomAppFontStyle.semiBold13.copyWith(
                                              color: dlgColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('yyyy/MM/dd').format(s.date),
                                            style: CustomAppFontStyle.regular12.copyWith(
                                              color: dlgColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (s.doctorNotes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          s.doctorNotes,
                                          style: CustomAppFontStyle.regular12.copyWith(
                                            color: dlgColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 20),

                          // Payments Section
                          Row(
                            children: [
                              const Icon(Icons.payment, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Text(
                                'سجل الدفعات والمتحصلات (${plan.payments.length} دفعة)',
                                style: CustomAppFontStyle.semiBold14.copyWith(
                                  color: dlgColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (plan.payments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'لم يتم تحصيل دفعات بعد',
                                style: CustomAppFontStyle.regular12.copyWith(
                                  color: dlgColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plan.payments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final p = plan.payments[i];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: dlgColors.surfaceLevel1,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: dlgColors.borderSubtle),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'دفعة: ${p.amount} ج.م (${p.paymentMethod})',
                                            style: CustomAppFontStyle.semiBold13.copyWith(
                                              color: dlgColors.isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                                            ),
                                          ),
                                          if (p.notes.isNotEmpty)
                                            Text(
                                              p.notes,
                                              style: CustomAppFontStyle.regular11.copyWith(
                                                color: dlgColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        DateFormat('yyyy/MM/dd').format(p.date),
                                        style: CustomAppFontStyle.regular12.copyWith(
                                          color: dlgColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

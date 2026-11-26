import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/clinical_record_models.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

/// قسم المتابعات التخصصية السريرية ومعرض مقارنة البداية والنهاية
/// (يدعم طب العيون IOP، الجلدية، تقويم وتجميل الأسنان Before & After)
class PatientSpecialtyTrackingSection extends StatefulWidget {
  const PatientSpecialtyTrackingSection({super.key});

  @override
  State<PatientSpecialtyTrackingSection> createState() =>
      _PatientSpecialtyTrackingSectionState();
}

class _PatientSpecialtyTrackingSectionState
    extends State<PatientSpecialtyTrackingSection> {
  // 0: معرض مقارنة البداية والنهاية (جلدية، أسنان، تجميل)
  // 1: متابعة قياسات طب العيون (IOP وضغط العين)
  int _activeSpecialtyTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        final patient = state.selectedPatient;
        if (patient == null) return const SizedBox.shrink();

        final eyeExams = patient.eyeExams ?? [];
        final galleryItems = patient.beforeAfterGallery ?? [];

        return CustomContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.track_changes_outlined,
                        color: AppColors.cyan,
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
                          'المتابعات التخصصية والتوثيق السريري المتقدم',
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'before_after_subtitle'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add Action Button
                  if (_activeSpecialtyTab == 0)
                    CustomPushButton(
                      height: 38,
                      width: 215,
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showAddGalleryItemDialog(context),
                      child: Text(
                        'add_before_after_comparison'.tr(),
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    CustomPushButton(
                      height: 38,
                      width: 195,
                      backgroundColor: AppColors.cyan,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showAddEyeExamDialog(context),
                      child: Text(
                        '+ تسجيل فحص عيون دوري',
                        style: CustomAppFontStyle.medium12.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Sub-navigation Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSubTab(
                      index: 0,
                      title: 'معرض مقارنة البداية والنهاية (Before & After)',
                      count: galleryItems.length,
                      icon: Icons.compare_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildSubTab(
                      index: 1,
                      title: 'متابعة قياسات طب العيون (IOP & Acuity)',
                      count: eyeExams.length,
                      icon: Icons.remove_red_eye_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tab 0: Before & After Gallery
              if (_activeSpecialtyTab == 0) ...[
                if (galleryItems.isEmpty)
                  _buildEmptyState(
                    title: 'لا توجد مقارنات سريرية مسجلة حتى الآن',
                    subtitle: 'يمكن لأطباء الجلدية والتقويم والتجميل توثيق صور قبل وبعد لمتابعة تطور الحالة مع الجلسات',
                    icon: Icons.photo_library_outlined,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: galleryItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = galleryItems[index];
                      return _BeforeAfterCard(item: item);
                    },
                  ),
              ]
              // Tab 1: Eye tracking exams
              else ...[
                if (eyeExams.isEmpty)
                  _buildEmptyState(
                    title: 'لا توجد فحوصات دورية لضغط العين مسجلة',
                    subtitle: 'خاص بأطباء وجراحي العيون لمتابعة ضغط العين الداخلي (IOP) وحدة الإبصار شهرياً',
                    icon: Icons.visibility_outlined,
                  )
                else
                  _buildEyeExamsTable(eyeExams),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubTab({
    required int index,
    required String title,
    required int count,
    required IconData icon,
  }) {
    final colors = context.themeColors;
    final isSelected = _activeSpecialtyTab == index;
    return InkWell(
      onTap: () => setState(() => _activeSpecialtyTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colors.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: isSelected
                  ? CustomAppFontStyle.semiBold13.copyWith(color: colors.primary)
                  : CustomAppFontStyle.medium13.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: CustomAppFontStyle.bold11.copyWith(
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final colors = context.themeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: CustomAppFontStyle.medium14.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: CustomAppFontStyle.regular12.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEyeExamsTable(List<EyeTrackingExamModel> exams) {
    final colors = context.themeColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: colors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'تاريخ الفحص',
                    style: CustomAppFontStyle.semiBold12.copyWith(color: colors.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'IOP ضغط اليمنى (OD)',
                    style: CustomAppFontStyle.semiBold12.copyWith(color: colors.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'IOP ضغط اليسرى (OS)',
                    style: CustomAppFontStyle.semiBold12.copyWith(color: colors.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'حدة الإبصار (OD / OS)',
                    style: CustomAppFontStyle.semiBold12.copyWith(color: colors.textSecondary),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'فحص قاع العين والملاحظات',
                    style: CustomAppFontStyle.semiBold12.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exams.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: colors.borderSubtle),
            itemBuilder: (context, index) {
              final exam = exams[index];
              final dateStr = DateFormat('yyyy/MM/dd').format(exam.examDate);

              // Flag high IOP (> 21 mmHg is clinically considered elevated / glaucoma suspect)
              final isHighRight = (exam.iopRight ?? 0) > 21;
              final isHighLeft = (exam.iopLeft ?? 0) > 21;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateStr,
                        style: CustomAppFontStyle.bold12.copyWith(color: colors.textPrimary),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHighRight
                              ? AppColors.error.withValues(alpha: 0.1)
                              : colors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isHighRight
                                ? AppColors.error.withValues(alpha: 0.3)
                                : colors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          exam.iopRight != null ? '${exam.iopRight} mmHg' : '-',
                          style: CustomAppFontStyle.bold12.copyWith(
                            color: isHighRight ? AppColors.error : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHighLeft
                              ? AppColors.error.withValues(alpha: 0.1)
                              : colors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isHighLeft
                                ? AppColors.error.withValues(alpha: 0.3)
                                : colors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          exam.iopLeft != null ? '${exam.iopLeft} mmHg' : '-',
                          style: CustomAppFontStyle.bold12.copyWith(
                            color: isHighLeft ? AppColors.error : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'OD: ${exam.visualAcuityRight ?? "-"} | OS: ${exam.visualAcuityLeft ?? "-"}',
                        style: CustomAppFontStyle.medium12.copyWith(color: colors.textPrimary),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exam.fundusNotes != null && exam.fundusNotes!.isNotEmpty)
                            Text(
                              exam.fundusNotes!,
                              style: CustomAppFontStyle.regular12.copyWith(color: colors.textPrimary),
                            ),
                          if (exam.notes != null && exam.notes!.isNotEmpty)
                            Text(
                              exam.notes!,
                              style: CustomAppFontStyle.regular11.copyWith(color: colors.textSecondary),
                            ),
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

  void _showAddGalleryItemDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => BlocProvider.value(
        value: parentContext.read<PatientsCubit>(),
        child: const _AddGalleryItemDialog(),
      ),
    );
  }

  void _showAddEyeExamDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => BlocProvider.value(
        value: parentContext.read<PatientsCubit>(),
        child: const _AddEyeExamDialog(),
      ),
    );
  }
}

/// بطاقة مقارنة قبل وبعد مع الصور والملاحظات
class _BeforeAfterCard extends StatelessWidget {
  final BeforeAfterGalleryItemModel item;

  const _BeforeAfterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final startDateStr = DateFormat('yyyy/MM/dd').format(item.startDate);
    final latestDateStr = item.latestDate != null
        ? DateFormat('yyyy/MM/dd').format(item.latestDate!)
        : 'الحالة الحالية';

    final specialtyLabel = switch (item.specialty) {
      'dermatology' => 'جلدية وليزر',
      'orthodontics' => 'تقويم أسنان',
      'dental' => 'طب وتجميل أسنان',
      'surgery' => 'جراحة تجميلية',
      _ => 'متابعة سريرية',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  specialtyLabel,
                  style: CustomAppFontStyle.semiBold12.copyWith(color: colors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.title,
                style: CustomAppFontStyle.bold15.copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'جلسة رقم: ${item.totalSessionsSoFar}',
                  style: CustomAppFontStyle.bold12.copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Side-by-side Comparison
          Row(
            children: [
              // Before Box
              Expanded(
                child: _buildImageCompareBox(
                  label: 'البداية (Baseline / Before)',
                  dateText: startDateStr,
                  imagePath: item.beforeImageBase64,
                  tagColor: AppColors.warning,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 16),
              // Arrow Indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.scaffoldBackground,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Icon(Icons.arrow_forward, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 16),
              // After Box
              Expanded(
                child: _buildImageCompareBox(
                  label: 'التقدم الحالي (Progress / After)',
                  dateText: latestDateStr,
                  imagePath: item.afterImageBase64,
                  tagColor: AppColors.success,
                  colors: colors,
                ),
              ),
            ],
          ),

          if (item.clinicalNotes != null && item.clinicalNotes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.clinicalNotes!,
                      style: CustomAppFontStyle.regular12.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCompareBox({
    required String label,
    required String dateText,
    required String? imagePath,
    required Color tagColor,
    required dynamic colors,
  }) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: colors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Stack(
        children: [
          // Visual Mock Image or Icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: colors.textSecondary.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 8),
                Text(
                  'توثيق سريري متاح في الملف',
                  style: CustomAppFontStyle.regular11.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Top Label Badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tagColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                label,
                style: CustomAppFontStyle.bold11.copyWith(color: tagColor),
              ),
            ),
          ),
          // Bottom Date Badge
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.cardBackground.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Text(
                dateText,
                style: CustomAppFontStyle.medium11.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// دايلوج إضافة فحص عيون دوري
class _AddEyeExamDialog extends StatefulWidget {
  const _AddEyeExamDialog();

  @override
  State<_AddEyeExamDialog> createState() => _AddEyeExamDialogState();
}

class _AddEyeExamDialogState extends State<_AddEyeExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _iopRightCtrl = TextEditingController(text: '15.5');
  final _iopLeftCtrl = TextEditingController(text: '16.0');
  final _vaRightCtrl = TextEditingController(text: '6/6');
  final _vaLeftCtrl = TextEditingController(text: '6/6');
  final _fundusCtrl = TextEditingController(text: 'شبكية سليمة، لا ارتشاح ولا نزيف');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _iopRightCtrl.dispose();
    _iopLeftCtrl.dispose();
    _vaRightCtrl.dispose();
    _vaLeftCtrl.dispose();
    _fundusCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            color: AppColors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.cyan, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تسجيل فحص دوري لقياسات العين (IOP)',
                          style: CustomAppFontStyle.semiBold16.copyWith(color: colors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _iopRightCtrl,
                        hintText: 'مثال: 16 mmHg',
                        headerText: 'ضغط العين اليمنى (IOP OD) *',
                        textInputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _iopLeftCtrl,
                        hintText: 'مثال: 15.5 mmHg',
                        headerText: 'ضغط العين اليسرى (IOP OS) *',
                        textInputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _vaRightCtrl,
                        hintText: 'مثال: 6/6',
                        headerText: 'حدة إبصار اليمنى (VA OD)',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _vaLeftCtrl,
                        hintText: 'مثال: 6/9',
                        headerText: 'حدة إبصار اليسرى (VA OS)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _fundusCtrl,
                  hintText: 'حالة العصب البصري والماكيولا وقاع العين...',
                  headerText: 'فحص قاع العين (Fundus Examination)',
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _notesCtrl,
                  hintText: 'تعليمات القطرات أو موعد قياس الضغط القادم...',
                  headerText: 'ملاحظات وتوصيات الطبيب',
                  maxLine: 2,
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: TextStyle(color: colors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    CustomPushButton(
                      height: 40,
                      width: 150,
                      backgroundColor: AppColors.cyan,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final exam = EyeTrackingExamModel(
                            id: 'EYE-${DateTime.now().millisecondsSinceEpoch}',
                            examDate: DateTime.now(),
                            iopRight: double.tryParse(_iopRightCtrl.text.trim()) ?? 15.0,
                            iopLeft: double.tryParse(_iopLeftCtrl.text.trim()) ?? 15.0,
                            visualAcuityRight: _vaRightCtrl.text.trim(),
                            visualAcuityLeft: _vaLeftCtrl.text.trim(),
                            fundusNotes: _fundusCtrl.text.trim(),
                            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                          );
                          context.read<PatientsCubit>().addEyeExam(exam);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'حفظ الفحص',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: Colors.white,
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
  }
}

/// دايلوج إضافة صورة سريرية ومقارنة Before & After
class _AddGalleryItemDialog extends StatefulWidget {
  const _AddGalleryItemDialog();

  @override
  State<_AddGalleryItemDialog> createState() => _AddGalleryItemDialogState();
}

class _AddGalleryItemDialogState extends State<_AddGalleryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  String _specialty = 'dermatology';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sessionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.compare_outlined, color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إضافة توثيق سريري (Before / After)',
                          style: CustomAppFontStyle.semiBold16.copyWith(color: colors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Specialty Selector
                Text(
                  'التخصص الطبي المعني *',
                  style: CustomAppFontStyle.medium12.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSpecChip('جلدية وتجميل', 'dermatology', colors),
                    _buildSpecChip('تقويم أسنان', 'orthodontics', colors),
                    _buildSpecChip('تجميل أسنان وزراعة', 'dental', colors),
                    _buildSpecChip('جراحة تجميل', 'surgery', colors),
                  ],
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _titleCtrl,
                  hintText: 'مثال: متابعة جلسات الفراكشنال ليزر للندبات',
                  headerText: 'عنوان التوثيق / الإجراء *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'برجاء إدخال عنوان الإجراء' : null,
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _sessionsCtrl,
                  hintText: 'مثال: 3',
                  headerText: 'رقم الجلسة المنفذة حتى الآن',
                  textInputType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _notesCtrl,
                  hintText: 'ملاحظات حول تحسن التصبغات، إغلاق الفراغات، أو النتائج الملموسة...',
                  headerText: 'الملاحظات السريرية والتوصيات',
                  maxLine: 2,
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('إلغاء', style: TextStyle(color: colors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    CustomPushButton(
                      height: 40,
                      width: 150,
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final item = BeforeAfterGalleryItemModel(
                            id: 'BA-${DateTime.now().millisecondsSinceEpoch}',
                            title: _titleCtrl.text.trim(),
                            specialty: _specialty,
                            startDate: DateTime.now().subtract(const Duration(days: 60)),
                            latestDate: DateTime.now(),
                            totalSessionsSoFar: int.tryParse(_sessionsCtrl.text.trim()) ?? 1,
                            clinicalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                          );
                          context.read<PatientsCubit>().addBeforeAfterGalleryItem(item);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'حفظ التوثيق',
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: Colors.white,
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
  }

  Widget _buildSpecChip(String label, String value, dynamic colors) {
    final isSelected = _specialty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _specialty = value);
      },
      selectedColor: colors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

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

class PatientLabRadiologySection extends StatefulWidget {
  final PatientModel? patient;

  const PatientLabRadiologySection({super.key, this.patient});

  @override
  State<PatientLabRadiologySection> createState() =>
      _PatientLabRadiologySectionState();
}

class _PatientLabRadiologySectionState
    extends State<PatientLabRadiologySection> {
  String _selectedFilter = 'all'; // 'all', 'lab', 'radiology'

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final currentPatient =
        widget.patient ?? context.watch<PatientsCubit>().state.selectedPatient;
    if (currentPatient == null) return const SizedBox.shrink();

    final allRecords = currentPatient.labAndRadiology ?? [];

    final filteredRecords = allRecords.where((r) {
      if (_selectedFilter == 'all') return true;
      return r.type == _selectedFilter;
    }).toList();

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
                      Icons.biotech_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفحوصات المخبرية والأشعة التشخيصية',
                        style: CustomAppFontStyle.bold16.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أرشيف نتائج التحاليل، صور وتقارير السونار والرنين والأشعة مع المرفقات',
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
                onTap: () => _showUploadDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'رفع نتيجة فحص أو أشعة',
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
          const SizedBox(height: 12),

          // Filter Chips: All, Labs, Radiology
          Row(
            children: [
              _buildFilterChip('all', 'الكل (${allRecords.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(
                'lab',
                'التحاليل المخبرية (${allRecords.where((r) => r.type == 'lab').length})',
                icon: Icons.science_outlined,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'radiology',
                'الأشعة التشخيصية (${allRecords.where((r) => r.type == 'radiology').length})',
                icon: Icons.camera_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (filteredRecords.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 40,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد نتائج فحوصات مسجلة في هذا القسم حالياً',
                    style: CustomAppFontStyle.medium12.copyWith(
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
              itemCount: filteredRecords.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final rec = filteredRecords[idx];
                final isLab = rec.type == 'lab';
                final dateStr =
                    '${rec.date.year}/${rec.date.month.toString().padLeft(2, '0')}/${rec.date.day.toString().padLeft(2, '0')}';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLab
                              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                              : const Color(0xFF0D9488).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLab ? Icons.science_rounded : Icons.photo_camera_back_outlined,
                          color: isLab
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0D9488),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    rec.title,
                                    style: CustomAppFontStyle.bold14.copyWith(
                                      color: colors.textPrimary,
                                    ),
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
                                    isLab ? 'تحليل دم / مخبري' : 'أشعة تشخيصية',
                                    style: CustomAppFontStyle.medium11.copyWith(
                                      color: isLab
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'التاريخ: $dateStr ${rec.centerName != null ? '• المعمل/المركز: ${rec.centerName}' : ''} ${rec.requestingDoctor != null ? '• الطبيب: ${rec.requestingDoctor}' : ''}',
                              style: CustomAppFontStyle.medium12.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            if (rec.resultSummary != null &&
                                rec.resultSummary!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.cardBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: colors.borderSubtle),
                                ),
                                child: Text(
                                  'ملخص النتيجة: ${rec.resultSummary}',
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                            if (rec.normalRange != null &&
                                rec.normalRange!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'المعدل الطبيعي: ${rec.normalRange}',
                                style: CustomAppFontStyle.regular11.copyWith(
                                  color: AppColors.success,
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

  Widget _buildFilterChip(String key, String label, {IconData? icon}) {
    final colors = context.themeColors;
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: CustomAppFontStyle.medium11.copyWith(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final colors = context.themeColors;
    final titleCtrl = TextEditingController();
    final centerCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final normalCtrl = TextEditingController();
    String selectedType = 'lab';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderSubtle),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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
                        'رفع نتيجة فحص معملي أو أشعة تشخيصية',
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

                  // Type Selector: Lab vs Radiology
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDlgState(() => selectedType = 'lab'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == 'lab'
                                  ? colors.primaryLight
                                  : colors.surfaceLevel1,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedType == 'lab'
                                    ? colors.primary
                                    : colors.borderSubtle,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_outlined,
                                    size: 16,
                                    color: selectedType == 'lab'
                                        ? colors.primary
                                        : colors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'تحليل معملي / مخبري',
                                  style: CustomAppFontStyle.semiBold12.copyWith(
                                    color: selectedType == 'lab'
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setDlgState(() => selectedType = 'radiology'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == 'radiology'
                                  ? colors.primaryLight
                                  : colors.surfaceLevel1,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedType == 'radiology'
                                    ? colors.primary
                                    : colors.borderSubtle,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 16,
                                    color: selectedType == 'radiology'
                                        ? colors.primary
                                        : colors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'أشعة تشخيصية / تصوير',
                                  style: CustomAppFontStyle.semiBold12.copyWith(
                                    color: selectedType == 'radiology'
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CustomTextFormField(
                    controller: titleCtrl,
                    headerText: 'اسم الفحص أو نوع الأشعة',
                    hintText: selectedType == 'lab'
                        ? 'مثال: صورة دم كاملة (CBC)'
                        : 'مثال: أشعة سينية على الصدر (Chest X-Ray)',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: centerCtrl,
                          headerText: 'اسم المعمل أو مركز الأشعة',
                          hintText: 'مثال: معمل المختبر',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextFormField(
                          controller: doctorCtrl,
                          headerText: 'الطبيب المعالج / الطالب',
                          hintText: 'مثال: د. حسام الدين مصطفى',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: summaryCtrl,
                    headerText: 'ملخص النتيجة الطبية',
                    hintText: 'اكتب النتيجة أو القراءات البارزة...',
                  ),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: normalCtrl,
                    headerText: 'المعدل الطبيعي (اختياري)',
                    hintText: 'مثال: 12 - 16 g/dL',
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
                          if (titleCtrl.text.trim().isEmpty) return;
                          final newRecord = LabRadiologyModel(
                            id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            type: selectedType,
                            date: DateTime.now(),
                            centerName: centerCtrl.text.trim(),
                            requestingDoctor: doctorCtrl.text.trim(),
                            resultSummary: summaryCtrl.text.trim(),
                            normalRange: normalCtrl.text.trim(),
                          );
                          context
                              .read<PatientsCubit>()
                              .addLabRadiologyRecord(newRecord);
                          Navigator.pop(dlgCtx);
                          CustomToast(
                            context: context,
                            header: 'تم رفع وتوثيق نتيجة الفحص بنجاح',
                          ).showTopToast();
                        },
                        child: const Text('حفظ وتوثيق الفحص',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

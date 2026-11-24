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

/// قسم السجل الجراحي والعمليات السابقة للمريض
class PatientSurgicalHistorySection extends StatelessWidget {
  const PatientSurgicalHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        final patient = state.selectedPatient;
        if (patient == null) return const SizedBox.shrink();

        final surgeries = patient.surgicalHistory ?? [];

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
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 22,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السجل الجراحي وتاريخ العمليات السابقة',
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'توثيق التدخلات الجراحية السابقة، المستشفيات، والأطباء الجراحين المشرفين',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomPushButton(
                    height: 38,
                    width: 175,
                    backgroundColor: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showAddSurgeryDialog(context),
                    child: Text(
                      '+ إضافة عملية جراحية',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (surgeries.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: colors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد عمليات جراحية مسجلة في السجل الطبي لهذا المريض',
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يمكنك توثيق أي عملية سابقة للمساعدة في سلامة التخدير والتاريخ السريري',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: surgeries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = surgeries[index];
                    return _SurgicalProcedureCard(item: item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSurgeryDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => BlocProvider.value(
        value: parentContext.read<PatientsCubit>(),
        child: const _AddSurgeryDialog(),
      ),
    );
  }
}

class _SurgicalProcedureCard extends StatelessWidget {
  final SurgicalProcedureModel item;

  const _SurgicalProcedureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final dateFormatted = DateFormat('yyyy/MM/dd').format(item.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.healing_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.procedureName,
                          style: CustomAppFontStyle.bold15.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFormatted,
                                style: CustomAppFontStyle.medium12.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hospital & Surgeon badges
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (item.hospital != null && item.hospital!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_hospital_outlined,
                                  size: 14,
                                  color: AppColors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'المستشفى: ${item.hospital}',
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: AppColors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.surgeonName != null && item.surgeonName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'الجراح: ${item.surgeonName}',
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.textSecondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.notes!,
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSurgeryDialog extends StatefulWidget {
  const _AddSurgeryDialog();

  @override
  State<_AddSurgeryDialog> createState() => _AddSurgeryDialogState();
}

class _AddSurgeryDialogState extends State<_AddSurgeryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _surgeonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 180));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hospitalCtrl.dispose();
    _surgeonCtrl.dispose();
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
                          child: Icon(Icons.healing_outlined, color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إضافة عملية جراحية سابقة',
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

                CustomTextFormField(
                  controller: _nameCtrl,
                  hintText: 'مثال: استئصال الزائدة الدودية بالمنظار',
                  headerText: 'اسم العملية الجراحية *',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'برجاء كتابة اسم العملية' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: _hospitalCtrl,
                        hintText: 'مثال: مستشفى السلام الدولي',
                        headerText: 'المستشفى / المركز الجراحي',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextFormField(
                        controller: _surgeonCtrl,
                        hintText: 'مثال: د. أشرف الشربيني',
                        headerText: 'اسم الطبيب الجراح',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date Picker field
                Text(
                  'تاريخ إجراء العملية',
                  style: CustomAppFontStyle.medium12.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy/MM/dd').format(_selectedDate),
                          style: CustomAppFontStyle.medium13.copyWith(color: colors.textPrimary),
                        ),
                        Icon(Icons.calendar_month_outlined, size: 18, color: colors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextFormField(
                  controller: _notesCtrl,
                  hintText: 'ملاحظات عن التخدير، مسار التعافي، أو المضاعفات إن وجدت...',
                  headerText: 'ملاحظات سريرية إضافية',
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
                      width: 160,
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final newSurgery = SurgicalProcedureModel(
                            id: 'SURG-${DateTime.now().millisecondsSinceEpoch}',
                            procedureName: _nameCtrl.text.trim(),
                            hospital: _hospitalCtrl.text.trim().isEmpty ? null : _hospitalCtrl.text.trim(),
                            surgeonName: _surgeonCtrl.text.trim().isEmpty ? null : _surgeonCtrl.text.trim(),
                            date: _selectedDate,
                            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                          );
                          context.read<PatientsCubit>().addSurgicalProcedure(newSurgery);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'حفظ في السجل الطبي',
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

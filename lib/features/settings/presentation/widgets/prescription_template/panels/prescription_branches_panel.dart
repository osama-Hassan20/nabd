import 'package:flutter/material.dart';
import '../../../../../../core/utils/extensions/theme_mode_extensions.dart';
import '../../../../../../core/utils/theme/app_colors.dart';
import '../../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../data/models/prescription_template_model.dart';

class PrescriptionBranchesPanel extends StatelessWidget {
  final PrescriptionTemplateModel template;
  final List<TextEditingController> addressCtrls;
  final List<TextEditingController> phoneCtrls;
  final TextEditingController footerHeightCtrl;
  final TextEditingController footerMarginTopCtrl;
  final TextEditingController footerMarginBottomCtrl;
  final TextEditingController footerMarginRightCtrl;
  final TextEditingController footerMarginLeftCtrl;
  final void Function(PrescriptionTemplateModel Function()) updateTemplate;
  final VoidCallback onAddAddress;
  final void Function(int) onRemoveAddress;
  final VoidCallback onAddPhone;
  final void Function(int) onRemovePhone;
  final VoidCallback onStateChanged;

  const PrescriptionBranchesPanel({
    super.key,
    required this.template,
    required this.addressCtrls,
    required this.phoneCtrls,
    required this.footerHeightCtrl,
    required this.footerMarginTopCtrl,
    required this.footerMarginBottomCtrl,
    required this.footerMarginRightCtrl,
    required this.footerMarginLeftCtrl,
    required this.updateTemplate,
    required this.onAddAddress,
    required this.onRemoveAddress,
    required this.onAddPhone,
    required this.onRemovePhone,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    return CustomContainer(
      backGroundColor: colors.cardBackground,
      border: Border.all(color: colors.borderSubtle),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'عناوين الفروع المطبوعة أسفل الروشتة:',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              CustomPushButton(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
                onTap: onAddAddress,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'إضافة فرع',
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._buildPairedAddressInputs(colors),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_in_talk_outlined,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'أرقام الهواتف والخط الساخن المطبوعة:',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              CustomPushButton(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: colors.primaryLight,
                borderRadius: BorderRadius.circular(6),
                onTap: onAddPhone,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'إضافة هاتف',
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._buildPairedPhoneInputs(colors),

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),

          // Footer Height Direct Number Input & Margins
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: footerHeightCtrl,
                  headerText: 'ارتفاع التذييل السفلي (px - كتابة رقم مباشر)',
                  hintText: '70',
                  textInputType: TextInputType.number,
                  onChanged: (v) {
                    final n = double.tryParse(v ?? '') ?? 70.0;
                    updateTemplate(() => template.copyWith(footerHeight: n));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: 'تقليل 5px',
                      onPressed: () {
                        final current =
                            double.tryParse(footerHeightCtrl.text) ??
                                template.footerHeight;
                        final next = (current - 5).clamp(20.0, 200.0);
                        footerHeightCtrl.text = next.toInt().toString();
                        updateTemplate(
                          () => template.copyWith(footerHeight: next),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: 'زيادة 5px',
                      onPressed: () {
                        final current =
                            double.tryParse(footerHeightCtrl.text) ??
                                template.footerHeight;
                        final next = (current + 5).clamp(20.0, 200.0);
                        footerHeightCtrl.text = next.toInt().toString();
                        updateTemplate(
                          () => template.copyWith(footerHeight: next),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Footer 4-way Margins
          Row(
            children: [
              Text(
                'هوامش التذييل (mm):',
                style: CustomAppFontStyle.medium11.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginTopCtrl,
                        headerText: 'أعلى',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 8.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginTop: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginBottomCtrl,
                        headerText: 'أسفل',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 12.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginBottom: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginRightCtrl,
                        headerText: 'يمين',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginRight: n),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextFormField(
                        controller: footerMarginLeftCtrl,
                        headerText: 'يسار',
                        textInputType: TextInputType.number,
                        onChanged: (v) {
                          final n = double.tryParse(v ?? '') ?? 15.0;
                          updateTemplate(
                            () => template.copyWith(footerMarginLeft: n),
                          );
                        },
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

  List<Widget> _buildPairedAddressInputs(AppThemeColors colors) {
    final widgets = <Widget>[];
    for (int i = 0; i < addressCtrls.length; i += 2) {
      final idx1 = i;
      final idx2 = i + 1;
      final hasSecond = idx2 < addressCtrls.length;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: addressCtrls[idx1],
                        hintText: 'مثال: فرع المعادي: 15 شارع النصر...',
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 26, minHeight: 26),
                      icon: const Icon(Icons.delete_outline,
                          size: 15, color: AppColors.error),
                      onPressed: () => onRemoveAddress(idx1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasSecond)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: addressCtrls[idx2],
                          hintText: 'مثال: فرع المهندسين: 42 شارع جامعة الدول...',
                          onChanged: (_) => onStateChanged(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemoveAddress(idx2),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildPairedPhoneInputs(AppThemeColors colors) {
    final widgets = <Widget>[];
    for (int i = 0; i < phoneCtrls.length; i += 2) {
      final idx1 = i;
      final idx2 = i + 1;
      final hasSecond = idx2 < phoneCtrls.length;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        controller: phoneCtrls[idx1],
                        hintText: 'مثال: 02 27508800 أو 01012345678',
                        textInputType: TextInputType.phone,
                        onChanged: (_) => onStateChanged(),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 26, minHeight: 26),
                      icon: const Icon(Icons.delete_outline,
                          size: 15, color: AppColors.error),
                      onPressed: () => onRemovePhone(idx1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasSecond)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: phoneCtrls[idx2],
                          hintText: 'مثال: الخط الساخن 19888',
                          textInputType: TextInputType.phone,
                          onChanged: (_) => onStateChanged(),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        icon: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                        onPressed: () => onRemovePhone(idx2),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

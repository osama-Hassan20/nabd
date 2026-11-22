import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class DefaultPricingTab extends StatefulWidget {
  final SettingsCubit settingsCubit;

  const DefaultPricingTab({super.key, required this.settingsCubit});

  @override
  State<DefaultPricingTab> createState() => _DefaultPricingTabState();
}

class _DefaultPricingTabState extends State<DefaultPricingTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final rate = widget.settingsCubit.state.defaultHourlyRate;
    _rateController = TextEditingController(text: rate.toString());
  }

  @override
  void didUpdateWidget(covariant DefaultPricingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_rateController.text.isEmpty) {
      _rateController.text = widget.settingsCubit.state.defaultHourlyRate
          .toString();
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final rate = num.tryParse(_rateController.text.trim()) ?? 0;

    final success = await widget.settingsCubit.savePricing(rate);

    if (mounted) {
      if (success) {
        CustomToast(
          context: context,
          header: 'settings_saved_successfully'.tr(),
        ).showTopToast();
      } else {
        CustomToast(
          context: context,
          header: 'failed_to_load'.tr(),
        ).showErrorToast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Form(
            key: _formKey,
            child: CustomContainer(
              padding: const EdgeInsets.all(24),
              backGroundColor: colors.cardBackground,
              border: Border.all(color: colors.borderSubtle),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomAssetImage(
                          path: AppIcons.money,
                          width: 20,
                          height: 20,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'tab_pricing'.tr(),
                        style: CustomAppFontStyle.semiBold18.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'default_hourly_rate_desc'.tr(),
                    style: CustomAppFontStyle.regular14.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(height: 1, color: colors.borderSubtle),
                  const SizedBox(height: 24),

                  // Info Alert Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ملاحظة: هذا السعر يعتبر معياراً افتراضياً عند فتح نافذة حجز جديد، ويمكن لمسؤول النظام تخصيص السعر لكل حجز على حدة عند الحاجة، ولا يؤثر تغيير هذا السعر على الحجوزات السابقة.',
                            style: CustomAppFontStyle.regular13.copyWith(
                              color: colors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Hourly Rate Field
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: CustomTextFormField(
                      controller: _rateController,
                      headerText: 'default_hourly_rate'.tr(),
                      hintText: 'default_hourly_rate_hint'.tr(),
                      textInputType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      prefixWidget: const Padding(
                        padding: EdgeInsets.all(12),
                        child: CustomAssetImage(
                          path: AppIcons.money,
                          width: 16,
                          height: 16,
                        ),
                      ),
                      besideHeader: Text(
                        'egp'.tr(),
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'field_required'.tr();
                        }
                        final numValue = num.tryParse(value.trim());
                        if (numValue == null || numValue < 0) {
                          return 'invalid_amount'.tr();
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: CustomPushButton(
                        height: 44,
                        backgroundColor: colors.primary,
                        isLoading: isLoading,
                        borderRadius: BorderRadius.circular(8),
                        onTap: isLoading ? null : _handleSave,
                        child: Center(
                          child: Text(
                            'save_changes'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
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

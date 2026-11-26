import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/settings/data/models/enums/clinic_type_enum.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/settings_state.dart';
import 'package:eyadty/features/settings/presentation/widgets/dialogs/change_password_dialog.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class CompanyInfoTab extends StatefulWidget {
  final SettingsCubit settingsCubit;

  const CompanyInfoTab({super.key, required this.settingsCubit});

  @override
  State<CompanyInfoTab> createState() => _CompanyInfoTabState();
}

class _CompanyInfoTabState extends State<CompanyInfoTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late ClinicTypeEnum _selectedClinicType;
  late String _selectedPrescriptionScope;

  @override
  void initState() {
    super.initState();
    final settings = widget.settingsCubit.state.settings;
    _nameController = TextEditingController(text: settings?.companyName ?? '');
    final rawPhone = settings?.phone;
    String initialDigits = CustomPhoneField.extractLocalDigits(rawPhone);
    if (initialDigits.isNotEmpty && !initialDigits.startsWith('0')) {
      initialDigits = '0$initialDigits';
    }
    _phoneController = TextEditingController(
      text: initialDigits,
    );
    _addressController = TextEditingController(text: settings?.address ?? '');
    _selectedClinicType = settings?.clinicType ?? ClinicTypeEnum.polyclinic;
    _selectedPrescriptionScope =
        settings?.prescriptionCustomizationScope ?? 'unifiedCenter';
  }

  @override
  void didUpdateWidget(covariant CompanyInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final settings = widget.settingsCubit.state.settings;
    if (_nameController.text.isEmpty && settings?.companyName != null) {
      _nameController.text = settings!.companyName!;
      String initialDigits = CustomPhoneField.extractLocalDigits(settings.phone);
      if (initialDigits.isNotEmpty && !initialDigits.startsWith('0')) {
        initialDigits = '0$initialDigits';
      }
      _phoneController.text = initialDigits;
      _addressController.text = settings.address ?? '';
      _selectedClinicType = settings.clinicType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Validates Egyptian phone numbers (Mobile or Landline with governorate code).
  ///
  /// Egyptian Phone Structure:
  /// - Mobile: 11 digits starting with 010, 011, 012, or 015
  /// - Landline Cairo/Giza: 10 digits starting with 02 (e.g. 0227508800)
  /// - Landline Alexandria: 9 digits starting with 03 (e.g. 031234567)
  /// - Landline Other Governorates: 10 digits starting with 013, 040, 050, 055, etc.
  String? _validateEgyptianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr();
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return 'invalid_phone'.tr();
    }

    if (!clean.startsWith('0')) {
      return 'يجب أن يبدأ الرقم بـ 0 (كود المحافظة للأرضي أو 01 للمحمول)';
    }

    if (clean.startsWith('01')) {
      if (clean.length < 3 || !RegExp(r'^01[0125]').hasMatch(clean)) {
        return 'رقم المحمول المصري يجب أن يبدأ بـ 010 أو 011 أو 012 أو 015';
      }
      if (clean.length != 11) {
        return 'رقم المحمول المصري يجب أن يتكون من 11 رقماً بالضبط';
      }
      return null;
    }

    if (clean.startsWith('02')) {
      if (clean.length != 10) {
        return 'رقم أرضي القاهرة/الجيزة يتكون من 10 أرقام (مثال: 0227508800)';
      }
      return null;
    }

    if (clean.startsWith('03')) {
      if (clean.length != 9) {
        return 'رقم أرضي الإسكندرية يتكون من 9 أرقام (مثال: 031234567)';
      }
      return null;
    }

    if (clean.length != 10) {
      return 'رقم الهاتف الأرضي مع كود المحافظة يجب أن يتكون من 10 أرقام';
    }

    return null;
  }

  bool get _isCurrentPhoneInvalid {
    final text = _phoneController.text.trim();
    if (text.isEmpty) return false;
    return _validateEgyptianPhone(text) != null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final formattedPhone = CustomPhoneField.formatWithCountryCode(
      _phoneController.text,
      countryCode: '+20',
    );

    final success = await widget.settingsCubit.updateCompanyInfo(
      name: _nameController.text.trim(),
      phone: formattedPhone,
      address: _addressController.text.trim(),
      clinicType: _selectedClinicType,
      prescriptionCustomizationScope: _selectedPrescriptionScope,
    );

    if (mounted) {
      if (success) {
        if (getIt.isRegistered<BookingsCubit>()) {
          getIt<BookingsCubit>().fetchCompanySettings();
        }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Company Info Card ──────────────────────────────────────
                CustomContainer(
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
                              path: AppIcons.company,
                              width: 20,
                              height: 20,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'tab_company_info'.tr(),
                            style: CustomAppFontStyle.semiBold18.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: colors.borderSubtle),
                      const SizedBox(height: 24),

                      // Company Name
                      CustomTextFormField(
                        controller: _nameController,
                        headerText: 'company_name'.tr(),
                        hintText: 'company_name_hint'.tr(),
                        prefixWidget: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CustomAssetImage(
                            path: AppIcons.info,
                            width: 16,
                            height: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'field_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Company Phone
                      CustomPhoneField(
                        phoneController: _phoneController,
                        header: 'company_phone'.tr(),
                        phoneCode: '+20',
                        hintText: '0227508800',
                        validatorFun: _validateEgyptianPhone,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_isCurrentPhoneInvalid) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'clinic_phone_invalid_alert'.tr(),
                                  style: CustomAppFontStyle.regular12.copyWith(
                                    color: AppColors.darkText,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Company Address
                      CustomTextFormField(
                        controller: _addressController,
                        headerText: 'company_address'.tr(),
                        hintText: 'company_address_hint'.tr(),
                        prefixWidget: const Padding(
                          padding: EdgeInsets.all(12),
                          child: CustomAssetImage(
                            path: AppIcons.location,
                            width: 16,
                            height: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'field_required'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Facility Operating Mode
                      Text(
                        'فئة ونوع المنشأة الطبية',
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تحدد طريقة تسجيل المواعيد وسلوك نموذج الحجز وتلقائية اختيار الأطباء وتحديد الأسعار.',
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildClinicTypeOption(
                              type: ClinicTypeEnum.polyclinic,
                              title: 'مركز طبي / مجمع عيادات',
                              subtitle:
                                  'أطباء وتخصصات متعددة؛ الاستقبال يحدد الطبيب، والأطباء يُملأ لهم طبيبهم الافتراضي مع إمكانية التحويل.',
                              icon: Icons.local_hospital_outlined,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildClinicTypeOption(
                              type: ClinicTypeEnum.singleDoctor,
                              title: 'عيادة فردية (طبيب واحد)',
                              subtitle:
                                  'طبيب واحد مع سكرتارية؛ إخفاء قائمة الأطباء وتعبئة كشف الطبيب وسعره تلقائياً دون أي خطوات إضافية.',
                              icon: Icons.person_outline_rounded,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),

                      if (_selectedClinicType == ClinicTypeEnum.polyclinic) ...[
                        const SizedBox(height: 20),
                        Divider(height: 1, color: colors.borderSubtle),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.print_outlined,
                                size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'سياسة وهوية قوالب الروشتة في المركز الطبي',
                              style: CustomAppFontStyle.semiBold14.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'تحدد ما إذا كان المركز يستخدم قالباً وهوية موحدة لجميع الأطباء، أو يُسمح لكل طبيب بتصميم روشتته الخاصة المستقلة.',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPrescriptionScopeOption(
                                scope: 'unifiedCenter',
                                title: 'روشتة موحدة للمركز (إشراف الإدارة)',
                                subtitle:
                                    'شعار وهوية وبانر المركز موحد لجميع العيادات؛ المالك فقط من يصمم القالب مع طباعة اسم الطبيب وتخصصه آلياً.',
                                icon: Icons.domain_rounded,
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPrescriptionScopeOption(
                                scope: 'perDoctor',
                                title: 'تخصيص مستقل لكل طبيب / عيادة',
                                subtitle:
                                    'يُمنح كل طبيب داخل المركز حرية رفع لوجو وبانر خاص وتصميم شكل الروشتة والظهر المستقل بما يناسب تخصصه.',
                                icon: Icons.badge_outlined,
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

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

                const SizedBox(height: 24),

                // ─── Security & Password Card ───────────────────────────────
                CustomContainer(
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
                              path: AppIcons.lock,
                              width: 20,
                              height: 20,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'security_settings'.tr(),
                            style: CustomAppFontStyle.semiBold18.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'security_settings_desc'.tr(),
                        style: CustomAppFontStyle.regular14.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: colors.borderSubtle),
                      const SizedBox(height: 20),

                      Row(
                        spacing: 16,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '••••••••••••',
                                  style: CustomAppFontStyle.bold18.copyWith(
                                    color: colors.textPrimary,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${'current_password'.tr()} (Admin)',
                                  style: CustomAppFontStyle.regular12.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: CustomPushButton(
                                height: 40,
                                backgroundColor: colors.surfaceLevel1,
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ChangePasswordDialog.show(
                                    context: context,
                                    settingsCubit: widget.settingsCubit,
                                  );
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CustomAssetImage(
                                        path: AppIcons.lock,
                                        width: 16,
                                        height: 16,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: FittedBox(
                                          child: Text(
                                            'change_password'.tr(),
                                            style: CustomAppFontStyle.semiBold14
                                                .copyWith(
                                                  color: colors.primary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClinicTypeOption({
    required ClinicTypeEnum type,
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic colors,
  }) {
    final isSelected = _selectedClinicType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedClinicType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryLight
              : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.borderSubtle.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: isSelected
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
    );
  }

  Widget _buildPrescriptionScopeOption({
    required String scope,
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic colors,
  }) {
    final isSelected = _selectedPrescriptionScope == scope;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPrescriptionScope = scope;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.surfaceLevel1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.borderSubtle.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: isSelected
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: CustomAppFontStyle.regular11.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
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
}

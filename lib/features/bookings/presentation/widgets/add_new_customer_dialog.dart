import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_form_options_model.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:purexo/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';

class AddNewCustomerDialog extends StatefulWidget {
  const AddNewCustomerDialog({super.key});

  static Future<BookingCustomerOption?> show(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return showDialog<BookingCustomerOption>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        return BlocProvider.value(
          value: cubit,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const AddNewCustomerDialog(),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AddNewCustomerDialog> createState() => _AddNewCustomerDialogState();
}

class _AddNewCustomerDialogState extends State<AddNewCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<BookingsCubit>();
    final newId = 'CUST-${cubit.state.customers.length + 1}';
    final formattedPhone = CustomPhoneField.formatWithCountryCode(
      _phoneController.text,
      countryCode: '+974',
    );

    final newCustomer = BookingCustomerOption(
      id: newId,
      name: _nameController.text.trim(),
      phone: formattedPhone,
      address: _addressController.text.trim(),
    );

    cubit.addCustomerOption(newCustomer);
    Navigator.of(context).pop(newCustomer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: CustomAssetImage(
                        path: AppIcons.user,
                        width: 18,
                        height: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'add_new_customer'.tr(),
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'أدخل بيانات العميل الجديد لتحديده مباشرة في الحجز',
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CloseButton(),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 18),

              // ─── Customer Name ───────────────────────────────────────
              CustomTextFormField(
                controller: _nameController,
                headerText: 'customer_name_hint'.tr(),
                hintText: 'مثال: شيخة الكواري',
                isRequired: true,
                prefixWidget: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomAssetImage(
                    path: AppIcons.user,
                    width: 16,
                    height: 16,
                    color: AppColors.primary,
                  ),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'field_required'.tr();
                  }
                  if (v.trim().length < 2) {
                    return 'الاسم يجب أن يكون حرفين على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ─── Customer Phone (Qatar +974) ─────────────────────────
              CustomPhoneField(
                phoneController: _phoneController,
                header: 'customer_phone_hint'.tr(),
                phoneCode: '+974',
                hintText: '33XX XXXX',
              ),
              const SizedBox(height: 14),

              // ─── Customer Address ────────────────────────────────────
              CustomTextFormField(
                controller: _addressController,
                headerText: 'customer_address_hint'.tr(),
                hintText: 'الدوحة، اللؤلؤة، برج 12...',
                prefixWidget: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomAssetImage(
                    path: AppIcons.location,
                    width: 16,
                    height: 16,
                    color: AppColors.primary,
                  ),
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
              ),
              const SizedBox(height: 22),

              // ─── Actions ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 42,
                    width: 90,
                    backgroundColor: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(),
                    child: Center(
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 42,
                      backgroundColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      onTap: _submit,
                      child: Center(
                        child: Text(
                          'save_customer'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.white,
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
      ),
    );
  }
}

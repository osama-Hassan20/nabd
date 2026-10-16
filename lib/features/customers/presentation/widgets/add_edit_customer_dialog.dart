import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_cubit.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_state.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddEditCustomerDialog extends StatefulWidget {
  final CustomerModel? customer;
  final bool isFullScreen;
  final CustomersCubit customersCubit;

  const AddEditCustomerDialog({
    super.key,
    this.customer,
    this.isFullScreen = false,
    required this.customersCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    CustomerModel? customer,
    CustomersCubit? customersCubit,
  }) {
    CustomersCubit? cubit = customersCubit;
    if (cubit == null) {
      try {
        cubit = context.read<CustomersCubit>();
      } catch (_) {
        cubit = getIt<CustomersCubit>();
      }
    }
    cubit.initCustomerForm(customer);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddEditCustomerDialog(
            customer: customer,
            isFullScreen: isMobile,
            customersCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AddEditCustomerDialog> createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final form = context.read<CustomersCubit>().state.formState;
    _nameController = TextEditingController(text: form?.name ?? '');

    final initialPhone = CustomPhoneField.extractLocalDigits(form?.phone);
    _phoneController = TextEditingController(text: initialPhone);
    _addressController = TextEditingController(text: form?.address ?? '');
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

    final formattedPhone = CustomPhoneField.formatWithCountryCode(
      _phoneController.text,
      countryCode: '+974',
    );

    context.read<CustomersCubit>().saveCustomer(
      name: _nameController.text.trim(),
      phone: formattedPhone,
      address: _addressController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    final titleText = isEditing ? 'edit_customer'.tr() : 'add_customer'.tr();

    return BlocConsumer<CustomersCubit, CustomersState>(
      bloc: widget.customersCubit,
      listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: isEditing
                ? 'تم تحديث بيانات العميل بنجاح'
                : 'تمت إضافة العميل بنجاح',
          ).showTopToast();
          Navigator.of(context).pop(true);
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: state.actionErrMessage ?? 'failed_to_load'.tr(),
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: widget.isFullScreen
                ? BorderRadius.zero
                : BorderRadius.circular(16),
            border: widget.isFullScreen
                ? null
                : Border.all(color: AppColors.grayE2E8F0),
            boxShadow: widget.isFullScreen
                ? null
                : [
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
                  // ─── Header ─────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: CustomAssetImage(
                            path: AppIcons.users,
                            width: 20,
                            height: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: CustomAppFontStyle.semiBold18.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? 'تحديث بيانات وسجل التواصل مع العميل'
                                  : 'أدخل معلومات العميل الجديد لإضافته للمنصة',
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
                  const SizedBox(height: 20),

                  // ─── Customer Name ────────────────────────────────────
                  CustomTextFormField(
                    controller: _nameController,
                    headerText: 'name'.tr(),
                    hintText: 'customer_name_hint'.tr(),
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
                  const SizedBox(height: 16),

                  // ─── Customer Phone (Qatar +974) ──────────────────────
                  CustomPhoneField(
                    phoneController: _phoneController,
                    header: 'customer_phone'.tr(),
                    phoneCode: '+974',
                    hintText: '33XX XXXX',
                  ),
                  const SizedBox(height: 16),

                  // ─── Customer Address ─────────────────────────────────
                  CustomTextFormField(
                    controller: _addressController,
                    headerText: 'customer_address'.tr(),
                    hintText: 'customer_address_hint'.tr(),
                    isRequired: true,
                    prefixWidget: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: CustomAssetImage(
                        path: AppIcons.location,
                        width: 16,
                        height: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(140)],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'field_required'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  // ─── Actions ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomPushButton(
                        height: 44,
                        width: 100,
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
                          height: 44,
                          backgroundColor: AppColors.primary,
                          isLoading: isLoading,
                          borderRadius: BorderRadius.circular(8),
                          onTap: _submit,
                          child: Center(
                            child: Text(
                              'save'.tr(),
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

        if (widget.isFullScreen) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              title: Text(
                titleText,
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const CustomAssetImage(
                  path: AppIcons.close,
                  width: 20,
                  height: 20,
                  color: AppColors.darkText,
                ),
              ),
            ),
            body: SafeArea(child: content),
          );
        }

        return content;
      },
    );
  }
}

import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final void Function(String password)? onConfirm;

  const ChangePasswordDialog({
    super.key,
    this.title = "تغيير كلمة المرور",
    this.subtitle = "أدخل كلمة المرور الجديدة وتأكيدها لتحديث بيانات الحساب",
    this.onConfirm,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: CustomAppFontStyle.regular18.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
              Text(
                widget.subtitle,
                style: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray7A828E,
                ),
              ),
              CustomTextFormField(
                controller: _passwordController,
                hintText: "كلمة المرور الجديدة",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور الجديدة';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
                  }
                  return null;
                },
                hintStyle: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray7A828E,
                ),
                prefixWidget: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomAssetImage(path: AppIcons.lock),
                ),
              ),
              CustomTextFormField(
                controller: _confirmPasswordController,
                hintText: "تأكيد كلمة المرور",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى تأكيد كلمة المرور';
                  }
                  if (value != _passwordController.text) {
                    return 'كلمات المرور غير متطابقة';
                  }
                  return null;
                },
                hintStyle: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray7A828E,
                ),
                prefixWidget: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomAssetImage(path: AppIcons.lock),
                ),
              ),
              CustomPushButton(
                height: 48,
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.onConfirm != null) {
                      widget.onConfirm!(_passwordController.text);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Center(
                  child: Text(
                    "تغيير كلمة المرور",
                    style: CustomAppFontStyle.regular16.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

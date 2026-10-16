import 'package:easy_localization/easy_localization.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/theme/app_icons.dart';
import '../../../../widgets/custom_text_field.dart';

class CustomPasswordField extends StatelessWidget {
  const CustomPasswordField({
    super.key,
    required this.isHidden,
    this.passwordController,
    this.passwordFocus,
    this.formKey,
    this.onFiledSumbitted,
    this.changeVisibilty,
    this.validationError,
    this.headerText,
    this.onValidationFailed,
    this.tempColor,
    this.hintText,
  });

  final bool isHidden;
  final String? validationError;
  final String? headerText;
  final TextEditingController? passwordController;
  final FocusNode? passwordFocus;
  final GlobalKey<FormState>? formKey;
  final void Function()? onFiledSumbitted;
  final void Function()? changeVisibilty;
  final void Function(String)? onValidationFailed;
  final Color? tempColor;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      headerText: headerText,
      isObeseureText: isHidden,
      controller: passwordController,
      focusNode: passwordFocus,
      validator: onValidationFailed != null
          ? (value) {
              onValidationFailed!(value ?? "");
              return null;
            }
          : (value) {
              if (value == null || value.trim().isEmpty) {
                return validationError ?? 'please_enter_password'.tr();
              }
              return null;
            },
      prefixWidget: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomAssetImage(path: AppIcons.lock),
      ),
      suffixWidget: IconButton(
        onPressed: () {
          changeVisibilty?.call();
        },
        icon: CustomAssetImage(
          path: isHidden ? AppIcons.visibileOn : AppIcons.visibileOff,
        ),
      ),
      hintText: hintText ?? 'password_hint'.tr(),
    );
  }
}

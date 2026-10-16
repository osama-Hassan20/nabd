import 'package:purexo/shared/widgets/custom_asset_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/theme/app_colors.dart';
import '../../../../../core/utils/theme/app_icons.dart';
import '../../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../function/phone_num_validation.dart';
import '../../../../widgets/custom_text_field.dart';

/// Formatter that automatically converts Arabic-Indic digits (٠-٩) to English digits (0-9)
class ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  const ArabicToEnglishDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var text = newValue.text;
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], '$i');
    }
    return newValue.copyWith(text: text, selection: newValue.selection);
  }
}

/// Dynamically limits phone digits:
/// If the phone starts with '0', it allows [baseLength + 1] digits.
/// If it does not start with '0', it allows [baseLength] digits.
class FlexiblePhoneLengthFormatter extends TextInputFormatter {
  final int baseLength;
  final bool acceptLeadingZero;

  const FlexiblePhoneLengthFormatter({
    required this.baseLength,
    this.acceptLeadingZero = true,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final startsWithZero = text.startsWith('0');
    final maxAllowed = (acceptLeadingZero && startsWithZero)
        ? baseLength + 1
        : baseLength;

    if (text.length > maxAllowed) {
      final truncated = text.substring(0, maxAllowed);
      return TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    return newValue;
  }
}

class CustomPhoneField extends StatelessWidget {
  const CustomPhoneField({
    super.key,
    this.onFieldSubmitted,
    this.phoneController,
    this.fillColor,
    this.enableValidator = true,
    this.isReadOnly = false,
    this.onTap,
    this.phoneFocus,
    this.hintText,
    this.validatorFun,
    this.header,
    this.tempColor,
    this.phoneCode,
    this.maxLength,
    this.acceptLeadingZero = true,
    this.onChanged,
    this.textDirection = TextDirection.ltr,
    this.textAlign,
  });

  final void Function(String? value)? onFieldSubmitted;
  final TextEditingController? phoneController;
  final Color? fillColor;
  final bool isReadOnly;
  final bool enableValidator;
  final void Function()? onTap;
  final String? hintText;
  final String? Function(String?)? validatorFun;
  final FocusNode? phoneFocus;
  final String? header;
  final Color? tempColor;
  final String? phoneCode;
  final int? maxLength;
  final bool acceptLeadingZero;
  final void Function(String? value)? onChanged;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  /// Extracts only the local phone digits from a phone number string,
  /// stripping country codes and any spaces/dashes that cause RTL reversal.
  /// Example: '+974 5512 3456' -> '55123456'
  /// Example: '5512 3456' -> '55123456'
  static String extractLocalDigits(
    String? phone, {
    String countryCode = '974',
  }) {
    if (phone == null || phone.isEmpty) return '';
    var clean = phone.trim();
    if (clean.startsWith('+$countryCode')) {
      clean = clean.substring(countryCode.length + 1);
    } else if (clean.startsWith('00$countryCode')) {
      clean = clean.substring(countryCode.length + 2);
    }
    // Remove all non-digits (spaces, dashes, parens, etc.)
    clean = clean.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith(countryCode) && clean.length > 8) {
      clean = clean.substring(countryCode.length);
    }
    return clean;
  }

  /// Normalizes the phone number by removing non-digits and stripping any leading 0,
  /// then prepends the country code.
  /// Example: '055123456' -> '+974 55123456'
  /// Example: '55123456' -> '+974 55123456'
  static String formatWithCountryCode(
    String phone, {
    String countryCode = '+974',
  }) {
    var clean = phone.trim();
    if (clean.startsWith('+')) return clean;
    clean = clean.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '$countryCode $clean'.trim();
  }

  String? _validatePhone(String? value, int baseLen, bool allowZero) {
    if (value == null || value.trim().isEmpty) {
      return 'ادخل رقم الهاتف...';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return 'ادخل رقم هاتف صحيح';
    }

    final startsWithZero = clean.startsWith('0');
    final minRequired = (allowZero && startsWithZero) ? baseLen + 1 : baseLen;

    if (clean.length < minRequired) {
      return startsWithZero
          ? 'رقم الهاتف غير مكتمل ($minRequired أرقام تبدأ بـ 0)'
          : 'رقم الهاتف غير مكتمل ($baseLen أرقام)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhoneCode = phoneCode ?? '+974';
    final int effectiveBaseLength =
        maxLength ?? (effectivePhoneCode == '+974' ? 8 : 10);

    return CustomTextFormField(
      focusNode: phoneFocus,
      fillDisableColor: fillColor,
      isReadOnly: isReadOnly,
      headerText: header,
      focusFillColor: fillColor,
      textDirection: textDirection,
      hintTextDirection: textDirection,
      textAlign: textAlign ?? TextAlign.start,
      prefixWidget: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomAssetImage(
          path: AppIcons.phone,
          color: tempColor ?? (AppColors.gray334155),
        ),
      ),
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: enableValidator
          ? (validatorFun ??
                (val) =>
                    _validatePhone(val, effectiveBaseLength, acceptLeadingZero))
          : null,
      controller: phoneController,
      tempColor: tempColor,
      textInputType: TextInputType.phone,
      inputFormatters: [
        const ArabicToEnglishDigitsFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        FlexiblePhoneLengthFormatter(
          baseLength: effectiveBaseLength,
          acceptLeadingZero: acceptLeadingZero,
        ),
      ],
      suffixWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                CustomAssetImage(path: AppIcons.qatar),
                Text(
                  effectivePhoneCode,
                  textDirection: TextDirection.ltr,
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: tempColor ?? (AppColors.gray71717A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      hintText:
          hintText ??
          (effectivePhoneCode == '+974' ? '33XX XXXX' : 'ادخل رقم الهاتف...'),
    );
  }
}

class CustomUserNameField extends StatelessWidget {
  const CustomUserNameField({
    super.key,
    this.onFieldSubmitted,
    this.nameController,
    this.fillColor,
    this.enableValidator = true,
    this.isReadOnly = false,
    this.onTap,
    this.nameFocus,
    this.hintText,
    this.validatorFun,
    this.tempColor,
  });

  final void Function(String? value)? onFieldSubmitted;
  final TextEditingController? nameController;
  final Color? fillColor;
  final bool isReadOnly;
  final bool enableValidator;
  final void Function()? onTap;
  final String? hintText;
  final String? Function(String?)? validatorFun;
  final FocusNode? nameFocus;
  final Color? tempColor;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      focusNode: nameFocus,
      fillDisableColor: fillColor,
      isReadOnly: isReadOnly,
      focusFillColor: fillColor,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      validator: enableValidator ? validatorFun ?? validateName : null,
      controller: nameController,
      //make validation for username to be alphanumeric and underscores only
      textInputType: TextInputType.text,
      // inputFormatters: [
      //   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_+]')),
      // ],
      prefixWidget: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomAssetImage(path: AppIcons.user),
      ),
      hintText: hintText ?? 'اسم المستخدم...',
    );
  }
}

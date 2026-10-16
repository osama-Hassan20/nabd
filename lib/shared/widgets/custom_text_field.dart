import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.maxLine = 1,
    this.minLine = 1,
    this.isDense = false,
    this.validator,
    this.besideHeader,
    this.controller,
    this.enableFocusBorder = true,
    this.textInputType,
    this.suffixText,
    this.suffixTextStyle,
    this.labelWidget,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.prefixWidget,
    this.suffixWidget,
    this.textStyle,
    this.enableFill = true,
    this.fillDisableColor = AppColors.fillDisableColor,
    this.label,
    this.isObeseureText = false,
    this.labelStyle,
    this.focusBorderColor,
    this.floatingLabelBehavior,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.headerText,
    this.isReadOnly = false,
    this.headerTextStyle,
    this.spacing = 4,
    this.initialValue,
    this.inputFormatters,
    this.contentPadding,
    this.maxLength,
    this.textAlign,
    this.onChanged,
    this.onEditingComplete,
    this.onTap,
    this.onSaved,
    this.hintStyle,
    this.hintText,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.disabledBorder,
    this.isRequired = false,
    this.height,
    this.errorStyle,
    this.isEnabled = true,
    this.textDirection,
    this.autovalidateMode,
    this.enableMinLine = true,
    this.isCollapsed = false,
    this.focusFillColor,
    this.bottomText,
    this.backgroundColor,
    this.tempColor,
    this.hintTextDirection,
    this.autofocus = false,
  });

  final Widget? labelWidget;
  final Widget? besideHeader;
  final double? borderRadius;
  final TextAlign? textAlign;
  final String? Function(String? value)? validator;
  final double? borderWidth;
  final Color? borderColor;
  final bool enableMinLine;
  final Color? fillDisableColor;
  final bool enableFill;
  final bool isCollapsed;
  final Widget? suffixWidget;
  final String? suffixText;
  final TextStyle? suffixTextStyle;
  final TextStyle? errorStyle;
  final Widget? prefixWidget;
  final int? maxLine;
  final int? minLine;
  final double spacing;
  final TextInputType? textInputType;
  final bool enableFocusBorder;
  final TextEditingController? controller;
  final TextStyle? textStyle;
  final String? label;
  final TextStyle? hintStyle;
  final String? hintText;
  final TextStyle? labelStyle;
  final double? height;
  final bool isObeseureText;
  final bool isRequired, isEnabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Color? focusBorderColor;
  final FocusNode? focusNode;
  final String? initialValue;
  final void Function(String?)? onFieldSubmitted;
  final void Function(String?)? onSaved;
  final void Function(String?)? onChanged;
  final void Function()? onEditingComplete;
  final void Function()? onTap;
  final String? headerText;
  final TextStyle? headerTextStyle;
  final Color? focusFillColor;
  final Color? backgroundColor;
  final bool isReadOnly;
  final EdgeInsetsDirectional? contentPadding;
  final int? maxLength;
  final bool isDense;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final TextDirection? textDirection;
  final TextDirection? hintTextDirection;
  final AutovalidateMode? autovalidateMode;
  final String? bottomText;
  final Color? tempColor;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBorderColor =
        borderColor ?? AppColors.lightBackground.withValues(alpha: 0.1);

    final Color effectiveFocusBorderColor =
        focusBorderColor ?? AppColors.darkBackground.withValues(alpha: 0.1);

    return Column(
      spacing: spacing,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerText != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  headerText!,
                  style:
                      headerTextStyle ??
                      CustomAppFontStyle.regular14.copyWith(
                        color: AppColors.gray71717A,
                      ),
                ),
              ),
              ?besideHeader,
            ],
          ),
        SizedBox(
          height: height,
          child: Transform.scale(
            scale: 1,
            child: TextFormField(
              minLines: enableMinLine ? minLine : null,
              obscuringCharacter: "•",
              //  i need to increase the font style of obsecure Text style of the obscure character
              autovalidateMode:
                  autovalidateMode ?? AutovalidateMode.onUserInteraction,
              onSaved: onSaved,
              enabled: isEnabled,
              onEditingComplete: onEditingComplete,
              onTap: onTap,
              onChanged: onChanged,
              mouseCursor: isReadOnly ? SystemMouseCursors.click : null,
              onTapOutside: (pos) {
                FocusScope.of(context).unfocus();
              },
              textDirection: textDirection,
              autofocus: autofocus,

              maxLength: maxLength,
              inputFormatters: inputFormatters,
              readOnly: isReadOnly,
              obscureText: isObeseureText,
              validator: validator,
              focusNode: focusNode,
              textInputAction: textInputAction,
              initialValue: initialValue,
              controller: controller,
              maxLines: maxLine,
              textAlign: textAlign ?? TextAlign.start,
              keyboardType: textInputType,
              cursorColor: tempColor ?? (AppColors.primary),
              style:
                  textStyle ??
                  CustomAppFontStyle.medium14.copyWith(
                    fontSize: 14,
                    color: (AppColors.black),
                  ),
              onFieldSubmitted: onFieldSubmitted,
              decoration: InputDecoration(
                fillColor: WidgetStateColor.resolveWith((states) {
                  return AppColors.fillDisableColor;
                }),
                isCollapsed: isCollapsed,
                filled: enableFill,
                isDense: isDense,
                hoverColor: Colors.transparent,
                counterText: "",
                errorMaxLines: 3,
                hintText: hintText,
                hintStyle:
                    hintStyle ??
                    CustomAppFontStyle.regular12.copyWith(
                      color: AppColors.grayBlue,
                    ),
                contentPadding:
                    contentPadding ??
                    const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 4,
                      bottom: 14,
                      top: 14,
                    ),
                alignLabelWithHint: true,
                labelText: label,
                labelStyle:
                    labelStyle ??
                    CustomAppFontStyle.regular14.copyWith(
                      color: AppColors.grayLight217,
                    ),
                errorStyle:
                    errorStyle ??
                    CustomAppFontStyle.regular12.copyWith(color: AppColors.red),
                focusColor: Colors.black,
                suffixIcon: suffixWidget,
                suffixText: suffixText,
                suffixStyle: suffixTextStyle,
                prefixIcon: prefixWidget,
                hintTextDirection: hintTextDirection ?? TextDirection.rtl,
                label: labelWidget,
                floatingLabelBehavior:
                    floatingLabelBehavior ?? FloatingLabelBehavior.never,
                errorBorder:
                    enabledBorder ??
                    customOutLineBorders(
                      borderWidth: 1,
                      borderColor: borderColor ?? AppColors.red,
                    ),
                disabledBorder:
                    disabledBorder ??
                    customOutLineBorders(
                      borderRadius: borderRadius,
                      borderColor: effectiveBorderColor,
                    ),
                border:
                    border ??
                    customOutLineBorders(
                      borderColor: effectiveBorderColor,
                      borderRadius: borderRadius,
                    ),
                enabledBorder:
                    enabledBorder ??
                    customOutLineBorders(
                      borderColor: effectiveFocusBorderColor,
                      borderRadius: borderRadius,
                    ),
                focusedBorder:
                    focusedBorder ??
                    customOutLineBorders(
                      borderWidth: 1,
                      borderRadius: borderRadius,
                      borderColor: enableFocusBorder
                          ? effectiveFocusBorderColor
                          : null,
                    ),
              ),
            ),
          ),
        ),
        if (bottomText != null) const SizedBox(height: 4),
        if (bottomText != null)
          Text(
            bottomText!,
            style:
                headerTextStyle ??
                CustomAppFontStyle.light16.copyWith(
                  color: AppColors.gray334155,
                ),
          ),
      ],
    );
  }
}

OutlineInputBorder customOutLineBorders({
  double? borderRadius,
  Color? borderColor,
  double? borderWidth,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadius ?? 14),
    borderSide: BorderSide(
      color: borderColor ?? AppColors.inputBorderColor,
      width: borderWidth ?? 0.75,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';

class CustomToast {
  final BuildContext context;
  final String header;
  final String? description;
  ToastificationType? type;
  final int duration;
  final AlignmentGeometry? alignment;
  CustomToast({
    required this.context,
    required this.header,
    this.description,
    this.alignment,
    this.duration = 3,
    this.type = ToastificationType.success,
  });

  void showTopToast() {
    toastification.show(
      showIcon: type == ToastificationType.warning ? true : false,
      primaryColor: type == ToastificationType.success
          ? const Color(0xff007834).withValues(alpha: 1)
          : null,

      style: ToastificationStyle.minimal,
      alignment: Alignment.topCenter,
      type: type,
      context: context,
      title: Text(
        header == 'No internet connection, please try again!'
            ? "ميزة الاتصال بالانترنت غير متوفرة"
            : header,
        style: CustomAppFontStyle.regular15.copyWith(
          color: type == ToastificationType.success
              ? const Color(0xff007834)
              : AppColors.red,
        ),
        textAlign: TextAlign.start,
        maxLines: 3,
      ),
      description: description != null
          ? Text(description!, style: CustomAppFontStyle.regular14)
          : null,
      autoCloseDuration: Duration(seconds: duration),
    );
  }

  void showErrorToast() {
    toastification.show(
      showIcon: true,
      primaryColor: AppColors.error,

      style: ToastificationStyle.minimal,
      alignment: Alignment.topCenter,
      type: ToastificationType.error,
      context: context,
      title: Text(
        header == 'No internet connection, please try again!'
            ? "ميزة الاتصال بالانترنت غير متوفرة"
            : header,
        style: CustomAppFontStyle.regular15.copyWith(color: AppColors.red),
        textAlign: TextAlign.start,
        maxLines: 3,
      ),
      description: description != null
          ? Text(description!, style: CustomAppFontStyle.regular14)
          : null,
      autoCloseDuration: Duration(seconds: duration),
    );
  }
}

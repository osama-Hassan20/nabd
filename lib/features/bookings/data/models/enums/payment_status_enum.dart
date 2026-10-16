import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';

enum PaymentStatusEnum {
  unpaid(
    value: 'unpaid',
    labelKey: 'payment_unpaid',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
    icon: AppIcons.pending,
  ),
  paid(
    value: 'paid',
    labelKey: 'payment_paid',
    color: AppColors.success,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.checkmarkCircle,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const PaymentStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static PaymentStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    return PaymentStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentStatusEnum.unpaid,
    );
  }
}

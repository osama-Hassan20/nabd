import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';

enum PaymentStatusEnum {
  paid(
    value: 'paid',
    labelKey: 'payment_status_paid',
    color: AppColors.secondary,
    backgroundColor: AppColors.secondaryLight,
  ),
  unpaid(
    value: 'unpaid',
    labelKey: 'payment_status_unpaid',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
  ),
  partiallyPaid(
    value: 'partially_paid',
    labelKey: 'payment_status_partially_paid',
    color: AppColors.statusWarning,
    backgroundColor: AppColors.statusWarningLight,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;

  const PaymentStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
  });

  String get label => labelKey.tr();

  static PaymentStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    final normalized = val.toLowerCase().trim();
    if (normalized == 'paid') return PaymentStatusEnum.paid;
    if (normalized == 'unpaid') return PaymentStatusEnum.unpaid;
    if (normalized == 'partially_paid' || normalized == 'partial') {
      return PaymentStatusEnum.partiallyPaid;
    }
    return PaymentStatusEnum.unpaid;
  }
}

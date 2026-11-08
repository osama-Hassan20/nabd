import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class BookingFormServiceField extends StatelessWidget {
  final TextEditingController controller;
  final bool isRequired;

  const BookingFormServiceField({
    super.key,
    required this.controller,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      headerText: 'reason_for_visit_label'.tr(),
      hintText: 'reason_for_visit_hint'.tr(),
      isRequired: isRequired,
      inputFormatters: [
        LengthLimitingTextInputFormatter(80),
      ],
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return 'field_required'.tr();
        }
        return null;
      },
    );
  }
}

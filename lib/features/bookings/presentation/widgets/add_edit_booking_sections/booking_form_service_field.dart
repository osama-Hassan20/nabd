import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';

class BookingFormServiceField extends StatelessWidget {
  final TextEditingController controller;

  const BookingFormServiceField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      headerText: 'service_label'.tr(),
      hintText: 'service_name_hint'.tr(),
      isRequired: true,
      inputFormatters: [
        LengthLimitingTextInputFormatter(80),
      ],
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'field_required'.tr();
        }
        return null;
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class BookingFormNotesSection extends StatelessWidget {
  final TextEditingController controller;

  const BookingFormNotesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      controller: controller,
      headerText: 'notes_label'.tr(),
      maxLine: 5,
      minLine: 3,
      hintText: 'booking_notes_hint'.tr(),
      inputFormatters: [
        LengthLimitingTextInputFormatter(500),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';

class BookingFormPricingSection extends StatelessWidget {
  final TextEditingController hourlyRateController;
  final TextEditingController totalPriceController;

  const BookingFormPricingSection({
    super.key,
    required this.hourlyRateController,
    required this.totalPriceController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextFormField(
            controller: hourlyRateController,
            headerText: 'hourly_rate_label'.tr(),
            hintText: '0',
            textInputType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CustomTextFormField(
            controller: totalPriceController,
            headerText: 'total_price_label'.tr(),
            hintText: '0',
            textInputType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

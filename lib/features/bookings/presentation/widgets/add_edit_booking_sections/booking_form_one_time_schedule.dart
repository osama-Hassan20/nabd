import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_text_field.dart';

class BookingFormOneTimeSchedule extends StatelessWidget {
  final TextEditingController dateController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final VoidCallback onPickDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;

  const BookingFormOneTimeSchedule({
    super.key,
    required this.dateController,
    required this.startTimeController,
    required this.endTimeController,
    required this.onPickDate,
    required this.onPickStartTime,
    required this.onPickEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: dateController,
          headerText: 'date_and_time_label'.tr(),
          hintText: 'اختر موعد الحجز...',
          isReadOnly: true,
          isRequired: true,
          onTap: onPickDate,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'field_required'.tr();
            }
            return null;
          },
          prefixWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: CustomAssetImage(
              path: AppIcons.calendar,
              width: 18,
              height: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: startTimeController,
                headerText: 'start_time'.tr(),
                hintText: 'وقت البدء...',
                isReadOnly: true,
                isRequired: true,
                onTap: onPickStartTime,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'field_required'.tr();
                  }
                  return null;
                },
                prefixWidget: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomAssetImage(
                    path: AppIcons.pending,
                    width: 18,
                    height: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextFormField(
                controller: endTimeController,
                headerText: 'end_time'.tr(),
                hintText: 'وقت الانتهاء...',
                isReadOnly: true,
                isRequired: true,
                onTap: onPickEndTime,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'field_required'.tr();
                  }
                  return null;
                },
                prefixWidget: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CustomAssetImage(
                    path: AppIcons.pending,
                    width: 18,
                    height: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

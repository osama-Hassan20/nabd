import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';

class BookingFormPatientSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function({String? initialQuery}) onAddNewPatient;

  const BookingFormPatientSection({
    super.key,
    required this.controller,
    required this.onAddNewPatient,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) => prev.customers != curr.customers,
      builder: (context, state) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomStackSelector<BookingPatientOption>(
                header: 'patient_label'.tr(),
                controller: controller,
                list: state.customers,
                itemAsString: (c) => "${c.name} ${c.phone}",
                displayStringForController: (c) => c.name,
                hintText: 'select_patient'.tr(),
                enableSearch: true,
                emptySearchBuilder: (ctx, query, close) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_search_outlined,
                            size: 36,
                            color: AppColors.gray71717A,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'no_patient_found_with_query'.tr(),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: AppColors.gray71717A,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          CustomPushButton(
                            height: 36,
                            backgroundColor: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              close();
                              onAddNewPatient(initialQuery: query);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'add_new_patient'.tr(),
                                    style:
                                        CustomAppFontStyle.semiBold12.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemBuilder: (context, c) {
                  final colors = context.themeColors;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.phone,
                            textDirection: TextDirection.ltr,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                changeValue: (c) => cubit.updateFormCustomer(c),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              height: 48,
              child: CustomPushButton(
                backgroundColor: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
                onTap: () => onAddNewPatient(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomAssetImage(
                      path: AppIcons.add,
                      width: 16,
                      height: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'add_new_patient'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


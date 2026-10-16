import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_form_options_model.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/custom_stack_selector.dart';

class BookingFormCustomerSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAddNewCustomer;

  const BookingFormCustomerSection({
    super.key,
    required this.controller,
    required this.onAddNewCustomer,
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
              child: CustomStackSelector<BookingCustomerOption>(
                header: 'customer_label'.tr(),
                controller: controller,
                list: state.customers,
                itemAsString: (c) => "${c.name} ${c.phone}",
                displayStringForController: (c) => c.name,
                hintText: 'select_customer'.tr(),
                enableSearch: true,
                itemBuilder: (context, c) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: AppColors.gray71717A,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.phone,
                            textDirection: TextDirection.ltr,
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
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
                onTap: onAddNewCustomer,
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
                        'add_new_customer'.tr(),
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

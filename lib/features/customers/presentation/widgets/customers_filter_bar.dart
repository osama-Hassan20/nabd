import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_cubit.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import 'add_edit_customer_dialog.dart';

class CustomersFilterBar extends StatelessWidget {
  const CustomersFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final isMobile = AdaptiveLayout.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextFormField(
            controller: cubit.searchController,
            hintText: 'search_customers_hint'.tr(),
            prefixWidget: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CustomAssetImage(
                path: AppIcons.search,
                width: 18,
                height: 18,
                color: AppColors.gray71717A,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomPushButton(
            height: 44,
            backgroundColor: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            onTap: () => AddEditCustomerDialog.show(context: context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CustomAssetImage(
                  path: AppIcons.add,
                  width: 18,
                  height: 18,
                  color: AppColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'add_customer'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: CustomTextFormField(
            controller: cubit.searchController,
            hintText: 'search_customers_hint'.tr(),
            prefixWidget: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CustomAssetImage(
                path: AppIcons.search,
                width: 18,
                height: 18,
                color: AppColors.gray71717A,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        CustomPushButton(
          height: 44,
          width: 240,
          backgroundColor: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onTap: () => AddEditCustomerDialog.show(context: context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.add,
                width: 18,
                height: 18,
                color: AppColors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'add_customer'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

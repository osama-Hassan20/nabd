import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/customers/data/models/customer_model.dart';
import 'package:purexo/features/customers/presentation/manager/customers_cubit.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

import 'add_edit_customer_dialog.dart';
import 'delete_customer_dialog.dart';

class CustomerActionsMenu extends StatelessWidget {
  final CustomerModel customer;

  const CustomerActionsMenu({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.grayf2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.more_vert,
          color: AppColors.gray71717A,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grayE2E8F0),
      ),
      color: AppColors.white,
      elevation: 0,
      offset: const Offset(0, 36),
      onSelected: (action) {
        switch (action) {
          case 'view':
            if (customer.id != null) {
              context.go('${AppRouter.customers}/${customer.id}');
            }
            break;
          case 'edit':
            AddEditCustomerDialog.show(
              context: context,
              customer: customer,
              customersCubit: context.read<CustomersCubit>(),
            );
            break;
          case 'delete':
            DeleteCustomerDialog.show(context: context, customer: customer);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.user,
                width: 16,
                height: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'view_details'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.edit,
                width: 16,
                height: 16,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 10),
              Text(
                'edit'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const CustomAssetImage(
                path: AppIcons.delete,
                width: 16,
                height: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Text(
                'delete'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/customers/data/models/customer_model.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_cubit.dart';
import 'package:eyadty/features/customers/presentation/manager/customers_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';

class DeleteCustomerDialog extends StatelessWidget {
  final CustomerModel customer;

  const DeleteCustomerDialog({super.key, required this.customer});

  static Future<bool?> show({
    required BuildContext context,
    required CustomerModel customer,
    CustomersCubit? customersCubit,
  }) {
    CustomersCubit? cubit = customersCubit;
    if (cubit == null) {
      try {
        cubit = context.read<CustomersCubit>();
      } catch (_) {
        cubit = getIt<CustomersCubit>();
      }
    }
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: cubit!,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DeleteCustomerDialog(customer: customer),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveBookings = (customer.upcomingBookings ?? 0) > 0;

    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: 'تم حذف العميل بنجاح',
          ).showTopToast();
          context.pop(true);
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: state.actionErrMessage ?? 'حدث خطأ أثناء حذف العميل',
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.red1A,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CustomAssetImage(
                        path: AppIcons.delete,
                        width: 20,
                        height: 20,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'confirm_delete_customer_title'.tr(),
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.name ?? '',
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              Text(
                'confirm_delete_customer_desc'.tr(),
                style: CustomAppFontStyle.regular14.copyWith(
                  color: AppColors.gray71717A,
                  height: 1.5,
                ),
              ),

              if (hasActiveBookings) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red1A,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.warning,
                        width: 18,
                        height: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لا يمكن حذف العميل لوجود (${customer.upcomingBookings}) حجوزات قادمة مسجلة له.',
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomPushButton(
                    height: 42,
                    width: 90,
                    backgroundColor: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(false),
                    child: Center(
                      child: Text(
                        'cancel'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 42,
                      width: 120,
                      backgroundColor: hasActiveBookings
                          ? AppColors.fillDisableColor
                          : AppColors.error,
                      isLoading: isLoading,
                      borderRadius: BorderRadius.circular(8),
                      onTap: hasActiveBookings || customer.id == null
                          ? null
                          : () => context.read<CustomersCubit>().deleteCustomer(
                              customer.id!,
                            ),
                      child: Center(
                        child: Text(
                          'delete'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

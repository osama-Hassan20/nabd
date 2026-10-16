import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/extensions/date_time_extentision.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/booking_model.dart';
import 'package:purexo/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:purexo/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:purexo/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:purexo/features/customers/presentation/manager/customers_cubit.dart';
import 'package:purexo/features/customers/presentation/manager/customers_state.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/custom_container.dart';
import 'package:purexo/shared/widgets/custom_push_container_button.dart';
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';

import '../add_edit_customer_dialog.dart';
import '../delete_customer_dialog.dart';

class CustomerProfileCardSection extends StatelessWidget {
  const CustomerProfileCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AdaptiveLayout.isMobile(context);

    return BlocBuilder<CustomersCubit, CustomersState>(
      buildWhen: (prev, curr) =>
          prev.selectedCustomer != curr.selectedCustomer,
      builder: (context, state) {
        final customer = state.selectedCustomer;
        if (customer == null) return const SizedBox.shrink();

        return CustomContainer(
          backGroundColor: AppColors.white,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: CustomAssetImage(
                        path: AppIcons.user,
                        width: 26,
                        height: 26,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                customer.name ?? '',
                                style: CustomAppFontStyle.bold18.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            if (customer.hasRepeatedBooking == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'recurring_booking'.tr(),
                                  style: CustomAppFontStyle.semiBold11.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const CustomAssetImage(
                              path: AppIcons.calendar,
                              width: 13,
                              height: 13,
                              color: AppColors.gray71717A,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${'customer_since'.tr()}: ${customer.createdAt?.toCustomFormat() ?? '-'}",
                              style: CustomAppFontStyle.regular12.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!isMobile) _buildActionButtons(context, state),
                ],
              ),

              if (isMobile) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context, state),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // Contact and Location Chips
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.grayf2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const CustomAssetImage(
                          path: AppIcons.phone,
                          width: 14,
                          height: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'customer_phone'.tr(),
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                          Text(
                            customer.phone ?? '-',
                            textDirection: TextDirection.ltr,
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.grayf2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const CustomAssetImage(
                          path: AppIcons.location,
                          width: 14,
                          height: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'customer_address'.tr(),
                            style: CustomAppFontStyle.regular11.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                          Text(
                            customer.address ?? '-',
                            style: CustomAppFontStyle.medium13.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Recurring Schedule Days & Times (if recurring customer)
              if (customer.hasRepeatedBooking == true &&
                  customer.recurrence?.daySchedules != null &&
                  customer.recurrence!.daySchedules!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CustomAssetImage(
                            path: AppIcons.calendar,
                            width: 15,
                            height: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'recurring_schedule'.tr(),
                            style: CustomAppFontStyle.semiBold13.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children:
                            customer.recurrence!.daySchedules!.map((sched) {
                          final dayName = DayOfWeekOption.fromKey(sched.day)
                              .getName(context);
                          final timeRange =
                              BookingTimeFormatter.formatTimeRange(
                            sched.startTime,
                            sched.endTime,
                            context,
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.grayE2E8F0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dayName,
                                  style: CustomAppFontStyle.semiBold12.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeRange,
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, CustomersState state) {
    final customer = state.selectedCustomer;
    if (customer == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // New Booking for this customer
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            await AddEditBookingDialog.show(
              context: context,
              booking: BookingModel(
                customer: customer,
              ),
            );
            if (customer.id != null && context.mounted) {
              context.read<CustomersCubit>().fetchCustomerDetails(customer.id!);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.add,
                width: 14,
                height: 14,
                color: AppColors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'create_booking_for_customer'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),

        // Edit Customer
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            final cubit = context.read<CustomersCubit>();
            final updated = await AddEditCustomerDialog.show(
              context: context,
              customer: customer,
              customersCubit: cubit,
            );
            if (updated == true && customer.id != null) {
              cubit.fetchCustomerDetails(customer.id!);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.edit,
                width: 14,
                height: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'edit_customer'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Delete Customer
        CustomPushButton(
          height: 38,
          backgroundColor: AppColors.red1A,
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onTap: () async {
            final cubit = context.read<CustomersCubit>();
            final deleted = await DeleteCustomerDialog.show(
              context: context,
              customer: customer,
              customersCubit: cubit,
            );
            if (deleted == true && context.mounted) {
              context.go(AppRouter.customers);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAssetImage(
                path: AppIcons.delete,
                width: 14,
                height: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                'delete_customer'.tr(),
                style: CustomAppFontStyle.semiBold12.copyWith(
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

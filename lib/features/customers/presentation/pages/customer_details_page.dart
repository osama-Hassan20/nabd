import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/routing/routes.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/core/utils/extensions/sliver_extentions.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_icons.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/customers/presentation/manager/customers_cubit.dart';
import 'package:purexo/features/customers/presentation/manager/customers_state.dart';
import 'package:purexo/features/customers/presentation/widgets/customer_details_sections/customer_bookings_section.dart';
import 'package:purexo/features/customers/presentation/widgets/customer_details_sections/customer_details_shimmer.dart';
import 'package:purexo/features/customers/presentation/widgets/customer_details_sections/customer_profile_card_section.dart';
import 'package:purexo/features/customers/presentation/widgets/customer_details_sections/customer_stats_cards_section.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';
import 'package:purexo/shared/widgets/error_page.dart';

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) =>
            getIt<CustomersCubit>()..fetchCustomerDetails(customerId),
        child: BlocBuilder<CustomersCubit, CustomersState>(
          builder: (context, state) {
            final cubit = context.read<CustomersCubit>();

            return RefreshIndicator(
              onRefresh: () async => cubit.fetchCustomerDetails(customerId),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Navigation Back Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.go(AppRouter.customers),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.grayE2E8F0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CustomAssetImage(
                                    path: AppIcons.arrowForward,
                                    width: 14,
                                    height: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'customers'.tr(),
                                    style: CustomAppFontStyle.medium13.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '/',
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.selectedCustomer?.name ??
                                'customer_details'.tr(),
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.detailsStatus == RequestStatusEnum.loading)
                    const CustomerDetailsShimmer().toSliver()
                  else if (state.detailsStatus == RequestStatusEnum.failure)
                    ErrorPage(
                      errorMessage:
                          state.detailsErrMessage ?? 'failed_to_load'.tr(),
                      onPressed: () => cubit.fetchCustomerDetails(customerId),
                    ).toSliver()
                  else ...[
                    const CustomerProfileCardSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const CustomerStatsCardsSection().toSliver(),
                    const SizedBox(height: 16).toSliver(),
                    const CustomerBookingsSection().toSliver(),
                    const SizedBox(height: 24).toSliver(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_cards/summary_card.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';

class BookingSummarySection extends StatelessWidget {
  const BookingSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.summaryStatus != curr.summaryStatus ||
          prev.summary != curr.summary ||
          prev.selectedStatus != curr.selectedStatus ||
          prev.selectedBranchId != curr.selectedBranchId ||
          prev.selectedDate != curr.selectedDate,
      builder: (context, state) {
        final cubit = context.read<BookingsCubit>();

        // 1. Loading State
        if (state.summaryStatus == RequestStatusEnum.loading &&
            state.summary == null) {
          return _buildShimmerSliver();
        }

        // 2. Error State with Retry
        if (state.summaryStatus == RequestStatusEnum.failure &&
            state.summary == null) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errMessage ?? 'error_occurred'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  CustomPushButton(
                    height: 36,
                    width: 90,
                    backgroundColor: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => cubit.fetchBookingSummary(),
                    child: Text(
                      'retry'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = state.summary ?? const BookingSummaryModel();
        final selected = state.selectedStatus;

        // 7 Cards Specifications
        final items = [
          // 1. Total (إجمالي)
          SummaryCard(
            title: '${summary.visitsToday}',
            subTitle: 'clinic_visits_today'.tr(),
            iconPath: AppIcons.calendar,
            gradient: AppGradient.primaryGradient,
            activeBorderColor: AppColors.white,
            isSelected: selected == null,
            onTap: () => cubit.toggleStatusFilterFromCard(null),
          ),
          // 2. Waiting (في صالة الانتظار)
          SummaryCard(
            title: '${summary.inWaiting}',
            subTitle: 'clinic_in_waiting'.tr(),
            iconPath: AppIcons.clock,
            gradient: const LinearGradient(
              colors: [Color(0xFFE89A24), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.waiting,
            onTap: () => cubit.toggleStatusFilterFromCard(BookingStatusEnum.waiting),
          ),
          // 3. In Consultation (داخل الكشف حالياً)
          SummaryCard(
            title: '${summary.inConsultation}',
            subTitle: 'clinic_in_consultation'.tr(),
            iconPath: AppIcons.team,
            gradient: const LinearGradient(
              colors: [Color(0xFF3880EC), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.inConsultation,
            onTap: () => cubit
                .toggleStatusFilterFromCard(BookingStatusEnum.inConsultation),
          ),
          // 4. Completed (الكشوفات المكتملة)
          SummaryCard(
            title: '${summary.completedToday}',
            subTitle: 'clinic_completed_today'.tr(),
            iconPath: AppIcons.checkmarkCircle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E9A68), Color(0xFF15803D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.completed,
            onTap: () => cubit.toggleStatusFilterFromCard(BookingStatusEnum.completed),
          ),
          // 5. No-Show (لم يحضروا)
          SummaryCard(
            title: '${summary.noShow}',
            subTitle: 'clinic_no_show'.tr(),
            iconPath: AppIcons.clock,
            gradient: const LinearGradient(
              colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.noShow,
            onTap: () => cubit.toggleStatusFilterFromCard(BookingStatusEnum.noShow),
          ),
          // 6. Cancelled (ملغي اليوم)
          SummaryCard(
            title: '${summary.cancelledToday}',
            subTitle: 'clinic_cancelled_today'.tr(),
            iconPath: AppIcons.cancelledBooking,
            gradient: const LinearGradient(
              colors: [Color(0xFFE54848), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.cancelled,
            onTap: () => cubit.toggleStatusFilterFromCard(BookingStatusEnum.cancelled),
          ),
          // 7. Postponed (مؤجل لتاريخ آخر)
          SummaryCard(
            title: '${summary.postponedToOther}',
            subTitle: 'clinic_postponed_to_other'.tr(),
            iconPath: AppIcons.pending,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            activeBorderColor: AppColors.white,
            isSelected: selected == BookingStatusEnum.postponed,
            onTap: () => cubit.toggleStatusFilterFromCard(BookingStatusEnum.postponed),
          ),
        ];

        return SliverLayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.crossAxisExtent < 650;

            if (isMobile) {
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 185,
                        child: items[index],
                      );
                    },
                  ),
                ),
              );
            }

            return SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 100,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => items[index],
                childCount: items.length,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerSliver() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.crossAxisExtent < 650;

        if (isMobile) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => const SizedBox(
                  width: 185,
                  child: SummaryCardShimmer(),
                ),
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 100,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const SummaryCardShimmer(),
            childCount: 7,
          ),
        );
      },
    );
  }
}

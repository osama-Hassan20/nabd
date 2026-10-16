import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/features/bookings/data/models/booking_summary_model.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_cards/summary_card.dart';

class BookingSummarySection extends StatelessWidget {
  const BookingSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      buildWhen: (prev, curr) =>
          prev.summaryStatus != curr.summaryStatus ||
          prev.summary != curr.summary,
      builder: (context, state) {
        if (state.summaryStatus == RequestStatusEnum.loading &&
            state.summary == null) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 100,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const SummaryCardShimmer(),
              childCount: 4,
            ),
          );
        }

        final summary = state.summary ?? const BookingSummaryModel();
        final items = [
          SummaryCard(
            title: '${summary.visitsToday}',
            subTitle: 'clinic_visits_today'.tr(),
            iconPath: AppIcons.calendar,
          ),
          SummaryCard(
            title: '${summary.inWaiting}',
            subTitle: 'clinic_in_waiting'.tr(),
            iconPath: AppIcons.clock,
          ),
          SummaryCard(
            title: '${summary.inConsultation}',
            subTitle: 'clinic_in_consultation'.tr(),
            iconPath: AppIcons.team,
          ),
          SummaryCard(
            title: '${summary.completedToday}',
            subTitle: 'clinic_completed_today'.tr(),
            iconPath: AppIcons.checkmarkCircle,
          ),
        ];

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 100,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => items[index],
            childCount: items.length,
          ),
        );
      },
    );
  }
}

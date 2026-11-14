import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';

class BookingFormStatusSection extends StatelessWidget {
  final TextEditingController bookingTypeController;
  final TextEditingController statusController;
  final TextEditingController paymentStatusController;

  const BookingFormStatusSection({
    super.key,
    required this.bookingTypeController,
    required this.statusController,
    required this.paymentStatusController,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomStackSelector<BookingTypeEnum>(
                header: 'booking_type_label'.tr(),
                controller: bookingTypeController,
                list: BookingTypeEnum.values,
                itemAsString: (t) => t.label,
                changeValue: (t) => cubit.updateFormBookingType(t),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomStackSelector<BookingStatusEnum>(
                header: 'status_label'.tr(),
                controller: statusController,
                list: BookingStatusEnum.values,
                itemAsString: (s) => s.label,
                changeValue: (s) => cubit.updateFormStatus(s),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'payment_status'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<BookingsCubit, BookingsState>(
                buildWhen: (prev, curr) =>
                    prev.formState?.paymentStatus !=
                    curr.formState?.paymentStatus,
                builder: (context, state) {
                  final status =
                      state.formState?.paymentStatus ?? PaymentStatusEnum.unpaid;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: status.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      status.label,
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: status.color,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

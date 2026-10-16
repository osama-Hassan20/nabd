import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:purexo/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:purexo/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:purexo/shared/widgets/custom_stack_selector.dart';

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
        CustomStackSelector<PaymentStatusEnum>(
          header: 'payment_status'.tr(),
          controller: paymentStatusController,
          list: PaymentStatusEnum.values,
          itemAsString: (p) => p.label,
          changeValue: (p) => cubit.updateFormPaymentStatus(p),
        ),
      ],
    );
  }
}

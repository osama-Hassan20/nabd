import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/patients/presentation/widgets/quick_add_patient_dialog.dart';

class AddNewPatientDialog extends StatelessWidget {
  const AddNewPatientDialog({super.key});

  static Future<BookingPatientOption?> show(
    BuildContext context, {
    String? initialQuery,
  }) async {
    final patient = await QuickAddPatientDialog.show(
      context: context,
      initialQuery: initialQuery,
    );
    if (patient == null) return null;

    final option = BookingPatientOption(
      id: patient.id ?? '',
      name: patient.name ?? '',
      phone: patient.phone ?? '',
      address: patient.address ?? '',
    );

    if (!context.mounted) return option;
    try {
      context.read<BookingsCubit>().addCustomerOption(option);
    } catch (_) {}

    return option;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

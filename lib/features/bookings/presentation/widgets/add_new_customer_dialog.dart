import 'package:flutter/material.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'add_new_patient_dialog.dart';

// Alias for backward compatibility
typedef AddNewCustomerDialog = AddNewPatientDialog;

extension AddNewCustomerDialogHelper on AddNewCustomerDialog {
  static Future<BookingPatientOption?> show(BuildContext context) {
    return AddNewPatientDialog.show(context);
  }
}

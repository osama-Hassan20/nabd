class AppRouter {
  static const String appLayout = '/';
  static const String login = '/login';

  // ─── Eyadty Medical Modules ────────────────────────────────────────────────
  // 1. Live Queue & Appointments
  static const String queue = '/bookings';
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/:id';

  // 2. Patients & Medical EMR
  static const String patients = '/patients';
  static const String patientDetails = '/patients/:id';
  static const String customers = '/patients';
  static const String customerDetails = '/patients/:id';

  // 3. Clinical Visits & Prescriptions
  static const String visits = '/visits';
  static const String visitDetails = '/visits/:id';

  // 4. Doctors & Staff Schedules
  static const String doctors = '/doctors';
  static const String doctorDetails = '/doctors/:id';
  static const String technicians = '/doctors';
  static const String technicianDetails = '/doctors/:id';

  // 5. Cashier & Shift Drawer
  static const String cashier = '/cashier';

  // 6. HR & Doctor Settlements
  static const String hr = '/hr';

  // 7. Executive Analytics & Statistics
  static const String analytics = '/analytics';

  // 8. Settings & Multi-Branch Management
  static const String settings = '/settings';
}

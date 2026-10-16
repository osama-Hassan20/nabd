class AppRouter {
  static const String appLayout = '/';
  static const String login = '/login';

  // ─── Eyadty Medical Modules ────────────────────────────────────────────────
  // 1. Live Queue & Appointments
  static const String queue = '/bookings';
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/:id';

  // 2. Patients & Medical EMR
  static const String patients = '/customers';
  static const String patientDetails = '/customers/:id';
  static const String customers = '/customers';
  static const String customerDetails = '/customers/:id';

  // 3. Clinical Visits & Prescriptions
  static const String visits = '/visits';
  static const String visitDetails = '/visits/:id';

  // 4. Doctors & Staff Schedules
  static const String doctors = '/technicians';
  static const String doctorDetails = '/technicians/:id';
  static const String technicians = '/technicians';
  static const String technicianDetails = '/technicians/:id';

  // 5. Cashier & Shift Drawer
  static const String cashier = '/cashier';

  // 6. HR & Doctor Settlements
  static const String hr = '/hr';

  // 7. Executive Analytics & Statistics
  static const String analytics = '/analytics';

  // 8. Settings & Multi-Branch Management
  static const String settings = '/settings';
}

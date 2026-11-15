enum StaffPermissionEnum {
  // ─── 1. Queue & Reception (الحجوزات والاستقبال) ───────────────────────────
  accessLiveQueue,
  createBooking,
  editBooking,
  cancelBooking,
  reorderQueue,

  // ─── 2. Patients & Medical Records (المرضى والسجلات الطبية) ─────────────
  accessPatients,
  createPatient,
  editPatient,
  viewVisitsQueue,
  startConsultation,
  recordVitals,
  viewMedicalRecordDiagnostics,
  viewConsultationNotes,
  viewAllDoctorsMedicalRecords,
  editMedicalDiagnosis,
  issuePrescription,
  manageDrugCatalog,

  // ─── 3. Doctors & Clinical Staff (الأطباء والعيادات) ─────────────────────
  accessDoctors,
  manageDoctorSchedules,
  manageDoctorLeaves,
  approveLeavesAndReferrals,
  viewClinicalPerformance,

  // ─── 4. Cashier & Financial Transactions (الخزينة والماليات) ─────────────
  accessCashier,
  collectPayment,
  refundPayment,
  viewCashierShift,
  applyManualDiscount,
  applyBookingDiscount,
  manageCashierShifts,
  manageDrawerMovements,

  // ─── 5. HR & Settlements (الموارد البشرية والمستحقات) ────────────────────
  accessHr,
  calculateDoctorSettlement,
  viewDoctorSettlements,
  confirmDoctorSettlement,
  payoutSettlement,
  manageCompensationRules,
  manageEmployeeLedger,
  viewOwnDoctorSettlement,
  manageStaffPayroll,

  // ─── 6. Analytics & Reports (التقارير والإحصائيات) ────────────────────────
  accessAnalytics,
  viewFinancialReports,

  // ─── 7. Settings & Governance (الإعدادات والحوكمة) ───────────────────────
  accessSettings,
  manageBranches,
  manageMedicalServices,
  manageRolesAndPermissions,
  createStaffUser,
  editStaffUser,
  deleteStaffUser,
  toggleStaffUserStatus,
  viewAuditLogs,
}


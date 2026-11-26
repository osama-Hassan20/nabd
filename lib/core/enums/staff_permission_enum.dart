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
  viewAuditLogs;

  String get localizedName {
    switch (this) {
      case StaffPermissionEnum.accessLiveQueue:
        return 'عرض شاشة الانتظار';
      case StaffPermissionEnum.createBooking:
        return 'إضافة حجز جديد';
      case StaffPermissionEnum.editBooking:
        return 'تعديل الحجز';
      case StaffPermissionEnum.cancelBooking:
        return 'إلغاء الحجز';
      case StaffPermissionEnum.reorderQueue:
        return 'إعادة ترتيب قائمة الانتظار';
      case StaffPermissionEnum.accessPatients:
        return 'الوصول لقائمة المرضى';
      case StaffPermissionEnum.createPatient:
        return 'إضافة مريض جديد';
      case StaffPermissionEnum.editPatient:
        return 'تعديل بيانات مريض';
      case StaffPermissionEnum.viewVisitsQueue:
        return 'عرض طابور الكشف';
      case StaffPermissionEnum.startConsultation:
        return 'بدء الكشف الطبي';
      case StaffPermissionEnum.recordVitals:
        return 'تسجيل العلامات الحيوية';
      case StaffPermissionEnum.viewMedicalRecordDiagnostics:
        return 'عرض الفحوصات والتشخيصات';
      case StaffPermissionEnum.viewConsultationNotes:
        return 'عرض ملاحظات الكشف';
      case StaffPermissionEnum.viewAllDoctorsMedicalRecords:
        return 'عرض سجلات جميع الأطباء';
      case StaffPermissionEnum.editMedicalDiagnosis:
        return 'تعديل التشخيص الطبي';
      case StaffPermissionEnum.issuePrescription:
        return 'إصدار الروشتات';
      case StaffPermissionEnum.manageDrugCatalog:
        return 'إدارة دليل الأدوية';
      case StaffPermissionEnum.accessDoctors:
        return 'الوصول لملفات الأطباء';
      case StaffPermissionEnum.manageDoctorSchedules:
        return 'إدارة جداول الأطباء';
      case StaffPermissionEnum.manageDoctorLeaves:
        return 'إدارة إجازات الأطباء';
      case StaffPermissionEnum.approveLeavesAndReferrals:
        return 'اعتماد الإجازات والتحويلات';
      case StaffPermissionEnum.viewClinicalPerformance:
        return 'عرض الأداء الإكلينيكي';
      case StaffPermissionEnum.accessCashier:
        return 'الوصول لشاشة الخزينة';
      case StaffPermissionEnum.collectPayment:
        return 'تحصيل المدفوعات';
      case StaffPermissionEnum.refundPayment:
        return 'استرداد المدفوعات';
      case StaffPermissionEnum.viewCashierShift:
        return 'عرض وردية الخزينة';
      case StaffPermissionEnum.applyManualDiscount:
        return 'تطبيق خصم يدوي';
      case StaffPermissionEnum.applyBookingDiscount:
        return 'تطبيق خصم على الحجز';
      case StaffPermissionEnum.manageCashierShifts:
        return 'إدارة ورادي الخزينة';
      case StaffPermissionEnum.manageDrawerMovements:
        return 'إدارة حركات الدرج ومصروفات النثرية';
      case StaffPermissionEnum.accessHr:
        return 'الوصول للموارد البشرية';
      case StaffPermissionEnum.calculateDoctorSettlement:
        return 'حساب تسويات الأطباء';
      case StaffPermissionEnum.viewDoctorSettlements:
        return 'عرض تسويات الأطباء';
      case StaffPermissionEnum.confirmDoctorSettlement:
        return 'اعتماد تسويات الأطباء';
      case StaffPermissionEnum.payoutSettlement:
        return 'صرف المستحقات';
      case StaffPermissionEnum.manageCompensationRules:
        return 'إدارة قواعد احتساب الأطباء';
      case StaffPermissionEnum.manageEmployeeLedger:
        return 'إدارة دفتر السلف والخصومات';
      case StaffPermissionEnum.viewOwnDoctorSettlement:
        return 'عرض المستحقات الخاصة';
      case StaffPermissionEnum.manageStaffPayroll:
        return 'إدارة مسير الرواتب';
      case StaffPermissionEnum.accessAnalytics:
        return 'الوصول للتقارير والتحليلات';
      case StaffPermissionEnum.viewFinancialReports:
        return 'عرض التقارير المالية';
      case StaffPermissionEnum.accessSettings:
        return 'الوصول لإعدادات النظام';
      case StaffPermissionEnum.manageBranches:
        return 'إدارة الفروع';
      case StaffPermissionEnum.manageMedicalServices:
        return 'إدارة الخدمات الطبية';
      case StaffPermissionEnum.manageRolesAndPermissions:
        return 'إدارة الأدوار والصلاحيات';
      case StaffPermissionEnum.createStaffUser:
        return 'إضافة مستخدم جديد';
      case StaffPermissionEnum.editStaffUser:
        return 'تعديل بيانات المستخدم';
      case StaffPermissionEnum.deleteStaffUser:
        return 'حذف المستخدم';
      case StaffPermissionEnum.toggleStaffUserStatus:
        return 'تفعيل / تعطيل المستخدم';
      case StaffPermissionEnum.viewAuditLogs:
        return 'عرض سجل العمليات والأمان';
    }
  }
}


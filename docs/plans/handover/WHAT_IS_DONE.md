# 📦 ما تم إنجازه في مشروع عيادتي (Eyadty)
> **آخر تحديث:** نوفمبر 2026 — وثيقة تسليم للمبرمج القادم

---

## 🎯 نبذة عن المشروع

**عيادتي (Eyadty)** منصة SaaS متعددة الفروع لإدارة المجموعات الطبية والعيادات الكبيرة.
مبنية بـ **Flutter** (Web + Desktop)، معمارية **Clean Architecture** كاملة، **Cubit** لإدارة الحالة، و**GoRouter** للتوجيه.

| الخاصية | القيمة |
|:---|:---|
| **التقنية** | Flutter 3.x, Dart SDK ^3.13.1 |
| **الحالة** | Mock data (بدون backend حقيقي بعد) |
| **الإصدار الحالي** | v1.0.4 |
| **الاختبارات** | 1073/1073 passed (100%) |
| **التحليل** | `flutter analyze` → 0 issues |

---

## 🏗️ البنية المعمارية العامة

```
lib/
├── main.dart                          # نقطة الدخول + DI setup
├── app.dart                           # MaterialApp + GoRouter
├── firebase_options.dart              # Firebase (معطّل حالياً)
│
├── core/                              # كل الأدوات المشتركة بين الفيتشرز
│   ├── api/                           # DioConsumer, ApiConsumer, interceptors
│   ├── animation/                     # Fade, Slide, Scale, HoverScale transitions
│   ├── audio/                         # PlatformAudioPlayer
│   ├── base/                          # SafeCubit (أساس كل Cubit في المشروع)
│   ├── cubits/session_cubit.dart      # الجلسة + المستخدم الحالي + الفرع النشط
│   ├── dependency_injection/          # get_it DI container
│   ├── enums/                         # StaffPermissionEnum, RoleEnum, PaymentMethod
│   ├── errors/failures.dart           # Failure types (ServerFailure, CacheFailure...)
│   ├── extensions/                    # formatPhoneNumber, getJoinedAgo, navigationMode
│   ├── helpers/                       # ArabicPluralHelper, DialogHelper, UploadImageToApi
│   ├── helpers/notification_helper/   # FirebaseNotifications
│   ├── layout_adaptive/widgets/       # CustomSideBar, CustomDrawer, CustomTable, EnhancedTable
│   ├── mixins/                        # PaginationMixin, SearchMixin
│   ├── models/                        # AudioModel, MediaModel
│   ├── network/                       # LocalNotificationService, MoneyHelper
│   ├── providers/                     # ActiveBookingsCountProvider
│   ├── routing/                       # app_router.dart, routes.dart, popup_observer.dart
│   ├── services/                      # PermissionEvaluator, AuditLogger, CairoTimeHelper
│   ├── storage/                       # SharedPreferences wrapper
│   ├── uses_cases/                    # Base UseCase<T, P>
│   └── utils/                         # Constants, theme (Warm Layered Minimalism), extensions
│
├── features/                          # كل فيتشر منفصل بـ Clean Architecture
│   ├── bookings/                      # الحجوزات والطابور الحي
│   ├── branches/                      # إدارة الفروع
│   ├── patients/                      # المرضى والملف الطبي
│   ├── doctors/                       # الأطباء والجداول والإجازات
│   ├── users_management/              # إدارة حسابات الموظفين والأدوار
│   ├── audit_logs/                    # سجل النشاط والأمان
│   ├── home_dashboard/                # لوحة التحكم الرئيسية
│   ├── settings/                      # إعدادات المنشأة والخدمات الطبية
│   ├── cashier/                       # الخزينة والورديات والفواتير F-05 (مكتمل 100%)
│   ├── hr/                            # الموارد البشرية وتسويات الأطباء والرواتب F-06 (مكتمل 100%)
│   ├── visits/                        # الكشف الطبي F-04a (مكتمل) + الروشتة F-04b
│   ├── drugs/                         # كتالوج الأدوية وقوالب الروشتات F-04b (مكتمل 100%)
│   └── analytics/                     # التقارير والإحصائيات والذكاء التنفيذي F-07 (مكتمل 100%)
│
└── shared/                            # مكونات مشتركة بين الفيتشرز
    ├── auth/                          # Authentication (Login)
    ├── app_layout/                    # Shell layout: Sidebar, Header, Drawer
    ├── widgets/                       # 40+ custom widget مشترك
    ├── cubit/                         # AppCubit (ثيم ولغة)
    ├── model/                         # نماذج مشتركة
    ├── services/                      # خدمات مشتركة
    └── uploads/                       # رفع الملفات
```

---

## ✅ الفيتشرز المكتملة بالكامل (100% Done)

### 🏢 F-01: إدارة الفروع (Multi-Branch Management)
**الحالة:** ✅ مكتملة ومختبرة

**ما تم بناؤه:**
- `BranchModel` — 100% nullable، يحتوي على: id, name, address, phone, isActive, openingHours, workDays, holidays
- `BranchesRepo` (interface) + `BranchesMockRepoImpl` — CRUD كامل + seed data بـ 3 فروع
- `BranchesCubit` + `BranchesState` — إدارة كاملة للحالة
- **UI مكتمل:** `BranchesTable`, `BranchCard`, `BranchStatusBadge`
- **Dialogs مكتملة:** `AddEditBranchDialog`, `CopyBranchSettingsDialog`, `ToggleBranchStatusDialog`
- `HeaderBranchSwitcher` — مفتاح تبديل الفروع في الهيدر، ديناميكي من SessionCubit
- **تبويب الفروع** مدمج داخل شاشة الإعدادات (`/settings` → tab_branches)
- **عزل الإعدادات:** كل فرع له إعداداته المنفصلة (ساعات عمل، عطلات، أسعار)
- نسخ إعدادات فرع إلى فرع آخر

**الاختبارات:** 30/30 passed
- `branches_models_and_repo_test.dart`: 12/12
- `header_branch_switcher_test.dart`: 3/3
- `branches_screen_and_dialogs_test.dart`: 10/10
- `branch_settings_isolation_test.dart`: 5/5

---

### 🔐 F-02: الأدوار والصلاحيات وحسابات الموظفين (RBAC & Staff Accounts)
**الحالة:** ✅ مكتملة ومختبرة

**ما تم بناؤه:**
- `StaffPermissionEnum` — 25+ صلاحية (manageStaff, manageDoctors, managePatients, viewFinancials, viewAuditLogs, إلخ)
- `PermissionEvaluator` — محرك فحص الصلاحيات المركزي (fail-closed دائماً)
- `SessionCubit` — يحمل بيانات المستخدم الحالي، الفرع النشط، الأدوار والصلاحيات
- `AuditLogger` + `InMemoryAuditLogger` — تسجيل الأحداث الحساسة

**نظام المستخدمين (Users Management):**
- `StaffUserModel` (100% nullable): id, name, email, phone, roleId, branchIds, permissions, isActive
- `RoleDefinitionModel` — تعريف الأدوار مع صلاحياتها
- `BranchAssignmentModel` — تعيين موظف لفرع
- `StaffUsersMockRepoImpl` — CRUD كامل + seed data بـ 6 موظفين بأدوار مختلفة
- **UI مكتمل:** `UsersManagementPage`, `StaffUsersTable`, `StaffRoleBadge`, `StaffUserAvatar`
- **Dialogs:** `AddEditStaffUserDialog`, `DeleteStaffUserDialog`, `ResetPasswordDialog`, `RolePermissionsMatrixDialog`, `ToggleUserStatusDialog`

**نظام التوجيه والحماية:**
- `GoRouter` مع `refreshListenable` → تحديث تلقائي عند تغيير الجلسة
- Route Guards: مستخدم غير مسجل → `/login?from=...`، بدون صلاحية → `/forbidden?from=...`
- Dynamic Sidebar Filtering — يظهر فقط ما يملك المستخدم صلاحيته

**نظام Login:**
- `LoginPage` بـ Design System كامل (Warm Layered Minimalism)
- `LoginCubit` + use cases كاملة (Login, ForgetPass, OTP, ResetPassword)
- `MustChangePasswordDialog` — يظهر عند أول دخول
- حفظ الجلسة في `SharedPreferences`

**الاختبارات:** 42/42 passed
- `staff_models_and_repo_test.dart`: 11/11
- `permission_evaluator_and_guards_test.dart`: 16/16
- `staff_users_screen_and_dialogs_test.dart`: 10/10
- `login_flow_and_must_change_password_test.dart`: 5/5

---

### 📋 F-03: سجل النشاط والأمان (Security Audit Log)
**الحالة:** ✅ مكتملة (قيد التدمج)

**ما تم بناؤه:**
- `SecurityAuditLogModel` (100% nullable): id, eventType, performedByUserId, performedByUserName, targetUserId, branchId, details, timestamp
- `AuditLogsRepo` (interface) + `AuditLogsMockRepoImpl` — مع seed data
- `AuditLogsCubit` + `AuditLogsState`
- **UI مكتمل:** `AuditLogsPage`, `AuditLogsTable`, `AuditLogsFilterBar`, `AuditEventTypeBadge`
- **Dialogs:** `AuditLogDetailsDialog`
- صلاحية `viewAuditLogs` حصرية للمالك افتراضياً
- Route `/settings/audit-logs` محمي بـ permission guard

---

### 🏥 F-00: الأطباء والجداول والإجازات (Doctors Module)
**الحالة:** ✅ مكتملة ومختبرة (كانت موجودة وتم تحسينها وتوحيدها)

**ما تم بناؤه:**
- `DoctorModel` (100% nullable): id, name, title, specialty, phone, licenseNumber, assignedBranchIds, consultationFee, commissionType, commissionValue, avgConsultationDurationMinutes
- `DoctorScheduleModel` — جدول الأسبوع مع Shift hours و max patients
- `DoctorLeaveModel` — الإجازات مع أنواعها ودواعيها
- `DoctorBreakTimeModel`, `DoctorWorkDayModel`
- `DoctorsMockRepoImpl` — 6 أطباء رسميين (DOC-01 إلى DOC-06)، CRUD كامل
- Helpers: `DoctorAvailabilityHelper`, `DoctorScheduleValidator`
- `DoctorsCubit` + `DoctorsState`
- **Pages:** `DoctorsPage`, `DoctorDetailsPage`
- **Widgets:** `DoctorsTable`, `DoctorCard`, `DoctorStatusBadge`, `AdaptiveDoctorsView`
- **Details Sections:** profile card, schedule, stats, today schedule, leaves, bookings
- **Dialogs:** `AddEditDoctorDialog`, `DoctorScheduleEditorDialog`, `AddDoctorLeaveDialog`, `DoctorUpcomingLeavesDialog`, `DeleteDoctorDialog`
- `CairoTimeHelper` — ساعة حقن للاختبار (`@visibleForTesting`)

**الاختبارات:** 8/8+ passed
- `doctor_catalog_unification_test.dart`: 5/5
- `cairo_time_helper_test.dart`: 4/4
- `doctor_schedule_and_leaves_r4_test.dart`: 3/3

---

### 📅 الحجوزات والطابور الحي (Bookings Feature)
**الحالة:** ✅ بنية كاملة ومكتملة

**ما تم بناؤه:**
- `BookingModel` (100% nullable): id, patientId, doctorId, branchId, visitType, status, appointmentDate, timeSlot, notes, fee, paymentStatus
- `BookingSummaryModel`, `BookingsResponseModel`, `BookingFormOptionsModel`
- Enums: `BookingStatusEnum`, `BookingTypeEnum`, `PaymentStatusEnum`, `SlotStatusEnum`
- `TimeSlotModel`
- `BookingsMockRepoImpl` — CRUD كامل مع seed data
- Helpers: `BookingStatisticsCalculator`, `SlotGeneratorHelper`
- `BookingsCubit` + `BookingsState`
- **Pages:** `BookingsPage`, `BookingDetailsPage`
- **Filter Bar:** فلترة بالدكتور، النوع، التاريخ
- **Views:** `AdaptiveBookingsView` (table/card responsive)
- **Calendar:** `BookingCalendarWidget`, `CompactDateStripWidget`, `CalendarYearDropdown`
- **Summary:** `BookingSummarySection` مع 4 بطاقات إحصائية
- **Action Dialogs:** تغيير الحالة، حذف، إعادة تعيين الدكتور
- **Add/Edit Dialog:** 10 sections كاملة (patient, doctor, slot, pricing, status, notes)
- **Details Sections:** 6 sections في صفحة التفاصيل

---

### 🧑‍⚕️ المرضى (Patients Feature)
**الحالة:** ✅ بنية كاملة ومكتملة

**ما تم بناؤه:**
- `PatientModel` (100% nullable): id, name, phone, nationalId, gender, dateOfBirth, bloodType, chronicDiseases, drugAllergies, emergencyContact, totalBalanceDue, familyMembers
- Enums: `BloodGroupEnum`, `GenderEnum`, `MedicalCatalogTypeEnum`
- `MedicalCatalogItemModel` — الأمراض المزمنة والحساسية الدوائية
- `KinshipRelations` — أنواع القرابة
- `EgyptianGovernorates` — المحافظات
- `PatientsMockRepoImpl` + `MedicalCatalogMockRepoImpl`
- Use Cases: get, getById, add, update, delete, archive, unarchive, findByPhone
- `PatientsCubit` + `PatientsState`
- **Pages:** `PatientsPage`, `PatientDetailsPage`
- **Widgets:** `PatientsTable`, `PatientCard`, `AdaptivePatientsView`, `PatientsFilter`
- **Details Sections:** profile card, stats cards, bookings history, shimmer
- **Dialogs:** `AddEditPatientDialog`, `DeletePatientDialog`, `DuplicatePhoneWarningDialog`, `QuickAddPatientDialog`
- **Form Components:** `BloodGroupSelector`, `KinshipChipsSelector`, `SearchableCatalogMultiSelector`

**الاختبارات:**
- `patient_model_and_helpers_test.dart`: passed
- `patient_dialogs_flow_test.dart`: passed

---

### ⚙️ الإعدادات (Settings Feature)
**الحالة:** ✅ بنية كاملة

**ما تم بناؤه:**
- `CompanySettingsModel`, `MedicalServiceModel`, `SpecialHolidayModel`
- `SettingsMockRepoImpl` + `MedicalServicesMockRepoImpl`
- `SettingsCubit` + `MedicalServicesCubit`
- **Page:** `SettingsPage` مع 7 تبويبات
- **Tabs:** company info, working schedule, default pricing, special holidays, notifications, branches management, doctors schedule
- **Medical Services:** table, cards, filter, add/edit/delete dialogs, status badge, shimmer
- **Doctors Schedule Tab:** cards, table, shimmer

**الاختبارات:**
- `medical_services_catalog_test.dart`: passed

---

### 🩺 F-04a: محرك الكشف الطبي ومتابعة الزيارات (Doctor Consultation Engine)
**الحالة:** ✅ مكتملة ومختبرة بالكامل (100%)

**ما تم بناؤه:**
- **Layer البيانات:**
  - `VisitModel` — نموذج الكشف الكامل (100% nullable) يشمل الحقول السريرية (chiefComplaint, diagnosis, physicalExam, treatmentPlan...) وحالة الزيارة (triage, in_progress, finalized) وقفل الكشف.
  - `VitalsModel` — تسجيل العلامات الحيوية وحساب مؤشر كتلة الجسم (BMI) التلقائي وتحذيرات الضغط والنبض والأكسجين والحرارة والوزن مع عتبات سريرية دقيقة (`VitalsThresholds`).
  - `ConsultationQueueItemModel` — عنصر طابور الكشف المدمج بين الحجز وحالة الزيارة الحية.
  - `VisitsRepo` (Interface) + `VisitsMockRepoImpl` — مستودع بيانات بالذاكرة مع seed لـ 3 زيارات تمثل حالات مختلفة وتزامن الحجوزات.
- **Layer الدومين (Use Cases):**
  - `StartConsultationUseCase` — بدء الكشف، تحديث حالة الحجز لـ inConsultation، إنشاء الزيارة، وفرض صلاحية `startConsultation` وقيد الطبيب المسند وتدقيق `visit_started`.
  - `RecordVitalsUseCase` — تسجيل العلامات الحيوية من قبل التمريض أو الطبيب، تحويل حالة الزيارة لـ triage/in_progress، وتدقيق `vitals_recorded`.
  - `SaveVisitDraftUseCase` — حفظ مسودة الملاحظات السريرية مع فحص الصلاحية وسجل التدقيق.
  - `FinalizeVisitUseCase` — التحقق السريري الإلزامي للشكوى والتشخيص، إنهاء الزيارة، تحديث الحجز لـ completed عبر Saga آمنة بدون Rollback، وتدقيق `visit_finalized`.
  - `GetDoctorQueueUseCase` — جلب طابور الكشف حسب الفرع والتاريخ والطبيب.
- **Layer العرض (Presentation):**
  - `VisitsCubit` + `VisitsState` + `VisitFormState` — إدارة حالة متكاملة بنمط SafeCubit، تشمل الحفظ التلقائي كل 30 ثانية للبيانات المعدلة فقط (`isDirty`) والتفريغ عند المغادرة (`flushDraftOnExit`).
  - `VisitsPage` — دليل طابور الكشوفات المتجاوب (`AdaptiveVisitsView`) يدعم العرض المكتبي (جدول `ConsultationQueueTable`) واللوحي/المحمول (بطاقات `ConsultationQueueCard`).
  - `DoctorConsultationScreen` — مساحة عمل الطبيب السريرية المتجاوبة (Desktop عمودين، Mobile عمود متدفق مع شريط سفلي)، بانر الحساسيات والأمراض المزمنة، ولوحة الملاحظات ولوحة العلامات الحيوية.
  - **الحوارات:** `RecordVitalsDialog` (تسجيل العلامات مع مؤشرات الخطر)، `FinalizeVisitDialog` (تأكيد الإنهاء مع ملخص سريري).
  - **نقاط الدخول من الحجوزات:** أزرار "بدء الكشف / استكمال الكشف" في جدول الحجوزات وبطاقة الحجز وشريط التفاصيل العلوي مقيدة بـ RBAC وتاريخ اليوم.
- **الأمان والخصوصية (Security & RBAC):**
  - صلاحية مستقلة `viewConsultationNotes` لمنع استراق النظر للسجلات الطبية.
  - تدقيق أمني للأحداث بالمعرفات فقط (Zero Clinical/Vitals Data in Audit Log).
  - حماية مسار `/visits/:id` بـ `AppRouter` عبر فحص الصلاحيات الحي وربط الطبيب المسند.

**الاختبارات:**
- موديول الزيارات: 129/129 passed (100%)
- أزرار الكشف في الحجوزات: 5/5 passed (100%)
- إجمالي اختبارات المشروع: 343/343 passed (100%)

---

## 🧰 البنية التحتية الجاهزة (Core Infrastructure)

### Design System — Warm Layered Minimalism
| الخاصية | القيمة |
|:---|:---|
| **الألوان الأساسية** | Terracotta Coral `#E0583E` (Primary), Eucalyptus Sage `#2D6A4F` (Secondary) |
| **الخلفية** | Off-White ناعمة |
| **Border Radius** | 24-28px للبطاقات، 100px للأزرار (Stadium Pills) |
| **الخط** | Madani (Arabic) |
| **الاتجاه** | RTL بالكامل |

### الـ Shared Widgets المكتملة (40+)
| الـ Widget | الوصف |
|:---|:---|
| `CustomTextFormField` | حقل إدخال مع headerText |
| `CustomStackSelector` | Dropdown مع بحث |
| `CustomAssetImage` | صور assets موحدة |
| `CustomPushButton` | زر بـ loading state |
| `SummaryCard` | بطاقة إحصائية مع gradient |
| `CustomTable` / `EnhancedTable` | جداول بيانات متجاوبة |
| `CustomShimmerContainer` | Skeleton loading |
| `CustomEmptyWidget` | شاشة فارغة |
| `CustomDeleteDialog` | حوار حذف موحد |
| `CustomStatusDialog` | حوار تغيير حالة |
| `PaginationListView` | قائمة مع pagination |
| `AdaptiveLayout` / `ScreenAdaptiveLayout` | تخطيط متجاوب |
| `CustomToast` | رسائل إشعار (toastification) |

### نظام التوجيه (GoRouter)
- `/login` → `LoginPage`
- `/` → Dashboard Shell (ShellRoute)
  - `/dashboard` → `HomeDashboardPage`
  - `/bookings` → `BookingsPage`
  - `/bookings/:id` → `BookingDetailsPage`
  - `/patients` → `PatientsPage`
  - `/patients/:id` → `PatientDetailsPage`
  - `/doctors` → `DoctorsPage`
  - `/doctors/:id` → `DoctorDetailsPage`
  - `/users-management` → `UsersManagementPage`
  - `/settings` → `SettingsPage` (مع tabs)
  - `/settings/audit-logs` → `AuditLogsPage`
  - `/visits` → `VisitsPage` (skeleton)
  - `/cashier` → `CashierPage` (skeleton)
  - `/hr` → `HrPage` (skeleton)
  - `/analytics` → `AnalyticsPage` (skeleton)

### حقن الاعتماديات (DI — get_it)
كل الـ Cubits والـ Repos والـ UseCases مسجلة في `dependency_injection.dart` كـ `lazySingleton`.

### المكتبات المستخدمة
```yaml
bloc / flutter_bloc: ^9.1.x     # State management
go_router: ^17.0.0              # Routing
get_it: ^9.0.5                  # DI
dartz: ^0.10.1                  # Either (error handling)
dio: ^5.8.0                     # HTTP client
easy_localization: ^3.0.8       # i18n (ar-EG + en-US)
fl_chart: ^1.2.0                # Charts
pdf + printing: ^3/5            # PDF generation & printing
shimmer: ^3.0.0                 # Loading skeletons
toastification: ^3.0.3          # Toasts
equatable: ^2.0.7               # Value equality
shared_preferences: ^2.5.3     # Local storage
image_picker + flutter_image_compress: ...
hugeicons: ^1.1.6               # Icon set
```

---

## 📂 الملفات الحاكمة (يجب قراءتها قبل أي عمل)

| الملف | الغرض |
|:---|:---|
| [`docs/AGENT_OPERATING_GUIDE.md`](../AGENT_OPERATING_GUIDE.md) | دليل التشغيل الكامل + القواعد المعمارية |
| [`docs/PRODUCT_PLAN.md`](../../../PRODUCT_PLAN.md) | رؤية المنتج والقرارات |
| [`FEATURES_EXECUTION_PLAN.md`](../../../FEATURES_EXECUTION_PLAN.md) | خطة تنفيذ كل فيتشر |
| [`docs/PROGRESS.md`](../PROGRESS.md) | حالة التقدم والاختبارات |
| [`docs/DECISIONS.md`](../DECISIONS.md) | سجل القرارات الهندسية |
| [`.agents/skills/`](../../../.agents/skills/) | Skills للـ AI Agent |

---

### B-DISC: نظام الخصومات والكشوفات المجانية (Booking Discounts & Free Consultations)
- **الحالة:** مكتمل ومختبر 100%
- **المكونات:**
  - `DiscountTypeEnum` (`none`, `percentage`, `fixedAmount`, `free`) مع getter `labelKey` و`localizedName`.
  - امتداد `BookingModel` بخصائص `isFreeConsultation`, `discountAmount`, `netAmount`, `effectivePaymentStatus`.
  - مصفوفة أدوار الطاقم `RoleDefinitionModel` مع `maxDiscountPercent` و`canGrantFreeConsultation`.
  - حوكمة دومينية كاملة عبر `SaveRoleUseCase` و`UpdateRoleDiscountPolicyUseCase` و`BookingDiscountValidator`.
  - اشتقاق معتمد ومزيل الخصم حصرياً من الجلسة النشطة `CurrentUserProvider`.
  - إعادة التحقق عند تغيير سعر الكشف وتصفير الخصم غير الصالح مع تدقيق مسجل (`fee_changed`).
  - شارة `FreeBookingBadge` وبطاقة `BookingPriceSummaryCard` وقسم `BookingDiscountSection` ونافذة حوار `RolePermissionsMatrixDialog`.

---

### 💊 F-04b: الروشتة الذكية وكتالوج الأدوية ومعايرة الطباعة (Prescriptions & Drugs)
- **الحالة:** مكتمل ومختبر 100% (137 اختباراً)
- **المكونات:**
  - كتالوج أدوية متكامل بنماذج `DrugModel`, `DrugDosageFormEnum`, `PrescriptionTemplateModel`.
  - محرك فحص التعارضات والحساسية الدوائية ومطابقة المرادفات الدوائية (Allergy Aliases).
  - إضافة الأدوية السريعة (Quick Add) والمراجعة والاعتماد (Review & Approve).
  - قوالب روشتات الأطباء المتخصصة حسب الطبيب أو العيادة.
  - إعدادات معايرة هوامش الروشتة والإيصالات بالملليمتر وتوليد PDF متجاوب.

### 💰 F-05: الخزينة والورديات والفواتير (Cashier & Invoicing)
- **الحالة:** مكتمل ومختبر 100% (140 اختباراً)
- **المكونات:**
  - إدارة ورديات الكاشير: فتح، إغلاق، جرد فعلي، وتسجيل العجز والزيادة مع دورة اعتماد المشرفين.
  - الفواتير المتعددة وتحصيل المدفوعات بمختلف الطرق (نقدي، بطاقة، إنستاباي، آجل).
  - تسجيل المصروفات النثرية من الدرج (Drawer Expenses) وعمليات الاسترداد (Refunds).
  - الإغلاق الإجباري للطوارئ (Force Close) مع تسجيل كامل لبيانات الرقابة والأمان.
  - توليد إيصالات دفع إلكترونية متجاوبة وتقرير إغلاق وردية تفصيلي بصيغة PDF.

### 👥 F-06: الموارد البشرية وتسويات الأطباء ومسير الرواتب (HR & Settlements)
- **الحالة:** مكتمل ومختبر 100% (171 اختباراً)
- **المكونات:**
  - قواعد احتساب تعويضات وأتعاب الأطباء: نسبة مئوية، مبلغ مقطوع، وشرائح تصاعدية (Slabs) بعد خصم المستهلكات.
  - مسودات التسوية (Settlement Drafts)، المطابقة مع الكشوفات المنجزة، والاعتماد والصرف.
  - مسير رواتب الموظفين (Staff Payroll): احتساب الراتب الأساسي والبدلات والخصومات وإصدار المسير الدوري.
  - دفتر الأستاذ العام للموظفين (Employee General Ledger) وتسجيل قيود الخصم والإضافة مع دعم حركات العكس المحاسبي.

### 📊 F-07: التقارير والإحصائيات ولوحة التحليلات التنفيذية (Analytics & BI)
- **الحالة:** مكتمل ومختبر 100% (160 اختباراً)
- **المكونات:**
  - بطاقات المؤشرات الرئيسية (KPIs): الإيرادات، الأرباح التقديرية، مديونيات المرضى، ومتوسط وقت الانتظار.
  - الرسوم البيانية التفاعلية: اتجاه الإيرادات (LineChart) ومقارنة الفروع وحصصها (BarChart) عبر `fl_chart`.
  - لوحة صدارة الأطباء (Doctor Leaderboard) وجدول مؤشرات الإنتاجية.
  - خريطة أوقات الذروة وازدحام العيادة (Peak Hours Heatmap) لساعات العمل من 09:00 إلى 22:00.
  - فلتر زمني متقدم (اليوم، الأسبوع، الشهر، فترة مخصصة)، عزل تام للفروع، وحجب البيانات المالية عن غير المصرح لهم.

---

## 🧪 نتيجة الاختبارات الحالية
```
flutter test → 1073/1073 passed (100%)
flutter analyze → 0 issues found
```

> **ملاحظة:** جميع واجهات ومنطق الأعمال مكتملة وتعمل ببيانات Mock، وجاهزة للربط بالـ Backend مباشرة.



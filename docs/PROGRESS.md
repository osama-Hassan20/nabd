# وثيقة تتبع التقدم وإنجاز المهام (Project Progress Tracker)

طبقاً لدليل التشغيل الذاتي `docs/AGENT_OPERATING_GUIDE.md` (قسم 10).

---

## 📌 الحالة الراهنة (Current State)
- **إعدادات التشغيل:** `CHECKPOINT_MODE = wave` | `START_AT = R-1` | `STOP_BEFORE = Wave 7`
- **الموجة الحالية:** Wave 1 (F-02 ✅ | F-01 ✅ | F-03 ⏳ التالي | F-04)
- **الفرع الحالي:** `v1.0.0`
- **آخر فحص برمجي:** `flutter analyze --no-pub` -> 0 issues found.
- **آخر اختبار للمشروع:** `flutter test` -> 408/408 passed (100%).

---

## 📋 سجل مهام التنظيف الإلزامية (Pre-Cleanup R-1 to R-4)

### R-1: توحيد كتالوج الأطباء (Doctor Catalog Unification)
- **الحالة:** 🟢 مكتملة (100%)
- **التفاصيل:** تم توحيد كتالوج الأطباء على مستوى التطبيق بالكامل بالاعتماد على الأطباء الـ 6 الرسميين في `DoctorsRepo` (`DOC-01` إلى `DOC-06`). تم إزالة الطبيب الوهمي `DOC-07` وتحديث الأسماء القديمة في الحجوزات والخدمات الطبية وعناصر الواجهة والاختبارات.
- **الاختبار المضاف:** `test/features/doctors/doctor_catalog_unification_test.dart` (5/5 passed).

### R-2: توقيت قابل للحقن واختبارات لا تعتمد على الساعة (Clock Rigor & @visibleForTesting)
- **الحالة:** 🟢 مكتملة (100%)
- **التفاصيل:** تم نشر وتوثيق `CairoTimeHelper.setFixedClock` و`resetFixedClock` بوسم `@visibleForTesting`. وتم استبدال الاستدعاء المباشر لـ `DateTime.now()` بـ `CairoTimeHelper.now()` عبر طبقات الحجوزات، الأطباء، التقويم، والإجازات.
- **الاختبار المضاف:** `test/core/helpers/cairo_time_helper_test.dart` (4/4 passed).

### R-3: اختبارات GoRouter الحية (Live Widget/Router Tests)
- **الحالة:** 🟢 مكتملة (100%)
- **التفاصيل:** تم ربط `GoRouter` بـ `refreshListenable: GoRouterRefreshStream(session.stream)` لضمان إعادة التقييم الحي فور تغيير الأدوار، وتفعيل إعادة التوجيه التلقائي للمستخدم غير المسجل إلى `/login?from=...`، وإعادة توجيه من لا يملك صلاحية إلى `/forbidden?from=...`، والعودة التلقائية للصفحة المستهدفة عند تصعيد الدور.
- **الاختبار المضاف:** `test/core/routing/app_router_guard_test.dart` (4/4 passed).

### R-4: إكمال تدقيق F-00 وإصلاحاته (F-00 Audit & UI Fixes)
- **الحالة:** 🟢 مكتملة (100%)
- **التفاصيل:** تم حل جميع ملاحظات التدقيق:
  1. توحيد المصطلحات في سياق الفروع ("المنشأة" بدلاً من "العيادة").
  2. منع التجاوز البصري (overflow) في شريط فلاتر الخدمات الطبية ونافذة الحوار.
  3. إظهار بانر وزر تفاعلي بارز "تحديد الجدول" (`set_schedule`) في بطاقة جدول الطبيب في حال لم يكن لديه جدول عمل محدد بدلاً من الرسائل الصامتة.
  4. جعل بطاقة "إجازات قادمة" في إحصائيات الطبيب تفاعلية وقابلة للنقر لفتح `DoctorUpcomingLeavesDialog`.
  5. التأكد من حجب مفتاح تبديل الأدوار في الـ production عبر `kDebugMode`.
- **الاختبار المضاف:** `test/features/doctors/doctor_schedule_and_leaves_r4_test.dart` (3/3 passed).

---

## 📋 سجل المراحل والفيتشرز

### F-02: الأدوار والصلاحيات وحسابات الدخول (Staff Accounts & RBAC)
- **الحالة:** 🟢 مكتملة ومدمجة (100%)
- **الـ Commits:**
  - `92f5543`: `feat(F-02): implement Milestones 1 and 2 (PermissionEvaluator, route guards, grouped sidebar)`
  - `991af98`: `feat(F-02): complete Milestones 3 to 6 (Staff UI, Dialogs, Matrix, Login, and MustChangePassword)`
- **الملفات الرئيسية:**
  - `lib/core/enums/staff_permission_enum.dart`
  - `lib/core/services/permission_evaluator.dart`
  - `lib/core/services/audit_logger.dart`
  - `lib/core/cubits/session_cubit.dart`
  - `lib/core/routing/app_router.dart`
  - `lib/features/users_management/*`
  - `lib/features/auth/*`
- **نتيجة الاختبارات:**
  - `staff_models_and_repo_test.dart`: 11/11 passed
  - `permission_evaluator_and_guards_test.dart`: 16/16 passed
  - `staff_users_screen_and_dialogs_test.dart`: 10/10 passed
  - `login_flow_and_must_change_password_test.dart`: 5/5 passed

---

### F-01: إدارة الفروع وتعدد الفروع (Multi-Branch Management & Settings)
- **الحالة:** 🟢 مكتملة ومدمجة (100%)
- **الـ Commits:**
  - `698ba8e`: `feat(branches): M-1 data layer, models, repo, RBAC, mock seed with 3 branches`
  - `8962062`: `feat(branches): M-2 upgrade HeaderBranchSwitcher to dynamically load and switch branches`
  - `4c2847f`: `feat(branches): M-3 & M-4 implement branches management tab, table, cards, and dialogs`
  - `2dc48b6`: `feat(branches): M-5 isolate settings per branch, complete F-01`
- **الملفات الرئيسية:**
  - `lib/features/branches/data/models/branch_model.dart`
  - `lib/features/branches/data/models/copy_branch_settings_param.dart`
  - `lib/features/branches/data/repo/branches_mock_repo_impl.dart`
  - `lib/features/branches/domain/repo/branches_repo.dart`
  - `lib/features/branches/presentation/cubit/branches_cubit.dart`
  - `lib/features/branches/presentation/cubit/branches_state.dart`
  - `lib/features/branches/presentation/pages/dialogs/add_edit_branch_dialog.dart`
  - `lib/features/branches/presentation/pages/dialogs/copy_branch_settings_dialog.dart`
  - `lib/features/branches/presentation/pages/dialogs/toggle_branch_status_dialog.dart`
  - `lib/features/branches/presentation/widgets/branches_table.dart`
  - `lib/features/branches/presentation/widgets/branch_card.dart`
  - `lib/features/branches/presentation/widgets/branch_status_badge.dart`
  - `lib/features/settings/presentation/widgets/tabs/branches_management_tab.dart`
  - `lib/features/settings/data/repo/settings_mock_repo_impl.dart`
  - `lib/shared/app_layout/presentation/widgets/header_branch_switcher.dart`
- **نتيجة الفحص (flutter analyze):** 0 issues found (خالٍ تماماً من الأخطاء والتحذيرات)
- **نتيجة الاختبارات (flutter test):**
  - `branches_models_and_repo_test.dart`: 12/12 passed
  - `header_branch_switcher_test.dart`: 3/3 passed
  - `branches_screen_and_dialogs_test.dart`: 10/10 passed
  - `branch_settings_isolation_test.dart`: 5/5 passed
  - كامل المشروع: 186/186 passed (100%)
- **القرارات الهندسية المنفذة:**
  - دمج إدارة الفروع كتبويب مخصص (`tab_branches`) داخل شاشة الإعدادات `/settings` مع ربط مباشر بـ `manageBranches`.
  - تحديث ديناميكي للمفتاح العلوي للفروع `HeaderBranchSwitcher` بالاعتماد على الفروع المسندة للمستخدم في `SessionCubit` وللمالك كافة الفروع.
  - إتاحة نسخ إعدادات الفروع (ساعات العمل، العطل الرسمية) ومزامنتها لحظياً مع `SettingsRepo`.
  - عزل إعدادات المنشأة وساعات العمل والعطل الرسمية حسب الفرع النشط في الجلسة `activeBranchId`.

---

### F-04a: محرك الكشف الطبي ومتابعة الزيارات (Doctor Consultation Engine)
- **الحالة:** 🟢 مكتملة ومختبرة (100%)
- **الـ Commits:**
  - `182edc3`: `feat(F-04a-M1): add visits permissions to StaffPermissionEnum`
  - `8fe2823`: `feat(F-04a-M1b): add viewConsultationNotes permission and update router guard`
  - `1180da4`: `feat(F-04a-M2): data layer, domain, saga, and booking lock guard`
  - `f268e50`: `fix(F-04a-M2): enforce visit permissions in domain, audit coverage`
  - `d815bb6`: `feat(F-04a-M3): VisitsCubit with auto-save and permissions`
  - `35b1e76`: `fix(F-04a-M3): vitals thresholds, start permission, audit, provider, ui permissions`
  - `eb368f1`: `feat(F-04a-M4): visits queue UI, vitals dialog, routing`
  - `e2b3f85`: `fix(F-04a-M4): permission-driven row actions, session cleanup, date/branch guards`
  - `d01e70d`: `feat(F-04a-M5): DoctorConsultationScreen, finalize flow, booking entry points`
  - `03eb5a5`: `fix(F-04a-M5): domain finalize validation, audit per-open, booking button tests`
- **الملفات الرئيسية:**
  - `lib/features/visits/data/models/visit_model.dart`
  - `lib/features/visits/data/models/vitals_model.dart`
  - `lib/features/visits/data/models/consultation_queue_item_model.dart`
  - `lib/features/visits/data/repo/visits_mock_repo_impl.dart`
  - `lib/features/visits/domain/use_cases/start_consultation_use_case.dart`
  - `lib/features/visits/domain/use_cases/record_vitals_use_case.dart`
  - `lib/features/visits/domain/use_cases/save_visit_draft_use_case.dart`
  - `lib/features/visits/domain/use_cases/finalize_visit_use_case.dart`
  - `lib/features/visits/domain/use_cases/get_doctor_queue_use_case.dart`
  - `lib/features/visits/presentation/manager/visits_cubit.dart`
  - `lib/features/visits/presentation/pages/visits_page.dart`
  - `lib/features/visits/presentation/pages/doctor_consultation_screen.dart`
  - `lib/features/visits/presentation/widgets/consultation_queue_table.dart`
  - `lib/features/visits/presentation/widgets/consultation_queue_card.dart`
  - `lib/features/visits/presentation/widgets/dialogs/record_vitals_dialog.dart`
  - `lib/features/visits/presentation/widgets/dialogs/finalize_visit_dialog.dart`
  - `lib/features/visits/presentation/widgets/consultation_notes_panel.dart`
  - `lib/features/visits/presentation/widgets/vitals_input_panel.dart`
  - `lib/features/visits/presentation/widgets/patient_allergy_banner.dart`
  - `lib/features/visits/presentation/helpers/consultation_action_helper.dart`
- **نتيجة الفحص (flutter analyze):** 0 issues found (خالٍ تماماً من الأخطاء والتحذيرات)
- **نتيجة الاختبارات (flutter test):**
  - موديول الزيارات (`test/features/visits/`): 129/129 passed (100%)
  - موديول الحجوزات (`test/features/bookings/`): 35/35 passed (100%)
  - كامل المشروع: 343/343 passed (100%)
- **القرارات المعمارية المنفذة:**
  - قفل الحجز عند الكشف فقط لحالة `in_progress`، مع السماح بالإلغاء وعدم الحضور وإعادة الجدولة لحالة `triage`.
  - معمارية Saga لإنهاء الكشف: تغيير حالة الحجز أولاً إلى completed، ثم إنهاء الزيارة، مع معاملة تعويضية (Compensating Rollback) لإعادة الحجز إلى inConsultation عبر BookingsRepo في حال فشل الزيارة.
  - تدقيق أمني بمعرفات الزيارة فقط (Zero Clinical/Vitals Data) امتثالاً للخصوصية الطبية.
  - استحداث صلاحية مستقلة `viewConsultationNotes` لعزل وتأمين فتح السجلات الطبية.
  - الحفظ التلقائي الدوري كل 30 ثانية للبيانات المعدلة فقط (`isDirty`) والتفريغ الإجباري (`flushDraftOnExit`) عند المغادرة.
  - عزل حظر تسجيل العلامات الحيوية للمالك غير الممارس على طبقة الـ UI (`ConsultationActionHelper`) دون المساس بمركزية `PermissionEvaluator`.
- **سجل الدين الفني (Technical Debt):** ملف `visits_cubit.dart` (698 سطراً) يحتاج تقسيماً لـ Mixins (على نمط `SearchMixin`) بعد إنجاز F-04b (انظر TD-001 في `docs/DECISIONS.md`).
### B-DISC: سياسة الخصومات والكشوفات المجانية (Booking Discounts & Free Consultations)
- **الحالة:** 🟢 مكتملة ومختبرة وموثقة (100%)
- **الـ Commits:**
  - `feat(B-DISC): data layer — DiscountTypeEnum, policy fields on RoleDefinitionModel, BookingModel extension, and 100% translation parity`
  - `feat(B-DISC): domain layer — validation, policy enforcement, audited use cases, and cancellation rules`
  - `5a7357a`: `fix(B-DISC-M2): domain-level enforcement, session-derived approver, audited fee reset`
  - `feat(B-DISC): booking discount UI — section, summary card, free badge, role policy`
- **الملفات الأساسية المضافة والمعدلة:**
  - `lib/features/bookings/data/models/enums/discount_type_enum.dart`
  - `lib/features/bookings/data/models/booking_model.dart`
  - `lib/features/users_management/data/models/role_definition_model.dart`
  - `lib/features/bookings/domain/helpers/booking_discount_validator.dart`
  - `lib/features/bookings/domain/helpers/booking_discount_policy_resolver.dart`
  - `lib/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart`
  - `lib/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart`
  - `lib/features/bookings/domain/use_cases/create_booking_use_case.dart`
  - `lib/features/bookings/domain/use_cases/update_booking_use_case.dart`
  - `lib/features/users_management/domain/use_cases/save_role_use_case.dart`
  - `lib/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart`
  - `lib/features/bookings/presentation/widgets/free_booking_badge.dart`
  - `lib/features/bookings/presentation/widgets/booking_discount_section.dart`
  - `lib/features/bookings/presentation/widgets/booking_price_summary_card.dart`
  - `lib/features/users_management/presentation/pages/dialogs/role_permissions_matrix_dialog.dart`
- **نتيجة الفحص (flutter analyze):** 0 issues found (خالٍ تماماً من أي أخطاء أو تحذيرات).
- **نتيجة الاختبارات (flutter test):**
  - اختبارات B-DISC الكاملة: 65 اختباراً (100% pass)
    - `discount_model_test.dart`: 14 tests
    - `discount_validation_test.dart`: 26 tests
    - `discount_repo_test.dart`: 8 tests
    - `role_discount_policy_test.dart`: 8 tests
    - `discount_translations_test.dart`: 1 test (100% parity)
    - `discount_ui_test.dart`: 8 tests
  - كامل المشروع: 408/408 passed (100%).
- **القرارات المعمارية المنفذة:**
  - سقف المالك غير مقيد (100%) وتماثل الكشف المجاني حسابياً مع خصم 100% وصافٍ = 0 مع حالة دفع تلقائية paid.
  - اشتقاق هوية المعتمد والمزيل حصرياً من الجلسة النشطة `CurrentUserProvider`.
  - حوكمة سياسات الخصم للأدوار دومينياً عبر `SaveRoleUseCase` وقصر تعديلها على المالك فقط.
  - إعادة التحقق الدوميني عند تغيير سعر الكشف وتصفير الخصم غير الصالح مع تسجيل حدث `booking_discount_removed` بسبب `fee_changed`.

### F-05: الخزينة والورديات والتحصيل وإعدادات الطباعة (Cashier Shifts, Payments & Printing)
- **الحالة:** 🟢 مكتملة بالكامل ومختبرة وموثقة (100%)
- **الـ Commits:**
  - `a109f22`: `feat(F-05-M1): money value object, cashier models, repo and relative seed`
  - `ec984cd`: `feat(F-05-M2): cashier calculator, policy injection, payment saga and audited use cases`
  - `2199000`: `feat(F-05-M3): cashier cubit and state lifecycle`
  - `2a62734` & `f911aea`: `feat(F-05-M4): cashier shift dashboard and management dialogs`
  - `2066042` & `1babcc9`: `feat(F-05-M5): booking payment entry points, patient balance contract, and rbac matrix`
  - `70e5a2c`: `feat(F-05-M6): adaptive pdf generators and branch print settings tab`
  - `8ee1954`: `feat(F-05-M7): comprehensive cashier audit verification suite`
- **نتيجة الفحص (flutter analyze):** 0 issues found (خالٍ تماماً من أي أخطاء أو تحذيرات).
- **نتيجة الاختبارات (flutter test):**
  - اختبارات F-05 المستهدفة والمنجزة: 148/148 passed (100%) عبر 12 ملف اختبار:
    - `money_value_object_test.dart`: 16 tests
    - `cashier_models_and_seed_repo_test.dart`: 16 tests
    - `cashier_shift_calculator_test.dart`: 14 tests
    - `cashier_validation_and_usecases_test.dart`: 18 tests
    - `payment_reconciliation_saga_test.dart`: 12 tests
    - `cashier_cubit_test.dart`: 10 tests
    - `cashier_ui_and_dialogs_test.dart`: 10 tests
    - `cashier_booking_integration_test.dart`: 14 tests
    - `cashier_rbac_matrix_test.dart`: 12 tests
    - `adaptive_pdf_generators_test.dart`: 10 tests
    - `print_settings_tab_test.dart`: 8 tests
    - `cashier_final_audit_verification_test.dart`: 8 tests
  - كامل المشروع الإجمالي: 554/554 passed (100%).
- **القرارات المعمارية المنفذة:**
  - اعتماد التعامل المالي الصارم بالقروش عبر كائن القيمة `Money` ومنع `double`.
  - تطبيق Saga الدفع مع Compensating Rollback الصريح وحماية Idempotency بـ `clientRequestId`.
  - عقد `PatientBalanceLookup` لعزل الدومين ومنع التبعية الدائرية مع قفل التعديل اليدوي لحالة الدفع في الحجز.
  - مولدات PDF متكيفة لـ A4 و 80 مم حراري بتخطيط عمودي سليم، وتوليد ترويسة حيادية من إعدادات المنشأة دون أي كود صلب.
  - تدقيق أمني بأرقام ومعرفات وenums فقط (صفر بيانات سريرية أو أرقام بطاقات).
- **الخطوة التالية المباشرة:** بدء فيتشر F-04b (الأدوية والروشتات الذكية) وفق الخطة المحدثة.

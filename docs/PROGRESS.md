# وثيقة تتبع التقدم وإنجاز المهام (Project Progress Tracker)

طبقاً لدليل التشغيل الذاتي `docs/AGENT_OPERATING_GUIDE.md` (قسم 10).

---

## 📌 الحالة الراهنة (Current State)
- **إعدادات التشغيل:** `CHECKPOINT_MODE = wave` | `START_AT = R-1` | `STOP_BEFORE = Wave 7`
- **الموجة الحالية:** Wave 1 (F-02 ✅ | F-01 ✅ | F-03 ⏳ التالي | F-04)
- **الفرع الحالي:** `v1.0.0`
- **آخر فحص برمجي:** `flutter analyze --no-pub` -> 0 issues found.
- **آخر اختبار للمشروع:** `flutter test` -> 186/186 passed (100%).

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
- **الخطوة الجاية:** البدء في **F-03 — سجل النشاط والأمان (Security Audit Log)** استمراراً للموجة 1.

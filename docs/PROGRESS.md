# وثيقة تتبع التقدم وإنجاز المهام (Project Progress Tracker)

طبقاً لدليل التشغيل الذاتي `docs/AGENT_OPERATING_GUIDE.md` (قسم 10).

---

## 📌 الحالة الراهنة (Current State)
- **إعدادات التشغيل:** `CHECKPOINT_MODE = wave` | `START_AT = R-1` | `STOP_BEFORE = Wave 7`
- **الفرع الحالي:** `v1.0.0`
- **آخر فحص برمجي:** `flutter analyze --no-pub` -> 0 issues found.
- **آخر اختبار للمشروع:** `flutter test` -> 128/128 passed (100%).

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

---

## 📋 سجل المراحل والفيتشرز

### F-02: الأدوار والصلاحيات وحسابات الدخول (Staff Accounts & RBAC)
- **الحالة:** 🟡 قيد التنفيذ (المرحلة 1 و 2 مكتملتان ومختبرتان، بانتظار R-1 إلى R-4 ثم المراحل 3 إلى 6)
- **الـ Commits:**
  - `92f5543`: `feat(F-02): implement Milestones 1 and 2 (PermissionEvaluator, route guards, grouped sidebar)`
- **الملفات الرئيسية:**
  - `lib/core/enums/staff_permission_enum.dart`
  - `lib/core/services/permission_evaluator.dart`
  - `lib/core/services/audit_logger.dart`
  - `lib/core/cubits/session_cubit.dart`
  - `lib/core/routing/app_router.dart`
  - `lib/features/users_management/data/models/*`
  - `lib/features/users_management/data/repositories/*`
  - `lib/shared/presentation/pages/forbidden_403_page.dart`
  - `lib/shared/app_layout/presentation/widgets/header_role_switcher.dart`
  - `lib/shared/app_layout/presentation/widgets/header_branch_switcher.dart`
  - `lib/core/layout_adaptive/widgets/custom_side_bar.dart`
- **نتيجة الفحص (flutter analyze):** 0 issues (خالٍ تماماً من الأخطاء والتحذيرات)
- **نتيجة الاختبارات (flutter test):**
  - `staff_models_and_repo_test.dart`: 11/11 passed
  - `permission_evaluator_and_guards_test.dart`: 16/16 passed
  - كامل المشروع: 119/119 passed
- **القرارات الهندسية المرتبطة:** DEC-001، DEC-002
- **غير مختبر:** الواجهة البصرية لشاشة 403 لم تُجرَّب بصرياً بالعين في المتصفح وإنما تم اختبارها عبر الـ Unit & Evaluation Tests.
- **الخطوة الجاية:** البدء في مهام التنظيف الإلزامية `R-1` إلى `R-4`، يتبعها إكمال المراحل 3 إلى 6 من F-02.


# خطة تنفيذ F-03: سجل النشاط والأمان (Security Audit Log)

طبقاً لدليل التشغيل الذاتي `docs/AGENT_OPERATING_GUIDE.md` وقواعد المشروع الهندسية.

---

## 1. النطاق والهدف (Scope & Objectives)
- **الهدف:** توفير شاشة وسجل كامل لنشاط وأمان النظام للمالك (`isOwner`) ولأصحاب صلاحية `viewAuditLogs`، لتتبع جميع العمليات الحساسة في المنشأة والفروع (إنشاء/تعديل المستخدمين، تسجيل الدخول والخروج وفشل المحاولات، تغيير الصلاحيات، عمليات الفروع، وفتح ملفات وسجلات المرضى).
- **داخل النطاق (In Scope):**
  - توسيع `AuditLogger` و`InMemoryAuditLogger` لدعم فلاتر متقدمة (نوع الحدث، المستخدم الفاعل، الفرع، النطاق الزمني، والبحث النصي).
  - توفير بذور أولية واقعية (Seed Audit Logs) لضمان تجربة حية غير فارغة.
  - إضافة صلاحية `viewAuditLogs` في `StaffPermissionEnum`، مع حصرها افتراضياً للمالك فقط (`isOwner == true`).
  - تسجيل حدث "فتح ملف المريض" (`view_patient_profile`) عند استعراض شاشة تفاصيل المريض.
  - حماية مسار `/settings/audit-logs` عبر `app_router.dart` وفحصه بـ `StaffPermissionEnum.viewAuditLogs`.
  - إضافة عنصر السايد بار "سجل النشاط والأمان" ضمن مجموعة الإعدادات (`nav_group_settings`).
  - بناء طبقة الـ Presentation: `AuditLogsCubit`, `AuditLogsState`, `AuditLogsPage`, `AuditLogsTable`, `AuditLogsFilterBar`, `AuditLogDetailsDialog`, `AuditEventTypeBadge`.
  - دعم تصدير السجل (Export / Print Snapshot Mock).
  - اختبارات شاملة لكل مرحلة بنسبة نجاح 100%.
- **خارج النطاق (Out of Scope):**
  - تعديل أو حذف أي سجل نشاط (السجل append-only وغير قابل للتعديل أو الحذف بتاتاً).
  - إرسال السجلات لسيرفر خارجي (مؤجل لما بعد Wave 6).

---

## 2. نموذج البيانات والـ RBAC (Data Model & Security)

### 2.1 نموذج البيانات `SecurityAuditLogModel` (Single Model Pattern)
- الحقول (جميعها 100% nullable ومطابقة لنمط المشروع):
  - `id`: String?
  - `eventType`: String?
  - `performedByUserId`: String?
  - `performedByUserName`: String?
  - `targetUserId`: String?
  - `targetUserName`: String?
  - `branchId`: String?
  - `branchName`: String?
  - `details`: String? (خالٍ تماماً من أي كلمات مرور أو رموز سرية ومصفى عبر `_sanitize`)
  - `ipAddress`: String?
  - `timestamp`: DateTime?

### 2.2 جدول seed الصلاحيات لـ F-03
| الدور | الافتراضي لـ `viewAuditLogs` | ملاحظات |
| :--- | :---: | :--- |
| **المالك (`isOwner`)** | ✅ متاح دائماً | يملك كل الصلاحيات |
| **مدير الفرع (`branchManager`)** | ❌ غير مفعل | يمكن تفعيله يدوياً من المالك |
| **المدير الطبي (`medicalDirector`)** | ❌ غير مفعل | مقفل افتراضياً |
| **الطبيب (`doctor`)** | ❌ مقفل | لا يملك الوصول |
| **موظف الاستقبال (`reception`)** | ❌ مقفل | لا يملك الوصول |
| **الكاشير (`cashier`)** | ❌ مقفل | لا يملك الوصول |
| **المحاسب (`accountant`)** | ❌ مقفل | لا يملك الوصول |
| **مسؤول الموارد البشرية (`hr`)** | ❌ مقفل | لا يملك الوصول |

### 2.3 حماية المسار (Route Guard)
- المسار: `/settings/audit-logs`
- الصلاحية المطلوبة: `StaffPermissionEnum.viewAuditLogs`
- الفحص: `PermissionEvaluator.can(StaffPermissionEnum.viewAuditLogs)`
- في حال عدم التوفر: إعادة توجيه فورية إلى `/forbidden?from=/settings/audit-logs`.

---

## 3. المراحل التنفيذية (Milestones)

### المرحلة 1 (M-1): الصلاحيات، توسيع `AuditLogger` وتسجيل "فتح ملف المريض"
- إضافة `viewAuditLogs` إلى `StaffPermissionEnum` وتحديث `PermissionEvaluator` ومصفوفة الصلاحيات.
- توسيع `AuditLogger` لدعم معايير الفلترة: `performedByUserId`, `eventType`, `branchId`, `startDate`, `endDate`, `searchQuery`, `limit`, `offset`.
- بذر سجلات أولية (Mock Seed Data) متنوعة لأحداث أمان وعمليات فروع وسجلات طبية.
- إضافة تسجيل حدث `view_patient_profile` في تدفق فتح ملف المريض (`PatientsCubit` / `PatientDetailsPage`).
- اختبارات M-1: اختبارات وحدة لـ `AuditLogger` وفلاتره، واختبار تسجيل فتح ملف المريض، واختبار الصلاحيات.

### المرحلة 2 (M-2): حماية المسارات وعنصر السايد بار
- إضافة `AppRouter.auditLogs = '/settings/audit-logs'` في `routes.dart` و`app_router.dart`.
- إضافة عنصر السايد بار في `app_list.dart` تحت مجموعة `nav_group_settings`.
- اختبارات M-2: اختبار حماية المسار (رفض غير المالك والمستخدمين العاديين، والسماح للمالك أو حامل الصلاحية).

### المرحلة 3 (M-3): طبقة العرض والـ Cubit
- إنشاء `AuditLogsState` و`AuditLogsCubit` لإدارة الفلاتر والبحث والتحميل وتصفية السجلات.
- إنشاء `AuditLogsRepo` و`AuditLogsRepoImpl` كـ wrapper نظيف لـ `AuditLogger` لضمان Clean Architecture.
- تسجيل `AuditLogsRepo` و`AuditLogsCubit` في `dependency_injection.dart`.
- اختبارات M-3: اختبارات وحدة لـ `AuditLogsCubit` (تطبيق الفلاتر، البحث، إعادة التحميل).

### المرحلة 4 (M-4): واجهة المستخدم (Table, FilterBar, Dialog, Badges)
- إنشاء `AuditLogsPage` متوافقة مع التصميم المتجاوب `AdaptiveLayout`.
- إنشاء `AuditLogsTable` باستخدام `CustomTable` مع تلوين وتصنيف شارات الأحداث `AuditEventTypeBadge`.
- إنشاء `AuditLogsFilterBar` للبحث بالاسم ومعرّف الحدث واختيار الفرع ونوع الحدث ومجال التاريخ.
- إنشاء `AuditLogDetailsDialog` لعرض التفاصيل الكاملة للسجل (المستخدم الفاعل، المستهدف، الفرع، التاريخ، التفاصيل المعقمة، وIP).
- مفاتيح الترجمة بالكامل في `ar-EG.json` و`en-US.json`.
- اختبارات M-4: اختبارات Widget لجدول السجلات والفلاتر ونافذة التفاصيل.

### المرحلة 5 (M-5): الاختبارات المتكاملة والإغلاق
- فحص كامل عبر `flutter analyze --no-pub`.
- تشغيل كامل اختبارات المشروع `flutter test` وضمان نجاح 100%.
- دمج فرع العمل في `v1.0.0` وتحديث `docs/PROGRESS.md`.

---

## 4. معايير القبول (Acceptance Criteria)
1. السجل للقراءة فقط (Append-only)، لا توجد أي أزرار أو دوال لتعديل أو حذف أي سجل نشاط.
2. تفاصيل السجلات معقمة بالكامل، ولا تحتوي على أي كلمات مرور أو توكنات.
3. فتح ملف أي مريض يولد تلقائياً سجلاً من نوع `view_patient_profile` بالاسم والمعرّف.
4. شاشة السجل محجوبة تماماً عن المستخدمين غير المالكين إلا بصلاحية صريحة.
5. الفلاتر تعمل فورياً مع السجلات (تصفية حسب الحدث، الفرع، المستخدم، والتاريخ).
6. نجاح 100% لجميع اختبارات المشروع وتحقيق 0 أخطاء في `flutter analyze`.

---

## 5. نتائج المراجعة الذاتية للخطة (Self-Review Checklist)
1. **هل في مصدرين للحقيقة لنفس المعلومة؟** لا، مصدر السجلات هو `AuditLogger` فقط.
2. **هل في فحص صلاحية ممكن يفتح لو معلومة ناقصة (fail-open)؟** لا، `PermissionEvaluator` يعمل fail-closed.
3. **هل في طريق لتصعيد الصلاحيات؟** لا، `viewAuditLogs` مقفولة افتراضياً عن كل الأدوار ومتاحة للمالك فقط.
4. **هل في اسم أو سعر منسوخ؟** لا، البيانات بالسجل هي snapshots تاريخية وقت وقوع الحدث وهو المطلوب في الـ audit.
5. **هل كل بيانات محتاجة تكون لكل فرع فعلاً لكل فرع؟** نعم، كل سجل يحتوي `branchId` ويخضع لفلترة الفروع.
6. **هل الحذف soft؟** السجل لا يحذف إطلاقاً (append-only).
7. **هل الخطة بتتعامل مع حالات التغيير أثناء الاستخدام؟** نعم، تحديث الجلسة يعيد تقييم الصلاحيات فوراً.
8. **هل كل قاعدة أمان ليها اختبار بالاسم؟** نعم، تم تخصيص اختبارات لصلاحية المالك، ومنع الوصول، وتعقيم السجلات، وفلاتر البحث.
9. **هل في نطاق زيادة؟** لا، ملتزم بنطاق F-03 المحدد بدقة.
10. **هل بتكسر شاشة موجودة؟** لا، توسيع `AuditLogger` اختياري وغير مكسر لأي كود قائم.
11. **هل في بيانات حساسة ممكن تتسرب؟** تم التحقق من تفعيل `_sanitize` لحجب أي بيانات اعتماد أو رموز سرية.
12. **هل عندي أي افتراض لم أتحقق منه؟** لا، تم فحص كل الملفات المعنية ومطابقتها.

# خريطة هيكل المشروع (Project Architecture Map)

تاريخ التحديث: 2026-11-25
الفرع: `improve/first-pass`

---

## 1. نظرة عامة على المعمارية (Architectural Overview)

تطبيق **عيادتي (Eyadty)** هو لوحة تحكم وإدارة عيادات ومراكز طبية متعددة الفروع مصممة بلغة Dart وإطار عمل Flutter.
- **التصميم وتعدد اللغات:** واجهة عربية أصيلة تدعم RTL افتراضياً عبر `easy_localization`.
- **معمارية الكود:** Clean Architecture مبوبة حسب الميزات (Feature-First) ومقسمة داخل كل ميزة إلى:
  - `data/`: النماذج (Models)، وتطبيقات المستودعات (Mock Repositories)، ومصادر البيانات.
  - `domain/`: الكيانات (Entities/Contracts)، وواجهات المستودعات (Repo Interfaces)، وحالات الاستخدام (Use Cases).
  - `presentation/`: مدراء الحالة (Cubits/Blocs)، والشاشات (Pages)، والعناصر البصرية (Widgets/Dialogs).
- **إدارة الحالة:** `flutter_bloc` / Cubits مع معالجة الأخطاء الوظيفية بـ `dartz` (Either<Failure, T>).
- **حقن التبعيات (DI):** `get_it` عبر `lib/core/dependency_injection/dependency_injection.dart`.
- **التوجيه (Routing):** `go_router` مع حراسة مسارات معتمدة على الصلاحيات (`PermissionEvaluator` و `SessionCubit`).
- **المرحلة الراهنة:** التطبيق يعمل بنمط البيانات الوهمية (Mock Mode) عمداً، حيث لا يوجد خادم خلفي (Backend) بعد، ويحتوي على 17 مستودعاً ومزوداً وهمياً مسجلة بالكامل في الـ DI.

---

## 2. جدول الميزات والمستودعات والمسارات (Features, Repos & Routes)

| الميزة (Feature) | واجهة المستودع (Domain Repo) | التطبيق الوهمي (Data Mock Repo) | المسار في الـ Router | الوصف والمسؤولية |
|---|---|---|---|---|
| **auth & app_layout** | `LoginRepo`, `LayoutRepo` | `LoginRepoImpl`, `LayoutRepoImpl` | `/login`, `/` | إدارة تسجيل الدخول والرموز المميزة، وتوليد جلسة المستخدم والنافذة العامة. |
| **bookings** | `BookingsRepo`, `ActiveVisitLookup` | `BookingsMockRepoImpl` | `/bookings`, `/bookings/:id` | إدارة حجز المواعيد، قائمة الانتظار، السياسات المالية للخصومات، وجدول الطبيب. |
| **visits** | `VisitsRepo` | `VisitsMockRepoImpl` | `/visits`, `/visits/:id` | الكشوفات السريرية، الملاحظات الطبية، تسجيل العلامات الحيوية، والروشتات الطبية. |
| **patients** | `PatientsRepo`, `MedicalCatalogRepo` | `PatientsMockRepoImpl`, `MedicalCatalogMockRepoImpl` | `/patients`, `/patients/:id` | السجل الطبي الشامل للمريض (EMR)، التاريخ المرضي والجراحي، والحساسيات. |
| **doctors** | `DoctorsRepo` | `DoctorsMockRepoImpl` | `/doctors`, `/doctors/:id` | بيانات الأطباء (DOC-01 إلى DOC-06)، جداول العمل، طلبات وإدارة الإجازات. |
| **drugs** | `DrugsRepo` | `DrugsMockRepoImpl` | `/drugs` | دليل الأدوية، قوالب الروشتات للأطباء، ومحرك فحص تعارض حساسيات المريض. |
| **medical_catalogs**| `MedicalCatalogsRepo` | `MedicalCatalogsMockRepoImpl` | `/medical-catalogs/*` | فهارس الأشعة، التحاليل الطبية، الأمراض المزمنة، الحساسيات، والعمليات الجراحية. |
| **inventory** | `InventoryRepo` | `InventoryMockRepoImpl` | `/inventory` | إدارة المخزون والمستلزمات الطبية والتحذيرات عند وصول حد الطلب. |
| **cashier** | `CashierRepo`, `CashierPolicy` | `CashierMockRepoImpl` | `/cashier` | الخزينة والوردية، تحصيل المبالغ والمدفوعات، استرداد المبالغ، ومصروفات الدرج. |
| **hr** | `HrRepo`, `DoctorSettlementVisitsLookup` | `HrMockRepoImpl`, `DoctorSettlementVisitsMockLookup` | `/hr` | رواتب الطاقم، محاسبة وتسوية مستحقات الأطباء، ومسيرات الرواتب. |
| **analytics** | `AnalyticsRepo` | `AnalyticsMockRepoImpl` | `/analytics` | المؤشرات والرسوم البيانية التشغيلية، الإيرادات، وتدفق المراجعين. |
| **branches** | `BranchesRepo` | `BranchesMockRepoImpl` | تابعة لـ `/settings` | إدارة الفروع وتعدد الفروع وعزل إعدادات العيادة لكل فرع. |
| **users_management**| `StaffUsersRepo` | `StaffUsersMockRepoImpl` | `/settings/users` | حسابات الطاقم، مصفوفة الصلاحيات (RBAC)، والسياسات الأمنية. |
| **audit_logs** | `AuditLogsRepo` | `AuditLogsMockRepoImpl` | `/settings/audit-logs` | سجل التدقيق والأنشطة الأمنية لحماية خصوصية البيانات السريرية والإدارية. |
| **settings** | `SettingsRepo`, `MedicalServicesRepo` | `SettingsMockRepoImpl`, `MedicalServicesMockRepoImpl` | `/settings` | إعدادات المنشأة، الخدمات الطبية وأسعارها، وإعدادات الطباعة. |
| **notifications** | - | `NotificationService` | `/notifications` | التنبيهات والإشعارات النظامية للمستخدمين. |
| **profile** | - | - | `/profile` | الملف الشخصي للمستخدم الحالي وتغيير كلمة المرور. |

---

## 3. قائمة الـ 17 Mock Repositories المسجلة في `get_it`

1. `BookingsMockRepoImpl` -> مسجل لـ `BookingsRepo`
2. `VisitsMockRepoImpl` -> مسجل لـ `VisitsRepo` و `ActiveVisitLookup`
3. `DrugsMockRepoImpl` -> مسجل لـ `DrugsRepo`
4. `MedicalCatalogMockRepoImpl` -> مسجل لـ `MedicalCatalogRepo` (في موديول المرضى)
5. `PatientsMockRepoImpl` -> مسجل لـ `PatientsRepo`
6. `SettingsMockRepoImpl` -> مسجل لـ `SettingsRepo`
7. `MedicalServicesMockRepoImpl` -> مسجل لـ `MedicalServicesRepo`
8. `DoctorsMockRepoImpl` -> مسجل لـ `DoctorsRepo`
9. `StaffUsersMockRepoImpl` -> مسجل لـ `StaffUsersRepo`
10. `BranchesMockRepoImpl` -> مسجل لـ `BranchesRepo`
11. `AuditLogsMockRepoImpl` -> مسجل لـ `AuditLogsRepo`
12. `CashierMockRepoImpl` -> مسجل لـ `CashierRepo`
13. `MedicalCatalogsMockRepoImpl` -> مسجل لـ `MedicalCatalogsRepo` (في موديول الفهارس الطبية)
14. `InventoryMockRepoImpl` -> مسجل لـ `InventoryRepo`
15. `HrMockRepoImpl` -> مسجل لـ `HrRepo`
16. `DoctorSettlementVisitsMockLookup` -> مسجل لـ `DoctorSettlementVisitsLookup`
17. `AnalyticsMockRepoImpl` -> مسجل لـ `AnalyticsRepo`

---

## 4. إعدادات الشبكة وملاحظات الوضع التجريبي (Networking & Mock Mode)

- **الرابط الأساسي الحالي:** `EndPoints.appBaseUrl = 'http://192.168.1.60:1601/'` في `lib/core/api/end_points.dart`.
- **الهدف المستقبلي:** استخراج رابط الـ API وإعدادات الوضع التجريبي في بيئة تكوين مركزية (`AppConfig` أو `EnvironmentConfig`) تمنع تسريب المستودعات الوهمية للإنتاج وتوضح للمستخدم عند عمل التطبيق في النمط التجريبي.

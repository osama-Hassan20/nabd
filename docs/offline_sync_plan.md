# خطة التشغيل دون اتصال وجاهزية المزامنة (Offline-First & Sync Readiness Plan)

**تاريخ التوثيق:** 2026-11-25  
**الفرع:** `feature/offline-sync-engine`  
**الحالة:** الخطوة 0 مكتملة — الانتقال المباشر للخطوة 1

---

## 1. مصادر البيانات الحالية في التطبيق (Where Data Comes From Today)

يعمل تطبيق **عيادتي (Eyadty)** حالياً في طور البيانات التجريبية (Mock Stage) بدون خادم حقيقي (No Backend Yet):
1. **المستودعات الوهمية (Mock Repositories):**
   - 17 مستودعاً وهمياً مسجلة في `get_it` عبر `lib/core/dependency_injection/dependency_injection.dart`:
     - `PatientsMockRepoImpl`, `BookingsMockRepoImpl`, `VisitsMockRepoImpl`, `DoctorsMockRepoImpl`
     - `CashierMockRepoImpl`, `DrugsMockRepoImpl`, `HrMockRepoImpl`, `InventoryMockRepoImpl`
     - `MedicalCatalogsMockRepoImpl`, `MedicalServicesMockRepoImpl`, `SettingsMockRepoImpl`
     - `StaffUsersMockRepoImpl`, `BranchesMockRepoImpl`, `AuditLogsMockRepoImpl`, `AnalyticsMockRepoImpl`
   - تعتمد على مصفوفات في الذاكرة (`List<T>`) وبذور بيانات تجريبية (Mock Seeds) تحاكي واقع العيادات المصرية.
2. **عميل الشبكة (Dio Client & Networking):**
   - `Dio` مهيأ عبر `lib/core/dependency_injection/dependency_injection.dart` مع `DioConsumer` وموجه لـ `EndPoints.baseUrl`.
   - `AppInterceptors`: يتولى حقن `Authorization: Bearer <token>`، تجديد التوكن، وحراسة التوكن التجريبي في الإنتاج.
3. **أعلام وضوابط الوضع التجريبي (Mock Flags & Safety Gates):**
   - `AppConfig.isDemoMode`: معرف عبر `--dart-define=DEMO_MODE=true` مع حراسة `AppConfig.assertDemoModeAllowed()` التي تمنع تشغيل المستودعات الوهمية في الإنتاج.
   - `AppConfig.generateDemoToken()`: يوسم توكنات الجلسة بـ `eyadty_demo_session_`.
4. **حزم التخزين الحالية (Existing Storage):**
   - `shared_preferences: ^2.5.3` مستخدمة عبر `AppSharedPreferences` لحفظ توكن الجلسة، معرف المستخدم، تفضيلات السمة (`themeMode`)، ورمز القفل المحلي (`localPasscode`).

---

## 2. المنصات المستهدفة وقيودها (Target Platforms & Constraints)

1. **الهواتف الذكية (Android / iOS):**
   - بيئة تشغيل مثالية للتخزين المشفر المحلي (`flutter_secure_storage` / SQLite / الملفات المعزولة).
   - دعم كامل للعمل في الخلفية والمزامنة عند عودة الاتصال.
2. **سطح المكتب (Windows / macOS / Linux):**
   - تشغيل مباشر، مساحة تخزين محلية واسعة، اتصال أحادي بملف قاعدة البيانات (Single Connection Owner).
3. **الويب (Flutter Web):**
   - **فصل الكاش عن ثبات البيانات:** كاش واجهة التطبيق عبر Service Worker لا يعني ثبات قاعدة البيانات؛ التخزين (IndexedDB/LocalStorage) معرض للمسح (Eviction) عند نقص مساحة المتصفح، ولا يعمل في التصفح الخفي (Incognito Mode).
   - **التبويبات المتعددة (Multi-tab concurrency):** ضرورة عزل عمليات المزامنة وضمان مشغل واحد فقط (Single-Flight Sync Engine) عبر التنسيق بين التبويبات لمنع تعارض الكتابة.
   - **البيانات الحساسة على الويب:** المتصفحات لا توفر بيئة تخزين مشفرة معتمدة على عتاد الجهاز (Hardware KeyStore/Secure Enclave)؛ لذلك يُحظر تخزين سجلات المرضى الحقيقية بصيغة نصية غير مشفرة على الويب، ويقتصر على البيانات التجريبية لحين ربطه بالخادم الحقيقي مع توثيق ذلك صراحة.

---

## 3. قائمة الكيانات الرئيسية (Core Entity List)

| الكيان (Entity) | المعرف المحلي (Local ID) | معيار التعديل والحذف (Mutation Policy) | حالة الحسابات المتعددة والاعتمادية |
|---|---|---|---|
| **Patient** (المرضى) | `UUID` (localId) | تحديث بالنسخ (Revision-tracked)؛ حذف عبر Tombstone | أساسي (Root entity)؛ تعتمد عليه الحجوزات والزيارات. |
| **Booking** (الحجوزات والانتظار) | `UUID` (localId) | تحديث بالحالة والوقت؛ حذف Soft-delete متزامن | يعتمد على المريض والطبيب؛ يوسم بـ "مؤقت/غير مؤكد" أوفلاين. |
| **Visit** (الزيارة الطبية السريرية) | `UUID` (localId) | سجل سريري مختوم؛ إضافة ملاحق (Append-only Addenda)؛ يمنع الكتابة فوق السجل | يعتمد على الحجز والمريض والطبيب. |
| **Prescription** (الروشتة) | `UUID` (localId) | ملحق غير قابل للحذف بعد الطباعة/الختم السريري | يعتمد على الزيارة السريرية. |
| **CashierPayment** (المدفوعات) | `UUID` (localId) | سجل مالي تصاعدي (Append-only)؛ التصحيح عبر قيود عكسية (Reversals) | يعتمد على الحجز ووردية الخزينة؛ يوسم بـ "محلي غير مؤكد". |
| **CashierShift** (وردية الخزينة) | `UUID` (localId) | فتح وإغلاق وردية؛ إجماليات محسوبة محلياً وتوسم بـ "مؤقتة" | معزول بالفرع والمستخدم. |
| **InventoryItem** (المخزون) | `UUID` (localId) | حركات الصرف والإضافة تصاعدية (Ledger movements) | يوسم الرصيد المحسوب محلياً بـ "رصيد تقديري غير مؤكد". |
| **DoctorSchedule & Leaves** | `UUID` (localId) | تحديث الجدول وتاريخ الإجازات مع تتبع المراجعة | معزول بالطبيب والفرع. |

---

## 4. معمارية التخزين المختار (Transactional Local Store & Outbox)

- **المتطلب الأساسي:** معاملة ذرية حقيقية (Atomic Transaction)؛ لا يُكتب أي تغيير في جدول الكيانات دون كتابة سجل الـ Outbox المقابل له في نفس المعاملة. وفي حال فشل أحدهما، يحدث تراجع كامل (Rollback) ولا يُترك أي أثر.
- **الاختيار الهندسي:**
  - واجهة معمارية موحدة `TransactionalLocalStore` تدعم المعاملات (`runInTransaction<T>()`) مع ضمانات ACID.
  - تطبيق عملي محكم يدعم المنصات كافة، مع ملفات يومية (Atomic Journaled Persistence) ومسار في الذاكرة للاختبارات الحتمية وFlutter Web.
  - جدول الكيانات الموحد: `(local_id, entity_type, server_id, account_id, branch_id, payload_json, local_revision, server_cursor, sync_status, is_provisional, updated_at, deleted_at)`.
  - جدول صندوق الإرسال (`Outbox`): `(operation_id, entity_type, local_id, operation, payload_json, base_revision, created_at, attempt_count, last_error, status, dependency_refs_json)`.

---

## 5. خطة التنفيذ خطوة بخطوة (Step-by-Step Roadmap)

1. **الخطوة 1: خدمة نمط البيانات (DataModeService) وعناصر الواجهة العلوية:**
   - بث تدفقي لحالة الاتصال: `online`، `offline`، `forcedLocal`.
   - فحص حقيقي لعنوان الخادم وليس فقط حالة شبكة الجهاز.
   - زر التبديل اليدوي في الشريط العلوي مع شارة الحالة والتنبيهات.
   - حماية الطلبات الجارية أثناء التبديل لحفظ الـ Ack دائماً.
2. **الخطوتان 2 و 3: المخزن المحلي الذري وصندوق الإرسال (Durable Store & Outbox):**
   - بناء محرك المعاملات الذرية وضمان التراجع التام عند الخطأ.
   - دعم التوسيم المؤقت (`isProvisional`)، وعزل البيانات حسب الفرع والحساب.
   - حماية الخروج (Logout) مع وجود عمليات معلقة.
3. **الخطوة 4: محرك المزامنة والخادم الوهمي (Sync Engine & FakeRemoteSyncApi):**
   - قفل المزامنة أحادي التشغيل (Single-flight lock).
   - إرسال صندوق الصادر ومعالجة ردود الخادم التكرارية (Idempotent replay).
   - سحب التغييرات عبر Cursor وحفظ التعارضات للمراجعة البشرية.
   - توثيق مقترح عقد الخادم المستقبلي في `docs/sync_contract.md`.
4. **الخطوة 5: واجهات المستخدم (UX):**
   - شارات "محلي - غير مؤكد" على الحجوزات والمدفوعات والمخزون المنشأة دون اتصال.
   - شاشة/نافذة تفاصيل المزامنة ومراجعة التعارضات وزر "مزامنة الآن".
5. **الخطوة 6: الاختبارات الشاملة (Tests Suite):**
   - تغطية حالات الاتصال، التراجع الذري، فقدان الـ Ack، التكرار، والتعارضات.

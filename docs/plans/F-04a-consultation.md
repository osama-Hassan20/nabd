# خطة التنفيذ — F-04a: محرك الكشف الطبي (Doctor Consultation Engine)
> **النطاق:** عرض طابور الطبيب (مبني على الحجوزات) + شاشة عمل الكشف + ربط الحجوزات — **بدون روشتة أو أدوية أو طباعة أو Addendum (مؤجلة لـ F-04b)**
> **المرجع المباشر:** `docs/plans/PKG-B-visit-prescription-drugs.md` + `docs/plans/PKG-AB-integration-contract.md`
> **تاريخ آخر تحديث:** 2026-11-10 (مراجعة شاملة — الإصدار النهائي)

---

## مراجعة ذاتية للخطة (§7 من AGENT_OPERATING_GUIDE)

| السؤال | الإجابة والتبرير |
|:---|:---|
| ١. مصدرين للحقيقة لنفس المعلومة؟ | لا — بيانات المريض والدكتور تُقرأ من `BookingModel` المُمرر، لا تُنسخ |
| ٢. fail-open في الصلاحيات؟ | لا — `PermissionEvaluator.can` fail-closed دائماً، أي حقل null = رفض |
| ٣. مسار لتصعيد الصلاحيات؟ | لا — `editMedicalDiagnosis` مقيد بـ `linkedDoctorId == visit.doctorId` |
| ٤. اسم أو سعر منسوخ قديم؟ | لا — اسم المريض والدكتور في `VisitModel` هم Snapshot وقت بدء الكشف |
| ٥. بيانات الفرع صح؟ | نعم — كل Visit مرتبطة بـ `branchId` من الحجز |
| ٦. الحذف Soft؟ | الكشف append-only — لا حذف نهائياً في F-04a |
| ٧. تغييرات أثناء الاستخدام؟ | Auto-Save كل 30 ثانية مع dirty flag. تعديل الدور أثناء الكشف = اختبار T11 في `visit_permission_test.dart` |
| ٨. كل قاعدة أمان لها اختبار؟ | نعم — كل صلاحية لها اختبار مسمى في §8 |
| ٩. نطاق زيادة؟ | لا — الروشتة والـ Addendum وكتالوج التشخيصات مُرجأة صراحة لـ F-04b |
| ١٠. يكسر شاشة موجودة؟ | نعم (مقصود ومُدار) — `VisitsPage` Placeholder يُستبدل، موثق |
| ١١. بيانات حساسة تتسرب؟ | لا — Cubit يجلب `allergies` فقط (وليس PatientModel كاملاً) للممرض |
| ١٢. افتراضات على ملفات ما قُرأت؟ | لا — قرأت `booking_model.dart`, `patient_model.dart` (الحقل الفعلي: `allergies` وليس `drugAllergies`), `staff_permission_enum.dart`, `role_definition_model.dart`, `audit_logger.dart`, `cairo_time_helper.dart`, `app_router.dart`, `change_booking_status_params.dart`, وكامل seed البيانات |

---

## 1. الوضع الحالي وما سيُعاد استخدامه

### 1.1 الموجود فعلاً (يُستخدم بدون تعديل)

| الملف / الكيان | ما سيُستخدم منه |
|:---|:---|
| `BookingModel` | يُمرر كاملاً لـ `VisitsCubit`؛ `branchId`, `doctorId`, `patientId`, `patientName`, `patientPhone`, `specialty` |
| `BookingStatusEnum` | الحالات الموجودة كافية: `inConsultation`, `completed`, `waiting` |
| `ChangeBookingStatusUseCase` + `ChangeBookingStatusParams` | لتحديث حالة الحجز في Saga (rollback + commit) |
| `BookingsRepo` (interface) | يُحقن في `StartConsultationUseCase` و`FinalizeVisitUseCase` |
| `PermissionEvaluator.can()` | لفحص الصلاحيات (fail-closed) |
| `AuditLogger.log()` | لتسجيل أحداث الكشف الحساسة |
| `CairoTimeHelper.now()` | بدلاً من `DateTime.now()` في كل الأوقات |
| `StaffPermissionEnum` | ستضاف إليه صلاحيات جديدة (§6) |
| `PatientModel.allergies` | الحقل الفعلي `List<String>? allergies` — لعرض لافتة الحساسية |
| `PatientModel.chronicDiseases` | للدكتور فقط (يتطلب `viewConsultationNotes`) |
| `PatientsRepo.getPatientById()` | الـ Cubit يستدعيه ويستخرج `allergies` فقط أو `chronicDiseases` حسب الصلاحية |
| `AdaptiveLayout`, `CustomTextFormField`, `CustomPushButton`, `CustomStackSelector`, `CustomToast`, `CustomShimmerContainer`, `CustomEmptyWidget` | مكونات الـ UI المشتركة |
| `SafeCubit`, `SearchMixin`, `RequestStatusEnum` | قاعدة الـ Cubit والحالة |
| `InMemoryAuditLogger` | تُمرر عبر DI للـ VisitsMockRepoImpl |
| `AppFormatterHelper.formatCurrency()` | لتنسيق أي مبالغ في الـ UI |

### 1.2 ما سيتغير في ملفات موجودة

| الملف | التغيير |
|:---|:---|
| `lib/features/visits/presentation/pages/visits_page.dart` | استبدال Placeholder بـ `VisitsPage` كاملة |
| `lib/core/enums/staff_permission_enum.dart` | إضافة `viewVisitsQueue`, `startConsultation`, `recordVitals`, `viewConsultationNotes` |
| `lib/core/dependency_injection/dependency_injection.dart` | تسجيل `VisitsRepo`, UseCases, `VisitsCubit`, وتسجيل `VisitsMockRepoImpl` كـ `ActiveVisitLookup` |
| `lib/core/routing/app_router.dart` | إضافة route لـ `/visits/:id` بـ guard `viewConsultationNotes` |
| `lib/features/bookings/domain/contracts/active_visit_lookup.dart` | جديد — عقد فك الارتباط: دالة فحص حالة Visit الحجز لمنع الاعتماد المتبادل |
| `lib/features/bookings/domain/use_cases/change_booking_status_use_case.dart` | إضافة guard عبر `ActiveVisitLookup`: رفض تعديل الحجز إن له Visit بحالة in_progress (§3.4) |
| `lib/features/bookings/domain/use_cases/reassign_technician_use_case.dart` | إضافة guard عبر `ActiveVisitLookup`: رفض التحويل إن للحجز Visit بحالة in_progress (مسموح مع triage) (§3.4) |
| `lib/features/bookings/domain/use_cases/delete_booking_use_case.dart` | إضافة guard عبر `ActiveVisitLookup`: رفض الحذف إن للحجز Visit بحالة triage أو in_progress (§3.4) |
| `assets/translations/ar-EG.json` | مفاتيح جديدة بـ prefix `visits_` (§7) |
| `assets/translations/en-US.json` | مفاتيح جديدة بـ prefix `visits_` (§7) |

> **ملاحظة:** زر "بدء الكشف" في `BookingsPage` و`BookingDetailsPage` يُضاف في **M-5** (بعد وجود route شاشة الكشف).

### 1.3 ما سيُنشأ من الصفر
جميع ملفات فيتشر `visits` خارج الـ Placeholder (تفاصيل في §2).

---

## 2. قائمة الملفات الكاملة

```
lib/features/visits/
├── data/
│   ├── models/
│   │   ├── visit_model.dart                      # جديد — 100% nullable
│   │   ├── vitals_model.dart                     # جديد — العلامات الحيوية
│   │   ├── consultation_queue_item_model.dart    # جديد — الربط booking + visit?
│   │   └── enums/
│   │       └── visit_status_enum.dart            # جديد — triage | in_progress | finalized
│   └── repo/
│       └── visits_mock_repo_impl.dart            # جديد — Mock + seed data
│
├── domain/
│   ├── repo/
│   │   └── visits_repo.dart                      # جديد — interface
│   └── use_cases/
│       ├── get_doctor_queue_use_case.dart         # جديد — طابور اليوم (doctorId اختياري)
│       ├── get_visit_by_booking_id_use_case.dart  # جديد — الكشف بـ bookingId
│       ├── start_consultation_use_case.dart       # جديد — Saga: حجز→Visit
│       ├── save_visit_draft_use_case.dart         # جديد — حفظ مسودة (Auto-Save)
│       ├── record_vitals_use_case.dart            # جديد — تسجيل العلامات (Saga)
│       └── finalize_visit_use_case.dart           # جديد — إنهاء الكشف (Saga)
│
└── presentation/
    ├── manager/
    │   ├── visits_cubit.dart                      # جديد — الـ Cubit الوحيد
    │   └── visits_state.dart                      # جديد — الحالة الكاملة
    ├── pages/
    │   ├── visits_page.dart                       # معدّل — استبدال Placeholder
    │   └── doctor_consultation_screen.dart        # جديد — شاشة عمل الكشف
    └── widgets/
        ├── consultation_queue_table.dart           # جديد — جدول طابور
        ├── consultation_queue_card.dart            # جديد — كارت موبايل
        ├── adaptive_visits_view.dart               # جديد — تبديل Table/Card
        ├── visits_filter_bar.dart                  # جديد — فلتر بالتاريخ والحالة
        ├── visits_shimmer.dart                     # جديد — Skeleton loading
        ├── patient_allergy_banner.dart             # جديد — شريط تحذير الحساسية
        ├── vitals_input_panel.dart                 # جديد — نموذج العلامات الحيوية
        ├── consultation_notes_panel.dart           # جديد — الشكوى والتشخيص والخطة
        ├── visit_status_badge.dart                 # جديد — Badge حالة الكشف
        ├── finalize_visit_dialog.dart              # جديد — تأكيد إنهاء الكشف
        └── record_vitals_dialog.dart               # جديد — Dialog تسجيل علامات (للممرض)

# ملفات معدلة أو جديدة خارج features/visits:
lib/core/enums/staff_permission_enum.dart
lib/core/dependency_injection/dependency_injection.dart
lib/core/routing/app_router.dart
lib/features/bookings/domain/contracts/active_visit_lookup.dart       # جديد — فك ارتباط Domain
lib/features/bookings/domain/use_cases/change_booking_status_use_case.dart
lib/features/bookings/domain/use_cases/reassign_technician_use_case.dart
lib/features/bookings/domain/use_cases/delete_booking_use_case.dart
lib/features/bookings/presentation/pages/bookings_page.dart        # M-5: زر بدء الكشف
lib/features/bookings/presentation/pages/booking_details_page.dart  # M-5: زر بدء الكشف
assets/translations/ar-EG.json
assets/translations/en-US.json
```

---

## 3. تصميم الـ Models والـ State

### 3.1 `VisitStatusEnum`
```dart
enum VisitStatusEnum {
  triage('triage'),          // علامات حيوية مسجّلة بمعرفة الممرض، الدكتور لم يبدأ
  inProgress('in_progress'), // الدكتور بدأ الكشف فعلاً، startedAt محدد
  finalized('finalized');    // انتهى الكشف، السجل مقفول للقراءة فقط

  final String value;
  const VisitStatusEnum(this.value);
  static VisitStatusEnum? fromValue(String? val) { ... }
}
```
> حالة `interrupted` محذوفة من F-04a (مؤجلة).

---

### 3.2 `VitalsModel` — العلامات الحيوية (100% nullable)
```dart
class VitalsModel {
  final num? systolicBp;         // ضغط الدم الانقباضي (mmHg) — تحذير إن <60 أو >200
  final num? diastolicBp;        // ضغط الدم الانبساطي (mmHg) — تحذير إن <40 أو >130
  final num? heartRate;          // النبض (bpm) — تحذير إن <30 أو >200
  final num? temperature;        // الحرارة (°C) — تحذير إن <34 أو >42
  final num? oxygenSaturation;   // SpO2 (%) — تحذير إن >100 أو <70
  final num? weightKg;           // الوزن (kg) — تحذير إن <1 أو >300
  final num? heightCm;           // الطول (cm) — تحذير إن <30 أو >250
  final DateTime? recordedAt;    // CairoTimeHelper.now()
  final String? recordedByUserId;

  num? get bmi { ... }           // computed getter — لا يُخزَّن

  // Validation helpers (تُرجع مفتاح ترجمة التحذير أو null):
  String? get systolicBpWarning => ...  // 'visits_vitals_warn_bp_high' etc
  String? get oxygenSaturationWarning => ...
  // ... إلخ
}
```
> الـ Validation = **تحذير وليس منعاً** — يُعرض كـ hint باللون الأصفر في `VitalsInputPanel`.

---

### 3.3 `VisitModel` — 100% nullable
```dart
class VisitModel {
  final String? id;
  final String? bookingId;
  final String? patientId;
  final String? branchId;

  // Snapshots (وقت بدء الكشف)
  final String? patientName;
  final String? patientPhone;
  final String? doctorId;
  final String? doctorName;
  final String? specialty;

  final VisitStatusEnum? status; // triage | in_progress | finalized

  final VitalsModel? vitals;

  // المحتوى السريري — محجوب عن التمريض والاستقبال
  final String? chiefComplaint;
  final String? medicalHistory;
  final String? physicalExam;
  final String? diagnosis;       // نص حر في F-04a
  final String? treatmentPlan;
  final String? followUpNotes;
  final int? followUpDays;

  final DateTime? triageAt;      // وقت أول علامات حيوية
  final DateTime? startedAt;     // وقت بدء كشف الدكتور (triage→in_progress)
  final DateTime? finalizedAt;   // وقت الإنهاء
  final DateTime? lastSavedAt;   // آخر Auto-Save

  const VisitModel({ ... });
  factory VisitModel.fromJson(Map<String, dynamic>? json) { ... }
  Map<String, dynamic> toJson() { ... }
  VisitModel copyWith({ ... }) { ... }
}
```
> **ملاحظة:** `VisitAddendumModel` مؤجلة لـ F-04b. السجل بعد `finalized` = قراءة فقط في F-04a.

---

### 3.4 قواعد قفل الحجز أثناء الكشف وفك الارتباط (ActiveVisitLookup)

#### 3.4.1 عقد فك الارتباط (`ActiveVisitLookup`)
لمنع الاعتماد المتبادل بين domain الحجوزات وdomain الكشوفات، يتم إنشاء واجهة صغيرة في domain الحجوزات:
```dart
// lib/features/bookings/domain/contracts/active_visit_lookup.dart
abstract class ActiveVisitLookup {
  Future<VisitStatusEnum?> getVisitStatusByBookingId(String bookingId);
}
```
`VisitsMockRepoImpl` ينفذ كلاً من `VisitsRepo` و `ActiveVisitLookup`، ويُسجَّل في DI تحت الواجهتين معاً. الـ Use Cases في الحجوزات تعتمد فقط على `ActiveVisitLookup` لفحص حالة الكشف.

#### 3.4.2 قواعد القفل الدقيقة:
> **المكان:** داخل `ChangeBookingStatusUseCase`, `ReassignTechnicianUseCase`, `DeleteBookingUseCase`.
> يستدعي الـ Use Case دالة `activeVisitLookup.getVisitStatusByBookingId(bookingId)` قبل إجراء أي تعديل.

```
1. إذا كانت حالة الكشف in_progress (الكشف جارٍ فعلياً مع الطبيب):
   - ChangeBookingStatusUseCase:
       • يمنع: cancelled | noShow | postponed | waiting
       • يرجع: Left(ServerFailure(errMessage: 'booking_locked_active_visit'))
       • ملاحظة: الـ Saga يستدعي BookingsRepo.changeBookingStatus مباشرة متجاوزاً هذا القيد عمداً
   - ReassignTechnicianUseCase:
       • يمنع: أي تحويل لطبيب آخر أثناء الكشف الجاري
       • يرجع: Left(ServerFailure(errMessage: 'booking_locked_active_visit'))
   - DeleteBookingUseCase:
       • يمنع: الحذف نهائياً
       • يرجع: Left(ServerFailure(errMessage: 'booking_locked_active_visit'))

2. إذا كانت حالة الكشف triage (تم تسجيل علامات حيوية فقط، الطبيب لم يبدأ بعد):
   - ChangeBookingStatusUseCase:
       • يسمح: cancelled | noShow | postponed | waiting
       • السلوك: يبقى الـ Visit كأرشيف للعلامات الحيوية ويُستبعد الحجز من طابور الكشف النشط
   - ReassignTechnicianUseCase:
       • يسمح: تحويل الحجز لطبيب آخر
       • السلوك: عند بدء الكشف لاحقاً بواسطة الطبيب الجديد عبر upsertConsultationStart،
         يتم تحديث حقول الـ Snapshot (doctorId, doctorName, specialty) بالقيم الجديدة للحجز المحوّل
   - DeleteBookingUseCase:
       • يمنع: الحذف نهائياً (لحماية سجل العلامات الحيوية من أن يصبح يتيماً Orphan)
       • يرجع: Left(ServerFailure(errMessage: 'booking_locked_active_visit'))

3. إذا كانت حالة الكشف finalized أو لا يوجد كشف (null):
   - تسمح جميع الـ Use Cases بالعمل الاعتيادي دون قفل كشف نشط.
```

---

### 3.5 `ConsultationQueueItemModel`
```dart
class ConsultationQueueItemModel {
  final BookingModel? booking;
  final VisitModel? visit;      // null = لم يبدأ بعد

  bool get hasActiveVisit =>
    visit?.status == VisitStatusEnum.inProgress ||
    visit?.status == VisitStatusEnum.triage;
  bool get isFinalized => visit?.status == VisitStatusEnum.finalized;
  bool get isTriageOnly => visit?.status == VisitStatusEnum.triage;
  String? get patientName => booking?.patientName;
  int? get queueNumber => booking?.queueNumber;
}
```

---

### 3.6 `VisitFormState` و `VisitsState`
```dart
class VisitFormState extends Equatable {
  // vitals
  final num? systolicBp, diastolicBp, heartRate, temperature,
             oxygenSaturation, weightKg, heightCm;

  // clinical (للدكتور فقط)
  final String chiefComplaint, medicalHistory, physicalExam,
               diagnosis, treatmentPlan, followUpNotes;
  final int? followUpDays;

  final bool isDirty;  // هل فيه تغييرات لم تُحفظ؟

  // التحويل — يتم في الـ Cubit فقط، Domain لا يعرف FormState إطلاقاً
  VisitModel toVisitModel(VisitModel existing) { ... }
}

class VisitsState extends Equatable {
  final RequestStatusEnum listStatus;
  final List<ConsultationQueueItemModel> queue;
  final String? listError;

  final RequestStatusEnum consultationStatus;
  final VisitModel? activeVisit;
  final String? consultationError;

  // بيانات الحساسية (مجلوبة منفصلة)
  final List<String> patientAllergies;        // لمن يملك viewVisitsQueue
  final List<String> patientChronicDiseases;  // لمن يملك viewConsultationNotes فقط

  final RequestStatusEnum actionStatus;
  final String? actionError;

  // فلاتر
  final DateTime? filterDate;
  final String? filterDoctorId;   // null = كل أطباء الفرع (للإداري/الممرض)
  final VisitStatusEnum? filterStatus;

  final VisitFormState? formState;
  final bool autoSaveEnabled;     // يتحكم فيه lifecycle الشاشة
}
```

---

### 3.7 `VisitsRepo` — الواجهة

```dart
abstract class VisitsRepo {
  // doctorId اختياري: null = كل أطباء الفرع
  Future<Either<Failures, List<ConsultationQueueItemModel>>> getDoctorQueue({
    String? doctorId,
    required String branchId,
    required DateTime date,
  });

  Future<Either<Failures, VisitModel?>> getVisitByBookingId({
    required String bookingId,
  });

  // ينشئ Visit جديد بحالة in_progress
  // إن وُجد Visit بحالة in_progress → Idempotent: يُعيده بدون تعديل
  // إن وُجد Visit بحالة triage → يحوّله لـ in_progress ويضبط startedAt ويحدّث doctorId و doctorName و specialty من الحجز الحالي
  // إن وُجد Visit بحالة finalized → Left(Failure)
  Future<Either<Failures, VisitModel>> upsertConsultationStart({
    required String bookingId,
    required String doctorId,
    required String branchId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String doctorName,
    required String? specialty,
  });

  // يستقبل VisitModel (الـ Cubit يحوّل FormState → VisitModel قبل الاستدعاء)
  Future<Either<Failures, VisitModel>> saveVisitDraft({
    required VisitModel draft,
  });

  // ينشئ Visit بحالة triage إن لم يكن موجوداً، أو يُحدّث vitals فقط إن كان triage
  // يرفض إن الحجز ليس بحالة waiting، أو Visit بحالة in_progress أو finalized
  Future<Either<Failures, VisitModel>> recordVitals({
    required String bookingId,
    required VitalsModel vitals,
    required String recordedByUserId,
    required String branchId,
    // بيانات Snapshot للـ Visit الجديد إن لم يكن موجوداً:
    required String patientId,
    required String patientName,
    required String? doctorId,
    required String? doctorName,
    required String? specialty,
  });

  // يستقبل VisitModel (الـ Cubit يحوّل FormState → VisitModel قبل الاستدعاء)
  Future<Either<Failures, VisitModel>> finalizeVisit({
    required VisitModel finalContent,
  });
}
```

---

### 3.7 توفير VisitsCubit (Lifecycle & Scoping)
1. **تسجيل الـ Cubit في DI:**
   - يُسجَّل `VisitsCubit` في `dependency_injection.dart` كـ `registerLazySingleton<VisitsCubit>`.
   - **السبب:** اشتراك ثلاث شاشات ونقاط تفاعل في نفس الحالة:
     1. شاشة طابور الكشف (`/visits`).
     2. شاشة الكشف الطبي النشط (`/visits/:id`).
     3. زر "بدء الكشف" وأزرار الإجراءات داخل شاشة الحجوزات (`BookingsPage` و `BookingDetailsPage`).
2. **عمر الـ Auto-Save Timer:**
   - الـ Timer (كل 30 ثانية) **لا يعمل طوال الوقت**؛ يبدأ فقط عند فتح كشف نشط (`loadActiveVisit`) عبر `startAutoSave()`.
   - يتوقف الـ Timer فوراً عبر `stopAutoSave()` عند:
     - الخروج من شاشة الكشف (`flushDraftOnExit()`).
     - إنهاء الكشف (`finalizeVisit()`).
     - إفراغ الكشف النشط (`clearActiveVisit()`).
     - إغلاق الـ Cubit (`close()`).
3. **حفظ المسودة الآمن عند الخروج (`flushDraftOnExit`):**
   - ينفذ `await saveVisitDraftUseCase(draft)` في المستودع.
   - محمي بفحص `if (!isClosed)` لمنع أي `emit` بعد الإغلاق، مما يضمن حفظ التعديلات في الذاكرة دون رمي أي `StateError`.
4. **تحديث صلاحيات الـ UI ديناميكياً:**
   - يشترك `VisitsCubit` في `SessionCubit.stream` ويعيد تقييم `canViewNotes` و `canEditDiagnosis` فور تغيير المستخدم أو تبديل الدور (`refreshPermissions()`)، مما ينعكس لحظياً على عناصر واجهة المستخدم.

---

## 4. سيناريوهات الـ Saga (ترتيب العمليات والتعويض)

> **تجاوز مقصود لقفل §3.4:** كلا من `StartConsultationUseCase` و `FinalizeVisitUseCase` يستدعيان `BookingsRepo.changeBookingStatus` مباشرة (عبر Repo Interface) لتغيير حالة الحجز دون المرور بـ `ChangeBookingStatusUseCase`، وهو تجاوز مقصود ومصمم لحركات الـ Saga المشروعة.

### 4.1 Saga — بدء الكشف (`StartConsultationUseCase`)

```
الخطوات:
  0. قراءة حالة الحجز الحالية وحفظها في متغير: previousStatus = booking.status
  1. BookingsRepo.changeBookingStatus(bookingId → inConsultation)
     ↓ فشل → Left(Failure) — لا تعويض لازم
  2. VisitsRepo.upsertConsultationStart(...)
     ↓ نجاح → Right(visit)
     ↓ فشل →
        ROLLBACK: BookingsRepo.changeBookingStatus(bookingId → previousStatus)
        (يُعاد الحجز لحالته السابقة الدقيقة: إن كان waiting يعود waiting، وإن كان inConsultation يعود inConsultation)
        يرجع Left(Failure)

ملاحظة سلوك upsertConsultationStart:
  - Visit غير موجود → ينشئ جديد بحالة in_progress مع بيانات الـ Snapshot
  - Visit بحالة triage → يحوّله لـ in_progress + يضبط startedAt = CairoTimeHelper.now()
    + يحدّث doctorId و doctorName و specialty في الـ Snapshot من الحجز الحالي (لدعم الحجز الذي أُعيد تعيينه أثناء triage)
  - Visit بحالة in_progress → Idempotent: يُعيده كما هو (ضغطتان = Visit واحد)
  - Visit بحالة finalized → Left(Failure) — لا تعارض
```

### 4.2 Saga — إنهاء الكشف (`FinalizeVisitUseCase`)

```
الخطوات:
  1. BookingsRepo.changeBookingStatus(bookingId → completed)
     ↓ فشل → Left(Failure) — لا تعويض لازم
  2. VisitsRepo.finalizeVisit(visitModel مع status: finalized)
     ↓ نجاح → Right(visit)
     ↓ فشل →
        ROLLBACK: BookingsRepo.changeBookingStatus(bookingId → inConsultation)
        يرجع Left(Failure)

ملاحظة: finalizeVisit لا تُرجع Visit من finalized إلى in_progress أبداً
  — التعويض يتم فقط عبر BookingsRepo (لا تعديل على Visit المقفول، وحذف revertVisitStatus يضمن الحماية المطلقة)
```

> **لماذا الحجز أولاً؟** الـ `BookingsRepo.changeBookingStatus` هي العملية الأكثر استقراراً (بدون قيود الـ Visit). لو فشل إنشاء الـ Visit، الـ rollback عبر `BookingsRepo` بسيط ومضمون. لو فشل إقفال الـ Visit (نادر جداً في Mock)، الـ rollback عبر `BookingsRepo` يُعيد الحجز لـ inConsultation ويترك الـ Visit in_progress — وهي الحالة الصحيحة (الكشف لم ينته فعلاً).

---

## 5. تدفق المستخدم (User Flow) خطوة بخطوة

### 5.1 تدفق الدكتور — VisitsPage (طابور اليوم)

```
الدكتور يفتح /visits
    ↓
PermissionEvaluator.can(viewVisitsQueue) → false → 403
    ↓ (true)
VisitsCubit.loadQueue(filterDate: today, filterDoctorId: session.linkedDoctorId)
GetDoctorQueueUseCase → VisitsRepo.getDoctorQueue(doctorId: linkedDoctorId, ...)
  يجمع حجوزات اليوم للدكتور بحالة [waiting, inConsultation]
  + الكشوفات المنتهية اليوم (completed) للعرض بزر "عرض" فقط
  لكل حجز: هل فيه Visit مرتبط به؟ → ConsultationQueueItemModel
    ↓
الجدول يعرض:
  • waiting + visit=null          → زر "بدء الكشف"
  • waiting + visit.triage        → زر "إكمال الكشف" (العلامات مسجّلة)
  • inConsultation + in_progress  → بانر "كشف مستمر" + زر "متابعة"
  • completed + finalized         → زر "عرض" فقط (قراءة)
    ↓
الدكتور يضغط "بدء الكشف" / "إكمال" / "متابعة"
    ↓
PermissionEvaluator.can(startConsultation, patientDoctorIds: {booking.doctorId})
    ↓
VisitsCubit.startConsultation(queueItem) →
  StartConsultationUseCase (Saga §4.1):
    1. BookingsRepo.changeBookingStatus → inConsultation
    2. VisitsRepo.upsertConsultationStart → VisitModel
    AuditLogger.log('visit_started', ...)
    ↓
GoRouter.push('/visits/${visit.id}') → DoctorConsultationScreen
```

### 5.2 تدفق الدكتور — DoctorConsultationScreen

```
Route محمي بـ: viewConsultationNotes (§6.1)
(السبب: دور التمريض يملك viewMedicalRecordDiagnostics أصلاً في seed النظام؛ حماية شاشة الكشف عبر viewConsultationNotes تضمن منع الممرض من دخول الشاشة بالرابط)
الممرض لا يصل لهذه الشاشة عبر الـ route

DoctorConsultationScreen يُبنى بـ visitId من URL params
    ↓
VisitsCubit.loadActiveVisit(visitId):
  تحقق: PermissionEvaluator.can(viewConsultationNotes, patientDoctorIds) → false → pop + CustomToast(error)
  تحقق: PermissionEvaluator.can(editMedicalDiagnosis, patientDoctorIds) → يحدد قابلية التعديل
  AuditLogger.log('view_patient_medical_record')
  جلب PatientModel → يستخرج allergies + chronicDiseases (للطبيب ومن يملك viewConsultationNotes)
  startAutoSave() → Timer.periodic(30s)

الشاشة:
  PatientAllergyBanner (allergies فقط — للدكتور والممرض عبر viewVisitsQueue)
  VitalsInputPanel (للدكتور + validate نطاقات)
  ConsultationNotesPanel (للطبيب فقط — محجوب إن !viewConsultationNotes)
  PatientChronicDiseasesPanel (للطبيب فقط — محجوب إن !viewConsultationNotes)
  إن status = finalized: 🔒 "هذا الكشف منتهٍ — قراءة فقط"
  أزرار [حفظ مسودة] [إنهاء الكشف] — مخفيان إن finalized

Auto-Save (كل 30 ثانية):
  ← إن !formState.isDirty → skip (zero calls to repo)
  ← إن visit.status == finalized → skip
  ← إن AutoSave جارٍ بالفعل → skip (لا تراكم)
  PermissionEvaluator.can(editMedicalDiagnosis, ...) → false → skip
  Cubit يُحوّل formState → VisitModel
  SaveVisitDraftUseCase → VisitsRepo.saveVisitDraft(draft)
  بعد نجاح: isDirty = false

عند الخروج من الشاشة (dispose / pop):
  إن formState.isDirty → حفظ أخير (fire-and-forget)
  stopAutoSave()

عند "إنهاء الكشف":
  FinalizeVisitDialog → تأكيد
  PermissionEvaluator.can(editMedicalDiagnosis, ...) → false → رسالة خطأ
  VisitsCubit.finalizeVisit() →
    Cubit يُحوّل formState → VisitModel محدّث بـ status: finalized
    FinalizeVisitUseCase (Saga §4.2):
      1. BookingsRepo.changeBookingStatus → completed
      2. VisitsRepo.finalizeVisit(visitModel)
      AuditLogger.log('visit_finalized', ...)
  stopAutoSave()
  إن أي autosave جارٍ → تجاهل نتيجته (Cubit يتحقق من status عند الاستجابة)
  GoRouter.pop() → يرجع لـ VisitsPage

عند فتح كشف جديد (انتقال من شاشة لأخرى):
  Cubit يُصفَّر formState و activeVisit قبل loadActiveVisit الجديد
```

### 5.3 تدفق التمريض — تسجيل العلامات الحيوية (Dialog فقط)

```
الممرض يفتح /visits (viewVisitsQueue = true)
الممرض لا يملك viewConsultationNotes → لا يصل لـ /visits/:id أبداً (Guard يرفض الدخول 403)

الممرض يضغط "تسجيل علامات" على حجز بحالة waiting
    ↓
قيود use case (RecordVitalsUseCase):
  • الحجز يجب أن يكون بحالة waiting (الحجز بحالة أخرى → Left(Failure))
  • الحجز يجب أن يكون لليوم ولفرع الممرض الحالي
    ↓
RecordVitalsDialog يظهر (Dialog وليس route):
  PatientAllergyBanner (allergies المريض — من VisitsState.patientAllergies)
  VitalsInputPanel (كل الحقول بتحذيرات نطاق)
  NO ConsultationNotesPanel
  NO chronic diseases (تتطلب viewConsultationNotes)
    ↓
VisitsCubit.recordVitals(bookingId, vitals, recordedByUserId) →
  PermissionEvaluator.can(recordVitals) → false → Left(Failure)
  RecordVitalsUseCase:
    1. VisitsRepo.recordVitals(bookingId, vitals, ...) →
       • Visit غير موجود → ينشئ Visit جديد بحالة triage
       • Visit بحالة triage → يُحدّث vitals فقط (يبقى triage)
       • Visit بحالة in_progress أو finalized → Left(Failure: ممنوع للتمريض تعديل كشف بدأه الطبيب أو كشف منتهٍ)
    2. AuditLogger.log('vitals_recorded', ...)

كيف يحصل الممرض على allergies:
  • عند لمس صف الحجز → VisitsCubit.loadPatientAllergies(patientId)
  • يستدعي PatientsRepo.getPatientById(patientId) ثم يستخرج allergies فقط
  • يُخزَّن في VisitsState.patientAllergies (List<String>)
  • لا يُخزَّن PatientModel كاملاً في الـ State (تجنب تسريب chronicDiseases للممرض)
  • PatientAllergyBanner يقرأ فقط من VisitsState.patientAllergies
```

### 5.4 الطابور الديناميكي حسب الدور
- **الدكتور:** `filterDoctorId = session.linkedDoctorId` (يرى طابوره فقط)
- **مدير الفرع / مالك / مدير طبي:** `filterDoctorId = null` → كل الكشوفات مع `CustomStackSelector` لاختيار الدكتور
- **الممرض:** `filterDoctorId = null` → كل الطابور (يسجّل علامات لأي مريض في فرعه)

### 5.5 زر "بدء الكشف" من صفحة الحجوزات (يُضاف في M-5)

```
BookingsPage: زر في action menu للصف بحالة [waiting, inConsultation]
  → يظهر إن: session.can(startConsultation) && linkedDoctorId == booking.doctorId
  → يستدعي VisitsCubit.startConsultation() ثم ينتقل لـ /visits/${visit.id}

BookingDetailsPage: بطاقة "إجراءات سريرية" تحتوي نفس الزر بنفس الشروط
```

---

## 6. الصلاحيات الجديدة وأحداث الـ Audit

### 6.1 صلاحيات جديدة

```dart
// تُضاف في مجموعة "2. Patients & Medical Records":
viewVisitsQueue,           // فتح /visits وعرض الطابور (الممرض والدكتور والإداري)
startConsultation,         // بدء الكشف (للطبيب فقط، مقيد بـ linkedDoctorId)
recordVitals,              // تسجيل العلامات الحيوية (للتمريض والطبيب)
viewConsultationNotes,     // فتح /visits/:id واستعراض ملاحظات وتشخيص الكشف السريري والأمراض المزمنة
```

### 6.2 Route Guard

| Route | الصلاحية المطلوبة |
|:---|:---|
| `/visits` | `viewVisitsQueue` |
| `/visits/:id` | `viewConsultationNotes` |

### 6.3 جدول زراعة الصلاحيات (Seed)
> **حوكمة أمان السجلات الطبية:** دور التمريض (Nurse) يملك `viewMedicalRecordDiagnostics` أصلاً في الـ seed الأصلي للنظام. لمنع التمريض من الوصول إلى شاشة الكشف السريرية `/visits/:id` أو قراءة التشخيصات والملاحظات السريرية، تم استحداث صلاحية مستقلة `viewConsultationNotes` ومُنحت للأدوار السريرية والإشرافية فقط دون التمريض.

| الصلاحية | مالك* | مدير فرع | مدير طبي | طبيب | ممرض | استقبال | محاسب |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `viewVisitsQueue` *(جديدة)* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| `startConsultation` *(جديدة)* | ✅† | ❌ | ❌ | ✅† | ❌ | ❌ | ❌ |
| `recordVitals` *(جديدة)* | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| `viewConsultationNotes` *(جديدة)* | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `viewMedicalRecordDiagnostics` *(موجودة)* | ✅ | ✅ | ✅ | ✅ | ✅‡ | ❌ | ❌ |
| `editMedicalDiagnosis` *(موجودة)* | ✅† | ❌ | ❌ | ✅† | ❌ | ❌ | ❌ |

> * **المالك:** كل الصلاحيات مفعلة ضمنياً عبر `PermissionEvaluator.can()` (لا يحتاج فحص قائمة الصلاحيات).
> † **مقيدة بالربط بالطبيب:** `linkedDoctorId == booking.doctorId`.
> **مدير الفرع والمدير الطبي:** يملكان `viewConsultationNotes`، ولكن لا يملكان `editMedicalDiagnosis`؛ وبناءً عليه تُفتح شاشة الكشف لهما **للقراءة والمتابعة فقط** دون أي إمكانية لحفظ تشخيص أو إنهاء كشف.
> ‡ **الممرض:** يملك `viewMedicalRecordDiagnostics` في الـ seed الأصلي لنظام الأدوار، إلا أنه **لا يملك `viewConsultationNotes`**، ومسار التمريض المعتمد في F-04a هو العمل عبر `RecordVitalsDialog` من صفحة الطابور مباشرة، ومحاولة فتحه لـ `/visits/:id` ترجع `403 Forbidden`.

### 6.4 أحداث الـ Audit

| `eventType` | يُطلق عند | الحقول المسجلة |
|:---|:---|:---|
| `visit_started` | بدء الكشف | visitId, bookingId, doctorId, patientId, branchId |
| `view_patient_medical_record` | فتح `DoctorConsultationScreen` | visitId, patientId, viewedByUserId |
| `vitals_recorded` | حفظ العلامات الحيوية | visitId, recordedByUserId, branchId |
| `visit_finalized` | إنهاء الكشف | visitId, bookingId, doctorId, finalizedAt |

---

## 7. مفاتيح الترجمة الجديدة (prefix: `visits_`)

> ar-EG و en-US متطابقان عدداً وترتيباً. تُضاف في §أ أدناه.

### ar-EG.json (إضافات جديدة فقط)
```json
{
  "visits_page_title": "طابور الكشف اليوم",
  "visits_page_subtitle": "الحجوزات المحوّلة للكشف الطبي",
  "visits_start_consultation": "بدء الكشف",
  "visits_continue_consultation": "متابعة الكشف",
  "visits_complete_vitals": "إكمال الكشف (علامات مسجّلة)",
  "visits_finalize_visit": "إنهاء الكشف",
  "visits_save_draft": "حفظ مسودة",
  "visits_auto_saved": "تم الحفظ تلقائياً",
  "visits_record_vitals": "تسجيل العلامات الحيوية",
  "visits_ongoing_banner": "كشف مستمر منذ {minutes} دقيقة",
  "visits_status_triage": "علامات مسجّلة",
  "visits_status_in_progress": "داخل الكشف",
  "visits_status_finalized": "منتهٍ",
  "visits_chief_complaint": "الشكوى الرئيسية",
  "visits_medical_history": "التاريخ المرضي",
  "visits_physical_exam": "الفحص السريري",
  "visits_diagnosis": "التشخيص",
  "visits_treatment_plan": "الخطة العلاجية",
  "visits_follow_up_notes": "ملاحظات المتابعة",
  "visits_follow_up_days": "موعد الإعادة (بعد كم يوم)",
  "visits_vitals_title": "العلامات الحيوية",
  "visits_systolic_bp": "ضغط الدم الانقباضي (mmHg)",
  "visits_diastolic_bp": "ضغط الدم الانبساطي (mmHg)",
  "visits_heart_rate": "النبض (bpm)",
  "visits_temperature": "الحرارة (°C)",
  "visits_oxygen_saturation": "نسبة الأكسجين (%)",
  "visits_weight_kg": "الوزن (kg)",
  "visits_height_cm": "الطول (cm)",
  "visits_bmi": "مؤشر كتلة الجسم",
  "visits_bmi_normal": "طبيعي",
  "visits_bmi_overweight": "زيادة وزن",
  "visits_bmi_obese": "سمنة",
  "visits_bmi_underweight": "نقص وزن",
  "visits_vitals_warn_bp_high": "تحذير: ضغط الدم مرتفع جداً",
  "visits_vitals_warn_bp_low": "تحذير: ضغط الدم منخفض جداً",
  "visits_vitals_warn_hr_high": "تحذير: النبض مرتفع جداً",
  "visits_vitals_warn_hr_low": "تحذير: النبض منخفض جداً",
  "visits_vitals_warn_temp_high": "تحذير: الحرارة مرتفعة جداً",
  "visits_vitals_warn_temp_low": "تحذير: الحرارة منخفضة جداً",
  "visits_vitals_warn_spo2_high": "تحذير: قيمة SpO2 أعلى من 100% — راجع القراءة",
  "visits_vitals_warn_spo2_low": "تحذير: نسبة الأكسجين منخفضة جداً",
  "visits_allergy_warning": "تحذير: هذا المريض لديه حساسية موثقة",
  "visits_no_allergies": "لا توجد حساسية موثقة",
  "visits_chronic_diseases_title": "الأمراض المزمنة",
  "visits_finalize_confirm_title": "إنهاء الكشف",
  "visits_finalize_confirm_body": "بعد الإنهاء، يصبح السجل الطبي مقفولاً للقراءة فقط. هل تريد المتابعة؟",
  "visits_finalize_success": "تم إنهاء الكشف بنجاح وتحويل المريض لقسم الاستقبال",
  "visits_locked_notice": "هذا الكشف منتهٍ ومقفول — للقراءة فقط",
  "visits_no_active_visits": "لا توجد كشوفات نشطة اليوم",
  "visits_no_permission_queue": "ليس لديك صلاحية الوصول لقائمة الكشف",
  "visits_no_permission_consultation": "ليس لديك صلاحية الوصول للسجلات الطبية",
  "visits_start_error": "فشل في بدء الكشف. تأكد أن الحجز ما زال في حالة الانتظار.",
  "visits_start_not_your_patient": "لا يمكنك بدء كشف لمريض معيّن لطبيب آخر.",
  "visits_draft_saved": "تم حفظ المسودة",
  "visits_vitals_saved": "تم حفظ العلامات الحيوية",
  "visits_filter_date": "التاريخ",
  "visits_filter_status": "حالة الكشف",
  "visits_filter_doctor": "الطبيب",
  "visits_action_view": "عرض الكشف",
  "visits_diagnosis_hint": "أدخل التشخيص (نص حر)",
  "visits_booking_locked_error": "لا يمكن تعديل هذا الحجز — يوجد كشف نشط. أنهِ الكشف أولاً.",
  "visits_save_error": "فشل في حفظ المسودة، يُرجى المحاولة مجدداً",
  "visits_finalize_error": "فشل في إنهاء الكشف، يُرجى المحاولة مجدداً",
  "visits_finalize_missing_fields": "يجب إدخال الشكوى الرئيسية والتشخيص قبل إنهاء الكشف",
  "visits_vitals_error": "فشل في حفظ العلامات الحيوية",
  "visits_vitals_finalized_error": "لا يمكن تعديل العلامات الحيوية بعد إنهاء الكشف",
  "visits_vitals_wrong_status_error": "يمكن تسجيل العلامات الحيوية فقط للحجوزات في حالة الانتظار",
  "visits_load_error": "فشل في تحميل الكشوفات، يُرجى المحاولة مجدداً",
  "visits_actions": "الإجراءات",
  "visits_assigned_doctor": "الطبيب المعالج",
  "visits_booking_time": "الوقت",
  "visits_chronic_diseases": "الأمراض المزمنة",
  "visits_consultation_details_title": "تفاصيل الكشف الطبي",
  "visits_finalized_read_only": "هذا الكشف مكتمل ومغلق — للقراءة فقط",
  "visits_no_chronic_diseases": "لا توجد أمراض مزمنة موثقة",
  "visits_patient_allergies": "الحساسية الدوائية والغذائية",
  "visits_patient_name": "المريض",
  "visits_patient_queue_num": "#",
  "visits_placeholder_message": "شاشة الكشف الطبي قيد التجهيز",
  "visits_queue_all_doctors": "جميع الأطباء",
  "visits_queue_all_statuses": "جميع الحالات",
  "visits_record_vitals_short": "العلامات",
  "visits_under_development": "تحت التطوير",
  "visits_vitals_bmi": "مؤشر الكتلة",
  "visits_vitals_diastolic": "الانبساطي",
  "visits_vitals_heart_rate": "النبض",
  "visits_vitals_height": "الطول",
  "visits_vitals_o2": "الأكسجين",
  "visits_vitals_systolic": "الانقباضي",
  "visits_vitals_temperature": "الحرارة",
  "visits_vitals_warn_height_high": "تحذير: الطول المسجل أعلى من الطبيعي",
  "visits_vitals_warn_height_low": "تحذير: الطول المسجل أقل من الطبيعي",
  "visits_vitals_warn_weight_high": "تحذير: الوزن المسجل أعلى من الطبيعي",
  "visits_vitals_warn_weight_low": "تحذير: الوزن المسجل أقل من الطبيعي",
  "visits_vitals_weight": "الوزن"
}
```

### en-US.json (نفس المفاتيح — متطابقة عدداً)
```json
{
  "visits_page_title": "Today's Consultation Queue",
  "visits_page_subtitle": "Bookings referred for medical consultation",
  "visits_start_consultation": "Start Consultation",
  "visits_continue_consultation": "Continue Consultation",
  "visits_complete_vitals": "Complete Visit (Vitals Recorded)",
  "visits_finalize_visit": "Finalize Visit",
  "visits_save_draft": "Save Draft",
  "visits_auto_saved": "Auto-saved",
  "visits_record_vitals": "Record Vital Signs",
  "visits_ongoing_banner": "Consultation in progress for {minutes} min",
  "visits_status_triage": "Vitals Recorded",
  "visits_status_in_progress": "In Consultation",
  "visits_status_finalized": "Finalized",
  "visits_chief_complaint": "Chief Complaint",
  "visits_medical_history": "Medical History",
  "visits_physical_exam": "Physical Examination",
  "visits_diagnosis": "Diagnosis",
  "visits_treatment_plan": "Treatment Plan",
  "visits_follow_up_notes": "Follow-up Notes",
  "visits_follow_up_days": "Follow-up in (days)",
  "visits_vitals_title": "Vital Signs",
  "visits_systolic_bp": "Systolic BP (mmHg)",
  "visits_diastolic_bp": "Diastolic BP (mmHg)",
  "visits_heart_rate": "Heart Rate (bpm)",
  "visits_temperature": "Temperature (°C)",
  "visits_oxygen_saturation": "Oxygen Saturation (%)",
  "visits_weight_kg": "Weight (kg)",
  "visits_height_cm": "Height (cm)",
  "visits_bmi": "BMI",
  "visits_bmi_normal": "Normal",
  "visits_bmi_overweight": "Overweight",
  "visits_bmi_obese": "Obese",
  "visits_bmi_underweight": "Underweight",
  "visits_vitals_warn_bp_high": "Warning: Blood pressure is very high",
  "visits_vitals_warn_bp_low": "Warning: Blood pressure is very low",
  "visits_vitals_warn_hr_high": "Warning: Heart rate is very high",
  "visits_vitals_warn_hr_low": "Warning: Heart rate is very low",
  "visits_vitals_warn_temp_high": "Warning: Temperature is very high",
  "visits_vitals_warn_temp_low": "Warning: Temperature is very low",
  "visits_vitals_warn_spo2_high": "Warning: SpO2 above 100% — please recheck",
  "visits_vitals_warn_spo2_low": "Warning: Oxygen saturation is very low",
  "visits_allergy_warning": "Warning: This patient has documented allergies",
  "visits_no_allergies": "No documented allergies",
  "visits_chronic_diseases_title": "Chronic Diseases",
  "visits_finalize_confirm_title": "Finalize Visit",
  "visits_finalize_confirm_body": "After finalization, the medical record will be locked for read-only access. Continue?",
  "visits_finalize_success": "Visit finalized successfully. Patient sent to reception.",
  "visits_locked_notice": "This visit is finalized and locked — read-only",
  "visits_no_active_visits": "No active consultations today",
  "visits_no_permission_queue": "You do not have access to the consultation queue",
  "visits_no_permission_consultation": "You do not have access to medical records",
  "visits_start_error": "Failed to start consultation. Ensure the booking is still in waiting status.",
  "visits_start_not_your_patient": "You cannot start a consultation assigned to another doctor.",
  "visits_draft_saved": "Draft saved",
  "visits_vitals_saved": "Vital signs saved",
  "visits_filter_date": "Date",
  "visits_filter_status": "Visit Status",
  "visits_filter_doctor": "Doctor",
  "visits_action_view": "View Consultation",
  "visits_diagnosis_hint": "Enter diagnosis (free text)",
  "visits_booking_locked_error": "Cannot modify this booking — an active consultation exists. Finalize the visit first.",
  "visits_save_error": "Failed to save draft, please try again",
  "visits_finalize_error": "Failed to finalize visit, please try again",
  "visits_finalize_missing_fields": "Chief complaint and diagnosis are required to finalize the visit",
  "visits_vitals_error": "Failed to save vital signs",
  "visits_vitals_finalized_error": "Cannot edit vital signs after visit finalization",
  "visits_vitals_wrong_status_error": "Vital signs can only be recorded for bookings in waiting status",
  "visits_load_error": "Failed to load consultations, please try again",
  "visits_actions": "Actions",
  "visits_assigned_doctor": "Attending Doctor",
  "visits_booking_time": "Time",
  "visits_chronic_diseases": "Chronic Diseases",
  "visits_consultation_details_title": "Medical Consultation Details",
  "visits_finalized_read_only": "This visit is finalized and locked — read-only",
  "visits_no_chronic_diseases": "No documented chronic diseases",
  "visits_patient_allergies": "Drug & Food Allergies",
  "visits_patient_name": "Patient",
  "visits_patient_queue_num": "#",
  "visits_placeholder_message": "Consultation screen under construction",
  "visits_queue_all_doctors": "All Doctors",
  "visits_queue_all_statuses": "All Statuses",
  "visits_record_vitals_short": "Vitals",
  "visits_under_development": "Under Development",
  "visits_vitals_bmi": "BMI",
  "visits_vitals_diastolic": "Diastolic",
  "visits_vitals_heart_rate": "Heart Rate",
  "visits_vitals_height": "Height",
  "visits_vitals_o2": "Oxygen",
  "visits_vitals_systolic": "Systolic",
  "visits_vitals_temperature": "Temperature",
  "visits_vitals_warn_height_high": "Warning: Recorded height is above normal",
  "visits_vitals_warn_height_low": "Warning: Recorded height is below normal",
  "visits_vitals_warn_weight_high": "Warning: Recorded weight is above normal",
  "visits_vitals_warn_weight_low": "Warning: Recorded weight is below normal",
  "visits_vitals_weight": "Weight"
}
```

---

## 8. خطة الاختبارات (Unit + Widget)

### M-2: Models والـ Domain Logic
**الملف:** `test/features/visits/visit_model_and_vitals_test.dart`
```
T1: VisitModel.fromJson() مع كل الحقول nullable
T2: VisitModel.fromJson(null) يرجع VisitModel فارغ بدون exception
T3: VitalsModel.bmi getter: (68 / (1.62^2)) ≈ 25.9 ✓
T4: VitalsModel.bmi getter: returns null لو weight أو height null
T5: VisitStatusEnum.fromValue('in_progress') = VisitStatusEnum.inProgress
T6: VisitStatusEnum.fromValue('triage') = VisitStatusEnum.triage
T7: VisitStatusEnum.fromValue(null) = null
T8: VisitModel.copyWith() يحافظ على الحقول غير المحددة
T9: ConsultationQueueItemModel.hasActiveVisit = true إن visit.status = triage
T10: ConsultationQueueItemModel.hasActiveVisit = true إن visit.status = in_progress
T11: ConsultationQueueItemModel.isFinalized = true إن visit.status = finalized
T12: VisitFormState.toVisitModel() يُحوّل الحقول بشكل صحيح
T13: VitalsModel.systolicBpWarning = not-null إن systolicBp > 200
T14: VitalsModel.oxygenSaturationWarning = not-null إن oxygenSaturation > 100
T15: VitalsModel.oxygenSaturationWarning = null إن oxygenSaturation = 98
```

### M-2: VisitsMockRepoImpl والـ Seed
**الملف:** `test/features/visits/visits_mock_repo_test.dart`
```
T1: getDoctorQueue(doctorId: 'DOC-01') يرجع ConsultationQueueItems بما فيها MED-101 وVIS-001
T2: getDoctorQueue(doctorId: null) يرجع كل أطباء الفرع
T3: getDoctorQueue يتضمن الكشوفات المنتهية (finalized) كعناصر للعرض
T4: getDoctorQueue يرجع قائمة فارغة لدكتور ليس لديه حجوزات اليوم
T5: upsertConsultationStart ينشئ VisitModel جديد بحالة in_progress لحجز waiting
T6: upsertConsultationStart يحوّل Visit من triage إلى in_progress ويضبط startedAt ويحدّث doctorId وdoctorName وspecialty
T7: upsertConsultationStart يُعيد Visit موجود بحالة in_progress (Idempotent)
T8: upsertConsultationStart يرجع Left(Failure) إن Visit بحالة finalized
T9: recordVitals(bookingId بدون Visit) → ينشئ Visit جديد بحالة triage
T10: recordVitals(bookingId مع Visit triage) → يُحدّث vitals ويبقى triage
T11: recordVitals(bookingId مع Visit in_progress) → Left(Failure) (التمريض لا يعدّل كشفاً بدأه الطبيب)
T12: recordVitals(bookingId مع Visit finalized) → Left(Failure)
T13: saveVisitDraft يُحدّث lastSavedAt ولا يغير status
T14: saveVisitDraft على Visit finalized → Left(Failure)
T15: finalizeVisit يغير status إلى finalized ويحدّث finalizedAt
T16: finalizeVisit على Visit finalized مرة ثانية → Left(Failure) (Idempotency)
```

### M-2: Saga Tests
**الملف:** `test/features/visits/visits_saga_test.dart`
```
T1: startConsultation — نجاح BookingsRepo + نجاح VisitsRepo → حجز inConsultation + Visit in_progress
T2: startConsultation — فشل BookingsRepo → Left(Failure)، Visit لا يُنشأ
T3: startConsultation — نجاح BookingsRepo + فشل VisitsRepo → Rollback للحالة السابقة (كان waiting يعود waiting)
T4: startConsultation — rollback من حجز كان inConsultation فيعود inConsultation
T5: startConsultation — Visit موجود بحالة triage → يحوّله لـ in_progress، يحدّث snapshot الطبيب، لا ينشئ Visit جديد
T6: startConsultation — rollback مع Visit بحالة triage ينجح والـ Visit يبقى بحالة triage
T7: finalizeVisit — نجاح BookingsRepo + نجاح VisitsRepo → حجز completed + Visit finalized
T8: finalizeVisit — فشل BookingsRepo → Left(Failure)، Visit لا يتغير
T9: finalizeVisit — نجاح BookingsRepo + فشل VisitsRepo → Rollback: حجز يرجع inConsultation، Left(Failure)، Visit يبقى in_progress
```

### M-2: قفل الحجز وفك الارتباط
**الملف:** `test/features/visits/booking_lock_test.dart`
```
T1: ChangeBookingStatusUseCase يرفض cancelled إن للحجز Visit بحالة in_progress
T2: ChangeBookingStatusUseCase يسمح cancelled إن للحجز Visit بحالة triage (الـ Visit يبقى أرشيفاً للعلامات)
T3: ChangeBookingStatusUseCase يسمح noShow إن للحجز Visit بحالة triage
T4: ChangeBookingStatusUseCase يسمح postponed إن للحجز Visit بحالة triage
T5: ChangeBookingStatusUseCase يرفض postponed إن للحجز Visit بحالة in_progress
T6: ChangeBookingStatusUseCase يرفض waiting إن للحجز Visit بحالة in_progress
T7: ChangeBookingStatusUseCase يسمح inConsultation إن للحجز Visit بحالة in_progress (من الـ Saga مباشرة)
T8: ReassignTechnicianUseCase يسمح التحويل لطبيب آخر إن للحجز Visit بحالة triage
T9: ReassignTechnicianUseCase يرفض التحويل إن للحجز Visit بحالة in_progress
T10: DeleteBookingUseCase يرفض الحذف إن للحجز Visit بحالة triage (حماية سجل القياسات)
T11: DeleteBookingUseCase يرفض الحذف إن للحجز Visit بحالة in_progress
T12: upsertConsultationStart بعد إعادة تعيين الطبيب أثناء triage يحدّث snapshot الطبيب الجديد
T13: ChangeBookingStatusUseCase يسمح التعديل إن الـ Visit finalized أو لا يوجد كشف
```

### M-3: الصلاحيات والـ RBAC
**الملف:** `test/features/visits/visit_permission_test.dart`
```
T1: PermissionEvaluator.can(viewVisitsQueue) = true للطبيب
T2: PermissionEvaluator.can(viewVisitsQueue) = true للممرض
T3: PermissionEvaluator.can(viewVisitsQueue) = false للمحاسب
T4: PermissionEvaluator.can(startConsultation) = true للطبيب المرتبط بالمريض
T5: PermissionEvaluator.can(startConsultation) = false للطبيب غير المرتبط
T6: PermissionEvaluator.can(editMedicalDiagnosis) = false لو linkedDoctorId != visit.doctorId
T7: PermissionEvaluator.can(recordVitals) = true للممرض
T8: PermissionEvaluator.can(viewMedicalRecordDiagnostics) = false للاستقبال
T9: Owner مع isPracticingDoctor = false لا يملك startConsultation
T10: Owner مع isPracticingDoctor = true ولكن linkedDoctorId مختلف = false لـ editMedicalDiagnosis
T11: (تعديل الدور أثناء الكشف) إن سُحب دور "طبيب" من مستخدم = PermissionEvaluator.can(editMedicalDiagnosis) = false في التقييم التالي
```

### M-3: VisitsCubit
**الملف:** `test/features/visits/visits_cubit_test.dart`
```
T1: الحالة الأولية = VisitsState() بـ listStatus: initial
T2: loadQueue يُصدر: loading → success مع قائمة الطابور
T3: loadQueue يُصدر: loading → failure مع errMessage عند خطأ
T4: startConsultation يُصدر actionStatus: loading → success
T5: startConsultation يُصدر actionStatus: failure لو unauthorized
T6: autoSaveDraft لا يُرسل لو isDirty = false (zero calls to repo)
T7: autoSaveDraft يُرسل لو isDirty = true ويُصفّر isDirty بعد النجاح
T8: autoSaveDraft لا يُرسل لو visit.status = finalized
T9: startAutoSave يُمكّن Auto-Save، stopAutoSave يوقفه
T10: finalizeVisit يُصدر consultationStatus: success مع activeVisit.status = finalized
T11: updateFormState يُحدّث formState ويضع isDirty = true
T12: recordVitals من ممرض يُصدر actionStatus: success
T13: loadActiveVisit الجديد يُصفَّر formState و activeVisit القديمَين أولاً
T14: نتيجة autoSave تُتجاهل لو visit.status = finalized وقت الاستجابة
T15: RecordVitalsUseCase يرفض لو الحجز ليس بحالة waiting
```

### M-5: Widget Tests
**الملف:** `test/features/visits/visits_ui_test.dart`
```
T1: PatientAllergyBanner يظهر بالأحمر لو المريض عنده حساسية
T2: PatientAllergyBanner لا يظهر لو لا توجد حساسية
T3: ConsultationNotesPanel لا يظهر لو المستخدم لا يملك viewConsultationNotes
T4: VitalsInputPanel يظهر للممرض الذي يملك recordVitals
T5: VitalsInputPanel يعرض تحذير أصفر لو SpO2 > 100
T6: BMI يُحسب ويُعرض بشكل صحيح لما يُدخل الوزن والطول
T7: زر "إنهاء الكشف" يفتح FinalizeVisitDialog
T8: FinalizeVisitDialog يستدعي VisitsCubit.finalizeVisit() عند التأكيد
T9: شاشة الكشف تعرض "مقفول" notice لو status = finalized
T10: أزرار الحفظ والإنهاء مخفية لو status = finalized
T11: VisitsPage تعرض CustomEmptyWidget لو لا توجد كشوفات
T12: VisitsPage تعرض Shimmer أثناء التحميل
T13: بانر "كشف مستمر" يظهر لو visit.status = in_progress في الطابور
T14: RecordVitalsDialog يظهر عند ضغط "تسجيل علامات" من الطابور
T15: RecordVitalsDialog لا يعرض ConsultationNotesPanel
```

---

## 9. ترتيب التنفيذ (Milestones)

### M-1: المتطلبات المسبقة (يوم 1)
1. إضافة `viewVisitsQueue`, `startConsultation`, `recordVitals` لـ `StaffPermissionEnum`.
2. تحديث seed الصلاحيات في `StaffUsersMockRepoImpl` و `defaultSystemRoles()`.
3. `flutter test` → 186+ passed. Commit: `feat(F-04a-M1): add visits permissions`

### M-2: نماذج البيانات والـ Domain (يوم 2)
1. إنشاء `VisitStatusEnum`, `VitalsModel` (مع validation getters), `VisitModel`, `ConsultationQueueItemModel`.
2. إنشاء عقد `ActiveVisitLookup` في domain الحجوزات لفك الارتباط.
3. إنشاء `VisitsRepo` interface (بدون `revertVisitStatus`).
4. إنشاء `VisitsMockRepoImpl` منفذاً لـ `VisitsRepo` و `ActiveVisitLookup` مع seed data (VIS-001↔MED-101 in_progress, VIS-002↔MED-104 finalized, VIS-003↔MED-107 finalized).
5. إنشاء Use Cases: `GetDoctorQueueUseCase`, `GetVisitByBookingIdUseCase`, `StartConsultationUseCase` (Saga مع rollback للحالة السابقة وتحديث snapshot الطبيب), `SaveVisitDraftUseCase`, `RecordVitalsUseCase` (waiting فقط), `FinalizeVisitUseCase` (Saga).
6. إضافة guard فحص الكشف النشط عبر `ActiveVisitLookup` لـ: `ChangeBookingStatusUseCase`, `ReassignTechnicianUseCase`, `DeleteBookingUseCase`.
7. كتابة اختبارات M-2 (visit_model_and_vitals_test, visits_mock_repo_test, visits_saga_test, booking_lock_test).
8. `flutter analyze` = 0 | `flutter test` = 100%. Commit: `feat(F-04a-M2): data layer, domain, saga, booking lock guard`

### M-3: الـ State Management (يوم 2-3)
1. إنشاء `VisitFormState`, `VisitsState`.
2. إنشاء `VisitsCubit` كاملاً مع Auto-Save Timer lifecycle.
3. تحديث `dependency_injection.dart`.
4. كتابة اختبارات M-3 (visit_permission_test, visits_cubit_test).
5. `flutter analyze` = 0 | `flutter test` = 100%. Commit: `feat(F-04a-M3): VisitsCubit with auto-save and permissions`

### M-4: واجهة الطابور وتسجيل العلامات الحيوية (يوم 3-4)
1. إنشاء `ConsultationQueueTable`, `ConsultationQueueCard`, `AdaptiveVisitsView`, `VisitsFilterBar`, `VisitsShimmer`, `VisitStatusBadge`.
2. إنشاء عناصر حساسية المريض والعلامات الحيوية: `PatientAllergyBanner`, `VitalsInputPanel`.
3. إنشاء حوار تسجيل العلامات للممرض: `RecordVitalsDialog` (تسجيل العلامات فقط دون ملاحظات طبية).
4. استبدال `VisitsPage` Placeholder بالواجهة التفاعلية الكاملة.
5. إضافة route `/visits/:id` في `app_router.dart` بـ guard `viewConsultationNotes` يوجّه لصفحة Placeholder مؤقتة حتى M-5.
6. إضافة كل مفاتيح الترجمة ar-EG و en-US واختبار اتساقها (`visits_translations_test.dart`).
7. كتابة اختبارات الـ Widget لـ M-4 (`consultation_queue_ui_test.dart`, `record_vitals_dialog_test.dart`).
8. `flutter analyze` = 0 | `flutter test` = 100%. Commit: `feat(F-04a-M4): visits queue UI, vitals dialog, routing`

### M-5: شاشة الكشف + زر الحجوزات (يوم 4-5)
1. إنشاء `ConsultationNotesPanel` وقائمة الأمراض المزمنة.
2. إنشاء `DoctorConsultationScreen` مع Auto-Save lifecycle وربط المسار `/visits/:id` بها.
3. إنشاء `FinalizeVisitDialog` لتأكيد إنهاء الكشف وإقفال السجل.
4. إضافة زر "بدء الكشف" في `BookingsPage` و`BookingDetailsPage`.
5. كتابة اختبارات M-5 (`visits_consultation_screen_test.dart`, `booking_start_consultation_test.dart`).
6. `flutter analyze` = 0 | `flutter test` = 100%. Commit: `feat(F-04a-M5): DoctorConsultationScreen, finalize dialog, booking entry points`

### M-6: التحقق النهائي والإقفال
1. مراجعة كل أحداث AuditLogger.
2. التأكد من صفر نصوص hardcoded.
3. تحديث `docs/PROGRESS.md`.
4. `flutter analyze` = 0 | `flutter test` = 100%.
5. Commit: `feat(F-04a): implement Doctor Consultation Engine`

---

## 10. قرارات مغلقة

| القرار | الحل |
|:---|:---|
| Q1: هيكلة الربط بالحجوزات | Saga Pattern: حجز أولاً ثم Visit، rollback عبر `BookingsRepo.changeBookingStatus`. لا `InMemoryBookingsStore`. |
| Q2: Auto-Save | Timer.periodic(30s) + dirty flag + guard ضد الحفظ بعد finalized + تجاهل نتائج autosave المتأخرة |
| Q3: إغلاق الشاشة بدون إنهاء | يبقى in_progress. بانر "كشف مستمر". Cubit lazySingleton يحفظ آخر تعديل عند dispose. |
| Q4: نطاق VisitsPage | صفحة واحدة + filterDoctorId ديناميكي حسب الدور. تُفتح بـ viewVisitsQueue. |
| Q5: Route الممرض | `/visits/:id` محمي بـ viewMedicalRecordDiagnostics. الممرض يسجّل من RecordVitalsDialog فقط. |
| Q6: الحساسية | الحقل الحقيقي `allergies` (وليس drugAllergies). الـ Cubit يستخرج allergies فقط للممرض (لا PatientModel كاملاً). |
| Q7: الدفع | الدكتور يبدأ الكشف بغض النظر عن الدفع. لا قاعدة دفع في F-04a. |
| Q8: Addendum | مؤجل لـ F-04b. بعد finalized = قراءة فقط في F-04a. |
| Q9: كتالوج التشخيصات | مؤجل لـ F-04b. التشخيص نص حر في F-04a. |

---

## 11. مؤجلات موثَّقة لـ F-04b
- Addendum سريري، كتالوج التشخيصات، الروشتة والأدوية، حالة `interrupted`

**الخطوة التالية:** وافق على الخطة ← أبدأ فوراً بـ M-1.

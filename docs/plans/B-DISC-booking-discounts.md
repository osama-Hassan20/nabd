# خطة التنفيذ — B-DISC: نظام الخصومات على الحجوزات (Booking Discounts)
> **النطاق:** دعم الكشف المجاني وخصم بنسبة % أو مبلغ ثابت على الحجز، بحيث تقرأه فاتورة F-05 جاهزاً
> **الأولوية:** بعد F-04a وقبل F-05 — لأن F-05 تحتاج `netAmount` و`effectivePaymentStatus` جاهزَين في `BookingModel`
> **تاريخ آخر تحديث:** 2026-11-10 (الإصدار النهائي)
> **العملة:** `AppFormatterHelper.formatCurrency()` لتنسيق كل المبالغ — لا `MoneyHelper` (غير موجود)

---

## مراجعة ذاتية للخطة

| السؤال | الإجابة والتبرير |
|:---|:---|
| ١. مصدر واحد للحقيقة؟ | نعم — `netAmount`, `discountAmount`, `effectivePaymentStatus` كلها getters محسوبة، لا تُخزَّن |
| ٢. fail-open في الصلاحيات؟ | لا — `maxDiscountPercent = null` = لا خصم (`canGrantFreeConsultation = null` = لا). Fail-closed |
| ٣. تغييرات على السعر الافتراضي تؤثر على حجوزات قديمة؟ | لا — `consultationFee` Snapshot وقت إنشاء الحجز |
| ٤. الحذف Soft؟ | الخصم يُزال بـ `removeDiscount(reason)` والسبب يُحفظ — Audit-trail |
| ٥. بيانات حساسة تتسرب؟ | لا — Audit يسجل المبالغ والنسبة والسبب فقط |
| ٦. يكسر شاشة موجودة؟ | نعم (مقصود ومُدار) — تعديل `BookingModel`, `BookingStatisticsCalculator`, بطاقة الرسوم |
| ٧. افتراضات على ملفات ما قُرأت؟ | لا — قرأت `booking_model.dart`, `role_definition_model.dart`, `payment_status_enum.dart`, `booking_statistics_calculator.dart`, `app_formatter_helper.dart`, وهيكل dialogs |

---

## 1. الوضع الحالي وما سيُعاد استخدامه

### 1.1 الموجود فعلاً

| الملف / الكيان | الحالة |
|:---|:---|
| `BookingModel` | يحتوي `consultationFee`, `paidAmount` — ستُضاف حقول الخصم |
| `PaymentStatusEnum` | `paid`, `unpaid`, `partiallyPaid` — **لا تُضاف `free`** (بدل ذلك: getter `effectivePaymentStatus`) |
| `BookingStatisticsCalculator` | يحسب على `consultationFee` — سيستخدم `netAmount` |
| `RoleDefinitionModel` | سيُضاف `maxDiscountPercent` و`canGrantFreeConsultation` nullable |
| `role_permissions_matrix_dialog.dart` | موجود في `presentation/pages/dialogs/` — سيُضاف إليه قسم "سياسة الخصم" |
| `AppFormatterHelper.formatCurrency()` | لتنسيق كل المبالغ في الـ UI |
| `PermissionEvaluator`, `AuditLogger`, `CairoTimeHelper.now()` | يُستخدم بدون تعديل |

### 1.2 ملفات تتغير

| الملف | التغيير |
|:---|:---|
| `lib/features/bookings/data/models/booking_model.dart` | +6 حقول nullable + 4 getters |
| `lib/features/bookings/data/repo/bookings_mock_repo_impl.dart` | +`applyDiscount`, `removeDiscount` |
| `lib/features/bookings/domain/repo/bookings_repo.dart` | +`applyDiscount`, `removeDiscount` |
| `lib/features/bookings/domain/helpers/booking_statistics_calculator.dart` | استخدام `netAmount` + discount stats |
| `lib/features/bookings/data/models/booking_summary_model.dart` | +discount إحصائيات (nullable) |
| `lib/features/users_management/data/models/role_definition_model.dart` | +`maxDiscountPercent`, `canGrantFreeConsultation` |
| `lib/core/enums/staff_permission_enum.dart` | +`applyBookingDiscount` |
| `lib/features/bookings/presentation/manager/bookings_cubit.dart` | +`applyDiscount`, `removeDiscount` methods |
| `lib/features/bookings/presentation/pages/booking_details_page.dart` | +BookingPriceSummaryCard |
| `lib/features/users_management/presentation/pages/dialogs/role_permissions_matrix_dialog.dart` | +قسم "سياسة الخصم" |
| `assets/translations/ar-EG.json` | مفاتيح جديدة بـ prefix `disc_` |
| `assets/translations/en-US.json` | مفاتيح جديدة بـ prefix `disc_` |

### 1.3 ملفات جديدة

```
lib/features/bookings/data/models/enums/discount_type_enum.dart
lib/features/bookings/domain/use_cases/apply_booking_discount_use_case.dart
lib/features/bookings/domain/use_cases/remove_booking_discount_use_case.dart
lib/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart
lib/features/users_management/domain/use_cases/params/update_role_discount_policy_params.dart
lib/features/bookings/domain/use_cases/params/apply_discount_params.dart
lib/features/bookings/domain/use_cases/params/remove_discount_params.dart
lib/features/bookings/presentation/widgets/booking_discount_section.dart
lib/features/bookings/presentation/widgets/booking_price_summary_card.dart
lib/features/bookings/presentation/widgets/free_booking_badge.dart
```

---

## 2. تصميم الـ Models

### 2.1 `DiscountTypeEnum`
```dart
enum DiscountTypeEnum {
  none('none'),
  percentage('percentage'),
  fixedAmount('fixed_amount'),
  free('free');

  final String value;
  const DiscountTypeEnum(this.value);
  static DiscountTypeEnum fromValue(String? val) {
    return DiscountTypeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DiscountTypeEnum.none,
    );
  }
}
```

---

### 2.2 تعديلات `BookingModel` — الحقول والـ Getters

```dart
// ─── حقول الخصم (6 حقول — كلها nullable) ───────────────────────────────
final DiscountTypeEnum? discountType;
final num? discountValue;                  // النسبة (0–100) أو المبلغ الثابت
final String? discountReason;              // إجباري لأي خصم
final String? discountApprovedByUserId;
final DateTime? discountApprovedAt;
final String? discountRemovedReason;       // سبب الإزالة (لو أُزيل)

// ─── Computed Getters (لا تُخزَّن — مصدر واحد للحقيقة) ─────────────────

num get discountAmount {
  final fee = consultationFee ?? 0;
  final type = discountType ?? DiscountTypeEnum.none;
  if (type == DiscountTypeEnum.none) return 0;
  if (type == DiscountTypeEnum.free) return fee;
  if (type == DiscountTypeEnum.percentage) {
    final pct = (discountValue ?? 0).clamp(0, 100);
    return (fee * pct / 100);
  }
  if (type == DiscountTypeEnum.fixedAmount) {
    return (discountValue ?? 0).clamp(0, fee);
  }
  return 0;
}

num get netAmount =>
    ((consultationFee ?? 0) - discountAmount).clamp(0, double.infinity);

bool get isFreeConsultation {
  final type = discountType ?? DiscountTypeEnum.none;
  if (type == DiscountTypeEnum.free) return true;
  if (type == DiscountTypeEnum.percentage && (discountValue ?? 0) >= 100) return true;
  if (type == DiscountTypeEnum.fixedAmount &&
      (discountValue ?? 0) >= (consultationFee ?? 0) &&
      (consultationFee ?? 0) > 0) return true;
  return false;
}

// حالة الدفع الفعلية (لا تُخزَّن — محسوبة)
PaymentStatusEnum get effectivePaymentStatus {
  if (isFreeConsultation && netAmount <= 0) {
    // الحجز مجاني: يُعتبر مسدداً لأغراض الإحصاء (لا متأخرات)
    return PaymentStatusEnum.paid;
  }
  return paymentStatus ?? PaymentStatusEnum.unpaid;
}
```

> **قرار مقفول:** لا تُضاف `free` لـ `PaymentStatusEnum`. بدلاً من ذلك `effectivePaymentStatus` getter يُعيد `paid` إن كان الحجز مجانياً. الـ UI يقرأ `isFreeConsultation` ليعرض `FreeBookingBadge`. البيانات المخزنة (`paymentStatus`) تبقى `paid/unpaid/partiallyPaid` فقط.

> **قاعدة:** بعد إزالة الخصم (removeDiscount) → يُعاد حساب `effectivePaymentStatus` من `paymentStatus` المخزنة. إزالة خصم مجاني = الحجز يعود إلى `unpaid` (لأن `paymentStatus` المخزنة كانت `unpaid` أصلاً).

---

### 2.3 تعديلات `RoleDefinitionModel`

```dart
class RoleDefinitionModel extends Equatable {
  // ... الحقول الموجودة ...

  // ─── سياسة الخصم (nullable = Fail-Closed) ────────────────────────────
  final num? maxDiscountPercent;          // null = لا خصم مسموح؛ 100 = بلا حد
  final bool? canGrantFreeConsultation;   // null أو false = ممنوع؛ true = مسموح

  const RoleDefinitionModel({ ... });

  RoleDefinitionModel copyWith({ ..., num? maxDiscountPercent, bool? canGrantFreeConsultation }) { ... }
}
```

**قيم seed الافتراضية في `defaultSystemRoles()`:**

| الدور | `maxDiscountPercent` | `canGrantFreeConsultation` | ملاحظة |
|:---|:---:|:---:|:---|
| مدير فرع (`branchManager`) | `100` | `true` | قابل للتعديل من المالك |
| مدير طبي (`medicalDirector`) | `null` | `null` | لا صلاحية خصم |
| طبيب (`doctor`) | `null` | `null` | لا صلاحية خصم |
| ممرض (`nurse`) | `null` | `null` | لا صلاحية خصم |
| استقبال (`reception`) | `20` | `false` | المالك يرفع الحد أو يفتح المجاني |
| محاسب (`accountant`) | `null` | `null` | لا صلاحية خصم |
| موارد بشرية (`hr`) | `null` | `null` | لا صلاحية خصم |

> **المالك:** PermissionEvaluator يُعيد true لكل شيء — لا يحتاج قيوداً في `RoleDefinitionModel`.

---

### 2.4 `ApplyDiscountParams` و `RemoveDiscountParams`

```dart
class ApplyDiscountParams extends Equatable {
  final String? bookingId;
  final DiscountTypeEnum? discountType;
  final num? discountValue;    // null للـ free
  final String? reason;        // إجباري
  final String? approvedByUserId;
}

class RemoveDiscountParams extends Equatable {
  final String? bookingId;
  final String? reason;        // إجباري
  final String? removedByUserId;
}
```

---

## 3. قواعد التحقق (Validation) — في `ApplyBookingDiscountUseCase` وسياسة الخصم

### 3.1 قواعد تطبيق الخصم على الحجز (`ApplyBookingDiscountUseCase`)

| القاعدة | الشرط | رسالة الخطأ |
|:---|:---|:---|
| `applyBookingDiscount` مطلوب | `PermissionEvaluator.can(applyBookingDiscount)` | — |
| الحجز ليس ملغياً | `booking.status != cancelled` | `disc_validation_cancelled_booking` |
| سبب الخصم مطلوب | `reason?.isNotEmpty == true` | `disc_validation_reason_required` |
| النسبة 0–100 | `percentage: 0 ≤ value ≤ 100` | `disc_validation_pct_range` |
| المبلغ ≤ السعر | `fixedAmount: value ≤ consultationFee` | `disc_validation_fixed_range` |
| **تحويل المبلغ لنسبة قبل مقارنة الحد:** | `effectivePct = (fixedAmount / fee) * 100` | — |
| **نسبة 100% أو مبلغ = السعر = مجاني:** | يُعامل كـ `free` → يتطلب `canGrantFreeConsultation` | `disc_validation_free_required` |
| الحد الأقصى (مع النسبة المحوّلة) | `effectivePct ≤ role.maxDiscountPercent` | `disc_validation_max_exceeded({limit})` |
| `canGrantFreeConsultation` لـ free | `role.canGrantFreeConsultation == true` | `disc_validation_free_required` |
| لا يجعل الصافي < المدفوع | `netAmount ≥ paidAmount` | `disc_validation_below_paid` |
| تعديل حجز بدون صلاحية خصم | لو `UpdateBookingUseCase` يحاول تغيير حقول الخصم | `disc_validation_no_permission` |

### 3.2 قواعد حوكمة سياسة الخصم في الـ Domain (المالك فقط)
> **قاعدة أمان حاسمة في الـ Domain:** تعديل `maxDiscountPercent` و `canGrantFreeConsultation` لأي دور (بما في ذلك الدور الخاص بالمستخدم أو أي دور آخر) **محصور حصرياً بالمالك (`user.isOwner == true`)**.
- **المنع الصارم:** حتى لو كان المستخدم يملك صلاحية إدارة الأدوار (`manageRolesAndPermissions`) مثل مدير الفرع، يُرفض تعديله لحقول سياسة الخصم رفضاً قاطعاً من الـ Domain عبر `Left(ServerFailure(errMessage: 'disc_policy_owner_only'))`.
- **الحماية في الاستدعاء العام:** أي استدعاء عام لـ `StaffUsersRepo.saveRole` أو `UpdateRoleUseCase` من قِبل مستخدم غير المالك **لا يُغيّر هذين الحقلين أبداً** ويحافظ على القيم المخزنة مسبقاً في الدور.

---

## 4. سياسة الخصم — Use Case وقسم في `RolePermissionsMatrixDialog`

### 4.1 Use Case مخصص: `UpdateRoleDiscountPolicyUseCase`
```dart
class UpdateRoleDiscountPolicyParams extends Equatable {
  final String roleId;
  final num? maxDiscountPercent;
  final bool? canGrantFreeConsultation;
  final String currentUserId;
}

class UpdateRoleDiscountPolicyUseCase implements UseCase<Unit, UpdateRoleDiscountPolicyParams> {
  final StaffUsersRepo staffUsersRepo;
  // يتحقق أولاً: هل currentUserId هو المالك؟ (isOwner == true)
  // إن لم يكن مالكاً → يرجع فوراً Left(ServerFailure(errMessage: 'disc_policy_owner_only'))
  // إن كان مالكاً → يحفظ السياسة ويسجل حدث Audit: discount_policy_changed
}
```

### 4.2 قسم "سياسة الخصم" في `RolePermissionsMatrixDialog`

**يُضاف قسم جديد "سياسة الخصم" في الـ Dialog الموجود:**
```
قسم "سياسة الخصم والمجاني":
─────────────────────────────────────────────────────
الحد الأقصى للخصم: [CustomTextFormField: % (0–100 أو 100 = بلا حد)]
السماح بالكشف المجاني: [Toggle: نعم / لا]
─────────────────────────────────────────────────────
```

**قيود الـ UI:**
- يظهر القسم فقط للمالك (`user.isOwner == true`).
- مدير الفرع لا يرى هذا القسم ولا يستطيع رفع حده الخاص أو حد أي دور آخر.
- عند الحفظ: يتم استدعاء `UpdateRoleDiscountPolicyUseCase` وتسجيل حدث `AuditLogger.log('discount_policy_changed', ...)`.

---

## 5. الصلاحيات والـ Audit

### 5.1 صلاحية جديدة
```dart
// تُضاف في مجموعة "4. Cashier & Financial Transactions":
applyBookingDiscount,
```

### 5.2 تحديث seed الصلاحيات في `defaultSystemRoles()`

| الدور | يُضاف `applyBookingDiscount` |
|:---|:---:|
| مدير فرع | ✅ |
| استقبال | ✅ |
| محاسب | ❌ |
| الباقي | ❌ |

### 5.3 أحداث الـ Audit

| `eventType` | يُطلق عند | الحقول المسجلة |
|:---|:---|:---|
| `booking_discount_applied` | تطبيق خصم | bookingId, discountType, discountValue, netAmount, reason, approvedByUserId |
| `booking_discount_removed` | إزالة خصم | bookingId, previousDiscountType, previousDiscountValue, removeReason, removedByUserId |
| `discount_policy_changed` | تعديل سياسة الخصم لدور | roleId, changedByUserId, oldMaxPct, newMaxPct, oldCanFree, newCanFree |

---

## 6. تأثير الخصم على الإحصائيات الموجودة

### 6.1 `BookingStatisticsCalculator`

```dart
// تغيير:
// قبل: sum(consultationFee) → بعد: sum(netAmount)

// إضافة:
int freeConsultationsCount;    // يستثني الملغيات
num totalDiscountsGiven;       // يستثني الملغيات
num totalNetRevenue;
```

### 6.2 `BookingSummaryModel` — حقول جديدة nullable

```dart
final num? totalDiscountsGiven;
final int? freeConsultationsCount;
final num? totalNetRevenue;
```

### 6.3 `effectivePaymentStatus` في الإحصائيات

```dart
// الحجز المجاني (isFreeConsultation == true):
//   → effectivePaymentStatus = paid
//   → لا يُحتسب في "المبالغ المتأخرة"
//   → يُحتسب في "إجمالي الكشوفات المكتملة"
//   → يُحتسب في freeConsultationsCount
```

---

## 7. تصميم الـ UI

### 7.1 `BookingDiscountSection` — في Dialog إضافة/تعديل الحجز
```
قسم "التسعير والخصم":
  السعر الأصلي: 300 جنيه (قراءة فقط)
  نوع الخصم: [CustomStackSelector: بدون خصم ▼ / نسبة % / مبلغ ثابت / مجاني]
  إن اختار نسبة: [CustomTextFormField: قيمة % (0–maxDiscountPercent)]
  إن اختار مبلغ: [CustomTextFormField: مبلغ ثابت]
  إن اختار مجاني: [CustomStackSelector: سبب الكشف المجاني ▼] (يظهر إن canGrantFreeConsultation)
  سبب الخصم: [CustomTextFormField] (مطلوب لأي خصم)
  الصافي: [يتحدث فورياً = getter محسوب، مُنسَّق بـ AppFormatterHelper.formatCurrency()]
```

**قيود الـ UI:**
- `BookingDiscountSection` يُخفى إن المستخدم لا يملك `applyBookingDiscount`
- خيار "مجاني" يُخفى إن `role.canGrantFreeConsultation != true`
- `maxDiscountPercent` يُقيَّد في الـ TextFormField (hint + validation)

### 7.2 `BookingPriceSummaryCard` — في `BookingDetailsPage`
```
┌─────────────────────────────────────────────────────┐
│  💰 الرسوم والدفع                                    │
│  السعر الأصلي          300 جنيه                     │
│  خصم (20%)            -60 جنيه                      │
│  الصافي               240 جنيه  (خط سميك)           │
│  المسدد               240 جنيه                     │
│  المتبقي              0 جنيه                       │
│  السبب: [سبب الخصم]                                 │
│  اعتمد بواسطة: [اسم] | [توقيت]                      │
└─────────────────────────────────────────────────────┘
```
إن `isFreeConsultation`: يعرض `FreeBookingBadge` بدل بادج الدفع + "الصافي: 0 جنيه".

### 7.3 `FreeBookingBadge`
```
📗 مجاني   (بادج أخضر/بنفسجي، في الجدول وتفاصيل الحجز)
```

---

## 8. مفاتيح الترجمة (prefix: `disc_`)

> ar-EG و en-US متطابقان عدداً وترتيباً.

### ar-EG.json
```json
{
  "disc_section_title": "الخصم",
  "disc_type_none": "بدون خصم",
  "disc_type_percentage": "خصم بنسبة %",
  "disc_type_fixed": "خصم بمبلغ ثابت",
  "disc_type_free": "مجاني",
  "disc_value_label": "قيمة الخصم",
  "disc_reason_label": "سبب الخصم (مطلوب)",
  "disc_reason_hint": "وضّح سبب الخصم",
  "disc_free_reason_humanitarian": "حالة إنسانية",
  "disc_free_reason_staff": "موظف / عائلة موظف",
  "disc_free_reason_colleague": "زمالة طبية",
  "disc_free_reason_charity": "مبادرة خيرية",
  "disc_free_reason_other": "أخرى",
  "disc_original_price": "السعر الأصلي",
  "disc_discount_amount": "الخصم",
  "disc_net_amount": "الصافي بعد الخصم",
  "disc_paid_amount": "المسدد",
  "disc_remaining": "المتبقي",
  "disc_approved_by": "اعتمد بواسطة",
  "disc_approved_at": "وقت الاعتماد",
  "disc_free_badge": "مجاني",
  "disc_validation_pct_range": "النسبة يجب أن تكون بين 0 و100",
  "disc_validation_fixed_range": "المبلغ يجب أن لا يتجاوز سعر الكشف",
  "disc_validation_reason_required": "سبب الخصم مطلوب",
  "disc_validation_free_reason_required": "سبب الكشف المجاني مطلوب",
  "disc_validation_free_required": "ليس لديك صلاحية منح الكشف المجاني",
  "disc_validation_max_exceeded": "تجاوز الحد الأقصى المسموح به ({limit}%)",
  "disc_validation_cancelled_booking": "لا يمكن تطبيق خصم على حجز ملغي",
  "disc_validation_below_paid": "لا يمكن تطبيق خصم يجعل الصافي أقل من المبلغ المسدد مسبقاً",
  "disc_validation_no_permission": "ليس لديك صلاحية تعديل حقول الخصم",
  "disc_applied_success": "تم تطبيق الخصم بنجاح",
  "disc_removed_success": "تم إزالة الخصم بنجاح",
  "disc_remove_confirm_title": "إزالة الخصم",
  "disc_remove_confirm_body": "هل أنت متأكد من إزالة الخصم؟ أدخل السبب:",
  "disc_remove_reason_label": "سبب الإزالة (مطلوب)",
  "disc_stats_total_discounts": "إجمالي الخصومات",
  "disc_stats_free_consultations": "الكشوفات المجانية",
  "disc_stats_net_revenue": "صافي الإيرادات",
  "disc_policy_title": "سياسة الخصم والمجاني",
  "disc_policy_max_pct": "الحد الأقصى للخصم (%)",
  "disc_policy_can_free": "السماح بالكشف المجاني",
  "disc_policy_changed_success": "تم تحديث سياسة الخصم بنجاح",
  "disc_policy_owner_only": "يمكن للمالك فقط تعديل سياسة الخصم"
}
```

### en-US.json
```json
{
  "disc_section_title": "Discount",
  "disc_type_none": "No Discount",
  "disc_type_percentage": "Percentage Discount",
  "disc_type_fixed": "Fixed Amount Discount",
  "disc_type_free": "Free Consultation",
  "disc_value_label": "Discount Value",
  "disc_reason_label": "Discount Reason (Required)",
  "disc_reason_hint": "Explain the reason for this discount",
  "disc_free_reason_humanitarian": "Humanitarian Case",
  "disc_free_reason_staff": "Staff / Staff Family",
  "disc_free_reason_colleague": "Medical Colleague",
  "disc_free_reason_charity": "Charity Initiative",
  "disc_free_reason_other": "Other",
  "disc_original_price": "Original Price",
  "disc_discount_amount": "Discount",
  "disc_net_amount": "Net After Discount",
  "disc_paid_amount": "Amount Paid",
  "disc_remaining": "Remaining",
  "disc_approved_by": "Approved By",
  "disc_approved_at": "Approved At",
  "disc_free_badge": "Free",
  "disc_validation_pct_range": "Percentage must be between 0 and 100",
  "disc_validation_fixed_range": "Amount must not exceed the consultation fee",
  "disc_validation_reason_required": "Discount reason is required",
  "disc_validation_free_reason_required": "Free consultation reason is required",
  "disc_validation_free_required": "You are not authorized to grant free consultations",
  "disc_validation_max_exceeded": "Exceeds the maximum allowed discount ({limit}%)",
  "disc_validation_cancelled_booking": "Cannot apply discount to a cancelled booking",
  "disc_validation_below_paid": "Cannot apply a discount that makes the net amount less than the amount already paid",
  "disc_validation_no_permission": "You are not authorized to modify discount fields",
  "disc_applied_success": "Discount applied successfully",
  "disc_removed_success": "Discount removed successfully",
  "disc_remove_confirm_title": "Remove Discount",
  "disc_remove_confirm_body": "Are you sure you want to remove the discount? Please enter the reason:",
  "disc_remove_reason_label": "Removal Reason (Required)",
  "disc_stats_total_discounts": "Total Discounts Given",
  "disc_stats_free_consultations": "Free Consultations",
  "disc_stats_net_revenue": "Net Revenue",
  "disc_policy_title": "Discount Policy",
  "disc_policy_max_pct": "Maximum Discount (%)",
  "disc_policy_can_free": "Allow Free Consultations",
  "disc_policy_changed_success": "Discount policy updated successfully",
  "disc_policy_owner_only": "Only the owner can modify discount policy"
}
```

---

## 9. خطة الاختبارات

### M-1: Models والـ Validation
**الملف:** `test/features/bookings/discount_model_test.dart`
```
T1: DiscountTypeEnum.fromValue('free') = DiscountTypeEnum.free
T2: DiscountTypeEnum.fromValue(null) = DiscountTypeEnum.none
T3: BookingModel.netAmount = consultationFee إن discountType = none
T4: BookingModel.netAmount = 0 إن discountType = free
T5: BookingModel.netAmount = consultationFee * (1 - 20/100) لخصم 20%
T6: BookingModel.netAmount = consultationFee - fixedAmount لخصم ثابت
T7: BookingModel.discountAmount لا يتجاوز consultationFee أبداً (clamp)
T8: BookingModel.isFreeConsultation = true إن discountType = free
T9: BookingModel.isFreeConsultation = true إن percentage = 100
T10: BookingModel.isFreeConsultation = true إن fixedAmount = consultationFee
T11: BookingModel.effectivePaymentStatus = paid إن isFreeConsultation
T12: BookingModel.effectivePaymentStatus = unpaid بعد إزالة الخصم (paymentStatus مخزنة = unpaid)
T13: BookingModel.copyWith() يحافظ على حقول الخصم غير المحددة
```

**الملف:** `test/features/bookings/discount_validation_test.dart`
```
T1: نسبة 101% → Left(Failure: validation error)
T2: مبلغ ثابت أكبر من consultationFee → Left(Failure)
T3: خصم بدون سبب → Left(Failure: reason_required)
T4: كشف مجاني بدون سبب → Left(Failure: free_reason_required)
T5: خصم على حجز cancelled → Left(Failure: cancelled_booking)
T6: خصم نسبة 30% والدور max 20% → Left(Failure: max_exceeded)
T7: مبلغ ثابت 150 من سعر 300 (= 50%) والدور max 20% → Left(Failure: max_exceeded) [التحويل لنسبة قبل المقارنة]
T8: نسبة 100% أو مبلغ = السعر + دور بدون canGrantFree → Left(Failure: free_required)
T9: نسبة 100% + دور canGrantFree = true → Right(success)
T10: خصم ثابت يجعل netAmount < paidAmount → Left(Failure: below_paid)
T11: استقبال بـ maxDiscount=20 يطبق خصم 15% → Right(success)
T12: مالك (isOwner) → لا حد أقصى → Right(success) لأي نسبة ≤ 100
T13: تعديل حقل discountType في UpdateBookingUseCase بدون applyBookingDiscount → Left(Failure: no_permission)
```

**الملف:** `test/features/users_management/role_discount_policy_test.dart`
```
T1: مدير الفرع يحاول رفع حده الخاص للخصم → Left(Failure: disc_policy_owner_only)
T2: مدير الفرع يحاول رفع حد الاستقبال للخصم → Left(Failure: disc_policy_owner_only)
T3: مستخدم غير المالك يستدعي saveRole لتعديل اسم الدور → ينجح ولكن maxDiscountPercent و canGrantFree لا يتغيران
T4: المالك (isOwner == true) يستدعي UpdateRoleDiscountPolicyUseCase لرفع حد الاستقبال إلى 30% → Right(Unit: نجاح)
T5: المالك يسمح بالكشف المجاني لدور الاستقبال → Right(Unit: نجاح)
```

### M-2: BookingsMockRepoImpl والـ Saga
**الملف:** `test/features/bookings/discount_repo_test.dart`
```
T1: applyDiscount يُحدّث discountType, discountValue, discountReason, discountApprovedAt
T2: removeDiscount يُصفَّر discountType → none ويُسجَّل discountRemovedReason
T3: removeDiscount لحجز مجاني → effectivePaymentStatus يرجع لـ unpaid
T4: BookingStatisticsCalculator يستخدم netAmount بدل consultationFee
T5: freeConsultationsCount يستثني الملغيات
T6: totalDiscountsGiven = مجموع discountAmount للحجوزات غير الملغية
T7: تغيير consultationFee على حجز له خصم → يُعاد التحقق، الخصم يُصفَّر إن أصبح غير صالح
```

### M-3: Widget Tests
**الملف:** `test/features/bookings/discount_ui_test.dart`
```
T1: BookingDiscountSection يظهر إن المستخدم يملك applyBookingDiscount
T2: BookingDiscountSection مخفي إن لا صلاحية
T3: خيار "مجاني" مخفي إن canGrantFreeConsultation = false
T4: اختيار "نسبة %" يُظهر حقل إدخال القيمة
T5: اختيار "مجاني" يُظهر CustomStackSelector لأسباب المجاني
T6: الصافي يتحدث فورياً عند إدخال النسبة
T7: FreeBookingBadge يظهر في الجدول لو isFreeConsultation = true
T8: BookingPriceSummaryCard يعرض الصافي بالخط السميك بـ AppFormatterHelper
T9: قسم "سياسة الخصم" يظهر في RolePermissionsMatrixDialog فقط للمالك
```

---

## 10. ترتيب التنفيذ (Milestones)

### M-1: Models والـ Domain Logic (يوم 1)
1. إنشاء `DiscountTypeEnum`.
2. تعديل `RoleDefinitionModel` (+`maxDiscountPercent`, `canGrantFreeConsultation`).
3. تحديث seed `defaultSystemRoles()` بالقيم الافتراضية.
4. تعديل `BookingModel` (+6 حقول + 4 getters).
5. إنشاء `ApplyDiscountParams`, `RemoveDiscountParams`.
6. إنشاء `ApplyBookingDiscountUseCase` بكل الـ validations.
7. إنشاء `RemoveBookingDiscountUseCase`.
8. إضافة `applyBookingDiscount` لـ `StaffPermissionEnum` + seed roles.
9. كتابة اختبارات (discount_model_test, discount_validation_test).
10. `flutter analyze` = 0 | `flutter test` = 100%.
11. Commit: `feat(B-DISC-M1): discount model, validation, use cases`

### M-2: Data & Statistics (يوم 2)
1. تعديل `BookingsRepo` interface (+`applyDiscount`, `removeDiscount`).
2. تعديل `BookingsMockRepoImpl` بتنفيذ الـ methods + guard تعديل السعر.
3. تعديل `BookingStatisticsCalculator` لاستخدام `netAmount`.
4. تعديل `BookingSummaryModel` (+discount fields).
5. تحديث `BookingsCubit` (+`applyDiscount`, `removeDiscount`).
6. إضافة مفاتيح الترجمة ar-EG و en-US.
7. كتابة اختبارات (discount_repo_test).
8. `flutter analyze` = 0 | `flutter test` = 100%.
9. Commit: `feat(B-DISC-M2): discount in repo, stats calculator, Cubit`

### M-3: UI (يوم 2-3)
1. إنشاء `BookingDiscountSection`, `BookingPriceSummaryCard`, `FreeBookingBadge`.
2. تعديل Dialog إضافة/تعديل الحجز (+`BookingDiscountSection`).
3. تعديل `BookingDetailsPage` (+`BookingPriceSummaryCard`).
4. تعديل `role_permissions_matrix_dialog.dart` (+قسم سياسة الخصم — للمالك فقط).
5. كتابة اختبارات (discount_ui_test).
6. `flutter analyze` = 0 | `flutter test` = 100%.
7. Commit: `feat(B-DISC): booking discount system — percentage, fixed, free, policy`

---

## 11. قرارات مغلقة

| القرار | الحل |
|:---|:---|
| Q1: `maxDiscountPercent` | يُضاف لـ `RoleDefinitionModel` كـ nullable. null = لا خصم (fail-closed). |
| Q2: `PaymentStatusEnum.free` | **لا تُضاف**. بدلاً منها getter `effectivePaymentStatus` + `isFreeConsultation` + `FreeBookingBadge`. |
| Q3: عمولة الطبيب | **تُحسب دائماً على `netAmount`** (بعد الخصم). مثال: كشف 300 بخصم 20% = عمولة على 240. موثَّق كقرار. |
| Q4: سؤال مؤجل لـ F-06 | الأطباء بأجر ثابت لكل كشف — هل يُدفع عن الكشف المجاني (netAmount = 0)؟ قرار مطلوب قبل بدء F-06. |

---

## 12. مخاطر

| المخاطرة | التأثير | التخفيف |
|:---|:---|:---|
| تعديل `BookingModel.copyWith()` يكسر اختبارات قائمة | متوسط | إضافة nullable بدون `required` — الاختبارات القائمة لا تتأثر |
| تعديل `BookingStatisticsCalculator` يغير قيم الاختبارات القائمة | عالٍ | مراجعة كل اختبار يعتمد على إجماليات مالية قبل الـ commit |
| تعديل `RoleDefinitionModel` يكسر seed الأدوار القائمة | منخفض | الحقلان nullable — البيانات الموجودة لا تتأثر، seed يُحدَّث يدوياً |
| الـ `effectivePaymentStatus` getter مكسور في الاختبارات | منخفض | اختبارات صريحة لكل حالة (T11, T12 في discount_model_test) |

---

**الخطوة التالية:** وافق على الخطتين ← أبدأ فوراً بـ F-04a M-1.

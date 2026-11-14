# خطة تنفيذ فيتشر F-06: الموارد البشرية وتسويات الأطباء ومسير الرواتب (محدّثة)
# HR & Doctor Settlements and Staff Payroll Plan (Patched)

> **المرجع الحاكم:** `docs/AGENT_OPERATING_GUIDE.md` و `docs/DECISIONS.md` و `docs/plans/PKG-AB-integration-contract.md`
> **الحالة:** 📝 وثيقة خطة تفصيلية معتمدة ومحدّثة بباتش الأساس المحصل والحوكمة والخصوصية
> **تاريخ التحديث:** 14 نوفمبر 2026

---

## 1. المراجعة الذاتية والملخص التنفيذي (Executive Summary & Self-Review)

تهدف فيتشر **F-06** إلى بناء منظومة متكاملة لحساب وتسوية أتعاب الأطباء (Doctor Settlements) على الأساس المحصل الفعلي، وإدارة حركات الموظفين والأطباء المالية عبر دفتر أستاذ ملحق (Employee Ledger)، وإدارة قواعد الأجر المرنة لكل (طبيب، فرع)، وإصدار مسير الرواتب الشهري لطاقم العمل (Staff Payroll)، مع دعم الطباعة المتكيفة (A4 و حراري 80 مم)، وحوكمة صارمة تعتمد على مبدأ عدم التكرار (Idempotency) وحفظ اللقطات الثابتة (Snapshots) غير القابلة للتعديل الرجعي (Append-only)، مع عزل كامل للفروع ومراعاة خصوصية البيانات والتدقيق الأمني الخالي تماماً من أي نصوص سريرية أو أسماء مرضى.

### 1.1 الثوابت المعمارية والقرارات المقفولة:
1. **أساس احتساب العمولة = الأساس المحصل (Cash-Collected Basis):**
   - العمولة تُحسب قطيعاً على **أحداث التحصيل والاسترداد المعترف بها داخل الفترة** (بتوقيت القاهرة) للكشوفات المنتهية (`finalized`) حصراً، وليس على إجمالي الفاتورة أو السعر المفوتر.
   - **تاريخ الاعتراف بالحدث:** هو الأحدث بين: $\max(\text{تاريخ الدفعة أو الاسترداد}, \text{finalizedAt})$.
   - التحصيل المسبق قبل إنهاء الكشف يُعترف به محاسبياً لحظة إنهاء الكشف (`finalizedAt`).
   - الاسترداد بعد اعتماد التسوية يُعترف به كحدث سالب في فترة حدوث الاسترداد تلقائياً، دون حاجة لآلية تعويض خاصة لهذه الحالة، وتبقى حركات التسوية (`adjustment`) للتصحيحات اليدوية فقط.
   - **استهلاك الأحداث لمرة واحدة فقط:** كل حدث تحصيل أو استرداد يدخل تسوية مؤكدة واحدة فقط؛ حيث تُسجل معرفات الأحداث المستهلكة (`consumedEventIds`) داخل لقطة التسوية، وتُستثنى من أي مسودات أو تسويات لاحقة.
   - **النسبة المئوية والتقريب:** نصيب الطبيب = مجموع أحداث الفترة $\times$ النسبة، بقاعدة تقريب النصف للأعلى (Round half-up) على كل عملية بدقة القروش `Money` لمنع الانجراف الحسابي (Accumulation Drift) عند تجميع مئات الحركات الصغيرة.
   - **المبلغ الثابت لكل كشف (`fixedPerVisit`):** يُعترف به فقط عندما يبلغ صافي المحصل (المقبوضات ناقص الاستردادات) كامل صافي الكشف (`netAmount`). ويُعكس سلباً في فترة الاسترداد إذا نزل المحصل دون الصافي. والكشف المجاني (`netAmount == 0`) لا يُدفع عنه أي مقابل إلا إذا نصت قاعدة الطبيب صراحة على `payForFreeVisits = true`.
2. **نطاق التسوية وقواعد الأجر لكل (طبيب، فرع، فترة):**
   - التسوية تصدر لنطاق محدد: `(doctorId, branchId, period)`.
   - قاعدة الأجر معرفة بدقة لكل `(doctorId, branchId)` بتاريخ سريان (`effectiveFrom`)، ولا توجد أي قاعدة بدون فرع.
   - الراتب الشهري الثابت (`monthlyBaseSalaryPiastres`) يأتي من قاعدة الفرع فقط، فلا يتكرر مطلقاً عبر الفروع.
   - غياب قاعدة أجر معتمدة سارية للطبيب في ذلك الفرع يمنع احتساب التسوية فوراً بنظام الإغلاق الآمن (Fail-Closed) مع إظهار رسالة خطأ واضحة.
   - تداخل أي تسوية جديدة مع فترة تسوية مؤكدة سابقة لنفس الطبيب والفرع ممنوع قطيعاً.
3. **إدارة قواعد الأجر (Compensation Rules Management):**
   - توفير واجهة مخصصة (تبويب وحوار إدارة القواعد بصفحة HR)، مع حالة استخدام `SaveDoctorCompensationRuleUseCase`.
   - الصلاحية محصورة في `StaffPermissionEnum.manageCompensationRules` (المالك ومسؤول HR فقط، ومحجوبة عن مدير الفرع والمحاسب).
   - قيود التحقق: النسبة بين $0-100\%$, المبالغ $\ge 0$ قرشاً، وحظر التعديل بأثر رجعي (تاريخ السريان لا يجوز أن يقع ضمن فترة تسوية مؤكدة سابقة).
   - صدور حدث تدقيق أمني `compensation_rule_saved` بمعرفات وأرقام فقط.
4. **حوكمة السلف ودفتر الأستاذ (Advances & Ledger Governance):**
   - رصيد السلف يُحسب حركياً من دفتر الأستاذ ولا يُخزن في حقل مستقل.
   - **سياسة الخصم من التسوية:** مبلغ الخصم = $\min(\text{رصيد السلف المستحق}, \text{المستحق للطبيب قبل الخصم})$. الصافي لا يكون سالباً، وأي رصيد متبقٍ يبقى في ذمة الطبيب للفترات اللاحقة. (نظام الأقساط المجدولة مؤجل).
   - **حذف حقلي `isSettled` و `settlementId` من نموذج قيد الدفتر:** القيد يظل غير قابل للتعديل (`append-only`)، والارتباط بالتسوية يُشتق حركياً من لقطة التسوية (`consumedAdvanceEntryIds`).
   - **التصحيح بالقيد العكسي:** تصحيح أي قيد خاطئ يتم عبر إنشاء قيد عكسي يحمل معرف الأصل `reversesEntryId` وسبباً توثيقياً إلزامياً، لمرة واحدة فقط لكل قيد، وبما لا يتجاوز مبلغ القيد الأصلي. ولا يجوز عكس قيد صرف (`payout`)، بل يُصحح بتسوية يدوية (`adjustment`).
5. **الاعتماد الصارم على Enums وتجريد النصوص:**
   - نوع الموظف: `EmployeeTypeEnum` (`doctor`, `staff`).
   - وسيلة الدفع: استخدام `PaymentMethod` المعتمد في الـ Core (`cash`, `bankTransfer`) مع تأجيل الشيك.
   - حالة الدفع: `PaymentStatusEnum` المعتمد في الحجوزات.
   - فلاتر الشاشة: استخدام قيم `nullable` بدلاً من النص `"all"`.
   - دوال التحويل `fromValue` آمنة مع قيم افتراضية واضحة.
6. **حماية الخصوصية والبيانات المالية:**
   - حذف `bankAccountNumber` و `bankName` من نموذج `StaffPayrollProfileModel`؛ وسيلة الدفع تسجل فقط لحظة الصرف الفعلي.
   - وثائق الطباعة تخلو تماماً من أسماء المرضى (تقتصر على معرف الكشف والتاريخ والخدمة).
   - تفاصيل الكشوفات على الشاشة تظهر الأسماء فقط للمصرح لهم إدارياً وسريرياً.
   - `HrCubit` لا يحمّل ولا يخزن في الـ State أي بيانات رواتب أو ملفات مالية لمن لا يملك صلاحية عرضها.
7. **الضرائب والتأمينات:**
   - تعامل كمدخلات مادية يدوية بمبالغ صحيحة (`Money`)، دون أي ادعاء لاحتساب قانوني أو شرائحي في الواجهات أو الوثائق، مع تسجيل أن الامتثال الضريبي خارج النطاق.
8. **مسير رواتب الموظفين (Staff Payroll Scope):**
   - نطاق المسير: فرع الموظف الأساسي (`primaryBranchId`) وشهر محدد، ولا يتكرر لنفس الفرع والشهر.
   - مدير الفرع لا يرى رواتب الطاقم العام.
9. **الـ Seed والتوقيت الحتمي:**
   - التسويات التاريخية المزروعة تحمل علامة `source = mockSeed` وتُستبعد صراحة من اختبارات مطابقة الكشوفات بالدفتر ومن حسابات الإيراد العام.
   - جميع اختبارات HR تعتمد على الساعة الثابتة `CairoTimeHelper.setFixedClock`.
   - قيم قواعد أجر الأطباء في الـ Seed هي عينات تجريبية لا تمثل توصيات تسعيرية.
10. **الطباعة المتكيفة:**
    - إضافة نوعي المستند `doctorSettlementSheet` و `staffPayrollSheet` لـ `PrintDocumentType` وإعدادهما في تبويب إعدادات الطباعة.
    - كشف تسوية الطبيب يدعم A4 والحراري 80 مم (ملخص).
    - مسير رواتب الموظفين يدعم A4 (أفقي) فقط؛ وإذا ضُبط حرارياً يسقط تلقائياً على A4 بسلوك موثق واختبار معتمد.
11. **التوقيت الصيفي المصري (DST Transitions):**
    - التحقق من سلوك `CairoTimeHelper` وحدود الفترات والشهور حول مواعيد التغيير في مصر (آخر جمعة من أبريل UTC+3، وآخر خميس من أكتوبر UTC+2).
12. **الصلاحيات والـ RBAC:**
    - إضافة `manageCompensationRules` للأدوار المصرح لها (`owner`, `hr`) دون تعديل أي صلاحية سابقة.
    - العزل الدوميني الصارم: مدير الفرع محصور بفرعه، المالك والمحاسب وHR للكل، الطبيب يرى تسويته فقط عبر `linkedDoctorId`.
    - المعتمد $\neq$ الطبيب، مع استثناء المالك الفردي بحدث `owner_self_confirmed` وسبب إلزامي.
13. **تطابق الاختبارات والـ Milestones:**
    - ربط كل ملف اختبار بـ Milestone واحد بدقة وتطابق تام في المجاميع (170 اختباراً موزعاً على 9 مراحل).
14. **الترجمة الكاملة:**
    - استكمال كافة المفاتيح الناقصة ببادئة `hr_` بتطابق تام بين `ar-EG.json` و `en-US.json`.

---

## 2. الوضع الحالي والمكونات القابلة لإعادة الاستخدام (Current State & Reusable Components)

- **صفحة HR الحالية:** `lib/features/hr/presentation/pages/hr_page.dart` (Skeleton تمهيدي).
- **مسار الراوتر:** `AppRouter.hr` (`/hr`) محمي بصلاحية `StaffPermissionEnum.accessHr`.
- **الشريط الجانبي:** `nav_hr` ضمن مجموعة "فريق العمل" (`nav_group_team`).
- **الأطباء الستة الرسميون:** `DOC-01` إلى `DOC-06` في `DoctorsMockRepoImpl`.
- **التوقيت القابل للحقن:** `CairoTimeHelper.now()` مع `setFixedClock` و `resetFixedClock`.
- **كائن القيمة المالي:** `Money` و `MoneyHelper` في `lib/features/cashier/domain/helpers/money.dart`.
- **منظومة الطباعة:** `PrintFormat` و `PrintDocumentType`.
- **الطاقم:** `StaffUserModel` وخاصية `linkedDoctorId`.
- **الحجوزات والخصومات:** `BookingModel` وحقول `netAmount`, `discountAmount`, `isFreeConsultation`.
- **الكشوفات الطبية:** `VisitModel` بحالة `finalized` وتوقيت `finalizedAt`.

---

## 3. قائمة الملفات الجديدة والمعدلة بمسارات متحقق منها (Verified File Manifest)

### 3.1 ملفات جديدة ستُنشأ داخل `lib/features/hr/`:

#### نماذج البيانات والـ Enums:
1. `lib/features/hr/data/models/enums/compensation_type_enum.dart`
2. `lib/features/hr/data/models/enums/settlement_status_enum.dart`
3. `lib/features/hr/data/models/enums/ledger_entry_type_enum.dart`
4. `lib/features/hr/data/models/enums/payroll_status_enum.dart`
5. `lib/features/hr/data/models/enums/employee_type_enum.dart`
6. `lib/features/hr/data/models/doctor_compensation_rule_model.dart`
7. `lib/features/hr/data/models/doctor_settlement_model.dart`
8. `lib/features/hr/data/models/doctor_settlement_item_model.dart`
9. `lib/features/hr/data/models/employee_ledger_entry_model.dart`
10. `lib/features/hr/data/models/staff_payroll_profile_model.dart`
11. `lib/features/hr/data/models/staff_payroll_period_model.dart`
12. `lib/features/hr/data/models/staff_payroll_item_model.dart`
13. `lib/features/hr/data/repo/hr_mock_repo_impl.dart`

#### عقود وحسابات وحالات استخدام الدومين:
14. `lib/features/hr/domain/contracts/doctor_settlement_visits_lookup.dart`
15. `lib/features/hr/domain/contracts/cashier_settlement_lookup.dart`
16. `lib/features/hr/domain/helpers/doctor_settlement_calculator.dart`
17. `lib/features/hr/domain/helpers/staff_payroll_calculator.dart`
18. `lib/features/hr/domain/repo/hr_repo.dart`
19. `lib/features/hr/domain/use_cases/get_doctor_compensation_rules_use_case.dart`
20. `lib/features/hr/domain/use_cases/save_doctor_compensation_rule_use_case.dart`
21. `lib/features/hr/domain/use_cases/get_doctor_settlements_use_case.dart`
22. `lib/features/hr/domain/use_cases/calculate_doctor_settlement_use_case.dart`
23. `lib/features/hr/domain/use_cases/confirm_doctor_settlement_use_case.dart`
24. `lib/features/hr/domain/use_cases/payout_doctor_settlement_use_case.dart`
25. `lib/features/hr/domain/use_cases/add_employee_ledger_entry_use_case.dart`
26. `lib/features/hr/domain/use_cases/reverse_employee_ledger_entry_use_case.dart`
27. `lib/features/hr/domain/use_cases/get_employee_ledger_use_case.dart`
28. `lib/features/hr/domain/use_cases/get_staff_payroll_profiles_use_case.dart`
29. `lib/features/hr/domain/use_cases/save_staff_payroll_profile_use_case.dart`
30. `lib/features/hr/domain/use_cases/generate_staff_payroll_period_use_case.dart`
31. `lib/features/hr/domain/use_cases/confirm_staff_payroll_period_use_case.dart`
32. `lib/features/hr/domain/use_cases/payout_staff_payroll_period_use_case.dart`

#### إدارة الحالة والعرض والطباعة:
33. `lib/features/hr/presentation/manager/hr_cubit.dart`
34. `lib/features/hr/presentation/manager/hr_state.dart`
35. `lib/features/hr/presentation/widgets/hr_tabs_bar.dart`
36. `lib/features/hr/presentation/widgets/doctor_settlements_tab.dart`
37. `lib/features/hr/presentation/widgets/doctor_compensation_rules_tab.dart`
38. `lib/features/hr/presentation/widgets/staff_payroll_tab.dart`
39. `lib/features/hr/presentation/widgets/employee_ledger_tab.dart`
40. `lib/features/hr/presentation/widgets/doctor_settlement_card.dart`
41. `lib/features/hr/presentation/widgets/doctor_settlement_table.dart`
42. `lib/features/hr/presentation/widgets/dialogs/settlement_breakdown_dialog.dart`
43. `lib/features/hr/presentation/widgets/dialogs/add_ledger_entry_dialog.dart`
44. `lib/features/hr/presentation/widgets/dialogs/reverse_ledger_entry_dialog.dart`
45. `lib/features/hr/presentation/widgets/dialogs/confirm_settlement_dialog.dart`
46. `lib/features/hr/presentation/widgets/dialogs/payout_settlement_dialog.dart`
47. `lib/features/hr/presentation/widgets/dialogs/save_compensation_rule_dialog.dart`
48. `lib/features/hr/presentation/widgets/dialogs/staff_payroll_profile_dialog.dart`
49. `lib/features/hr/presentation/helpers/adaptive_doctor_settlement_pdf_generator.dart`
50. `lib/features/hr/presentation/helpers/adaptive_staff_payroll_pdf_generator.dart`

### 3.2 ملفات موجودة سيتم تعديلها:
1. `lib/core/enums/print_document_type.dart` — إضافة `doctorSettlementSheet`, `staffPayrollSheet`.
2. `lib/core/enums/staff_permission_enum.dart` — إضافة الصلاحيات المقترحة.
3. `lib/features/users_management/data/models/role_definition_model.dart` — تحديث الأدوار في `defaultSystemRoles()` دون مساس بالقائم.
4. `lib/core/dependency_injection/dependency_injection.dart` — تسجيل كافة توابع F-06.
5. `lib/features/hr/presentation/pages/hr_page.dart` — الواجهة التفاعلية الكاملة.
6. `assets/translations/ar-EG.json` و `assets/translations/en-US.json` — القاموس الموحد.
7. `docs/plans/handover/WHAT_IS_MISSING.md` — تسجيل المؤجلات وتحديث الحالة.

---

## 4. النماذج وهيكلية الحالة المحدثة (Models & State Architecture)

### 4.1 تفاصيل النماذج المالية الدقيقة:

#### `DoctorCompensationRuleModel`:
- `String? id`, `String? doctorId`, `String? branchId` (إلزامي للفرع), `CompensationTypeEnum? compensationType`, `num? commissionPercentage`, `int? fixedAmountPerVisitPiastres`, `int? monthlyBaseSalaryPiastres`, `DateTime? effectiveFrom`, `DateTime? createdAt`, `bool? isActive`, `bool? payForFreeVisits`, `String? notes`.

#### `DoctorSettlementModel`:
- `String? id`, `String? settlementNumber` (`SET-DOC-YYYYMM-XXX`), `String? doctorId`, `String? doctorName`, `String? branchId` (إلزامي للفرع), `DateTime? periodStart`, `DateTime? periodEnd`, `SettlementStatusEnum? status`, `int? totalVisitsCount`, `int? totalNetRevenuePiastres`, `int? totalDoctorCommissionPiastres`, `int? totalClinicSharePiastres`, `int? baseSalaryPiastres`, `int? totalBonusesPiastres`, `int? totalDeductionsPiastres`, `int? totalAdvancesDeductedPiastres`, `int? netPayablePiastres`, `DoctorCompensationRuleModel? compensationRuleSnapshot`, `List<DoctorSettlementItemModel>? items`, `List<String>? consumedEventIds`, `List<String>? consumedAdvanceEntryIds`, `String? confirmedByUserId`, `DateTime? confirmedAt`, `DateTime? paidAt`, `PaymentMethod? paymentMethod`, `String? paymentReferenceNumber`, `bool? isOwnerSelfConfirmed`, `String? source` (`null` أو `mockSeed`), `DateTime? createdAt`.

#### `DoctorSettlementItemModel`:
- `String? visitId`, `String? bookingId`, `DateTime? recognitionDate`, `String? branchId`, `String? patientId`, `String? patientName` (للعرض المصرح فقط), `String? serviceName`, `int? grossFeePiastres`, `int? discountAmountPiastres`, `int? netAmountPiastres`, `int? recognizedAmountPiastres`, `num? commissionPercentageSnapshot`, `int? fixedFeeSnapshotPiastres`, `int? doctorEarnedPiastres`, `int? clinicSharePiastres`, `PaymentStatusEnum? paymentStatusSnapshot`, `bool? isFullyCollected`, `List<String>? eventIds`.

#### `EmployeeLedgerEntryModel`:
- `String? id`, `String? employeeId`, `EmployeeTypeEnum? employeeType`, `String? branchId`, `LedgerEntryTypeEnum? entryType`, `int? amountPiastres`, `String? reason`, `DateTime? date`, `String? performedByUserId`, `String? clientRequestId`, `String? reversesEntryId`, `DateTime? createdAt`.
- *(حُذف حقلا `isSettled` و `settlementId` لضمان مبدأ عدم التعديل الرجعي).*

#### `StaffPayrollProfileModel`:
- `String? id`, `String? staffUserId`, `String? fullName`, `String? jobTitle`, `String? primaryBranchId`, `int? baseSalaryPiastres`, `int? housingAllowancePiastres`, `int? transportationAllowancePiastres`, `int? insuranceDeductionPiastres`, `int? taxDeductionPiastres`, `bool? isActive`, `DateTime? updatedAt`.
- *(حُذف حقلا `bankAccountNumber` و `bankName` لحماية الخصوصية المالية).*

#### `StaffPayrollPeriodModel` & `StaffPayrollItemModel`:
- نطاق المسير محكم لكل `(primaryBranchId, month, year)`، ولا يتكرر إطلاقا لنفس الفرع والشهر.

---

## 5. الحسابات المحصلة والتعامل مع التوقيت الصيفي (Collected Basis & DST Math)

### 5.1 معادلة الاعتراف المالي بالكشوفات:
1. **تاريخ الاعتراف بالحدث:**
   $$\text{RecognitionDate} = \max(\text{TransactionDate}, \text{Visit.finalizedAt})$$
2. **التحصيل قبل الإنهاء:**
   - الحجز `MED-104` دُفعت قيمته (150 ج.م) قبل بدء الكشف في `08:45`، وأُنهي الكشف في `09:25`.
   - تاريخ الاعتراف المحاسبي هو `09:25`.
3. **الاسترداد بعد اعتماد التسوية:**
   - يدرج كحدث سالب في الشهر الذي حدث فيه الاسترداد، فيُنقص عمولة الطبيب في تسوية ذلك الشهر تلقائياً.
4. **المبلغ الثابت لكل كشف:**
   - لا يستحق الطبيب المبلغ الثابت إلا إذا كان: $\text{TotalNetCollected} \ge \text{netAmount}$.
   - وإذا حدث استرداد نزل بالرصيد دون الصافي، يُعكس المبلغ الثابت سلباً في فترة الاسترداد.

### 5.2 اختبار التوقيت الصيفي المصري (DST Handling):
- مصر تطبق التوقيت الصيفي (تقديم الساعة 60 دقيقة في آخر جمعة من أبريل UTC+3، وتأخيرها في آخر خميس من أكتوبر UTC+2).
- `CairoTimeHelper` يحسب الفارق بدقة عبر جدول تحويل الساعات الحتمي.
- يتم تضمين اختبارات حتمية تثبت:
  - كشف منجز الساعة `23:45` ليلة التحويل يدخل في اليوم الصحيح.
  - حساب حدود الشهر (من `01 00:00:00` إلى آخر لحظة في الشهر `23:59:59`) لا يتأثر بتغير إزاحة التوقيت بين الصيف والشتاء.

---

## 6. مصفوفة الصلاحيات والحوكمة المحدثة (RBAC Matrix)

| الإجراء / العملية | الصلاحية المطلوبة | الأدوار المصرح لها نظامياً | قيود العزل الدوميني والحوكمة |
| :--- | :--- | :--- | :--- |
| **دخول صفحة HR** | `accessHr` | مدير الفرع، المحاسب، مسؤول HR، المالك | فتح الشاشة والقائمة |
| **عرض تسويات الأطباء** | `viewDoctorSettlements` | مدير الفرع (فرعه فقط)، المحاسب، مسؤول HR، المالك | مدير الفرع معزول تماماً عن الفروع الأخرى |
| **احتساب مسودة التسوية** | `calculateDoctorSettlement` | مدير الفرع (فرعه فقط)، المحاسب، مسؤول HR، المالك | احتساب أحداث الفترة غير المستهلكة |
| **تأكيد وقفل التسوية** | `confirmDoctorSettlement` | مدير الفرع (فرعه فقط)، المحاسب، المالك | المعتمد $\neq$ الطبيب (باستثناء المالك الفردي) |
| **تسجيل صرف التسوية** | `payoutSettlement` | المحاسب، المالك فقط (**وليس مدير الفرع**) | تسجيل الصرف بالدفتر |
| **إدارة قواعد الأجر** | `manageCompensationRules` | مسؤول HR، المالك فقط (**وليس مدير الفرع**) | النسبة 0-100، لا أثر رجعي |
| **إدارة دفتر السلف والخصم** | `manageEmployeeLedger` | مدير الفرع (فرعه فقط)، المحاسب، مسؤول HR، المالك | تسجيل سلفة/خصم وقيد عكسي مبرر |
| **عرض الطبيب لتسويته** | `viewOwnDoctorSettlement` | **طبيب** (`doctor`)، والمالك | **يرى تسوياته المؤكدة فقط عبر linkedDoctorId** |
| **إدارة مسير رواتب الطاقم** | `manageStaffPayroll` | مسؤول HR، المحاسب، المالك | مدير الفرع لا يرى رواتب الطاقم العام |

---

## 7. أحداث التدقيق الأمني الرقمية (Audit Logging)

تلتزم جميع الأحداث بـ DEC-006 (خلو تام من الأسماء والنصوص السريرية والبيانات المالية الحساسة):
- `doctor_settlement_drafted`: `settlementId`, `doctorId`, `branchId`, `periodStart`, `periodEnd`, `visitsCount`, `netRevenuePiastres`, `commissionPiastres`
- `doctor_settlement_confirmed`: `settlementId`, `doctorId`, `confirmedByUserId`, `netPayablePiastres`, `itemsCount`
- `doctor_settlement_paid`: `settlementId`, `doctorId`, `paidAmountPiastres`, `paymentMethod`, `paidByUserId`
- `owner_self_confirmed`: `settlementId`, `doctorId`, `ownerUserId`, `netPayablePiastres`, `reason: owner_self_confirmed_single_operator`
- `employee_ledger_entry_added`: `entryId`, `employeeId`, `entryType`, `amountPiastres`, `performedByUserId`, `clientRequestId`
- `employee_ledger_entry_reversed`: `entryId`, `reversesEntryId`, `employeeId`, `amountPiastres`, `performedByUserId`
- `compensation_rule_saved`: `ruleId`, `doctorId`, `branchId`, `compensationType`, `percentage`, `fixedPiastres`, `baseSalaryPiastres`
- `staff_payroll_confirmed`: `payrollId`, `periodMonth`, `periodYear`, `employeesCount`, `totalNetPayablePiastres`, `confirmedByUserId`
- `staff_payroll_paid`: `payrollId`, `totalAmountPiastres`, `paidByUserId`

---

## 8. خطة الاختبارات الشاملة المحدثة (170 اختباراً مؤتمتاً)

| رقم | ملف الاختبار | النطاق والمضمون | الـ Milestone | عدد الاختبارات |
| :---: | :--- | :--- | :---: | :---: |
| 1 | `test/features/hr/doctor_settlement_calculator_test.dart` | حاسبة التسويات: الأساس المحصل، تواريخ الاعتراف، التقريب half-up، الكشف المجاني، الدفع الجزئي، والاسترداد | M-1 | 18 |
| 2 | `test/features/hr/employee_ledger_and_advances_test.dart` | دفتر الأستاذ: رصيد السلف الحركي، القيود العكسية `reversesEntryId`، قفل التعديل الرجعي، وعدم التكرار `clientRequestId` | M-1 | 16 |
| 3 | `test/features/hr/doctor_compensation_rules_test.dart` | قواعد الأجر: نطاق (طبيب، فرع)، السريان الزمني، حظر التعديل بأثر رجعي، والتحقق الحسابي | M-2 | 14 |
| 4 | `test/features/hr/doctor_settlement_usecases_test.dart` | حالات استخدام التسوية: توليد المسودة، تجميد اللقطة والأحداث المستهلكة، الصرف، وحظر التداخل | M-3 | 20 |
| 5 | `test/features/hr/staff_payroll_calculator_and_usecases_test.dart` | مسير رواتب الموظفين: النطاق (فرع أساسي، شهر)، البدلات، الاستقطاعات اليدوية، وخصم السلف | M-4 | 18 |
| 6 | `test/features/hr/hr_cubit_lifecycle_and_state_test.dart` | دورة حياة `HrCubit`: التصفير التلقائي عند تبديل الفرع والمستخدم، عزل بيانات الرواتب الحساسة | M-5 | 14 |
| 7 | `test/features/hr/hr_settlements_ui_and_dialogs_test.dart` | واجهة المستخدم: تبويب التسويات، شريط الفلاتر، حوار تفصيل الكشوفات، وحوار حفظ قواعد الأجر | M-6 | 16 |
| 8 | `test/features/hr/hr_payroll_and_ledger_ui_test.dart` | واجهة مسير الموظفين ودفتر الأستاذ: الجداول المتجاوبة، حوار السلف، وحوار القيد العكسي | M-7 | 14 |
| 9 | `test/features/hr/adaptive_hr_pdf_generators_test.dart` | الطباعة المتكيفة: تسوية الطبيب (A4 و 80 مم)، مسير الرواتب (A4 أفقي وسقوط 80 مم على A4) | M-8 | 12 |
| 10 | `test/features/hr/hr_rbac_and_branch_isolation_test.dart` | الحوكمة والأدوار: عزل فروع المدير، رؤية الطبيب لتسويته فقط، المعتمد $\neq$ الطبيب، واستثناء المالك | M-9 | 16 |
| 11 | `test/features/hr/hr_dst_and_audit_verification_test.dart` | اختبارات التوقيت الصيفي المصري (أبريل وأكتوبر)، والتحقق الصارم من سجل التدقيق الأمني | M-9 | 12 |
| **المجموع** | **11 ملف اختبار شامل** | **تغطية شاملة 100% متطابقة تماماً مع جدول المراحل** | — | **170** |

---

## 9. تقسيم المراحل التنفيذية المحدث (9 Milestones — كل مرحلة $\le$ يومين)

| الـ Milestone | النطاق والمخرجات | المدة | الاختبارات | رسالة الـ Commit المقترحة |
| :--- | :--- | :---: | :---: | :--- |
| **M-1: Data Layer, Money Math & Calculator** | نماذج قواعد الأجر، نماذج التسوية، دفتر الأستاذ، `DoctorSettlementCalculator` بالأساس المحصل، و `HrMockRepoImpl`. | 1.5 يوم | 34 (18 حاسبة + 16 دفتر) | `feat(F-06-M1): hr models, collected-basis calculator and employee ledger` |
| **M-2: Compensation Rules Management** | حالات استخدام قواعد الأجر لكل (طبيب، فرع)، السريان الزمني، حظر الأثر الرجعي، وصلاحية `manageCompensationRules`. | 1.0 يوم | 14 | `feat(F-06-M2): doctor compensation rules domain, validation and audit` |
| **M-3: Doctor Settlement Domain & Snapshots** | احتساب المسودة، تجميد لقطة الأحداث المستهلكة، الصرف، وحظر تداخل الفترات. | 1.5 يوم | 20 | `feat(F-06-M3): doctor settlement usecases, append-only snapshots and payout` |
| **M-4: Staff Payroll Domain Engine** | محرك مسير رواتب الموظفين، الملفات المالية بدون بيانات بنكية، وخصم السلف المعلقة. | 1.5 يوم | 18 | `feat(F-06-M4): staff payroll calculator, profile usecases and monthly payroll engine` |
| **M-5: State Management & Cubit Lifecycle** | بناء `HrCubit` و `HrState`، الربط في `dependency_injection.dart`، والتصفير التلقائي وعزل البيانات. | 1.0 يوم | 14 | `feat(F-06-M5): hr cubit and reactive branch-isolated state lifecycle` |
| **M-6: UI - Doctor Settlements & Rules** | تبويب تسويات الأطباء، الفلاتر، جدول التسويات، حوار تفصيل الكشوفات، وحوار إدارة قواعد الأجر. | 2.0 يوم | 16 | `feat(F-06-M6): doctor settlements dashboard, rules management and breakdown dialog` |
| **M-7: UI - Staff Payroll & Ledger** | تبويب مسير الموظفين، تبويب دفتر الأستاذ، حوار تسجيل السلف والخصم، وحوار القيد العكسي. | 1.5 يوم | 14 | `feat(F-06-M7): staff payroll tab, employee ledger views and reversal dialogs` |
| **M-8: Adaptive PDF Printing & Settings** | مولدات PDF لكشف التسوية ومسير الرواتب (A4 وحراري 80 مم مع تراجع المسير لـ A4) وإعدادات الطباعة. | 1.5 يوم | 12 | `feat(F-06-M8): adaptive pdf generators for doctor settlements and staff payroll` |
| **M-9: Verification, RBAC, DST & Closure** | فحص التوقيت الصيفي، مصفوفة الصلاحيات، عزل الفروع، فحص التدقيق الأمني، وتحديث السجلات. | 1.0 يوم | 28 (16 صلاحيات + 12 توقيت وتدقيق) | `docs(F-06): complete hr verification, dst validation and decisions record` |

**المجموع الإجمالي:** **170 اختباراً مؤتمتاً** متطابقة 100% بين الجدولين.

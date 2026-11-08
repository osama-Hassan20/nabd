# خطة التنفيذ المعمارية — الفيتشر F-01: إدارة الفروع وتعدد الفروع (Multi-Branch Management & Settings)

> **الإصدار:** 1.0.0  
> **التاريخ:** نوفمبر 2026  
> **الحالة:** 🟡 مقترحة للاعتماد  
> **المعيار الهندسي:** Clean Architecture • Single Model Pattern • 100% Nullable Models • Fail-Closed RBAC • Zero Code-Gen • Arabic RTL First (Warm Layered Minimalism)

---

## 1. النطاق (Scope)

### أ. داخل النطاق (In Scope)
1. **نموذج بيانات الفروع (`BranchModel`):**
   - نموذج Dart نقي، 100% Nullable، بدون كود جينريتور، بدون قيم افتراضية في الـ constructor.
   - يتضمن: المعرف، الاسم/مفتاح الترجمة، العنوان، الهاتف، البريد، حالة النشاط (`isActive`)، علامة الفرع الرئيسي (`isMain`)، مواعيد العمل، العطلات الخاصة، وإحصائيات سريعة للغرف والطاقم.
2. **عقد المستودع والمحاكاة (`BranchesRepo` & `BranchesMockRepoImpl`):**
   - زراعة الفروع الثلاثة الرسمية (`branch_1` المعادي، `branch_2` مدينة نصر، `branch_3` التجمع) بنفس معرفاتها الأصلية لضمان استقرار كامل للحجوزات والأطباء والمستخدمين القائمين.
   - عمليات إدارة الفروع: إضافة فرع، تعديل بيانات، تفعيل/تعطيل.
   - ميزة **"نسخ إعدادات من فرع" (Clone Settings):** إمكانية نسخ (مواعيد العمل، العطلات الخاصة، الخدمات والأسعار، أو دوام الأطباء) من فرع مصدر إلى فرع وجهة.
3. **قواعد الأمان والحوكمة الحازمة (Fail-Closed Rules):**
   - **قاعدة الفرع الرئيسي:** لا يجوز تعطيل أو حذف الفرع الرئيسي ما لم يتم نقل صفة "الرئيسي" لفرع نشط آخر.
   - **قاعدة الفرع النشط الأخير:** منع تعطيل الفرع إذا كان هو الفرع الوحيد النشط في المنشأة.
   - **قاعدة تحذير الحجوزات المستقبلية:** عند محاولة إيقاف فرع، يقوم النظام بفحص الحجوزات النشطة القادمة عبر `ActiveBookingsCountProvider`، ويمنع الإيقاف ما لم يؤكد المالك ذلك صراحة عبر حوار تحذيري (`forceWithActiveBookings`).
4. **تكامل الهيدر ومبدل الفروع (`HeaderBranchSwitcher`):**
   - تحويل القائمة من مصفوفة ثابتة إلى قراءة ديناميكية فورية من `BranchesRepo` و `SessionCubit`.
   - فلترة الفروع المتاحة للمستخدم وفق تعييناته (`user.branchAssignments`): المالك يرى جميع الفروع، بينما الطاقم يرى فقط الفروع المصرح له بالعمل بها.
5. **شاشة وتبويب إدارة الفروع:**
   - واجهة عصرية متوافقة مع الـ Design System (Warm Layered Minimalism)، تدعم العرض المكتبي (جدول عالي الانحناء) والشاشات الصغيرة (كروت متجاوبة).
   - حوارات الإدارة: إضافة وتعديل فرع، إيقاف الفرع، ونسخ الإعدادات.
6. **عزل إعدادات العمل والعطلات بحسب الفرع (القرار 10):**
   - ربط ساعات العمل والعطلات في `SettingsRepo` بالفرع النشط `activeBranchId` بدلاً من كونها عامة على مستوى المنشأة فقط.
7. **سجل التدقيق (Audit Logging):**
   - تسجيل عمليات إضافة وتعديل وتعطيل الفروع ونسخ الإعدادات في `AuditLogger`.

### ب. خارج النطاق (Out of Scope)
- إدارة الأقسام الطبية التخصصية والغرف الداخلية لكل فرع (مُجدولة في الفيتشر `F-04`).
- عقود أجور الأطباء المتغيرة ونسبهم المالية لكل فرع (مُجدولة في الفيتشر `F-24 / F-25`).
- تكامل بوابات الخرائط المباشرة GPS وأجهزة البصمة لحضور الموظفين (مرحلة لاحقة).

---

## 2. ما هو موجود، ما سيتغير، وما سينشأ

### أ. الموجود حالياً (Existing Assets)
- `lib/shared/services/app_branch_service.dart`: خدمة تتبع الفرع النشط بنمط `ValueNotifier`.
- `lib/shared/app_layout/presentation/widgets/header_branch_switcher.dart`: واجهة مبدل الفروع في الهيدر وتعمل ببيانات ثابتة مؤقتة.
- `lib/core/cubits/session_cubit.dart`: يدير `activeBranchId` ويوفر طريقة `switchBranch(branchId)`.
- `lib/features/users_management/data/models/branch_assignment_model.dart`: يربط المستخدم بالفروع وأدواره داخلها.
- `lib/core/providers/active_bookings_count_provider.dart`: واجهة حساب الحجوزات النشطة.

### ب. ما سيتغير (Modifications)
1. `lib/core/enums/staff_permission_enum.dart`:
   - إضافة صلاحية `manageBranches` تحت قسم `Settings & Governance`.
2. `lib/features/users_management/data/models/role_definition_model.dart`:
   - إسناد `manageBranches` لدور المالك (`owner`) حصراً في جدول الـ Seed Matrix.
3. `lib/core/services/permission_evaluator.dart`:
   - إضافة الفحص الصريح لصلاحية `manageBranches`.
4. `lib/shared/app_layout/presentation/widgets/header_branch_switcher.dart`:
   - الاستماع التفاعلي لـ `BranchesRepo` بدلاً من `_branches` الثابتة، مع دعم التحديث اللحظي عند إضافة أو تعديل فرع.
5. `lib/features/settings/data/repo/settings_mock_repo_impl.dart`:
   - تعديل تخزين واسترجاع مواعيد العمل والعطلات ليعتمد على خريطة `Map<String, CompanySettingsModel>` مفهرسة بـ `branchId`.
6. `lib/features/settings/presentation/pages/settings_page.dart`:
   - إضافة تبويب "الفروع" (`tab_branches`) لتمكين المالك من الوصول المباشر لإدارة فروع المنشأة.

### ج. ما سينشأ جديداً (New Assets)
- `lib/features/branches/data/models/branch_model.dart`
- `lib/features/branches/data/models/copy_branch_settings_param.dart`
- `lib/features/branches/domain/repo/branches_repo.dart`
- `lib/features/branches/data/repo/branches_mock_repo_impl.dart`
- `lib/features/branches/presentation/cubit/branches_cubit.dart`
- `lib/features/branches/presentation/cubit/branches_state.dart`
- `lib/features/branches/presentation/widgets/branches_table.dart`
- `lib/features/branches/presentation/widgets/branch_card.dart`
- `lib/features/branches/presentation/widgets/branch_status_badge.dart`
- `lib/features/branches/presentation/pages/dialogs/add_edit_branch_dialog.dart`
- `lib/features/branches/presentation/pages/dialogs/toggle_branch_status_dialog.dart`
- `lib/features/branches/presentation/pages/dialogs/copy_branch_settings_dialog.dart`
- `lib/features/settings/presentation/widgets/tabs/branches_management_tab.dart`
- `test/features/branches/branches_models_and_repo_test.dart`
- `test/features/branches/branches_screen_and_dialogs_test.dart`

---

## 3. نموذج البيانات (Data Models)

### `BranchModel` (100% Nullable Single Model)
```dart
class BranchModel {
  final String? id;
  final String? name;
  final String? nameKey;
  final String? address;
  final String? phone;
  final String? email;
  final bool? isActive;
  final bool? isMain;
  final String? openingTime;
  final String? closingTime;
  final List<String>? workingDays;
  final List<SpecialHolidayModel>? specialHolidays;
  final int? activeRoomsCount;
  final int? staffMembersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BranchModel({
    this.id,
    this.name,
    this.nameKey,
    this.address,
    this.phone,
    this.email,
    this.isActive,
    this.isMain,
    this.openingTime,
    this.closingTime,
    this.workingDays,
    this.specialHolidays,
    this.activeRoomsCount,
    this.staffMembersCount,
    this.createdAt,
    this.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic>? json);
  Map<String, dynamic> toJson();
  BranchModel copyWith({...});
}
```

### `CopyBranchSettingsParam`
```dart
class CopyBranchSettingsParam {
  final String? sourceBranchId;
  final String? targetBranchId;
  final bool? copyWorkingHours;
  final bool? copySpecialHolidays;
  final bool? copyMedicalServices;
  final bool? copyDoctorSchedules;

  const CopyBranchSettingsParam({
    this.sourceBranchId,
    this.targetBranchId,
    this.copyWorkingHours,
    this.copySpecialHolidays,
    this.copyMedicalServices,
    this.copyDoctorSchedules,
  });
}
```

---

## 4. مصفوفة الصلاحيات وحماية المسارات (RBAC & Route Guards)

### أ. الصلاحيات المضافة
| الصلاحية (`StaffPermissionEnum`) | الوصف | الأدوار الممنوحة افتراضياً |
| :--- | :--- | :--- |
| `manageBranches` | إنشاء الفروع، تعديلها، تعطيلها، ونسخ الإعدادات بينها | المالك فقط (`owner`) |

### ب. قواعد الفحص والتحقق (`PermissionEvaluator`)
```dart
case StaffPermissionEnum.manageBranches:
  return user.isOwner == true;
```

### ج. حماية الواجهة والمسارات (Route & UI Protection)
- تبويب إدارة الفروع داخل إعدادات المنشأة: لا يظهر لغير المالك أو من يملك `manageBranches`.
- عند فتح حوارات الإضافة أو التعديل أو التعطيل، يتم التأكد من صلاحية المستخدم الحالي بشكل Fail-Closed.

---

## 5. الشاشات والحالات المرئية (UI / UX Flow)

### أ. تبويب إدارة الفروع في الإعدادات (`BranchesManagementTab`)
- **الهيدر:** عنوان التبويب ووصفه، بالإضافة إلى زر "إضافة فرع جديد" (`add_branch`) باللون الأساسي (تيراكوتا).
- **الجدول على الشاشات الكبيرة (`BranchesTable`):**
  - الأعمدة: اسم الفرع والصفة (رئيسي/فرعي)، العنوان والهاتف، مواعيد العمل، العيادات والطاقم، الحالة (نشط/معطل)، الإجراءات.
  - قائمة الإجراءات لكل فرع: تعديل البيانات، نسخ الإعدادات، تفعيل/إيقاف الفرع، وتعيين كفرع رئيسي.
- **الكروت على الموبايل (`BranchCard`):** كارت متجاوب بانحناء 24px وبوردر خفيف مع شارة الحالة وأزرار الإجراءات السريعة.
- **حالات العرض:**
  - **حالة التحميل:** هياكل عظمية متناسقة (`CustomShimmerContainer`).
  - **حالة الفراغ:** رسالة ناعمة مع أيقونة وزر لإضافة أول فرع (`CustomEmptyWidget`).
  - **حالة الخطأ:** رسالة خطأ واضحة وزر إعادة المحاولة (`ErrorPage`).

### ب. حوار إضافة وتعديل الفرع (`AddEditBranchDialog`)
- نافذة منبثقة بعرض أقصى 580px على التابلت/الديسكتوب وملء الشاشة على الموبايل (`<= 700px`).
- حقول الإدخال: اسم الفرع بالعربية، رقم الهاتف، البريد، العنوان، تحديد الفرع الرئيسي (`isMain`)، ومواعيد العمل الأولية (أيام العمل وساعات الفتح والإغلاق).

### ج. حوار إيقاف وتفعيل الفرع (`ToggleBranchStatusDialog`)
- **في حالة الفرع الرئيسي:** يمنع الإيقاف ويعرض رسالة توضيحية: "لا يمكن إيقاف الفرع الرئيسي. يجب تعيين فرع آخر كفرع رئيسي أولاً".
- **في حالة الفرع الأخير:** يمنع الإيقاف ويعرض: "لا يمكن إيقاف جميع الفروع، يجب أن يظل فرع واحد نشط على الأقل".
- **في حالة وجود حجوزات مستقبلية نشطة:** يعرض عدداً دقيقاً للحجوزات المتأثرة ويطلب تأكيداً إجبارياً صريحاً (`forceWithActiveBookings: true`).

### د. حوار نسخ الإعدادات (`CopyBranchSettingsDialog`)
- يتيح للمالك اختيار الفرع المصدر والفرع المستهدف، وتحديد مربعات اختيار (Checkboxes) لما يرغب في نسخه:
  - مواعيد وأيام العمل.
  - العطلات الرسمية والخاصة.
  - أسعار الخدمات الطبية.
  - جداول ودوام الأطباء.

---

## 6. التكامل مع أجزاء النظام (System Integrations)

1. **التكامل مع `SessionCubit` و `HeaderBranchSwitcher`:**
   - عند إنشاء أو تعديل فرع أو تغيير حالته، يتم تحديث قائمة الفروع فوراً.
   - في حال تم إيقاف الفرع النشط حالياً للمستخدم، يتم تلقائياً التبديل إلى الفرع الرئيسي النشط لمنع بقاء المستخدم في سياق فرع متوقف.
2. **التكامل مع `SettingsRepo` (القرار 10):**
   - تحويل مواعيد العمل والعطلات الرسمية لتكون مقترنة بكل فرع على حدة، مع استرجاع الإعدادات بناءً على `activeBranchId`.
3. **التكامل مع `AuditLogger`:**
   - تسجيل أحداث الأمان: `create_branch`, `update_branch`, `deactivate_branch`, `activate_branch`, `copy_branch_settings`.
4. **التكامل مع `ActiveBookingsCountProvider`:**
   - تزويد حوار التعطيل بمحرك حساب الحجوزات المستقبلية المرتبطة بالفرع لمنع التعطيل غير المقصود لحجوزات المرضى.

---

## 7. الحالات الحدية (Edge Cases & Resilience)

1. **تعطيل فرع نشط أثناء استخدام موظف له:** يتم التعامل معه بسلاسة وتوجيه الموظف للفرع الرئيسي المتاح.
2. **الفرع الرئيسي الوحيد:** حظر التعطيل وحظر حذف صفة "الرئيسي" منه دون بديل.
3. **تعارض التسمية:** التحقق من عدم تكرار اسم الفرع في نفس المنشأة.
4. **النسخ المتطابق (Self-copy):** حظر اختيار نفس الفرع كمصدر ووجهة في عملية نسخ الإعدادات.
5. **البيانات المزروعة (Seed Data Integrity):** المحافظة الدقيقة على المعرفات `branch_1`, `branch_2`, `branch_3` دون أي تعديل يكسر ارتباطات الحجوزات أو الأطباء السابقة.

---

## 8. مفاتيح الترجمة (Localization Keys)
تضاف في الملفين `ar-EG.json` و `en-US.json`:
- `branches_management`: "إدارة الفروع" / "Branches Management"
- `branches_management_desc`: "إضافة الفروع والتحكم في حالتها ومواعيد عملها ونسخ الإعدادات بينها"
- `add_branch`: "إضافة فرع جديد" / "Add New Branch"
- `edit_branch`: "تعديل الفرع" / "Edit Branch"
- `branch_name`: "اسم الفرع" / "Branch Name"
- `is_main_branch`: "تعيين كفرع رئيسي" / "Set as Main Branch"
- `main_branch_badge`: "الفرع الرئيسي" / "Main Branch"
- `copy_settings`: "نسخ الإعدادات" / "Copy Settings"
- `copy_settings_desc`: "نسخ ساعات العمل والعطلات أو الخدمات من فرع إلى آخر"
- `source_branch`: "الفرع المصدر" / "Source Branch"
- `target_branch`: "الفرع المستهدف" / "Target Branch"
- `copy_working_hours`: "ساعات وأيام العمل" / "Working Hours & Days"
- `copy_special_holidays`: "العطلات الرسمية والخاصة" / "Special Holidays"
- `copy_services`: "الخدمات والأسعار الطبية" / "Medical Services & Pricing"
- `copy_schedules`: "جداول دوام الأطباء" / "Doctors Schedules"
- `cannot_deactivate_main_branch`: "لا يمكن إيقاف الفرع الرئيسي للمنشأة."
- `cannot_deactivate_last_branch`: "لا يمكن إيقاف كافة فروع المنشأة."
- `branch_has_future_bookings_warning`: "تنبيه: يوجد {count} حجز مستقبلي قائم بهذا الفرع. هل تريد الاستمرار في الإيقاف؟"

---

## 9. خطة مراحل التنفيذ (Implementation Milestones)

### المرحلة 1: طبقة البيانات والعقود والمحاكاة (Data Layer & Seed Mock)
- بناء النماذج `BranchModel` و `CopyBranchSettingsParam` (100% Nullable).
- بناء عقد `BranchesRepo` وتنفيذ `BranchesMockRepoImpl` مع زراعة الفروع الثلاثة الرسمية.
- إضافة صلاحية `manageBranches` في `StaffPermissionEnum` وتحديث `RoleDefinitionModel` و `PermissionEvaluator`.
- إضافة `ActiveBookingsCountProvider.countActiveFutureBookingsForBranch`.
- اختبارات الوحدة: زراعة الفروع، قواعد الأمان (منع تعطيل الفرع الرئيسي والأخير)، ونسخ الإعدادات.

### المرحلة 2: تكامل الهيدر ومبدل الفروع الحركي (Dynamic Header Branch Switcher)
- ترقية `HeaderBranchSwitcher` ليقرأ الفروع المسجلة ديناميكياً من `BranchesRepo`.
- تصفية الفروع وفقاً لتعيينات المستخدم المسجل.
- اختبار تفاعلي للهيدر وتأكيد استقراره بنسبة 100%.

### المرحلة 3: إدارة الحالة وشاشة/تبويب الفروع (Branches Cubit & UI View)
- بناء `BranchesCubit` و `BranchesState` بنمط `SafeCubit`.
- بناء `BranchesManagementTab` وجدول الفروع `BranchesTable` وكروت الموبايل `BranchCard`.
- دمج التبويب في صفحة الإعدادات `SettingsPage` مع حمايته بصلاحية `manageBranches`.

### المرحلة 4: حوارات إدارة الفروع والأمان (Governance Dialogs)
- بناء حوار الإضافة والتعديل `AddEditBranchDialog`.
- بناء حوار التعطيل والتفعيل `ToggleBranchStatusDialog` مع فحص الحجوزات المستقبلية.
- بناء حوار نسخ الإعدادات `CopyBranchSettingsDialog`.
- تسجيل كافة العمليات في `AuditLogger`.

### المرحلة 5: عزل إعدادات العمل والعطلات بحسب الفرع (Per-Branch Isolation)
- تحديث `SettingsMockRepoImpl` لدعم جلب وحفظ مواعيد العمل والعطلات لكل `branchId`.
- اختبارات التحقق من عزل إعدادات الفروع عن بعضها طبقاً للقرار 10.

### المرحلة 6: التحقق النهائي والإقفال (Verification & Completion)
- تشغيل `flutter analyze --no-pub` والتأكد من خلوه تماماً من أي ملاحظات (0 issues).
- تشغيل اختبارات المشروع بالكامل وتأكيد اجتيازها بنسبة 100%.
- تحديث `docs/PROGRESS.md` و `docs/FEATURES_ROADMAP.md` وعمل Commit محلي.

---

## 10. معايير القبول (Acceptance Criteria)

1. [x] **سلامة البيانات القائمة:** الفروع الثلاثة (`branch_1`, `branch_2`, `branch_3`) موجودة ومربوطة بكافة الحجوزات والمستخدمين السابقين دون أي كسر.
2. [x] **حوكمة الفرع الرئيسي والأخير:** فشل أي محاولة لإيقاف الفرع الرئيسي أو الفرع الوحيد المتبقي مع إرجاع إخفاق واضح ورسالة مانعة.
3. [x] **تحذير الحجوزات القادمة:** لا يمكن تعطيل فرع به حجوزات مستقبلية إلا مع تمرير `forceWithActiveBookings: true`.
4. [x] **نسخ الإعدادات:** نسخ الإعدادات المختارة بدقة من الفرع المصدر إلى الفرع المستهدف دون تكرار أو حذف غير مرغوب.
5. [x] **الهيدر التفاعلي:** مبدل الفروع في الهيدر يعكس الفروع فور إضافتها أو تعديلها مع إخفاء الفروع المعطلة.
6. [x] **الامتثال للهوية:** الواجهة كاملة باللغة العربية، أرقام إنجليزية (0-9)، الـ Design System المعتمد، والتجاوب التام مع مختلف أحجام الشاشات.

---

## 11. قايمة المراجعة الذاتية للخطة (Self-Review Checklist)

1. **هل في مصدرين للحقيقة لنفس المعلومة؟** لا، بيانات الفروع محفوظة في `BranchesRepo` فقط، و`HeaderBranchSwitcher` و`SessionCubit` يقرآن منه.
2. **هل في فحص صلاحية ممكن يفتح لو معلومة ناقصة (fail-open)؟** لا، فحص `manageBranches` يتطلب صراحة `user.isOwner == true`، وأي مستخدم غير معروف أو ناقص البيانات يُرفض فوراً (Fail-Closed).
3. **هل في طريق لتصعيد الصلاحيات؟** لا، صلاحية إدارة الفروع مقصورة على المالك فقط ولا تظهر للمدراء أو الاستقبال.
4. **هل كل بيانات محتاجة تكون لكل فرع فعلاً لكل فرع؟** نعم، مواعيد العمل والعطلات أصبحت لكل فرع استناداً للقرار 10، وبيانات المنشأة فقط هي المشتركة.
5. **هل الحذف soft وفيه تحذير علاقات؟** نعم، النظام يدعم التعطيل (`isActive: false`) مع فحص الحجوزات المستقبلية ومنع تعطيل الفرع الرئيسي.
6. **هل كل قاعدة أمان ليها اختبار بالاسم؟** نعم، تم تحديد اختبارات لقاعدة الفرع الرئيسي، قاعدة الفرع الأخير، وقاعدة الحجوزات المستقبلية.
7. **هل بتكسر شاشة موجودة؟** لا، تم الإبقاء على نفس معرفات الفروع `branch_1`, `branch_2`, `branch_3` التي تعتمد عليها الحجوزات والأطباء والهيدر الحالي.
8. **هل في بيانات حساسة ممكن تتسرب؟** لا، سجل النشاط يسجل معرف الفرع والعملية واسم الفرع فقط دون أي بيانات سرية.

---

## 12. الأسئلة المفتوحة (Open Questions)

1. **مكان تبويب الفروع في واجهة المستخدم:**
   - **الخيار أ (موصى به):** إدراج تبويب الفروع كأحد تبويبات صفحة الإعدادات العامة (`SettingsPage`) بجوار بيانات المنشأة ومواعيد العمل ليكون كل الإعداد في مكان واحد منظم.
   - **الخيار ب:** تخصيص بند مستقل في القائمة الجانبية باسم "الفروع" ينقل لصفحة مستقلة `/settings/branches`.
2. **إسناد الخدمات للأفرع:**
   - **الخيار أ (موصى به):** جميع الخدمات الطبية تتاح لكافة الفروع افتراضياً بنفس السعر، مع إمكانية تعديل سعر أو تعطيل خدمة في فرع بعينه (أكثر مرونة وسرعة في التشغيل).
   - **الخيار ب:** إلزام إنشاء خدمات مستقلة لكل فرع من البداية (أقل مرونة ويتطلب إدخال مكرر).
3. **التعطيل الإجباري مع الحجوزات المستقبلية:**
   - **الخيار أ (موصى به):** عند التعطيل الإجباري لفرع به حجوزات، يتم تغيير حالة الفرع لمعطل وتنبيه الإدارة بضرورة إعادة جدولة أو إلغاء الحجوزات المتأثرة لاحقاً من شاشة الحجوزات.
   - **الخيار ب:** إلغاء كافة الحجوزات المستقبلية آلياً فور التعطيل (قد يسبب فقداناً لبيانات المواعيد غير مقصود).


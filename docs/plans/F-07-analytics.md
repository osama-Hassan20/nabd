# خطة تنفيذ فيتشر F-07: التقارير والإحصائيات ولوحة التحليلات التنفيذية
# Feature F-07: Analytics, Reports & Executive Business Intelligence Plan

> **المرجع الحاكم:** `docs/AGENT_OPERATING_GUIDE.md` و `docs/DECISIONS.md` و `docs/plans/handover/WHAT_IS_MISSING.md`
> **الحالة:** 📝 وثيقة خطة تفصيلية معتمدة للتنفيذ
> **تاريخ الإنشاء:** 15 نوفمبر 2026

---

## 1. الملخص التنفيذي وأهداف الفيتشر (Executive Summary & Goals)

تهدف فيتشر **F-07** إلى تزويد إدارة العيادة والمالك (Owner)، والمديرين الإداريين والمحاسبين، بلوحة تحليلات تنفيذية وتقارير تفاعلية ذكية (Executive Business Intelligence) تجمع وتلخص المؤشرات التشغيلية والسريرية والمالية بدقة بالغة اعتماداً على بيانات النظام (الكشوفات، الحجوزات، الخزينة، أتعاب الأطباء، ومسير الرواتب)، مع دعم الفلاتر الزمنية الحركية (اليوم، الأسبوع، الشهر، أو فترة مخصصة) والعزل الصارم للفروع وصلاحيات الـ RBAC.

### 1.1 المؤشرات الرئيسية (Core KPIs):
1. **المؤشرات المالية (Financial Intelligence):**
   - إجمالي الإيرادات المحصلة (اليوم والشهر) لكل فرع ومجمعاً.
   - صافي أرباح العيادة التقديري (الإيرادات المحصلة - أتعاب وتسويات الأطباء - مسير الرواتب والمصروفات).
   - إجمالي مديونيات المرضى غير المحصلة (Outstanding Debts).
   - متوسط قيمة الزيارة (Average Revenue Per Visit).
   - توزيع الإيرادات حسب التخصص والخدمة الطبية وطريقة الدفع.
2. **المؤشرات التشغيلية والسريرية (Operational & Clinical Intelligence):**
   - إجمالي عدد الحجوزات والكشوفات المكتملة، ونسبة الحضور مقابل الإلغاء وعدم الحضور (No-Show Rate).
   - متوسط وقت انتظار المريض في العيادة (Average Patient Wait Time).
   - أوقات الذروة وازدحام العيادة خلال ساعات اليوم وأيام الأسبوع (Peak Hours Heatmap).
   - معدل زيارات المتابعة للمرضى (Patient Retention & Return Rate).
3. **أداء وإنتاجية الأطباء (Doctor Performance Leaderboard):**
   - ترتيب الأطباء حسب عدد الحالات والكشوفات المنجزة.
   - مساهمة كل طبيب في إيرادات العيادة.
   - متوسط مدة الكشف لكل طبيب.

---

## 2. الثوابت والقرارات المعمارية الصارمة (Strict Architectural Decisions)

1. **DEC-070: بنية نماذج بيانات حتمية وموحّدة (No Entities, 100% Nullable):**
   - جميع النماذج تنتهي بـ `Model` (بدون طبقة `entities/`).
   - كافة الحقول `final Type? field;` وقابلة للـ `null` بأمان، مع دوال `copyWith` و `toMap` و `fromMap`.
   - استخدام `fl_chart: ^1.2.0` المعتمد في `pubspec.yaml` للرسوم البيانية التفاعلية.
2. **DEC-071: التعامل المالي الصارم (Integer Piastres & Money):**
   - كافة القيم المالية تُحسب وتُخزن بالقروش الصحيحة (`int` piastres) لتفادي أخطاء النقطة العائمة (Floating-point errors).
   - التنسيق للعرض عبر `MoneyHelper.formatMoney()` وعملة النظام المعتمدة من الجلسة.
3. **DEC-072: التوقيت الحتمي ومنع الانجراف (CairoTimeHelper):**
   - جميع حسابات الفترات الزمنية وتجميع الأيام والشهور تعتمد حصراً على `CairoTimeHelper.now()` لتأمين الدقة خلال الانتقال بين التوقيت الصيفي والشتوي.
   - الفترات الزمنية: اليوم (`today`)، هذا الأسبوع (`thisWeek`)، هذا الشهر (`thisMonth`)، أو فترة مخصصة (`custom`).
4. **DEC-073: الأمان والعزل وصلاحيات الـ RBAC:**
   - الدخول لشاشة التحليلات محمي بـ `StaffPermissionEnum.accessAnalytics`.
   - عرض البيانات المالية والأرباح والإيرادات محمي بـ `StaffPermissionEnum.viewFinancialReports`.
   - إذا كان المستخدم يملك `accessAnalytics` ولا يملك `viewFinancialReports` (مثل مدير فرع تشغيلي بدون صلاحية مالية)، تُحجب أو تُقنع الأرقام المالية وتُعرض فقط المؤشرات التشغيلية والسريرية.
   - عزل الفروع: المستخدم المقيد بفرع محدد يرى بيانات فرعه فقط، بينما المالك والمدير العام والمحاسب المصرح لهم يمكنهم التبديل بين الفروع أو اختيار "كل الفروع" (`All Branches`).
5. **DEC-074: إدارة الحالة وعزل أقسام الصفحة (Dashboard Section Builder & SafeCubit):**
   - Cubit واحد فقط للفيتشر: `AnalyticsCubit extends SafeCubit<AnalyticsState>`.
   - حالة الصفحة تحتوي على `RequestStatusEnum` مستقل لكل قسم (`summaryStatus`, `trendStatus`, `branchesStatus`, `doctorsStatus`) لتطبيق مبدأ عدم تعطل الصفحة حال تعثر قسم واحد.
   - جلب متوازي للبيانات عبر `Future.wait`.
   - شيمر هيكلي (Exact Shimmer Skeletons) مطابق لأبعاد كل عنصر أثناء التحميل.
6. **DEC-075: حيادية الـ Multi-tenant والتوطين الكامل:**
   - صفر نصوص hardcoded في كافة الواجهات.
   - تطابق بنسبة 100% بين `ar-EG.json` و `en-US.json` لكافة المفاتيح ببادئة `analytics_`.

---

## 3. قائمة الملفات التي سيتم إنشاؤها وتعديلها (File Manifest)

### 3.1 النماذج والـ Enums (`lib/features/analytics/data/models/`):
1. `lib/features/analytics/data/models/enums/analytics_time_range_enum.dart`
2. `lib/features/analytics/data/models/enums/analytics_tab_enum.dart`
3. `lib/features/analytics/data/models/analytics_summary_kpi_model.dart`
4. `lib/features/analytics/data/models/revenue_trend_point_model.dart`
5. `lib/features/analytics/data/models/branch_analytics_comparison_model.dart`
6. `lib/features/analytics/data/models/doctor_performance_metric_model.dart`
7. `lib/features/analytics/data/models/hourly_traffic_metric_model.dart`
8. `lib/features/analytics/data/models/service_revenue_distribution_model.dart`

### 3.2 طبقة المستودع والدومين (`lib/features/analytics/domain/` & `data/repo/`):
9. `lib/features/analytics/domain/repo/analytics_repo.dart`
10. `lib/features/analytics/data/repo/analytics_mock_repo_impl.dart`
11. `lib/features/analytics/domain/use_cases/get_analytics_summary_use_case.dart`
12. `lib/features/analytics/domain/use_cases/get_revenue_trend_use_case.dart`
13. `lib/features/analytics/domain/use_cases/get_branch_comparison_use_case.dart`
14. `lib/features/analytics/domain/use_cases/get_doctor_performance_use_case.dart`
15. `lib/features/analytics/domain/use_cases/get_hourly_traffic_use_case.dart`

### 3.3 طبقة العرض والـ Cubit (`lib/features/analytics/presentation/`):
16. `lib/features/analytics/presentation/manager/analytics_state.dart`
17. `lib/features/analytics/presentation/manager/analytics_cubit.dart`
18. `lib/features/analytics/presentation/pages/analytics_page.dart` (استبدال السكلتون بواجهة متكاملة متجاوبة)
19. `lib/features/analytics/presentation/widgets/analytics_filter_bar.dart`
20. `lib/features/analytics/presentation/widgets/analytics_metric_grid.dart`
21. `lib/features/analytics/presentation/widgets/analytics_metric_card.dart`
22. `lib/features/analytics/presentation/widgets/revenue_trend_chart_card.dart`
23. `lib/features/analytics/presentation/widgets/branch_comparison_chart_card.dart`
24. `lib/features/analytics/presentation/widgets/doctor_performance_table_card.dart`
25. `lib/features/analytics/presentation/widgets/hourly_traffic_heatmap_card.dart`
26. `lib/features/analytics/presentation/widgets/shimmers/analytics_grid_shimmer.dart`
27. `lib/features/analytics/presentation/widgets/shimmers/analytics_chart_shimmer.dart`

### 3.4 ملفات التهيئة والربط:
28. `lib/core/di/injection_container.dart` (تسجيل الـ Repos والـ UseCases والـ Cubit)
29. `assets/translations/ar-EG.json` (إضافة مفاتيح `analytics_*`)
30. `assets/translations/en-US.json` (إضافة مفاتيح `analytics_*`)

---

## 4. خطة المراحل والتسليم (Milestones Breakdown & Test Strategy)

| المرحلة | الوصف | عدد الاختبارات | الملفات المستهدفة |
|:---|:---|:---:|:---|
| **M-1** | نماذج البيانات والـ Enums وسلامة الحسابات | 20 | `test/features/analytics/analytics_models_and_enums_test.dart` |
| **M-2** | محرك التجميع ومستودع البيانات التجريبي (Mock Repo Engine) | 25 | `test/features/analytics/analytics_mock_repo_test.dart` |
| **M-3** | حالات الاستخدام وحوكمة الصلاحيات (Use Cases & RBAC) | 20 | `test/features/analytics/analytics_usecases_test.dart` |
| **M-4** | إدارة الحالة ودورة حياة الكيوبت (AnalyticsCubit State) | 20 | `test/features/analytics/analytics_cubit_test.dart` |
| **M-5** | بطاقات المؤشرات الرئيسية والشبكة المتجاوبة (KPI Cards UI) | 15 | `test/features/analytics/analytics_metric_grid_ui_test.dart` |
| **M-6** | الرسوم البيانية التفاعلية (Revenue Trend & Branch Comparison) | 15 | `test/features/analytics/analytics_charts_ui_test.dart` |
| **M-7** | جدول كفاءة الأطباء ومخطط ساعات الذروة (Leaderboard & Traffic) | 15 | `test/features/analytics/analytics_tables_and_traffic_ui_test.dart` |
| **M-8** | شاشة التحليلات الكاملة وحقن الاعتماديات والترجمة (Integration & DI) | 15 | `test/features/analytics/analytics_page_integration_test.dart` |
| **M-9** | التحقق النهائي، عزل الفروع، الفحص الأمني، والإقفال (Gate & Audit) | 15 | `test/features/analytics/analytics_rbac_and_isolation_test.dart` |
| **المجموع** | **9 مراحل متكاملة** | **160 اختباراً** | تغطية شاملة 100% |

---

## 5. مصفوفة التحقق وبوابة الاعتماد (Milestone Gate Protocol)

لكل مرحلة من المراحل التسع:
1. كتابة الكود والاختبارات المطابقة تماماً للمتطلبات.
2. تشغيل الاختبارات الخاصة بالمرحلة: `flutter test test/features/analytics/{test_file}.dart`
3. التحقق من بوابة المشروع:
   - `flutter analyze` = 0 issues.
   - جميع الاختبارات تمر بنسبة 100%.
4. تنفيذ Commit واضح بالبادئة: `feat(F-07-M{X}): {description}`.

# Sliver UI Patterns Reference

This reference documents how to construct sliver-based scrollable pages in this dashboard using `CustomScrollView`, `RefreshIndicator`, `SliverMainAxisGroup`, and responsive grids.

---

## 1. Page Shell Architecture

The outer shell must always follow this structure:

```dart
class AdminFeaturePageView extends StatelessWidget {
  const AdminFeaturePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await context.read<AdminFeatureCubit>().refreshData();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const FeatureSummarySection(),
          const SizedBox(height: 16).toSliver(),
          
          const FeatureFilterSection(),
          const SizedBox(height: 16).toSliver(),
          
          // Data Table / Content Sliver
          const FeatureTableSection(),
          
          const SizedBox(height: 24).toSliver(),
        ],
      ),
    );
  }
}
```

### Key Rules:
- `physics: const AlwaysScrollableScrollPhysics()` guarantees pull-to-refresh works even when content fits on a single screen without native scrolling.
- Use `import 'package:purexo/core/utils/extensions/sliver_extentions.dart';` to enable `.toSliver()` on any standard widget (`SizedBox`, `Container`, `Padding`).

---

## 2. Section Grouping with `SliverMainAxisGroup`

When an individual section contains a header and a grid or list, group them into a single `SliverMainAxisGroup`:

```dart
return SliverMainAxisGroup(
  slivers: [
    SliverPadding(
      padding: const EdgeInsets.only(bottom: 12),
      sliver: SliverToBoxAdapter(
        child: SectionHeaderWithAction(
          title: 'العمليات الأخيرة',
          onPressed: () {
            context.go(AppRouter.transactions);
          },
        ),
      ),
    ),
    SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        return TransactionCard(item: state.transactions[index]);
      },
    ),
  ],
);
```

---

## 3. Shimmer Skeletons in Slivers

### A. Table Shimmer
```dart
if (state.status == RequestStatusEnum.loading)
  const CustomTableShimmer(
    headers: ['#', 'الاسم', 'الحالة', 'التاريخ', 'الإجراءات'],
    columnWidths: {
      0: FixedColumnWidth(60),
      1: FixedColumnWidth(180),
      2: FixedColumnWidth(120),
      3: FixedColumnWidth(140),
      4: FixedColumnWidth(80),
    },
  ).toSliver()
```

### B. Summary Metric Cards Shimmer
```dart
SliverToBoxAdapter(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 600 ? 1 : constraints.maxWidth < 1000 ? 2 : 4;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => const CustomShimmerContainer(borderRadius: 12),
      );
    },
  ),
)
```

---

## 4. Error and Empty States in Slivers

### Error State with Retry
```dart
else if (state.status == RequestStatusEnum.failure)
  ErrorPage(
    errorMessage: state.errMessage ?? 'حدث خطأ في تحميل البيانات',
    onPressed: () => cubit.getAllItems(),
  ).toSliver()
```

### Empty State
```dart
else if (state.status == RequestStatusEnum.empty || state.items.isEmpty)
  const SliverFillRemaining(
    child: ColoredBox(
      color: Colors.white,
      child: CustomEmptyWidget(
        title: 'لا توجد بيانات متاحة حاليًا',
        imagePath: AppImages.emptyData,
      ),
    ),
  )
```

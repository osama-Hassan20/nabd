---
name: dashboard-table-system
description: >-
  Use this skill when creating, styling, or debugging data tables, columns, pagination,
  and loading shimmer in Flutter dashboard projects. Covers CustomTable, EnhancedTable,
  column width configurations, horizontal scroll constraints, status badges, action menus,
  CustomTableShimmer, and CustomPaginationTable integration.
---

# Dashboard Table System & Pagination Skill

This skill provides complete patterns, widgets, and best practices for creating data tables with horizontal scrolling, custom column sizing, responsive pagination, action popups, and loading shimmers in this dashboard.

---

## 1. Table Architecture Comparison

| Component | Location | Implementation | Best Used For |
| :--- | :--- | :--- | :--- |
| **`CustomTable`** | `lib/core/layout_adaptive/widgets/cutom_table.dart` | Flutter `Table` widget with `Map<int, TableColumnWidth>` | Standard data grids with exact column width controls (e.g. Teachers, Orders, Students). |
| **`EnhancedTable`** | `lib/core/layout_adaptive/widgets/enhanced_table.dart` | Card container + `EnhancedTableHeader` (gradient) + divider-separated rows | Modern card-styled tables, widgets requiring gradient headers and custom row heights. |
| **`CustomTableShimmer`** | Inside `cutom_table.dart` | Animated shimmer placeholder matching column widths | Zero-layout-shift loading state during data fetching. |
| **`CustomPaginationTable`**| `lib/core/layout_adaptive/widgets/pagination_table.dart` | Page buttons + ellipsis + page jump dialog | Bottom pagination bar across all dashboard tables. |

---

## 2. Implementing `CustomTable` (Standard Pattern)

### A. Column Width Definitions
Define exact column widths so columns never shrink below readable sizes:
```dart
const columnWidths = {
  0: FixedColumnWidth(60),   // Index (#)
  1: FixedColumnWidth(160),  // Name / Title
  2: FixedColumnWidth(140),  // Category / Role
  3: FixedColumnWidth(120),  // Phone / Contact
  4: FixedColumnWidth(110),  // City / Province
  5: FixedColumnWidth(130),  // Amount / Balance
  6: FixedColumnWidth(130),  // Date
  7: FixedColumnWidth(120),  // Status Badge
  8: FixedColumnWidth(80),   // Actions Menu
};
```

### B. Full Table Widget (`{feature}_table.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/layout_adaptive/widgets/cutom_table.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/core/utils/extensions/date_time_extentision.dart';
import 'package:purexo/core/network/mony_helper.dart';

class MyFeatureTable extends StatelessWidget {
  final List<MyFeatureModel> data;
  final MyFeatureCubit cubit;

  const MyFeatureTable({
    super.key,
    required this.data,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTable(
      minWidth: 1050, // Minimum table width before horizontal scrolling triggers
      columnWidths: const {
        0: FixedColumnWidth(60),
        1: FixedColumnWidth(180),
        2: FixedColumnWidth(140),
        3: FixedColumnWidth(130),
        4: FixedColumnWidth(140),
        5: FixedColumnWidth(120),
        6: FixedColumnWidth(80),
      },
      headers: [
        "#",
        "name".tr(),
        "department".tr(),
        "amount".tr(),
        "created_at".tr(),
        "status".tr(),
        "actions".tr(),
      ],
      rows: data.map((item) => _buildRow(context, item)).toList(),
    );
  }

  List<Widget> _buildRow(BuildContext context, MyFeatureModel item) {
    final TextStyle cellStyle = CustomAppFontStyle.regular14.copyWith(
      color: AppColors.primary,
    );

    return [
      // 0: Index
      Center(child: Text((data.indexOf(item) + 1).toString(), style: cellStyle)),
      
      // 1: Name (Always safely handle null)
      Center(child: Text(item.name ?? "-", style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
      
      // 2: Category / Department
      Center(child: Text(item.categoryName ?? "-", style: cellStyle)),
      
      // 3: Money with formatting and localization
      Center(
        child: Text(
          "${MonyHelper.formatMoney(item.amount ?? 0)} ${'currency_symbol'.tr()}",
          style: cellStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      
      // 4: Formatted Date
      Center(child: Text(item.createdAt?.toCustomFormat() ?? "-", style: cellStyle)),
      
      // 5: Status Badge
      Center(child: ItemStatusWidget(status: item.status)),
      
      // 6: Actions Menu (Single feature cubit passed)
      Center(child: ItemActionsMenu(item: item, cubit: cubit)),
    ];
  }
}
```

---

## 3. Status Badge Component

Create distinct gradient or colored badges for each status (localized via `.tr()`):

```dart
class ItemStatusWidget extends StatelessWidget {
  final String? status;
  const ItemStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      gradient: _getGradient(status),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(8),
      child: Text(
        'status_${status ?? "unknown"}'.tr(),
        style: CustomAppFontStyle.regular14.copyWith(color: Colors.white),
      ),
    );
  }

  LinearGradient _getGradient(String? status) {
    switch (status) {
      case 'active':
      case 'completed':
      case 'available':
        return AppGradient.greenGradient;
      case 'busy':
      case 'pending':
        return AppGradient.orangeGradient;
      case 'cancelled':
      case 'on_leave':
        return AppGradient.redGradient;
      default:
        return AppGradient.grayGradient;
    }
  }
}
```

---

## 4. Row Actions Menu Component (Fully Localized)

```dart
class ItemActionsMenu extends StatelessWidget {
  final MyFeatureModel item;
  final MyFeatureCubit cubit; // Single feature Cubit handles all actions

  const ItemActionsMenu({super.key, required this.item, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.gray71717A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (action) {
        switch (action) {
          case 'view':
            context.go('${AppRouter.myFeature}/${item.id}');
            break;
          case 'edit':
            _showEditDialog(context);
            break;
          case 'delete':
            _showDeleteConfirm(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('view_details'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text('edit'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
              const SizedBox(width: 8),
              Text('delete'.tr(), style: const TextStyle(color: AppColors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        if (isMobile) {
          return Dialog.fullscreen(
            child: EditItemDialog(item: item, cubit: cubit, isFullScreen: true),
          );
        }
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: EditItemDialog(item: item, cubit: cubit, isFullScreen: false),
          ),
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('delete_confirmation_msg'.tr(namedArgs: {'name': item.name ?? ''})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (item.id != null) {
                cubit.deleteItem(item.id!);
              }
            },
            child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Integrating Loading Shimmer, Empty, and Error States

In the main page widget's `CustomScrollView`:

```dart
// 1. Loading State (Must match table headers & columnWidths!)
if (state.status == RequestStatusEnum.loading)
  CustomTableShimmer(
    headers: [
      "#", 'name'.tr(), 'category'.tr(), 'amount'.tr(), 'created_at'.tr(), 'status'.tr(), 'actions'.tr()
    ],
    columnWidths: const {
      0: FixedColumnWidth(60),
      1: FixedColumnWidth(180),
      2: FixedColumnWidth(140),
      3: FixedColumnWidth(130),
      4: FixedColumnWidth(140),
      5: FixedColumnWidth(120),
      6: FixedColumnWidth(80),
    },
  ).toSliver()

// 2. Failure State
else if (state.status == RequestStatusEnum.failure)
  ErrorPage(
    errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
    onPressed: () => cubit.getAllItems(),
  ).toSliver()

// 3. Empty State
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

// 4. Success Table
else
  SliverToBoxAdapter(
    child: MyFeatureTable(
      data: state.items,
      cubit: cubit,
    ),
  ),
```

---

## 6. Bottom Pagination Integration (`CustomPaginationTable`)

Placed at the bottom of the page column:

```dart
if (state.status == RequestStatusEnum.success && state.items.isNotEmpty)
  Align(
    alignment: Alignment.bottomCenter,
    child: CustomPaginationTable(
      onTapNext: () => cubit.changePage(cubit.paginationParams.page! + 1),
      onTapPrevious: () => cubit.changePage(cubit.paginationParams.page! - 1),
      onTapNumber: (pageNum) => cubit.changePage(pageNum),
      pagesCount: cubit.totalPages, // Or state.totalPages / cubit.paginationParams.page
      currentPage: cubit.paginationParams.page ?? 1,
    ),
  ),
```

---

## 7. Adaptive View Switcher: Desktop Table vs. Tablet/Mobile Cards

> **Why this matters**: In dense dashboard pages, large tables look clean on Desktop screens (`width >= 1000`), but on Tablets (`700 <= width < 1000`) and Phones (`width < 700`), tables force cumbersome horizontal dragging. Instead, seamlessly switch to **Informative Data Cards** for smaller viewports!

### A. The Responsive Data Card Component (`{feature}_card.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purexo/core/network/mony_helper.dart';
import 'package:purexo/core/utils/extensions/date_time_extentision.dart';
import 'package:purexo/core/utils/extensions/theme_mode_extensions.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/shared/widgets/custom_container.dart';

class MyFeatureCard extends StatelessWidget {
  final MyFeatureModel item;
  final MyFeatureCubit cubit;

  const MyFeatureCard({
    super.key,
    required this.item,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return CustomContainer(
      backGroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      enableShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          // ─── Header: Name, Status Badge, & Actions Popup ──────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name ?? 'no_name'.tr(),
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  ItemStatusWidget(status: item.status),
                  ItemActionsMenu(item: item, cubit: cubit),
                ],
              ),
            ],
          ),

          const Divider(height: 1),

          // ─── Body Details: Category, Governorate, Money ───────────────
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                icon: Icons.category_outlined,
                label: item.categoryName ?? "-",
                isDark: isDark,
              ),
              _buildDetailChip(
                icon: Icons.location_on_outlined,
                label: item.governorate ?? "-",
                isDark: isDark,
              ),
              _buildDetailChip(
                icon: Icons.account_balance_wallet_outlined,
                label: "${MonyHelper.formatMoney(item.amount ?? 0)} ${'currency_symbol'.tr()}",
                isDark: isDark,
                isBold: true,
              ),
              _buildDetailChip(
                icon: Icons.calendar_today_outlined,
                label: item.createdAt?.toCustomFormat() ?? "-",
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 16, color: AppColors.gray71717A),
        Text(
          label,
          style: CustomAppFontStyle.regular14.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDark ? AppColors.white : AppColors.gray71717A,
          ),
        ),
      ],
    );
  }
}
```

### B. The Adaptive Table-or-Card View Component

Wrap your content inside an adaptive switcher that evaluates `constraints.maxWidth`:

```dart
class AdaptiveFeatureView extends StatelessWidget {
  final List<MyFeatureModel> items;
  final MyFeatureCubit cubit;

  const AdaptiveFeatureView({
    super.key,
    required this.items,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop (width >= 1000): Render full Data Table
        if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
          return MyFeatureTable(data: items, cubit: cubit);
        }

        // Tablet (700 <= width < 1000): Render 2-Column Responsive Card Grid
        if (constraints.maxWidth >= ScreenWidthBreakpoints.tablet) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 160,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => MyFeatureCard(
              item: items[index],
              cubit: cubit,
            ),
          );
        }

        // Mobile (width < 700): Render 1-Column Vertical Card List
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => MyFeatureCard(
            item: items[index],
            cubit: cubit,
          ),
        );
      },
    );
  }
}
```

### C. Adaptive Loading Shimmer (Table on Desktop, Cards on Mobile/Tablet)

```dart
class AdaptiveFeatureShimmer extends StatelessWidget {
  const AdaptiveFeatureShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
          return const CustomTableShimmer(
            headers: ["#", "الاسم", "القسم", "المبلغ", "التاريخ", "الحالة", "الإجراءات"],
            columnWidths: {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(180),
              2: FixedColumnWidth(140),
              3: FixedColumnWidth(130),
              4: FixedColumnWidth(140),
              5: FixedColumnWidth(120),
              6: FixedColumnWidth(80),
            },
          );
        }

        // Card Shimmer Skeleton for Tablet / Mobile
        final int columns = constraints.maxWidth >= ScreenWidthBreakpoints.tablet ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 160,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const CustomShimmerContainer(
            borderRadius: 12,
            height: 160,
          ),
        );
      },
    );
  }
}
```


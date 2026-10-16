---
name: dashboard-responsive-layout
description: >-
  Use this skill when designing or implementing responsive layouts, screen resizing, adaptive widgets,
  and breakpoints in Flutter dashboard projects. Covers ScreenWidthBreakpoints, AdaptiveLayout,
  ScreenAdaptiveLayout, collapsible sidebar behaviors (desktop/tablet/mobile), responsive grids, and avoiding overflow issues.
---

# Dashboard Responsive Layout & Resizing Skill

This skill provides guidelines and practical code templates for building adaptive, responsive dashboard screens that gracefully handle dynamic window resizing on Desktop, Tablet, and Mobile.

---

## 1. Breakpoint System (`ScreenWidthBreakpoints`)

Located at: `lib/shared/widgets/responsive_helper/screen_width_breakpoints.dart`

```dart
class ScreenWidthBreakpoints {
  static const double desktop = 1000;
  static const double tablet = 700;
  static const double mobile = 400;
}
```

### Breakpoint Matrix:
| Device Mode | Condition | Primary UX Behavior |
| :--- | :--- | :--- |
| **Mobile** | `width <= 700` | Sidebar hidden, hamburger button in header opens `CustomDrawer`. Grid items stack vertically (1 column). Tables horizontally scrollable. |
| **Tablet** | `700 < width < 1000` | 100px mini icon rail sidebar. Header displays compact actions. Grids display in 2 columns. |
| **Desktop** | `width >= 1000` | Full 270px sidebar (collapsible to 100px via toggle). Full summary cards (3–4 columns). Tables display full layout. |

---

## 2. Helper Primitives

### A. Quick Queries
```dart
import 'package:purexo/shared/widgets/responsive_helper/adaptive_layout.dart';

final isMobile = AdaptiveLayout.isMobile(context);   // width <= 700
final isTablet = AdaptiveLayout.isTablet(context);   // 700 < width < 1000
final isDesktop = AdaptiveLayout.isDesktop(context); // width >= 1000
```

### B. Inline Value Interpolation (`getResponsiveValue`)
Use for font sizes, paddings, icon sizes, and card heights:

```dart
final double headerHeight = AdaptiveLayout.getResponsiveValue(
  context: context,
  mobile: 100.0,
  tablet: 75.0,
  desktop: 75.0,
);

final double fontSize = AdaptiveLayout.getResponsiveValue(
  context: context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);
```

### C. Declarative Layout Switching (`AdaptiveLayout`)
```dart
AdaptiveLayout(
  mobileLayout: (context) => const MobileSummaryView(),
  tabletLayout: (context) => const TabletSummaryView(),
  desktopLayout: (context) => const DesktopSummaryView(),
)
```

### D. Adaptive Padding (`AdaptivePadding`)
```dart
AdaptivePadding(
  mobilePadding: 12,
  tabletPadding: 16,
  desktopPadding: 24,
  child: MyContentWidget(),
)
```

---

## 3. Sidebar Responsive Mechanics in `AppLayout`

The core layout (`lib/shared/app_layout/presentation/pages/app_layout.dart`) implements 3 distinct sidebar behaviors:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 1. Sidebar Column
    ScreenAdaptiveLayout(
      // Mobile: Do not render sidebar in row (drawer handles mobile)
      mobileLayout: (context) => const SizedBox.shrink(),
      
      // Tablet: Fixed 100px mini-bar with icon-only mode
      tabletLayout: (context) => SizedBox(
        width: 100,
        child: CustomSideBarList(
          isMobile: false,
          isTablet: true,
          items: layoutItems(context),
          onToggle: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      
      // Desktop: Smooth animated toggle between 270px and 100px
      desktopLayout: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isCollapsed ? 100 : 270,
        child: CustomSideBarList(
          isMobile: false,
          isTablet: isCollapsed,
          items: layoutItems(context),
          onToggle: () {
            setState(() {
              isCollapsed = !isCollapsed;
            });
          },
        ),
      ),
    ),
    
    // 2. Main Content Column
    Expanded(
      child: Column(
        children: [
          // Header (scales height adaptively)
          CustomHeaderLayout(...),
          // Router Child Screen
          Expanded(child: widget.child),
        ],
      ),
    ),
  ],
)
```

---

## 4. Responsive Summary Cards & Metric Grids

When displaying metrics/statistics at the top of a feature page (e.g. `TeacherSummarySection`, `OrderStatisticsSection`), use this responsive grid pattern:

```dart
class FeatureSummarySection extends StatelessWidget {
  const FeatureSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate columns based on container width
        final int crossAxisCount = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 1100
                ? 2
                : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth < 600 ? 3.0 : 2.2,
          children: [
            SummaryCard(title: 'total_records'.tr(), value: '1,240', icon: AppIcons.total),
            SummaryCard(title: 'status_active'.tr(), value: '890', icon: AppIcons.active),
            SummaryCard(title: 'status_pending'.tr(), value: '230', icon: AppIcons.pending),
            SummaryCard(title: 'status_completed'.tr(), value: '120', icon: AppIcons.completed),
          ],
        );
      },
    );
  }
}
```

---

## 5. Responsive Filter & Search Bars

Filter bars should wrap controls gracefully instead of causing right-edge pixel overflows:

```dart
class FeatureFilterSection extends StatelessWidget {
  const FeatureFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;

        if (isCompact) {
          // Stacked layout for small screens / mobile
          return Column(
            spacing: 12,
            children: [
              SearchTextField(onChanged: (val) => cubit.search(val)),
              Row(
                spacing: 12,
                children: [
                  Expanded(child: StatusDropdown(...)),
                  Expanded(child: DateRangePickerButton(...)),
                ],
              ),
            ],
          );
        }

        // Single row for desktop
        return Row(
          spacing: 16,
          children: [
            Expanded(flex: 3, child: SearchTextField(...)),
            Expanded(flex: 2, child: StatusDropdown(...)),
            Expanded(flex: 2, child: DateRangePickerButton(...)),
            const ResetFiltersButton(),
          ],
        );
      },
    );
  }
}
```

---

## 6. Adaptive Data Presentation: Table-to-Card Pattern (Desktop vs. Tablet/Mobile)

> **Golden Rule**: On Desktop (`width >= 1000`), render dense data tables (`CustomTable` / `EnhancedTable`). On Tablet (`700 <= width < 1000`) and Mobile (`width < 700`), dense tables require excessive horizontal scrolling. Instead, switch to an **Adaptive Card View** (2-column grid on Tablet, 1-column list on Mobile).

### The Adaptive Presenter Pattern:

```dart
class AdaptiveDataPresenter<T> extends StatelessWidget {
  final List<T> data;
  final Widget Function(List<T> items) tableBuilder;
  final Widget Function(T item) cardBuilder;

  const AdaptiveDataPresenter({
    super.key,
    required this.data,
    required this.tableBuilder,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: Full Data Table
        if (constraints.maxWidth >= ScreenWidthBreakpoints.desktop) {
          return tableBuilder(data);
        }

        // Tablet: 2-Column Responsive Card Grid
        if (constraints.maxWidth >= ScreenWidthBreakpoints.tablet) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 180, // Adapt to card content height
            ),
            itemCount: data.length,
            itemBuilder: (context, index) => cardBuilder(data[index]),
          );
        }

        // Mobile: 1-Column Card List
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => cardBuilder(data[index]),
        );
      },
    );
  }
}
```

### Adaptive Loading Shimmers:
- **Desktop**: Returns `CustomTableShimmer(headers: [...], columnWidths: {...})`.
- **Tablet/Mobile**: Returns `CardShimmerGrid` (2 columns on tablet) or `CardShimmerList` (1 column on mobile) so the skeleton matches the exact rendered layout.

---

## 7. Rules to Prevent Pixel Overflows During Window Resize

1. **Never use fixed screen-width calculations**: Avoid `MediaQuery.of(context).size.width - 200` directly on non-scrolling elements. Use `Expanded`, `Flexible`, or `LayoutBuilder` constraints.
2. **Always wrap horizontal text inside tables & rows**:
   ```dart
   Text(
     item.title,
     maxLines: 1,
     overflow: TextOverflow.ellipsis,
   )
   ```
3. **Always wrap tables in horizontal SingleChildScrollView**:
   Data tables should never clip or shrink columns to illegible widths. See the `dashboard-table-system` skill for the horizontal scrolling container pattern.
4. **Adaptive Dialog Sizing (Mobile Fullscreen Dialog Rule - MANDATORY)**:
   > **Golden Rule:** On Mobile (`AdaptiveLayout.isMobile(context)` or screen width `<= 700px`), all dialogs (Create/Edit, Filters, Details, Confirmations) MUST open in **Full Screen** (`Dialog.fullscreen`). Small floating modals on mobile cause severe layout constraint issues, double-nested scrollbars, and keyboard overlap bugs. On Tablet and Desktop, dialogs render as centered floating modals constrained to a maximum width (e.g. 650–700px).

   ```dart
   showDialog(
     context: context,
     useSafeArea: true,
     builder: (dialogCtx) {
       final isMobile = AdaptiveLayout.isMobile(dialogCtx);

       // 1. Mobile: Native Fullscreen Dialog
       if (isMobile) {
         return Dialog.fullscreen(
           child: MyDialogContent(isFullScreen: true),
         );
       }

       // 2. Desktop & Tablet: Centered Constrained Modal Dialog
       return Dialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         child: ConstrainedBox(
           constraints: BoxConstraints(
             maxWidth: 650,
             maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.9,
           ),
           child: const MyDialogContent(isFullScreen: false),
         ),
       );
     },
   );
   ```

   **Inside `MyDialogContent`**:
   - When `isFullScreen: true`, render a full-width header (e.g. `AppBar` or customized top bar with a back/close icon, localized title, and action buttons) with clean padding.
   - When `isFullScreen: false`, render a dialog header with title and a trailing close icon button.
   - Always wrap form body in `SingleChildScrollView` to prevent keyboard resize overflows.


# Formatting, Utility & i18n Architecture Rules

This reference documents the mandatory architectural standards for **Internationalization (i18n)**, **Date/Time formatting**, **Money formatting**, and **Pagination Lifecycles** across the dashboard.

---

## 0. Strict Internationalization Standard (`easy_localization` + `.tr()`)

### ❌ Anti-Pattern: Hardcoded Text in Widgets
```dart
// BAD: Hardcoded text in UI
Text("إدارة الحجوزات")
Text("Delete")
```

### ✅ Clean Pattern: Centralized Translation via `.tr()`
All static UI text (headers, buttons, badges, table columns, placeholders, dialog titles, validation messages) must be resolved via:
```dart
Text('bookings_header'.tr())
Text('delete'.tr())
```

### Golden Rules:
1. Every string that is NOT dynamic backend data must have an entry in both `assets/translations/ar-EG.json` and `assets/translations/en-US.json`.
2. Never concatenate localized strings manually; use named arguments if parameterized: `'welcome_user'.tr(namedArgs: {'name': name})`.

---

## 1. Centralized Date & Time Formatting (`DateTimeExtension`)

### ❌ Anti-Pattern: Ad-Hoc DateFormat in Widgets
```dart
// BAD: Importing intl and duplicating DateFormat directly inside UI widgets
Text(DateFormat('yyyy/MM/dd', 'ar').format(item.date!))
Text(DateFormat('hh:mm a', 'ar').format(item.date!))
```

### ✅ Clean Pattern: Centralized `DateTimeExtension`
Location: `lib/core/utils/extensions/date_time_extentision.dart`

```dart
import 'package:purexo/core/utils/extensions/date_time_extentision.dart';

// Standard formatted date (e.g. "2026/09/16")
Text(item.createdAt.toCustomFormat(), style: cellStyle);

// Standard date with time (e.g. "2026/09/16 - 10:30 ص")
Text(item.createdAt.toCustomFormatWithTime(), style: cellStyle);
```

### Golden Rules:
1. **Never import `intl` in feature UI** just to format dates or times. Always import and use `DateTimeExtension`.
2. **Null-Safety Guaranteed**: `DateTimeExtension` is defined on `DateTime?` and returns `""` when the object is `null`, eliminating force unwraps (`date!`) and null check boilerplate.

---

## 2. Centralized Money Formatting (`MonyHelper`)

### ❌ Anti-Pattern: Manual String Interpolation
```dart
// BAD: Hardcoding currency symbols and manual string concatenation
Text('${item.walletBalance} د.ع')
Text('$price L.E')
```

### ✅ Clean Pattern: Centralized `MonyHelper`
Location: `lib/core/network/mony_helper.dart`

```dart
import 'package:purexo/core/network/mony_helper.dart';

// Formatted with thousand separators
Text(
  "${MonyHelper.formatMoney(item.amount ?? 0)} ${'currency_symbol'.tr()}",
  style: cellStyle.copyWith(fontWeight: FontWeight.bold),
)
```

---

## 3. Cubit Pagination Lifecycles

This dashboard uses two distinct pagination patterns based on the UI requirement:

### Pattern A: Data Table Pagination (`CustomPaginationTable`)
- Used for tabular desktop grids (`CustomTable` / `EnhancedTable`).
- Managed via `PaginationParams(page: currentPage, limit: limit)`.
- Cubit exposes `changePage(int newPage)` which fetches and updates the table.

### Pattern B: Infinite Scroll Pagination (`PaginationMixin`)
- Used for vertical scrollable feeds, mobile views, or drawer activity feeds.
- Mixed into the Cubit: `class MyCubit extends SafeCubit<MyState> with PaginationMixin`
- Location: `lib/core/mixins/pagination_mixin.dart`

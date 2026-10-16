# Cubit & State Patterns Reference

This reference documents the state management architecture used across the dashboard (`SafeCubit`, single-Cubit policy, granular section statuses, `RequestStatusEnum`, parallel fetching, and rebuild isolation).

---

## 0. The Strict "SINGLE-CUBIT PER PAGE / FEATURE" Policy

In this dashboard architecture:
1. **Each feature or page has EXACTLY ONE Cubit.**
2. **Never create auxiliary Cubits** (e.g. do NOT create a separate `FormCubit`, `FilterCubit`, `DialogCubit`, or `DetailsCubit` for the same feature).
3. The feature Cubit (e.g. `BookingsCubit`) coordinates:
   - Data loading and pagination
   - Filter queries and debounced search
   - Detail view data and sub-route state
   - Creation / edit dialog submissions and inline entity creation
   - Action triggers (status updates, deletion, assignments)
4. State mutations are grouped cleanly in `FeatureState` using copyWith.

---

## 1. Granular Section States vs Monolithic State

In dashboard landing pages or composite screens (e.g. `HomeDashboardCubit` or `SettingsCubit`), multiple asynchronous requests happen concurrently.

### ❌ Anti-Pattern: Monolithic State Unions
```dart
// BAD: If one request fails, the entire page enters loading or error state
sealed class DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState { ... }
class DashboardError extends DashboardState { final String msg; }
```

### ✅ Clean Architecture Pattern: Granular Status per Section
```dart
class HomeDashboardState {
  final RequestStatusEnum kpiStatus;
  final RequestStatusEnum todayScheduleStatus;
  final RequestStatusEnum techAvailabilityStatus;

  final DashboardKpiModel? kpiData;
  final List<BookingModel> todaySchedule;
  final List<TechnicianModel> availableTechnicians;
  final String? errMessage;

  const HomeDashboardState({
    this.kpiStatus = RequestStatusEnum.initial,
    this.todayScheduleStatus = RequestStatusEnum.initial,
    this.techAvailabilityStatus = RequestStatusEnum.initial,
    this.kpiData,
    this.todaySchedule = const [],
    this.availableTechnicians = const [],
    this.errMessage,
  });

  HomeDashboardState copyWith({ ... }) { ... }
}
```

**Benefits**:
1. If one API fails or takes longer, other sections continue to render seamlessly.
2. The user can retry loading ONLY the failed section without re-fetching working sections.
3. Shimmer skeletons show ONLY for sections that are actively loading.

---

## 2. SafeCubit Integration

All Cubits in this app extend `SafeCubit<T>` instead of raw `Cubit<T>`.

Location: `lib/core/base/safe_cubit.dart`

```dart
abstract class SafeCubit<T> extends Cubit<T> {
  SafeCubit(super.initialState);

  @override
  void emit(T state) {
    if (isClosed) return;
    super.emit(state);
  }
}
```

**Why**: `SafeCubit` prevents `StateError: Cannot emit new states after calling close` exceptions when asynchronous network calls or timers resolve after the user has navigated away from the screen.

---

## 3. RequestStatusEnum Matrix

Location: `lib/core/utils/enums/request_status_enum.dart`

```dart
enum RequestStatusEnum {
  initial,
  loading,
  success,
  failure,
  empty,
  loadingMore,
  successMore,
  failureMore,
}
```

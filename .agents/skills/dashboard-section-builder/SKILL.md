---
name: dashboard-section-builder
description: >-
  Use this skill when building, modifying, or composing reactive dashboard landing sections,
  metric summary cards, charts, and sliver widgets in Flutter dashboard projects.
  Covers granular section state architecture, parallel Future.wait fetching, independent retry,
  Shimmer skeletons, SliverMainAxisGroup, and buildWhen rebuild isolation.
---

# Dashboard Section Builder & Composable Slivers Skill

This skill provides step-by-step instructions and architectural patterns for creating composable, reactive sections on dashboard landing pages or composite overview screens (e.g. `AdminDashboardLandingPage`).

---

## 1. Core Architecture Principles

1. **Independent Reactive Sections**: Each section on the dashboard has its own `RequestStatusEnum {section}Status` and data model in state. A failure or delay in one section (e.g. analytics graph) NEVER crashes or blocks other sections (e.g. statistics cards or pending approvals table).
2. **Parallel Fetching**: `loadDashboardData()` uses `Future.wait([getStatistics(), getGraphData(), getPendingList()])`.
3. **Independent Error Retry**: If a section fails, its `ErrorPage` retry button triggers ONLY that specific section's fetch method (`cubit.get{Section}()`).
4. **Rebuild Isolation with `buildWhen`**: Every section widget uses `buildWhen` in `BlocBuilder` to ensure updates to one section never trigger rebuilds in others.
5. **Exact Match Shimmers**: Every section provides a shimmer skeleton widget matching its exact layout dimensions.
6. **Centralized Utilities**: Always use `MonyHelper.formatMoney()` for prices/balances and `DateTimeExtension` for dates.

---

## 2. Step-by-Step Implementation Flow

### Step 1: Add Granular Fields to Cubit State
In `presentation/manager/{feature}_state.dart`:

```dart
class AdminDashboardState {
  final RequestStatusEnum statsStatus;
  final RequestStatusEnum {section}Status;

  final StatisticsModel? statistics;
  final List<{Section}Model> {section}List;
  final String? errMessage;

  const AdminDashboardState({
    this.statsStatus = RequestStatusEnum.initial,
    this.{section}Status = RequestStatusEnum.initial,
    this.statistics,
    this.{section}List = const [],
    this.errMessage,
  });

  AdminDashboardState copyWith({
    RequestStatusEnum? statsStatus,
    RequestStatusEnum? {section}Status,
    StatisticsModel? statistics,
    List<{Section}Model>? {section}List,
    String? errMessage,
  }) {
    return AdminDashboardState(
      statsStatus: statsStatus ?? this.statsStatus,
      {section}Status: {section}Status ?? this.{section}Status,
      statistics: statistics ?? this.statistics,
      {section}List: {section}List ?? this.{section}List,
      errMessage: errMessage ?? this.errMessage,
    );
  }
}
```

### Step 2: Add Parallel Fetch Method to Cubit
In `presentation/manager/{feature}_cubit.dart`:

```dart
Future<void> get{Section}() async {
  emit(state.copyWith({section}Status: RequestStatusEnum.loading));

  final result = await get{Section}UseCase(const NoParams());

  result.fold(
    (failure) => emit(
      state.copyWith(
        {section}Status: RequestStatusEnum.failure,
        errMessage: failure.errMessage,
      ),
    ),
    (data) => emit(
      state.copyWith(
        {section}Status: data.isEmpty ? RequestStatusEnum.empty : RequestStatusEnum.success,
        {section}List: data,
      ),
    ),
  );
}

// Bootstrap all dashboard sections in parallel
Future<void> loadDashboardData() async {
  await Future.wait([
    getStatistics(),
    get{Section}(),
  ]);
}
```

### Step 3: Build the Composable Section Widget
In `presentation/widgets/{section}_section.dart`:

```dart
class {Section}Section extends StatelessWidget {
  const {Section}Section({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      buildWhen: (previous, current) =>
          previous.{section}Status != current.{section}Status ||
          previous.{section}List != current.{section}List,
      builder: (context, state) {
        final cubit = context.read<AdminDashboardCubit>();

        // 1. Loading State (Shimmer Skeleton)
        if (state.{section}Status == RequestStatusEnum.loading) {
          return const {Section}Shimmer().toSliver();
        }

        // 2. Failure State (Independent Retry)
        if (state.{section}Status == RequestStatusEnum.failure) {
          return ErrorPage(
            errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
            onPressed: () => cubit.get{Section}(),
          ).toSliver();
        }

        // 3. Empty State
        if (state.{section}Status == RequestStatusEnum.empty || state.{section}List.isEmpty) {
          return const SizedBox.shrink().toSliver();
        }

        // 4. Success State
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: SectionHeaderWithAction(
                title: '{section_title}'.tr(),
                onPressed: () => context.go(AppRouter.{sectionRoute}),
              ),
            ),
            const SizedBox(height: 12).toSliver(),
            SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 130,
              ),
              itemCount: state.{section}List.length,
              itemBuilder: (context, index) {
                return {Section}Card(item: state.{section}List[index]);
              },
            ),
          ],
        );
      },
    );
  }
}
```

---

## 3. Assembling the Dashboard Landing Page

In `presentation/pages/admin_dashboard_landing_page.dart`:

```dart
class AdminDashboardLandingPage extends StatelessWidget {
  const AdminDashboardLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AdminDashboardCubit>()..loadDashboardData(),
      child: RefreshIndicator(
        onRefresh: () => context.read<AdminDashboardCubit>().loadDashboardData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const DashboardStatisticsSection(),
            const SizedBox(height: 20).toSliver(),
            
            const DashboardGraphSection(),
            const SizedBox(height: 20).toSliver(),
            
            const {Section}Section(),
            const SizedBox(height: 24).toSliver(),
          ],
        ),
      ),
    );
  }
}
```

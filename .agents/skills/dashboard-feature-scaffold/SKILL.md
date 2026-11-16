---
name: dashboard-feature-scaffold
description: >-
  Use this skill when scaffolding a complete new feature or creating a clone/module
  in this Flutter dashboard architecture. Covers end-to-end Clean Architecture (data, domain, presentation),
  SafeCubit with SearchMixin and RequestStatusEnum, DI registration with get_it, GoRouter ShellRoute integration,
  responsive layout, data tables, and filters.
---

# Dashboard Feature Scaffold & Clone Generator Skill

This skill is the master blueprint for creating or cloning any dashboard module from start to finish, following the exact Clean Architecture conventions, state management rules, DI registrations, and routing setups of this project.

---

## 0. Absolute Engineering Laws (NON-NEGOTIABLE)

1. **NO Entity Classes:**
   - **Do NOT create `Entity` classes or `domain/entities/` folders.**
   - Use `{Name}Model` exclusively across all three layers (Data, Domain, Presentation).
   - Domain Repositories and UseCases return and accept `{Name}Model` directly.
2. **100% Nullable Models:**
   - **Every single field in every Model MUST be nullable (`final Type? property;`).**
   - **NO `required` constructor parameters** in models.
   - Use `num?` for numbers to parse both `int` and `double` safely.
   - Parse JSON defensively (e.g. `json['id']?.toString()`, `DateTime.tryParse(...)`).
3. **Exactly ONE Cubit Per Feature / Page:**
   - **A single page/feature has ONLY ONE Cubit.** Never create secondary or child Cubits for forms, dialogs, filters, or details.
   - All mutations, dialog triggers, pagination, and filter changes flow through the single feature Cubit.
4. **Mandatory i18n Localization (`easy_localization` + `.tr()`):**
   - **ZERO hardcoded strings in UI widgets.**
   - Every static string (table headers, button labels, badge texts, dialog titles, placeholders, error messages) MUST use `'key'.tr()`.
   - Keys must exist in both `assets/translations/ar-EG.json` and `assets/translations/en-US.json`.
5. **No Code Generation:**
   - **No Freezed. No build_runner.** Use Dart 3 native records, sealed classes, and manual `fromJson`/`toJson`.
6. **Strict Standardized JSON Keys (camelCase Only):**
   - **Always use `id` (never `_id`), `customerId` (never `customer_id`), `technicianId` (never `technician_id`), `createdAt` (never `created_at`).**
   - **Never use fallback chaining (`json['id'] ?? json['_id']`).** Standardize all keys uniformly across both `fromJson` and `toJson`.
7. **Mobile Fullscreen Dialogs (MANDATORY):**
   - **On mobile devices (`AdaptiveLayout.isMobile(context)` or screen width `<= 700px`), EVERY dialog MUST open in full screen (`Dialog.fullscreen`).**
   - On tablet and desktop, dialogs open as centered modal dialogs constrained to `maxWidth: 650`–`700` and `maxHeight: 90%`.
   - Never show small floating modal dialogs on mobile screens.
8. **Universal Use of `CustomStackSelector<T>` for All Dropdowns (STRICT LAW):**
   - **ZERO `DropdownButton` or `DropdownButtonFormField` across the entire codebase.**
   - All dropdowns, selection menus, and picker triggers in forms, dialogs, tables, and filter bars MUST use `CustomStackSelector<T>` (`lib/shared/widgets/custom_stack_selector.dart`).

---

## 1. Feature Architecture Directory Tree

When creating a new feature named `{feature_name}`:

```text
lib/features/{feature_name}/
├── data/
│   ├── models/
│   │   └── {feature_name}_model.dart         # All fields are strictly nullable!
│   └── repo/
│       └── {feature_name}_repo_impl.dart
├── domain/
│   ├── repo/
│   │   └── {feature_name}_repo.dart          # Pure Dart: returns Future<Either<Failures, T>>
│   └── use_cases/
│       └── {feature_name}_use_cases.dart     # Accepts and returns Models
└── presentation/
    ├── manager/
    │   ├── {feature_name}_cubit.dart         # The ONLY Cubit for this entire feature
    │   └── {feature_name}_state.dart         # Unified state with RequestStatusEnum
    ├── pages/
    │   ├── {feature_name}_page.dart
    │   └── {feature_name}_details_page.dart  (optional sub-page)
    └── widgets/
        ├── {feature_name}_filter_bar.dart
        ├── {feature_name}_table.dart         # (Desktop Data Table)
        ├── {feature_name}_card.dart          # (Tablet / Mobile Data Card)
        ├── adaptive_{feature_name}_view.dart # (Responsive switcher)
        ├── {feature_name}_actions_menu.dart
        └── add_edit_{feature_name}_dialog.dart (optional dialog)
```

---

## 2. Step 1: 100% Nullable Data Model (`data/models/{name}_model.dart`)

> **RULES:**
> - NO Entity class. Model is used directly.
> - EVERY field is nullable (`Type?`).
> - No `required` constructor parameters.
> - No code generation (manual `fromJson` and `toJson`).

```dart
class {Name}Model {
  final String? id;
  final String? name;
  final String? status;
  final num? amount;
  final DateTime? createdAt;
  final Map<String, dynamic>? extra;

  const {Name}Model({
    this.id,
    this.name,
    this.status,
    this.amount,
    this.createdAt,
    this.extra,
  });

  factory {Name}Model.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const {Name}Model();
    return {Name}Model(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      status: json['status'] as String?,
      amount: json['amount'] as num?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      extra: json['extra'] is Map<String, dynamic> ? json['extra'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (amount != null) 'amount': amount,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (extra != null) 'extra': extra,
    };
  }
}
```

---

## 3. Step 2: Domain Layer (Pure Dart — ZERO Flutter Imports)

### A. Abstract Repository (`domain/repo/{name}_repo.dart`)
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../data/models/{name}_model.dart';

abstract class {Name}Repo {
  Future<Either<Failures, List<{Name}Model>>> getAll{Name}s({
    required PaginationParams params,
  });

  Future<Either<Failures, {Name}Model>> get{Name}ById({
    required String id,
  });

  Future<Either<Failures, {Name}Model>> create{Name}({
    required {Name}Model data,
  });

  Future<Either<Failures, {Name}Model>> update{Name}({
    required {Name}Model data,
  });

  Future<Either<Failures, String>> delete{Name}({
    required String id,
  });
}
```

### B. Use Cases (`domain/use_cases/{name}_use_cases.dart`)
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/uses_cases/use_cases.dart';
import '../../data/models/{name}_model.dart';
import '../repo/{name}_repo.dart';

class GetAll{Name}sUseCase
    extends UseCase<List<{Name}Model>, PaginationParams> {
  final {Name}Repo repo;
  GetAll{Name}sUseCase({required this.repo});

  @override
  Future<Either<Failures, List<{Name}Model>>> call(PaginationParams params) {
    return repo.getAll{Name}s(params: params);
  }
}

class Get{Name}ByIdUseCase extends UseCase<{Name}Model, String> {
  final {Name}Repo repo;
  Get{Name}ByIdUseCase({required this.repo});

  @override
  Future<Either<Failures, {Name}Model>> call(String id) {
    return repo.get{Name}ById(id: id);
  }
}

class Delete{Name}UseCase extends UseCase<String, String> {
  final {Name}Repo repo;
  Delete{Name}UseCase({required this.repo});

  @override
  Future<Either<Failures, String>> call(String id) {
    return repo.delete{Name}(id: id);
  }
}
```

---

## 4. Step 3: Data Layer Repository Implementation (`data/repo/{name}_repo_impl.dart`)

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/uses_cases/params.dart';
import '../../domain/repo/{name}_repo.dart';
import '../models/{name}_model.dart';

class {Name}RepoImpl implements {Name}Repo {
  final ApiConsumer apiConsumer;

  {Name}RepoImpl({required this.apiConsumer});

  @override
  Future<Either<Failures, List<{Name}Model>>> getAll{Name}s({
    required PaginationParams params,
  }) async {
    try {
      final response = await apiConsumer.get(
        EndPoints.{name}s,
        queryParameters: params.toJson(),
      );

      final List items = response['data'] ?? [];
      return Right(items.map((e) => {Name}Model.fromJson(e as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, {Name}Model>> get{Name}ById({
    required String id,
  }) async {
    try {
      final response = await apiConsumer.get('${EndPoints.{name}s}/$id');
      return Right({Name}Model.fromJson(response['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, {Name}Model>> create{Name}({
    required {Name}Model data,
  }) async {
    try {
      final response = await apiConsumer.post(
        EndPoints.{name}s,
        body: data.toJson(),
      );
      return Right({Name}Model.fromJson(response['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, {Name}Model>> update{Name}({
    required {Name}Model data,
  }) async {
    try {
      final response = await apiConsumer.patch(
        '${EndPoints.{name}s}/${data.id}',
        body: data.toJson(),
      );
      return Right({Name}Model.fromJson(response['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, String>> delete{Name}({required String id}) async {
    try {
      final response = await apiConsumer.delete('${EndPoints.{name}s}/$id');
      return Right(response['message']?.toString() ?? 'deleted_successfully');
    } on DioException catch (e) {
      return Left(ServerFailure.fromDioError(e));
    } catch (e) {
      return Left(ServerFailure(errMessage: e.toString()));
    }
  }
}
```

---

## 5. Step 4: Presentation State & Single SafeCubit

> **RULE:** Exactly ONE Cubit per feature. Form dialog actions, detail views, and filters all reside in this Cubit.

### A. State (`presentation/manager/{name}_state.dart`)
```dart
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/{name}_model.dart';

class {Name}State {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final List<{Name}Model> items;
  final {Name}Model? selectedItem;
  final String? errMessage;
  final int totalPages;

  const {Name}State({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.selectedItem,
    this.errMessage,
    this.totalPages = 1,
  });

  {Name}State copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    List<{Name}Model>? items,
    {Name}Model? selectedItem,
    String? errMessage,
    int? totalPages,
  }) {
    return {Name}State(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      items: items ?? this.items,
      selectedItem: selectedItem ?? this.selectedItem,
      errMessage: errMessage ?? this.errMessage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
```

### B. Single Feature Cubit (`presentation/manager/{name}_cubit.dart`)
```dart
import '../../../../core/base/safe_cubit.dart';
import '../../../../core/mixins/search_mixin.dart';
import '../../../../core/uses_cases/params.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../domain/use_cases/{name}_use_cases.dart';
import '../../data/models/{name}_model.dart';
import '{name}_state.dart';

class {Name}Cubit extends SafeCubit<{Name}State> with SearchMixin {
  final GetAll{Name}sUseCase getAllUseCase;
  final Delete{Name}UseCase deleteUseCase;

  {Name}Cubit({
    required this.getAllUseCase,
    required this.deleteUseCase,
  }) : super(const {Name}State());

  PaginationParams paginationParams = PaginationParams(page: 1, limit: 10);

  void addListener() {
    addSearchListener(() {
      getAllItems();
    });
  }

  Future<void> getAllItems() async {
    paginationParams = paginationParams.copyWith(
      filterList: [
        if (searchQuery.isNotEmpty)
          FilterParam(key: 'search', value: searchQuery.trim()),
      ],
    );

    emit(state.copyWith(status: RequestStatusEnum.loading));

    final result = await getAllUseCase(paginationParams);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: data.isEmpty ? RequestStatusEnum.empty : RequestStatusEnum.success,
          items: data,
        ),
      ),
    );
  }

  Future<void> deleteItem(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final result = await deleteUseCase(id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        getAllItems();
      },
    );
  }

  void changePage(int newPage) {
    if (newPage < 1) return;
    paginationParams = paginationParams.copyWith(page: newPage);
    getAllItems();
  }
}
```

---

## 6. Step 5: Presentation Main Page with Full Localization (`presentation/pages/{name}_page.dart`)

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/layout_adaptive/widgets/pagination_table.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/extensions/sliver_extentions.dart';
import '../../../../shared/widgets/custom_empty_widget.dart';
import '../../../../shared/widgets/error_page.dart';
import '../manager/{name}_cubit.dart';
import '../manager/{name}_state.dart';
import '../widgets/{name}_filter_bar.dart';
import '../widgets/adaptive_{name}_view.dart';
import '../widgets/{name}_shimmer.dart';

class {Name}Page extends StatelessWidget {
  const {Name}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<{Name}Cubit>()
        ..getAllItems()
        ..addListener(),
      child: BlocBuilder<{Name}Cubit, {Name}State>(
        builder: (context, state) {
          final cubit = context.read<{Name}Cubit>();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => cubit.getAllItems(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const {Name}FilterBar().toSliver(),
                      const SizedBox(height: 16).toSliver(),

                      if (state.status == RequestStatusEnum.loading)
                        const {Name}AdaptiveShimmer().toSliver()
                      else if (state.status == RequestStatusEnum.failure)
                        ErrorPage(
                          errorMessage: state.errMessage ?? 'failed_to_load'.tr(),
                          onPressed: () => cubit.getAllItems(),
                        ).toSliver()
                      else if (state.status == RequestStatusEnum.empty || state.items.isEmpty)
                        SliverFillRemaining(
                          child: ColoredBox(
                            color: Colors.white,
                            child: CustomEmptyWidget(title: 'no_data_found'.tr()),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: Adaptive{Name}View(
                            items: state.items,
                            cubit: cubit,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (state.status == RequestStatusEnum.success && state.items.isNotEmpty)
                CustomPaginationTable(
                  onTapNext: () => cubit.changePage((cubit.paginationParams.page ?? 1) + 1),
                  onTapPrevious: () => cubit.changePage((cubit.paginationParams.page ?? 1) - 1),
                  onTapNumber: (pageNum) => cubit.changePage(pageNum),
                  pagesCount: state.totalPages,
                  currentPage: cubit.paginationParams.page ?? 1,
                ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 7. Step 6: Registration Checklist (CRITICAL)

### 1. `lib/core/dependency_injection/dependency_injection.dart`
```dart
// 1. Repo
getIt.registerLazySingleton<{Name}Repo>(
  () => {Name}RepoImpl(apiConsumer: getIt<DioConsumer>()),
);

// 2. UseCases
getIt.registerLazySingleton<GetAll{Name}sUseCase>(
  () => GetAll{Name}sUseCase(repo: getIt<{Name}Repo>()),
);
getIt.registerLazySingleton<Delete{Name}UseCase>(
  () => Delete{Name}UseCase(repo: getIt<{Name}Repo>()),
);

// 3. Exactly ONE Cubit per feature registered as Factory
getIt.registerFactory<{Name}Cubit>(
  () => {Name}Cubit(
    getAllUseCase: getIt<GetAll{Name}sUseCase>(),
    deleteUseCase: getIt<Delete{Name}UseCase>(),
  ),
);
```

### 2. `lib/core/routing/routes.dart` & `app_router.dart`
- Add route path in `routes.dart`: `static const String {name} = '/{name}';`
- Add permissions in `_routePermissions` in `app_router.dart`.
- Add `GoRoute` inside `ShellRoute.routes` in `app_router.dart`.

### 3. `lib/core/utils/constants/app_list.dart`
- Add `SideBarItemModel` inside `layoutItems(context)` using localized strings (`tr()`).

---

## 8. Mandatory Formatting, Utility & i18n Standards

1. **Strict i18n Localization (`easy_localization`)**:
   - Always use `'key'.tr()`.
   - Never write raw Arabic or English text inside widget trees.
   - Any new label, button, badge, or message must be added to both `ar-EG.json` and `en-US.json`.
2. **Date & Time Formatting**:
   - Always use `item.createdAt.toCustomFormat()` or `.toCustomFormatWithTime()` from `lib/core/utils/extensions/date_time_extentision.dart`.
   - **Never** instantiate raw `DateFormat(...)` inside presentation or widget files.
3. **Money & Balance Formatting**:
   - Always use `MonyHelper.formatMoney(amount)` from `lib/core/network/mony_helper.dart`.
   - **Never** use manual string interpolation like `'$amount د.ع'` without `MonyHelper`.
4. **Dual Pagination Support**:
   - **Table Pagination**: Use `PaginationParams` + `CustomPaginationTable` for data grids.
   - **Infinite Scroll Pagination**: Use `PaginationMixin` with `addPaginationListener` for scrollable feeds and lists.
5. **Strict Ban on `setState`**:
   - `setState` is strictly forbidden for business logic, async statuses, or form mutations. All mutations flow through the single Cubit state.
6. **Adaptive Dialog Presentation Pattern (Mobile Fullscreen Dialog)**:
   - When launching any dialog (Create, Edit, Details, Filters):
   ```dart
   void showAdaptiveFeatureDialog({
     required BuildContext context,
     required Widget child,
   }) {
     showDialog(
       context: context,
       useSafeArea: true,
       builder: (dialogCtx) {
         final isMobile = AdaptiveLayout.isMobile(dialogCtx);
         if (isMobile) {
           return Dialog.fullscreen(child: child);
         }
         return Dialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
           child: ConstrainedBox(
             constraints: BoxConstraints(
               maxWidth: 650,
               maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.9,
             ),
             child: child,
           ),
         );
       },
     );
   }
   ```


# PROJECT ARCHITECTURE REFERENCE

> **App**: Computer World (`Iraq-Soft`)
> **Platform**: Flutter (Android, iOS, Web, Windows, macOS, Linux)
> **Dart SDK**: `^3.10.4`
> **Live API**: `https://computer-world.md-iraqsoft.com/`
> **Primary Language**: Arabic (RTL-first, with English fallback via `easy_localization`)

---

## SECTION 1 — FOLDER & FILE STRUCTURE

### 1.1 Architectural Pattern

**Clean Architecture + Feature-first organization**

The project follows a strict three-layer Clean Architecture pattern within each feature module:

```
feature/
  ├── data/         → Models, Repo Implementations, Data Sources
  ├── domain/       → Abstract Repos, Use Cases
  └── presentation/ → Cubits (state), Pages (screens), Widgets
```

Cross-cutting concerns live in `core/` and shared modules live in `shared/`.

### 1.2 Full Folder Tree

```
Iraq-Soft/
├── .github/
│   └── workflows/
│       └── main.yml                          # CI/CD: multi-platform build + Telegram deploy
├── assets/
│   ├── audio/
│   │   └── typing.mp3                        # Typing sound effect
│   ├── fonts/
│   │   ├── Hanimation-Regular.otf
│   │   ├── Hanimation-Bold.otf
│   │   ├── Hanimation-Light.otf
│   │   ├── Hanimation-Medium.otf
│   │   └── Hanimation-SemiBold.otf
│   ├── icons/                                # 110 SVG icons + 1 PNG app logo
│   │   └── *.svg / app_logo.png
│   ├── images/                               # 14 files (SVGs for empty states, PNGs for splash/map)
│   │   └── *.svg / *.png
│   ├── map_styles/
│   │   └── black_white.json                  # Custom Google Maps dark style
│   └── translations/
│       ├── ar.json                           # Arabic translations (primary)
│       └── en.json                           # English translations (fallback)
├── lib/
│   ├── main.dart                             # App entry point
│   ├── app.dart                              # MyApp widget (MaterialApp.router)
│   ├── firebase_options.dart                 # Firebase config (auto-generated)
│   ├── core/                                 # Cross-cutting infrastructure
│   │   ├── animation/                        # Reusable animation widgets
│   │   │   ├── fade_transition_animation.dart
│   │   │   ├── page_fade_transition.dart
│   │   │   ├── page_slide_transition.dart
│   │   │   ├── scale_transition_animation.dart
│   │   │   └── slide_transition_animation.dart
│   │   ├── api/                              # Networking layer
│   │   │   ├── api_consumer.dart             # Abstract API contract
│   │   │   ├── app_interceptor.dart          # Auth + token refresh interceptor
│   │   │   ├── device_service_helper.dart    # Device ID generation
│   │   │   ├── dio_consumer.dart             # Dio implementation of ApiConsumer
│   │   │   ├── end_points.dart               # All API endpoint constants
│   │   │   └── status_code.dart              # HTTP status code constants
│   │   ├── bloc_observer.dart                # Global BlocObserver for debugging
│   │   ├── dependency_injection/
│   │   │   ├── dependency_injection.dart     # get_it setup (setupGetIt function)
│   │   │   └── dependency_injection_impr.dart # Empty placeholder
│   │   ├── enums/
│   │   │   └── role_enum.dart                # RoleEnum { merchant, user }
│   │   ├── errors/
│   │   │   └── failures.dart                 # Failures hierarchy (ServerFailure, OfflineFailures, CacheFailures)
│   │   ├── extensions/
│   │   │   └── formate_phone_number.dart     # PhoneNumberFormatter extension (Egyptian +20, Iraqi +964)
│   │   ├── helpers/
│   │   │   └── notification_helper/
│   │   │       └── firebase_notifications.dart # FCM + local notifications + topic subscriptions
│   │   ├── models/
│   │   │   ├── audio_model.dart              # AudioModel (file/network source)
│   │   │   └── media_model.dart              # MediaModel (image/video/audio/document, file/network)
│   │   ├── routing/
│   │   │   ├── app_router.dart               # GoRouter config + custom page transitions
│   │   │   └── routes.dart                   # Route path constants (AppRouter class)
│   │   ├── storage/
│   │   │   └── cache_helper.dart             # SharedPreferences wrapper (AppSharedPreferences)
│   │   ├── uses_cases/
│   │   │   ├── params.dart                   # NoParams, PaginationParams, FilterParam, etc.
│   │   │   └── use_cases.dart                # Abstract UseCase<T, Params> base class
│   │   └── utils/
│   │       ├── constants/
│   │       │   ├── app_constants.dart         # SharedPrefs keys, phone code, font family, etc.
│   │       │   ├── app_enums.dart             # ImageActions, RequestStatueEnum
│   │       │   └── app_list.dart              # Bottom nav items, order status list, BookingStatusEnum
│   │       ├── extensions/
│   │       │   ├── dimensions.dart            # BuildContext extensions (width, height, isLandscape)
│   │       │   ├── nullable_strings_empty.dart # String? null/empty check
│   │       │   ├── sliver_extentions.dart      # Sliver helpers
│   │       │   └── theme_mode_extensions.dart   # isDarkMode convenience
│   │       └── theme/
│   │           ├── app_animations.dart        # Lottie animation path constants
│   │           ├── app_colors.dart            # 160+ color constants (AppColors)
│   │           ├── app_gradient.dart          # Gradient presets (AppGradient)
│   │           ├── app_icons.dart             # 130+ SVG icon path constants (AppIcons)
│   │           ├── app_images.dart            # Image path constants (AppImages)
│   │           ├── app_theme.dart             # Light + Dark ThemeData (MyAppTheme)
│   │           └── custom_app_font_styles.dart # 55+ TextStyle presets (10px–26px × 5 weights)
│   ├── features/                             # Feature modules
│   │   ├── categories/                       # Categories feature (data fetched at app-level)
│   │   │   ├── data/repo/categories_repo_impl.dart
│   │   │   ├── domain/repo/categories_repo.dart
│   │   │   └── domain/use_cases/categories_use_cases.dart
│   │   ├── notifications/                    # News + Notifications
│   │   │   ├── data/
│   │   │   │   ├── news_model.dart
│   │   │   │   ├── notification_model.dart
│   │   │   │   └── repo/notification_news_repo_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repo/notification_news_repo.dart
│   │   │   │   └── use_cases/notification_news_use_cases.dart
│   │   │   └── presentation/
│   │   │       ├── manager/
│   │   │       │   ├── notification_news_cubit.dart
│   │   │       │   └── notification_news_state.dart
│   │   │       ├── pages/notification_page.dart
│   │   │       └── widgets/ (news_card, news_shimmer, news_view, notification_card, etc.)
│   │   ├── store/                            # Merchant/Store features
│   │   │   ├── google_map/                   # Google Maps integration
│   │   │   │   └── presentation/cubits/ + pages/
│   │   │   ├── reels/                        # Store reels (order browsing)
│   │   │   │   └── presentation/pages/ + widgets/
│   │   │   ├── settings/                     # Store settings/profile edit
│   │   │   │   ├── data/repo/
│   │   │   │   ├── domain/repo/ + use_cases/
│   │   │   │   └── presentation/cubit/ + pages/ + widgets/
│   │   │   ├── store_home/                   # Store dashboard
│   │   │   │   ├── data/model/ + repo/
│   │   │   │   ├── domain/repo/ + use_cases/
│   │   │   │   └── presentation/cubit/ + pages/ + widgets/
│   │   │   └── store_orders/                 # Store order management
│   │   │       ├── data/models/ + repos/
│   │   │       ├── domain/repo/ + use_cases/
│   │   │       └── presentation/manager/ + pages/ + widgets/
│   │   └── user/                             # Customer features
│   │       ├── about_us/                     # About page
│   │       │   └── presentation/pages/ + widgets/
│   │       ├── check_out/                    # Checkout (cities, regions, delivery)
│   │       │   ├── data/models/ + repo/
│   │       │   ├── domain/repo/ + use_cases/
│   │       │   └── presentation/cubit/ + pages/ + widgets/
│   │       ├── home/                         # User home page
│   │       │   ├── data/models/search_item_model.dart  (CategoryModel)
│   │       │   └── presentation/cubit/ + pages/ + widgets/
│   │       └── orders/                       # User order management
│   │           ├── data/models/ + repo/
│   │           ├── domain/repo/ + use_cases/
│   │           └── presentation/manager/ + pages/ + widgets/
│   └── shared/                               # Shared across features
│       ├── app_layout/                       # App shell (bottom nav, layout pages)
│       │   ├── data/models/ + repositories/
│       │   ├── domain/repositories/ + use_cases/
│       │   └── presentation/cubit/ + pages/ + widgets/
│       ├── auth/                             # Authentication (login, signup, forget password, OTP)
│       │   ├── data/models/ + repositories/
│       │   ├── domain/repositories/ + use_cases/
│       │   └── presentation/cubits/ + pages/ + widgets/
│       ├── cubit/
│       │   ├── basic_cubit.dart              # Global app cubit (theme, categories, logout, page index)
│       │   └── basic_states.dart             # States for BasicCubit
│       ├── function/                         # Utility functions
│       │   ├── launch_phone_whats_app.dart
│       │   ├── list_equals.dart
│       │   ├── mony_helper.dart
│       │   └── phone_num_validation.dart
│       ├── model/
│       │   └── bottom_nav_model.dart         # BottomNavModel (icon + label)
│       ├── pages/
│       │   ├── custom_loading_screen.dart
│       │   └── splash_screen.dart            # VideoSplashScreen
│       ├── uploads/                          # File upload subsystem (images, videos, audio, documents)
│       │   ├── data/data_source/ + models/ + repo/
│       │   └── domain/repo/ + use_cases/
│       └── widgets/                          # 40 reusable widgets
│           ├── custom_cached_image.dart
│           ├── custom_text_field.dart
│           ├── custom_app_bar.dart
│           ├── custom_add_edit_media_list.dart
│           ├── custom_audio_player.dart
│           ├── video_preview_widget.dart
│           ├── responsive_helper/            # Responsive layout utilities
│           └── ... (30+ more reusable widgets)
├── pubspec.yaml
├── analysis_options.yaml
├── firebase.json
├── flutter_launcher_icons.yaml
└── test/
```

### 1.3 Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | [login_repo_impl.dart](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/data/repositories/login_repo_impl.dart) |
| Classes | `PascalCase` | [LoginRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/data/repositories/login_repo_impl.dart#14-38) |
| Abstract repos | Prefixed with feature name | [LoginRepo](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/domain/repositories/login_repo.dart#8-11), [OrdersRepo](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| Repo implementations | Suffix [Impl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/data/repositories/login_repo_impl.dart#14-38) | [LoginRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/data/repositories/login_repo_impl.dart#14-38) |
| Use case classes | Suffix [UseCase](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/uses_cases/use_cases.dart#5-8) | [GetOrdersUseCase](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/domain/use_cases/orders_use_cases.dart#8-19) |
| Cubit classes | Suffix [Cubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/cubit/basic_cubit.dart#12-126) | [HomeStoreCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/presentation/cubit/home_store_cubit.dart#19-342) |
| State classes | Suffix [State](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/app_layout/presentation/pages/customer_layout_page.dart#43-68) | [HomeStoreState](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/presentation/cubit/home_store_state.dart#3-84) |
| Constants classes | Prefix [App](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/app.dart#11-17) | [AppColors](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/utils/theme/app_colors.dart#3-169), [AppIcons](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/utils/theme/app_icons.dart#2-376), [AppImages](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/utils/theme/app_images.dart#2-18) |
| Enum values | `camelCase` | `OrderStatus.waiting` |
| Route constants | `camelCase` on [AppRouter](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/routing/routes.dart#1-17) | `AppRouter.customerAppLayout` |

---

## SECTION 2 — STATE MANAGEMENT

### 2.1 Solution: **Flutter Bloc / Cubit**

- **Package**: `flutter_bloc: ^9.1.1`, `bloc: ^9.1.0`
- **Pattern**: Cubits exclusively (no Bloc event classes used)
- **Error handling**: `dartz` `Either<Failures, T>` for all async operations

### 2.2 State Architecture

Two distinct state patterns are used:

#### Pattern A — Sealed class states (used by [BasicCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/cubit/basic_cubit.dart#12-126), [LoginCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/presentation/cubits/login/login_cubit.dart#7-50))

```dart
// basic_states.dart
sealed class BasicStates {}
final class LocalProductInitial extends BasicStates {}
final class ThemeChangedState extends BasicStates { ... }
final class ChangePageIndexState extends BasicStates { ... }
final class LogoutLoadingState extends BasicStates {}
final class LogoutSuccessState extends BasicStates {}
```

#### Pattern B — Single Equatable state with `RequestStatueEnum` fields (used by [HomeStoreCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/presentation/cubit/home_store_cubit.dart#19-342), [NotificationNewsCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/notifications/presentation/manager/notification_news_cubit.dart#17-226), [AddNewOrderCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/presentation/manager/cubit/add_new_order_cubit.dart#14-105), etc.)

```dart
// home_store_state.dart
class HomeStoreState extends Equatable {
  final RequestStatueEnum getOrdersStatus;
  final RequestStatueEnum getProfileStatus;
  final RequestStatueEnum addReplyStatus;
  // ...
  HomeStoreState copyWith({ ... });
}
```

```dart
// app_enums.dart
enum RequestStatueEnum {
  initial, loading, success, failure, empty, loadingMore, successMore, failureMore
}
```

### 2.3 All Cubits in the Project

| Cubit | Location | Manages |
|---|---|---|
| [BasicCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/cubit/basic_cubit.dart#12-126) | [shared/cubit/basic_cubit.dart](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/cubit/basic_cubit.dart) | Theme mode, page index, categories, logout |
| [LoginCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/presentation/cubits/login/login_cubit.dart#7-50) | `shared/auth/presentation/cubits/login/` | Login flow, password visibility |
| `SignUpCubit` | `shared/auth/presentation/cubits/sign_up/` | Registration flow |
| `ForgetPasswordCubit` | `shared/auth/presentation/cubits/forget_pass/` | Password reset flow |
| `LayoutCubit` | `shared/app_layout/presentation/cubit/` | Layout state, notification check |
| [UserHomeCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/home/presentation/cubit/user_home_cubit.dart#14-82) | `features/user/home/presentation/cubit/` | Categories list, recent orders |
| `OrdersCubit` | `features/user/orders/presentation/manager/orders_cubit/` | User order list + pagination |
| [AddNewOrderCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/presentation/manager/cubit/add_new_order_cubit.dart#14-105) | `features/user/orders/presentation/manager/cubit/` | Order creation form state |
| `RepliesCubit` | `features/user/orders/presentation/manager/replies_cubit/` | Order replies |
| `CheckOutCubit` | `features/user/check_out/presentation/cubit/` | Checkout flow (cities, regions) |
| [HomeStoreCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/presentation/cubit/home_store_cubit.dart#19-342) | `features/store/store_home/presentation/cubit/` | Store dashboard, orders, reels, replies, summary |
| [StoreOrderDetailsCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_orders/presentation/manager/store_order_details_cubit.dart#8-93) | `features/store/store_orders/presentation/manager/` | Order reply, report, ignore |
| `StoreSettingsCubit` | `features/store/settings/presentation/cubit/` | Store profile update |
| `GoogleMapCubit` | `features/store/google_map/presentation/cubits/` | Map location state |
| [NotificationNewsCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/notifications/presentation/manager/notification_news_cubit.dart#17-226) | `features/notifications/presentation/manager/` | News + notifications + pagination |

### 2.4 Global vs Local State

| Scope | Cubit | How Provided |
|---|---|---|
| **Global** (app-level singleton) | [BasicCubit](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/cubit/basic_cubit.dart#12-126) | `BlocProvider` in [app.dart](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/app.dart), registered as `LazySingleton` in get_it |
| **Local** (page-level) | All others | Created via `BlocProvider(create: ...)` in page widgets |

### 2.5 State Flow Example — Order Creation

```
1. User fills form in AddNewOrderPage
2. AddNewOrderCubit.addNewOrder() called
3. Cubit emits state.copyWith(createOrder: RequestStatueEnum.loading)
4. createOrderUseCase.call(orderModel) invoked
   → OrdersRepoImpl.createOrder()
     → Uploads image/video/audio via UploadFileUseCase if file type
     → POST to EndPoints.orders
5. UseCase returns Either<Failures, void>
6. result.fold():
   - Left(failure) → emit state.copyWith(createOrder: .failure, errMessage: ...)
   - Right(data)   → emit state.copyWith(createOrder: .success)
7. UI uses BlocListener to show toast/navigate on success or show error on failure
```

---

## SECTION 3 — API INTEGRATION

### 3.1 HTTP Client

**Dio** (`dio: ^5.8.0+1`) via [DioConsumer](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/api/dio_consumer.dart#5-86) implementing abstract [ApiConsumer](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/api/api_consumer.dart#3-40).

```dart
// api_consumer.dart
abstract class ApiConsumer {
  Future<dynamic> get({ required String path, ... });
  Future<dynamic> post({ required String path, ... });
  Future<dynamic> put({ ... });
  Future<dynamic> delete({ ... });
  Future<dynamic> patch({ ... });
}
```

### 3.2 Base URL & Configuration

```dart
// end_points.dart
static String appBaseUrl = 'https://computer-world.md-iraqsoft.com/';
static String baseUrl = '${appBaseUrl}api/v1/';
static String baseImageUrl = "${appBaseUrl}images/";
```

```dart
// dependency_injection.dart — Dio setup
Dio(BaseOptions(
  baseUrl: EndPoints.baseUrl,
  connectTimeout: Duration(seconds: 90),
  receiveTimeout: Duration(seconds: 90),
))
..followRedirects = false
..receiveDataWhenStatusError = true;
```

**Interceptors** (added in order):
1. [AppInterceptors](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/api/app_interceptor.dart#13-113) — Injects `Bearer` token, handles 401/403, auto-refreshes tokens
2. `PrettyDioLogger` — Only in `kDebugMode`

### 3.3 Authentication Mechanism

**JWT with Refresh Token**:

```dart
// app_interceptor.dart — onRequest
options.headers['Authorization'] = 'Bearer $authToken';
```

**Token Refresh Flow (401 handler)**:
1. On 401, check if refresh already in progress (prevents concurrent refresh)
2. Create clean [Dio](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/api/dio_consumer.dart#5-86) instance (no interceptors) to avoid loops
3. `POST /api/v1/token` with `{ "token": refreshToken }`
4. Extract `accessToken` from response, save to SharedPreferences
5. Retry original request with new token
6. On refresh failure → clear all credentials → redirect to `customerAppLayout`

**403 handler**: If message contains "Not Allowed", log it. Otherwise, logout.

### 3.4 All API Endpoints

| Endpoint | Method | Purpose | Used In |
|---|---|---|---|
| `auth/login` | POST | User login | [LoginRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/auth/data/repositories/login_repo_impl.dart#14-38) |
| `store/login` | POST | Store login | Defined but usage via store login flow |
| `auth/createVerificationCode` | POST | Send OTP for signup | `SignUpRepoImpl` |
| `auth/verify` | POST | Verify OTP code | `SignUpRepoImpl` |
| `auth/createVerificationCodeCheck` | POST | Send OTP for password reset | `ForgetPassRepoImpl` |
| `auth/forget-password` | POST | Reset password | `ForgetPassRepoImpl` |
| `auth/signup` | POST | Create account | `SignUpRepoImpl` |
| `auth/logout` | POST | Logout | Defined in endpoints |
| `token` | POST | Refresh access token | [AppInterceptors](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/core/api/app_interceptor.dart#13-113) |
| `users/getMe` | GET | Get current user profile | [StoreHomeRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/data/repo/store_home_repo_impl.dart#12-48) |
| `users/updateMe` | PUT | Update user profile | `StoreSettingRepoImpl` |
| `orders` | GET | List orders (with pagination/filters) | [OrdersRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| `orders` | POST | Create new order | [OrdersRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| `orders/{id}` | GET | Get order by ID | [OrdersRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| `orders/{id}/cancel` | PUT | Update order status | [OrdersRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| `orders/ignore` | POST | Ignore order (store) | `OrderDetailsRepoImp` |
| `orders/merchantSummary/{userId}` | GET | Merchant dashboard summary | [StoreHomeRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/store/store_home/data/repo/store_home_repo_impl.dart#12-48) |
| `replays` | GET | Get replies for orders | [OrdersRepoImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/features/user/orders/data/repo/orders_repo_impl.dart#18-164) |
| `replays` | POST/PUT | Add/update reply | `OrderDetailsRepoImp` |
| `reports` | POST | Create report | `OrderDetailsRepoImp` |
| `categories` | GET | List categories | `CategoriesRepoImpl` |
| `note` | GET | Get notifications | `NotificationNewsRepoImpl` |
| `note/readAllNotes` | PUT | Mark all as read | `NotificationNewsRepoImpl` |
| `news` | GET | Get news articles | `NotificationNewsRepoImpl` |
| `cities` | GET | Get cities (checkout) | `CheckOutRepoImpl` |
| `regions` | GET | Get regions (checkout) | `CheckOutRepoImpl` |
| `upload/image` | POST | Upload image file | [FileUploadDataSourceImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/uploads/data/data_source/file_upload_data_source.dart#30-302) |
| `upload/video` | POST | Upload video file | Defined in endpoints |
| `upload/document` | POST | Upload document | Defined in endpoints |
| `upload/any` | POST | Upload any file | Defined in endpoints |
| `stores` | GET | Get stores | Defined in endpoints |
| `users` | GET | Get users | Defined in endpoints |

### 3.5 Response Parsing

**Manual `fromJson` factories** — no code generation (no freezed/json_serializable):

```dart
// order_model.dart
factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
  id: json['_id'] ?? json['id'],
  title: json['prodactName'],
  description: json['description'],
  image: json['image'] != null
    ? MediaModel.fromNetwork(json['image'], category: MediaCategory.image)
    : null,
  // ...
);
```

All models use `Map<String, dynamic>` parsing with manual null-safety.

### 3.6 Error Handling Strategy

```
DioException
  └── ServerFailure.fromDioException(dioException)
        ├── connectionTimeout → "No internet connection"
        ├── badResponse → ServerFailure.fromResponse(statusCode, body)
        │     ├── 400/401/404/409/422 → response['message'] ?? response['error']
        │     ├── 403 → "Not Allowed" or "Session expired"
        │     ├── 406 → Arabic: "تم تعطيل حسابك"
        │     └── 500 → "Server error"
        └── unknown → "Unexpected error"

All repo methods return: Either<Failures, T>
All cubits fold: result.fold((failure) => emit error, (data) => emit success)
```

### 3.7 File Upload Pipeline

[FileUploadDataSourceImpl](file:///d:/mahmoud_sobhi/Iraq-Soft/lib/shared/uploads/data/data_source/file_upload_data_source.dart#30-302) handles:
1. **Images**: Compressed via `image` package in isolate (`compute`), resized to max 1920px, JPEG quality 85
2. **Videos**: Compressed via `video_compress` package (`VideoQuality.LowQuality`)
3. Uploads as `MultipartFile` via `FormData` to `upload/image` endpoint
4. Returns server filename from `response['fileName']`

---

## SECTION 4 — ASSETS & STYLING

### 4.1 Asset Types

| Type | Location | Count | Format |
|---|---|---|---|
| Icons | `assets/icons/` | 110 | SVG + 1 PNG (app_logo) |
| Images | `assets/images/` | 14 | SVG (empty states, auth illustrations) + PNG (splash, map) |
| Fonts | `assets/fonts/` | 5 | OTF (Hanimation family) |
| Audio | `assets/audio/` | 1 | MP3 (typing.mp3) |
| Map styles | `assets/map_styles/` | 1 | JSON (Google Maps dark theme) |
| Translations | `assets/translations/` | 2 | JSON (ar.json, en.json) |
| Animations | Referenced in code | 17 | Lottie JSON (via `lottie: ^3.3.1`) |

### 4.2 Asset Declaration (pubspec.yaml)

```yaml
assets:
  - assets/translations/
  - assets/icons/
  - assets/images/
  - assets/fonts/
  - assets/audio/
  - assets/map_styles/

fonts:
  - family: Hanimations
    fonts:
      - asset: assets/fonts/Hanimation-Regular.otf
      - asset: assets/fonts/Hanimation-Bold.otf
        weight: 700
      - asset: assets/fonts/Hanimation-Light.otf
        weight: 300
      - asset: assets/fonts/Hanimation-Medium.otf
        weight: 500
      - asset: assets/fonts/Hanimation-SemiBold.otf
        weight: 600
```

### 4.3 How Assets are Referenced in Code

Icons are centralized in `AppIcons`:
```dart
static const String home = "assets/icons/home.svg";
// Used via: SvgPicture.asset(AppIcons.home)
```

Images are centralized in `AppImages`:
```dart
static const String emptyOrders = 'assets/images/empty_orders.svg';
```

Animations are centralized in `AppAnimations`:
```dart
static const String loading = 'assets/animations/loading.json';
// Used via: Lottie.asset(AppAnimations.loading)
```

### 4.4 Theming

**Dual theme support** (light + dark) defined in `MyAppTheme`:

| Property | Light | Dark |
|---|---|---|
| Scaffold background | `#F5F7FA` (`lightBackground`) | `#0A1628` (`darkPrimary`) |
| Primary color | `#0088CC` (`lightPrimary`) | `#00BFFF` (`primary`) |
| Accent | `#00B8D4` (`lightAccent`) | `#00E5FF` (`darkAccent`) |
| Surface | `#FFFFFF` | `#111D2E` (`darkSurface`) |
| Card | `#FFFFFF` | `#162236` (`darkCard`) |
| Error | `#EF4444` | `#FF5252` |
| Font family | `Hanimations` | `Hanimations` |
| Material 3 | ✅ | ✅ |

**Theme switching**: `BasicCubit.toggleTheme()` → saves to `SharedPreferences("isDarkMode")` → rebuilds via `BlocBuilder` in `app.dart`.

### 4.5 Text Styles

`CustomAppFontStyle` provides 55+ presets:

```
Format: {weight}{size}  →  e.g., bold16, medium14, regular12, semiBold20, light10
Sizes:  10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26
Weights: light(300), regular(400), medium(500), semiBold(600), bold(700)
```

### 4.6 Color Palette

`AppColors` defines 160+ named colors. Key semantic colors:

| Usage | Color Name | Hex |
|---|---|---|
| Dark background | `darkPrimary` | `#0A1628` |
| Light primary | `lightPrimary` | `#0088CC` |
| Dark accent | `darkAccent` | `#00E5FF` |
| Success | `greenB76A` | `#12B76A` |
| Error/Red | `redEB42` | `#EB423F` |
| Warning/Yellow | `yellowE9B8` | `#E9B824` |
| Category-specific | `processorBg/Icon`, `gpuBg/Icon`, `ramBg/Icon`, etc. | Hardware-themed pairs |

### 4.7 Gradients

`AppGradient` provides 8 presets:
- `blackLinearGradient` — Primary brand gradient
- `greenGradient`, `redGradient`, `purpleGradient` — Status gradients
- `replitDarkGradient`, `replitLightGradient` — Theme-aware background gradients
- `pointCartGradient` — Gold/orange for points
- `cover`, `productBadge` — UI-specific

### 4.8 Responsive Design

- `ScreenUtilInit` with design size `375 × 812` (standard mobile)
- Custom `ResponsiveHelper` widgets in `shared/widgets/responsive_helper/`
- `BuildContext` extensions for `width`, `height`, `isLandscape`

---

## SECTION 5 — CUSTOMIZATION & CONFIGURATION

### 5.1 Environment Configuration

Currently single environment via hardcoded base URL in `EndPoints`:
```dart
static String appBaseUrl = 'https://computer-world.md-iraqsoft.com/'; // live production
// Commented alternative: 'http://192.168.1.206:5672/' // local testing
```

Phone code configured for Iraq: `static const String phoneCode = '+964';`
(Commented: `'+20'` for Egypt testing)

### 5.2 Dependency Injection

**Package**: `get_it: ^9.0.5`

All setup in `setupGetIt()` in `dependency_injection.dart`. Registration patterns:

| Type | Registration | Example |
|---|---|---|
| Infrastructure | `registerSingleton` | `Dio`, `DioConsumer`, `CancelToken` |
| Repositories | `registerLazySingleton<Abstract>` | `LoginRepo` → `LoginRepoImpl` |
| Use Cases | `registerLazySingleton` | `GetOrdersUseCase` |
| Global Cubits | `registerLazySingleton` | `BasicCubit` |
| Page Cubits | `registerFactory` | `NotificationNewsCubit` |

Injection chain: `Dio` → `DioConsumer` → `RepoImpl` → `UseCase` → `Cubit`

### 5.3 CI/CD Pipeline

**GitHub Actions** (`.github/workflows/main.yml`):

Triggered: `workflow_dispatch` (manual)

| Job | Runner | Output |
|---|---|---|
| `prepare` | ubuntu | Extracts app name + version from pubspec.yaml |
| `build-android` | ubuntu | Split APKs (arm64-v8a, armeabi-v7a, x86_64) + AAB |
| `build-windows` | windows | Inno Setup installer (`.exe`) |
| `build-web` | ubuntu | Zipped web build |
| `deploy-telegram` | ubuntu | Sends all artifacts to Telegram via bot API |

### 5.4 Key Third-Party Packages

| Package | Version | Role |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | State management |
| `dio` | ^5.8.0+1 | HTTP client |
| `dartz` | ^0.10.1 | Functional `Either` for error handling |
| `get_it` | ^9.0.5 | Service locator / DI |
| `go_router` | ^17.0.0 | Declarative routing |
| `easy_localization` | ^3.0.8 | i18n (Arabic/English) |
| `flutter_screenutil` | ^5.9.3 | Responsive scaling |
| `cached_network_image` | ^3.4.1 | Image caching |
| `flutter_svg` | ^2.2.0 | SVG rendering |
| `shared_preferences` | ^2.5.3 | Local key-value storage |
| `firebase_core` | ^4.5.0 | Firebase init |
| `firebase_messaging` | ^16.1.2 | FCM push notifications |
| `flutter_local_notifications` | ^19.4.2 | Local notification display |
| `image_picker` | ^1.1.2 | Camera/gallery access |
| `video_compress` | ^3.1.2 | Video compression |
| `flutter_image_compress` | ^2.4.0 | Image compression (alternative) |
| `image` | ^4.8.0 | In-memory image processing (isolate) |
| `google_maps_flutter` | ^2.12.3 | Google Maps widget |
| `geolocator` | 14.0.1 | GPS location |
| `geocoding` | ^4.0.0 | Address ↔ coordinates |
| `lottie` | ^3.3.1 | Lottie animations |
| `shimmer` | ^3.0.0 | Shimmer loading effects |
| `video_player` | ^2.10.0 | Video playback |
| `audioplayers` | (null) | Audio playback |
| `record` | (null) | Audio recording |
| `pinput` | ^6.0.1 | OTP input field |
| `webview_flutter` | ^4.13.0 | In-app web views |
| `pretty_qr_code` | ^3.5.0 | QR code generation |
| `qr_code_scanner_plus` | ^2.0.10+1 | QR code scanning |
| `toastification` | ^3.0.3 | Toast messages |
| `equatable` | ^2.0.7 | Value equality for state objects |
| `pretty_dio_logger` | ^1.4.0 | Debug HTTP logging |
| `permission_handler` | ^12.0.1 | Runtime permissions |
| `device_info_plus` | ^12.3.0 | Device identification |
| `timeago` | ^3.7.1 | Relative time display |
| `url_launcher` | ^6.3.2 | Open URLs/phone/email |
| `intl` | ^0.20.2 | Date/number formatting |
| `visibility_detector` | ^0.4.0+2 | Widget visibility tracking |

### 5.5 Routing

**`go_router`** with custom animated page transitions:

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: AppRouter.splashScreen,
  routes: [ ... ]
);
```

| Route | Page | Animation |
|---|---|---|
| `/splashScreen` | `VideoSplashScreen` | slideFromRight / cupertino |
| `/customerAppLayout` | `CustomerAppLayout` | slideFromRight / cupertino |
| `/storeAppLayout` | `StoreLayoutPage` | fade / cupertino |
| `/signUp` | `SignUp` | slideFromRight |
| `/forgetPassword` | `ForgetPassPage` | slideFromBottom |
| `/termsAndConditions` | `TermsAndConditions` | slideFromRight |
| `/addNewOrder` | `AddNewOrderPage` | slideFromBottom |
| `/orderDetails` | `OrderDetailsPage` | slideFromRight |
| `/storeOrderDetails` | `StoreOrderDetailsPage` | slideFromRight |
| `/checkout` | `CheckOutPage` | fade |
| `/storeReels` | `StoreReelPage` | fade |
| `/googleMap` | `GoogleMapView` | fade |
| `/notification` | `NotificationPage` | fade |
| `/storeSettings` | `StoreSettingsPage` | fade |

Platform-aware: iOS uses `CupertinoPage`, Android uses custom `CustomTransitionPage`.

### 5.6 Push Notifications (FCM)

Topic-based subscription system:

| Topic | Prefix | Subscribers |
|---|---|---|
| `computer_user` | `computer_` | User role |
| `computer_users` | `computer_` | All users |
| `computer_all` | `computer_` | Everyone |
| `computer_merchants` | `computer_` | Merchant role |
| `computer_{userId}` | `computer_` | Individual user |
| `computer_{deviceId}` | `computer_` | Individual device (guest) |

---

## SECTION 6 — PATTERNS & CONVENTIONS SUMMARY

### 6.1 How to Add a New Feature

1. Create folder under `lib/features/{user|store}/{feature_name}/`
2. Create three layers:
   ```
   feature_name/
   ├── data/
   │   ├── models/feature_model.dart         (fromJson, toJson)
   │   └── repo/feature_repo_impl.dart       (implements domain repo)
   ├── domain/
   │   ├── repo/feature_repo.dart            (abstract class)
   │   └── use_cases/feature_use_cases.dart  (extends UseCase<T, Params>)
   └── presentation/
       ├── cubit/feature_cubit.dart          (extends Cubit)
       ├── cubit/feature_state.dart          (Equatable with RequestStatueEnum fields)
       ├── pages/feature_page.dart
       └── widgets/
   ```
3. Register in `dependency_injection.dart`:
   ```dart
   getIt.registerLazySingleton<FeatureRepo>(
     () => FeatureRepoImpl(apiConsumer: getIt.get<DioConsumer>()),
   );
   getIt.registerLazySingleton(
     () => FeatureUseCase(featureRepo: getIt.get<FeatureRepo>()),
   );
   ```
4. Add route in `routes.dart` and `app_router.dart`

### 6.2 How to Add a New API Call

1. Add endpoint to `EndPoints` in `core/api/end_points.dart`:
   ```dart
   static String myEndpoint = 'my-endpoint';
   ```
2. Add method to abstract repo in `domain/repo/`:
   ```dart
   Future<Either<Failures, MyModel>> getMyData(PaginationParams params);
   ```
3. Implement in `data/repo/` repo impl:
   ```dart
   @override
   Future<Either<Failures, MyModel>> getMyData(PaginationParams params) async {
     try {
       final response = await apiConsumer.get(
         path: EndPoints.myEndpoint,
         queryParameters: params.toJson(),
       );
       return Right(MyModel.fromJson(response['data']));
     } on DioException catch (e) {
       return Left(ServerFailure.fromDioException(dioException: e));
     } catch (e) {
       return Left(ServerFailure(errMessage: e.toString()));
     }
   }
   ```
4. Create use case in `domain/use_cases/`:
   ```dart
   class GetMyDataUseCase extends UseCase<MyModel, PaginationParams> { ... }
   ```
5. Register in DI, inject into cubit

### 6.3 How to Add a New Screen

1. Create page widget in `presentation/pages/my_page.dart`
2. Add route constant in `routes.dart`:
   ```dart
   static const String myPage = '/myPage';
   ```
3. Add `GoRoute` in `app_router.dart`:
   ```dart
   GoRoute(
     path: AppRouter.myPage,
     name: AppRouter.myPage,
     pageBuilder: (context, state) => buildAnimatedPage(
       key: state.pageKey,
       child: MyPage(param: state.extra as MyParam),
       animationType: Platform.isIOS
         ? AnimationType.cupertino
         : AnimationType.slideFromRight,
     ),
   ),
   ```
4. Navigate: `context.push(AppRouter.myPage, extra: myParam)`

### 6.4 How to Add New Assets

1. Place file in the appropriate `assets/` subdirectory
2. If it's a new directory, add to `pubspec.yaml` under `assets:`
3. Add constant to the appropriate registry class:
   - SVG icons → `AppIcons` in `core/utils/theme/app_icons.dart`
   - Images → `AppImages` in `core/utils/theme/app_images.dart`
   - Lottie → `AppAnimations` in `core/utils/theme/app_animations.dart`
4. Reference via the constant: `SvgPicture.asset(AppIcons.myIcon)`

### 6.5 Naming Rules Quick Reference

```
Files:            snake_case.dart
Classes:          PascalCase
Variables:        camelCase
Constants:        camelCase (static const on class)
Enums:            PascalCase name, camelCase values
Repo interface:   {Feature}Repo
Repo impl:        {Feature}RepoImpl
Use case:         {Action}{Feature}UseCase
Cubit:            {Feature}Cubit
State:            {Feature}State
Page:             {Feature}Page
Widget:           Custom{Purpose}Widget or {descriptive_name}
Params:           {Feature}Param / {Feature}PassParam
Model:            {Feature}Model
```

---

> **Document generated from actual codebase analysis — every file name, class name, method name, and path referenced here exists in the source code.**

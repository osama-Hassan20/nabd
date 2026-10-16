# PUREXO SERVICE ADMIN DASHBOARD — MASTER FEATURE PLAN & ARCHITECTURAL SPECIFICATION

> **Document Type:** Master Feature Plan & Technical Implementation Specification  
> **Target System:** Purexo Service Admin Dashboard (Home Cleaning, AC Repair, Plumbing, etc.)  
> **Source Analysis:** `app_readme/00-data-model.md` through `app_readme/04-settings.md`  
> **Core Architecture:** Clean Architecture (Presentation → Domain → Data) + Pure Dart 3 (No Code Generation)  
> **Project Rules Enforcement:**
> 1. **NO Entities:** Models ONLY across all layers (`data`, `domain`, `presentation`).
> 2. **ALL Model Fields Are Nullable:** Every field in every model is strictly nullable (`String?`, `num?`, `DateTime?`, etc.).
> 3. **Pure Entity Models (Zero Foreign Nesting):** Models represent pure entities (`CustomerModel`, `TechnicianModel`). Bookings or leaves are NOT embedded inside customer/technician models; they are fetched as separate datasets via `GetBookingsUseCase` with `FilterParam`!
> 4. **Strict Standardized JSON Keys (camelCase Only):** Always use `id` (never `_id`), `customerId` (never `customer_id`), `technicianId` (never `technician_id`), etc. No fallback chains or snake_case keys.
> 5. **Single Cubit Per Feature/Page:** Exactly ONE Cubit per module managing state, actions, dialogs, and filters.
> 6. **Complete Localization (i18n):** All static UI texts, table headers, buttons, labels, and badges translated in `ar-EG.json` and `en-US.json` via `.tr()`.
> 7. **Mobile Fullscreen Dialogs:** Any dialog across the application MUST open in full screen (`Dialog.fullscreen`) on mobile devices (`width <= 700px`), and as a centered constrained modal on tablet/desktop.

---

## 1. Scope, Design Philosophy & Boundary Rules

### 1.1 Business Scope
The Purexo Admin Dashboard is a specialized operations platform for managing on-demand home service bookings, customers, technicians, and company availability rules.

#### Strict Scope Boundaries (From `app_readme`):
- **NO `Service` Entity/Model:** Services are plain text strings (`serviceName`: `"Home Cleaning"`, `"AC Repair"`, `"Plumbing"`).
- **NO Technician / Customer Apps:** The entire workflow is operated directly by company administrators via this dashboard.
- **NO Standalone `Payment` Model:** Payment is tracked via `paymentStatus` (`unpaid`, `paid`) on the Booking model.
- **NO Standalone `Statistics` / `History` Models:** Metrics (total bookings, upcoming counts, completed services, revenue) are derived dynamically via domain use cases or aggregation methods.
- **NO Standalone `Holiday` Module:** Holidays are categorized into:
  1. **Weekly Days Off** (`CompanySettingsModel.workingDays` exclusion)
  2. **Special Holidays** (`CompanySettingsModel.specialHolidays[]`)
- **Technician Leave vs. Company Holidays:**
  - Company Holiday / Day Off = Company-wide closure (blocks all bookings for everyone).
  - Technician Leave = Individual absence (blocks bookings only for that specific technician).

---

### 1.2 Engineering Rules & Architecture Discipline

| Rule Category | Requirement | Implementation Standard |
| :--- | :--- | :--- |
| **Model Exclusivity** | **NO `Entity` classes.** Use only `{Name}Model`. | Models live in `data/models/` and are returned by Domain Repos and UseCases. |
| **100% Nullable Models** | **ALL fields in all Models MUST be nullable.** | Every property is `final Type? property;` with manual `fromJson` and `toJson`. |
| **Pure Models (No Foreign Nesting)** | **No foreign lists inside models.** | `CustomerModel` has only customer fields. Bookings are fetched via `GetBookingsUseCase` with `FilterParam`. |
| **Unified JSON Keys (camelCase)** | **Strictly standardized keys without fallbacks.** | Use `id` (never `_id`), `customerId` (never `customer_id`), `technicianId` (never `technician_id`). |
| **Single Cubit Per Page** | **Exactly ONE Cubit per feature/page.** | No secondary cubits for dialogs, forms, or sub-sections. One unified state per module. |
| **Mobile Fullscreen Dialogs** | **ALL dialogs on mobile MUST open in full screen.** | On mobile (`AdaptiveLayout.isMobile(context)` or `width <= 700px`), invoke `Dialog.fullscreen`. On tablet/desktop, open centered modal constrained to `maxWidth: 650`–`700`. |
| **Domain Purity** | Zero Flutter imports (`package:flutter/...`) in `domain/`. | Pure Dart 3 only. |
| **No Code-Gen** | Strict ban on `build_runner`, `freezed`, and `json_serializable`. | Dart 3 sealed classes / records / manual JSON serialization. |
| **Full Localization (i18n)** | Every static UI string must be translated in `ar-EG.json` & `en-US.json`. | Access via `'key'.tr()`. Zero hardcoded Arabic/English text in UI widgets. |
| **Formatting Helpers** | All prices via `MonyHelper.formatMoney()`. All dates via `DateTimeExtension` (`.toCustomFormat()`). | Zero raw DateFormat or manual price strings in UI. |
| **Custom SVG Assets ONLY** | Strict ban on `Icons.xxx`. ALWAYS use `AppIcons` with `SvgPicture.asset` / `CustomAssetImage`. | If an SVG is missing, ask the user to provide it. Never use default Flutter icons. |

---

## 2. Universal Clean Architecture Directory Template

Every feature follows this exact 3-layer structure (with **Models only** and **1 Cubit only**):

```text
lib/features/{feature_name}/
├── data/
│   ├── models/
│   │   └── {feature_name}_model.dart         # Pure fields, all nullable, camelCase keys!
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
        ├── adaptive_{feature_name}_view.dart
        └── add_edit_{feature_name}_dialog.dart
```

---

## 3. Global All-Nullable Pure Models Specification

### 3.1 Rich Strongly-Typed Enums (`lib/features/bookings/data/models/enums/`)
```dart
enum BookingStatusEnum {
  scheduled(
    value: 'scheduled',
    labelKey: 'status_scheduled',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  completed(
    value: 'completed',
    labelKey: 'status_completed',
    color: AppColors.success,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.checkmarkCircle,
  ),
  cancelled(
    value: 'cancelled',
    labelKey: 'status_cancelled',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
    icon: AppIcons.close,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const BookingStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static BookingStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    return BookingStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingStatusEnum.scheduled,
    );
  }
}

enum BookingTypeEnum {
  oneTime(
    value: 'one_time',
    labelKey: 'one_time',
    color: AppColors.primary,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.calendar,
  ),
  recurring(
    value: 'recurring',
    labelKey: 'recurring',
    color: AppColors.cyan,
    backgroundColor: AppColors.primaryLight,
    icon: AppIcons.pending,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const BookingTypeEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static BookingTypeEnum? fromValue(String? val) {
    if (val == null) return null;
    return BookingTypeEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingTypeEnum.oneTime,
    );
  }
}

enum PaymentStatusEnum {
  unpaid(
    value: 'unpaid',
    labelKey: 'payment_unpaid',
    color: AppColors.error,
    backgroundColor: AppColors.red1A,
    icon: AppIcons.pending,
  ),
  paid(
    value: 'paid',
    labelKey: 'payment_paid',
    color: AppColors.success,
    backgroundColor: AppColors.secondaryLight,
    icon: AppIcons.checkmarkCircle,
  );

  final String value;
  final String labelKey;
  final Color color;
  final Color backgroundColor;
  final String icon;

  const PaymentStatusEnum({
    required this.value,
    required this.labelKey,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  String get label => labelKey.tr();

  static PaymentStatusEnum? fromValue(String? val) {
    if (val == null) return null;
    return PaymentStatusEnum.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentStatusEnum.unpaid,
    );
  }
}
```

---

### 3.2 Booking Model (`lib/features/bookings/data/models/booking_model.dart`)
```dart
class BookingModel {
  final String? id;
  final String? customerId;
  final String? customerName;     // Denormalized/joined by backend
  final String? customerPhone;
  final String? customerAddress;
  final String? technicianId;     // Nullable: allows unassigned bookings
  final String? technicianName;   // Denormalized/joined by backend
  final String? serviceName;      // Plain text e.g. "Home Cleaning"
  final BookingTypeEnum? bookingType;
  final DateTime? date;           // For one-time bookings
  final RecurrenceRuleModel? recurrence; // For recurring bookings
  final String? startTime;        // e.g. "10:00"
  final String? endTime;          // e.g. "13:00"
  final int? durationMinutes;     // Calculated duration
  final num? hourlyRate;          // Snapshot from CompanySettings at creation
  final num? totalPrice;          // durationHours * hourlyRate
  final BookingStatusEnum? status;
  final PaymentStatusEnum? paymentStatus;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    this.id,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.technicianId,
    this.technicianName,
    this.serviceName,
    this.bookingType,
    this.date,
    this.recurrence,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.hourlyRate,
    this.totalPrice,
    this.status,
    this.paymentStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BookingModel();
    return BookingModel(
      id: json['id']?.toString(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerAddress: json['customerAddress'] as String?,
      technicianId: json['technicianId']?.toString(),
      technicianName: json['technicianName'] as String?,
      serviceName: json['serviceName'] as String?,
      bookingType: BookingTypeEnum.fromValue(json['bookingType']?.toString()),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      recurrence: json['recurrence'] != null
          ? RecurrenceRuleModel.fromJson(json['recurrence'] as Map<String, dynamic>)
          : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      hourlyRate: json['hourlyRate'] as num?,
      totalPrice: json['totalPrice'] as num?,
      status: BookingStatusEnum.fromValue(json['status']?.toString()),
      paymentStatus: PaymentStatusEnum.fromValue(json['paymentStatus']?.toString()),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerAddress != null) 'customerAddress': customerAddress,
      if (technicianId != null) 'technicianId': technicianId,
      if (technicianName != null) 'technicianName': technicianName,
      if (serviceName != null) 'serviceName': serviceName,
      if (bookingType != null) 'bookingType': bookingType?.value,
      if (date != null) 'date': date?.toIso8601String(),
      if (recurrence != null) 'recurrence': recurrence?.toJson(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (hourlyRate != null) 'hourlyRate': hourlyRate,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (status != null) 'status': status?.value,
      if (paymentStatus != null) 'paymentStatus': paymentStatus?.value,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class RecurrenceRuleModel {
  final String? frequency;          // "weekly"
  final List<String>? daysOfWeek;   // ["sunday", "tuesday"]
  final DateTime? startDate;
  final DateTime? endDate;

  const RecurrenceRuleModel({
    this.frequency,
    this.daysOfWeek,
    this.startDate,
    this.endDate,
  });

  factory RecurrenceRuleModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecurrenceRuleModel();
    return RecurrenceRuleModel(
      frequency: json['frequency'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (frequency != null) 'frequency': frequency,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
    };
  }
}
```

---

### 3.2 Customer Model (`lib/features/customers/data/models/customer_model.dart`)
> **Pure Entity Model:** Contains ONLY customer attributes. Does NOT embed bookings or derived counts. Customer bookings are fetched separately via `GetBookingsUseCase(filterList: [FilterParam(key: 'customerId', value: customerId)])`.

```dart
class CustomerModel {
  final String? id;
  final String? name;
  final String? phone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    this.id,
    this.name,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CustomerModel();
    return CustomerModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
```

---

### 3.3 Technician & Leave Models (`lib/features/technicians/data/models/technician_model.dart`)
> **Pure Entity Model:** Contains ONLY technician attributes. Does NOT embed schedules or leaves. Technician schedules/bookings are fetched via `GetBookingsUseCase(filterList: [FilterParam(key: 'technicianId', value: techId)])` and leaves via `GetTechnicianLeavesUseCase`.

```dart
class TechnicianModel {
  final String? id;
  final String? name;
  final String? phone;
  final int? age;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TechnicianModel({
    this.id,
    this.name,
    this.phone,
    this.age,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TechnicianModel();
    return TechnicianModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      image: json['image'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (age != null) 'age': age,
      if (image != null) 'image': image,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class TechnicianLeaveModel {
  final String? id;
  final String? technicianId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reason;

  const TechnicianLeaveModel({
    this.id,
    this.technicianId,
    this.startDate,
    this.endDate,
    this.reason,
  });

  factory TechnicianLeaveModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TechnicianLeaveModel();
    return TechnicianLeaveModel(
      id: json['id']?.toString(),
      technicianId: json['technicianId']?.toString(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (technicianId != null) 'technicianId': technicianId,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (reason != null) 'reason': reason,
    };
  }
}
```

---

### 3.4 Company Settings Model (`lib/features/settings/data/models/company_settings_model.dart`)
```dart
class CompanySettingsModel {
  final String? id;
  final String? companyName;
  final String? logo;
  final String? phone;
  final String? address;
  final num? defaultHourlyRate;
  final List<String>? workingDays;       // ["saturday", "sunday", ...]
  final String? openingTime;             // "09:00"
  final String? closingTime;             // "18:00"
  final List<SpecialHolidayModel>? specialHolidays;
  final bool? notificationEnabled;
  final int? reminderMinutesBefore;

  const CompanySettingsModel({
    this.id,
    this.companyName,
    this.logo,
    this.phone,
    this.address,
    this.defaultHourlyRate,
    this.workingDays,
    this.openingTime,
    this.closingTime,
    this.specialHolidays,
    this.notificationEnabled,
    this.reminderMinutesBefore,
  });

  factory CompanySettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanySettingsModel();
    return CompanySettingsModel(
      id: json['id']?.toString(),
      companyName: json['companyName'] as String?,
      logo: json['logo'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      defaultHourlyRate: json['defaultHourlyRate'] as num?,
      workingDays: (json['workingDays'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      specialHolidays: (json['specialHolidays'] as List<dynamic>?)
          ?.map((e) => SpecialHolidayModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      notificationEnabled: json['notificationEnabled'] as bool?,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyName != null) 'companyName': companyName,
      if (logo != null) 'logo': logo,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (defaultHourlyRate != null) 'defaultHourlyRate': defaultHourlyRate,
      if (workingDays != null) 'workingDays': workingDays,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (specialHolidays != null) 'specialHolidays': specialHolidays?.map((e) => e.toJson()).toList(),
      if (notificationEnabled != null) 'notificationEnabled': notificationEnabled,
      if (reminderMinutesBefore != null) 'reminderMinutesBefore': reminderMinutesBefore,
    };
  }
}

class SpecialHolidayModel {
  final String? id;
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;

  const SpecialHolidayModel({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
  });

  factory SpecialHolidayModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SpecialHolidayModel();
    return SpecialHolidayModel(
      id: json['id']?.toString(),
      name: json['name'] as String?,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
    };
  }
}
```

---

## 4. Single-Cubit Architecture For Every Feature

Each feature contains **exactly ONE Cubit** that handles all state mutations, dialog actions, filters, and details:

### 4.1 Feature 1: `BookingsCubit` (One Cubit for Bookings)
```text
BookingsCubit (extends SafeCubit<BookingsState> with SearchMixin)
│
├── State Fields:
│   ├── status: RequestStatusEnum (loading, success, failure, empty)
│   ├── actionStatus: RequestStatusEnum (for status changes, creation, edits)
│   ├── selectedDate: DateTime (calendar active day)
│   ├── monthCounts: Map<DateTime, int> (bookings count per calendar day)
│   ├── bookings: List<BookingModel>
│   ├── selectedBookingDetails: BookingModel? (for details page or viewing)
│   ├── availableTechnicians: List<TechnicianModel> (dropdown in dialog)
│   ├── customersList: List<CustomerModel> (dropdown in dialog)
│   ├── errMessage: String?
│   └── activeFilters: (customerName, technicianId, status)
│
└── Methods:
    ├── getMonthCalendar(DateTime month)
    ├── selectCalendarDate(DateTime date)
    ├── getBookingsForDate({DateTime? date})
    ├── changeBookingStatus(String bookingId, String newStatus)
    ├── reassignTechnician(String bookingId, String newTechId)
    ├── createBooking(BookingModel model)
    ├── createCustomerInline(CustomerModel newCustomer) // Creates & selects without leaving modal!
    └── cancelBooking(String bookingId)
```

---

### 4.2 Feature 2: `CustomersCubit` (One Cubit for Customers)
```text
CustomersCubit (extends SafeCubit<CustomersState> with SearchMixin)
│
├── Dependencies:
│   ├── CustomersRepo / UseCases (for CustomerModel CRUD)
│   └── GetBookingsUseCase (to query bookings by customerId filter)
│
├── State Fields:
│   ├── status: RequestStatusEnum
│   ├── actionStatus: RequestStatusEnum (for add/edit/delete)
│   ├── detailsStatus: RequestStatusEnum
│   ├── customers: List<CustomerModel>
│   ├── selectedCustomer: CustomerModel? (pure customer data)
│   ├── customerBookings: List<BookingModel> (SEPARATE DATASET queried by FilterParam!)
│   ├── totalPages: int
│   └── errMessage: String?
│
└── Methods:
    ├── getCustomers() (with debounced search by name or phone)
    ├── getCustomerDetails(String id):
    │   1. Fetch CustomerModel via getCustomerByIdUseCase(id)
    │   2. Fetch separate bookings via getBookingsUseCase(PaginationParams(filterList: [FilterParam(key: 'customerId', value: id)]))
    │   3. Derive upcoming, history, and booking counts on the fly from customerBookings
    ├── addCustomer(CustomerModel customer)
    ├── updateCustomer(CustomerModel customer)
    ├── deleteCustomer(String id)
    └── changePage(int page)
```

---

### 4.3 Feature 3: `TechniciansCubit` (One Cubit for Technicians)
```text
TechniciansCubit (extends SafeCubit<TechniciansState> with SearchMixin)
│
├── Dependencies:
│   ├── TechniciansRepo / UseCases (for TechnicianModel CRUD)
│   ├── GetBookingsUseCase (to query bookings by technicianId filter)
│   └── GetTechnicianLeavesUseCase (to query leaves by technicianId filter)
│
├── State Fields:
│   ├── status: RequestStatusEnum
│   ├── actionStatus: RequestStatusEnum
│   ├── detailsStatus: RequestStatusEnum
│   ├── technicians: List<TechnicianModel>
│   ├── selectedTechnician: TechnicianModel? (pure technician data)
│   ├── technicianBookings: List<BookingModel> (SEPARATE DATASET queried by FilterParam!)
│   ├── technicianLeaves: List<TechnicianLeaveModel> (SEPARATE DATASET queried by FilterParam!)
│   ├── statusFilter: String? ("all", "available", "busy", "on_leave")
│   └── errMessage: String?
│
└── Methods:
    ├── getTechnicians()
    ├── getTechnicianDetails(String id):
    │   1. Fetch TechnicianModel via getTechnicianByIdUseCase(id)
    │   2. Fetch separate bookings via getBookingsUseCase(PaginationParams(filterList: [FilterParam(key: 'technicianId', value: id)]))
    │   3. Fetch separate leaves via getTechnicianLeavesUseCase(id)
    │   4. Derive today's schedule, upcoming tasks, and calculated status (On Leave > Busy > Available)
    ├── addTechnician(TechnicianModel technician)
    ├── updateTechnician(TechnicianModel technician)
    ├── deleteTechnician(String id) (with guard check against active bookings)
    ├── addLeave(TechnicianLeaveModel leave)
    └── deleteLeave(String leaveId)
```

---

### 4.4 Feature 4: `SettingsCubit` (One Cubit for Settings)
```text
SettingsCubit (extends SafeCubit<SettingsState>)
│
├── State Fields:
│   ├── status: RequestStatusEnum
│   ├── saveStatus: RequestStatusEnum
│   ├── settings: CompanySettingsModel?
│   ├── selectedTab: int (0: Info, 1: Schedule, 2: Pricing, 3: Holidays, 4: Notifications)
│   └── errMessage: String?
│
└── Methods:
    ├── getSettings()
    ├── updateCompanyInfo(CompanySettingsModel model)
    ├── updateWorkingSchedule(List<String> workingDays, String openTime, String closeTime)
    ├── updateDefaultHourlyRate(num rate)
    ├── addHoliday(SpecialHolidayModel holiday)
    ├── updateHoliday(SpecialHolidayModel holiday)
    ├── deleteHoliday(String holidayId)
    └── updateNotificationSettings(bool enabled, int reminderMinutes)
```

---

### 4.5 Feature 5: `HomeDashboardCubit` (One Cubit for Overview)
```text
HomeDashboardCubit (extends SafeCubit<HomeDashboardState>)
│
├── State Fields (Granular Rebuild Isolation via dashboard-section-builder):
│   ├── kpiStatus: RequestStatusEnum
│   ├── todayScheduleStatus: RequestStatusEnum
│   ├── techAvailabilityStatus: RequestStatusEnum
│   ├── recentBookingsStatus: RequestStatusEnum
│   ├── totalBookingsToday: int
│   ├── activeTechniciansCount: int
│   ├── completedTasksCount: int
│   ├── todayRevenue: num
│   ├── todayBookings: List<BookingModel>
│   ├── availableTechCount: int, busyTechCount: int, onLeaveTechCount: int
│   └── recentBookings: List<BookingModel>
│
└── Methods:
    ├── loadDashboardData() // Parallel Future.wait
    ├── getKpiStats()
    ├── getTodayBookings()
    ├── getTechnicianAvailability()
    └── getRecentBookings()
```

---

## 5. Complete Localization (i18n) Key Matrix (`ar-EG.json` & `en-US.json`)

All UI elements must use `'key'.tr()`. Below is the complete translation key mapping:

### 5.1 General & Common UI Keys
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `save` | حفظ | Save |
| `cancel` | إلغاء | Cancel |
| `confirm` | تأكيد | Confirm |
| `edit` | تعديل | Edit |
| `delete` | حذف | Delete |
| `view_details` | عرض التفاصيل | View Details |
| `search_hint` | بحث بالاسم أو الهاتف... | Search by name or phone... |
| `no_data_found` | لا توجد بيانات متاحة حالياً | No data found |
| `failed_to_load` | فشل في تحميل البيانات | Failed to load data |
| `retry` | إعادة المحاولة | Retry |
| `actions` | الإجراءات | Actions |
| `status` | الحالة | Status |
| `date` | التاريخ | Date |
| `time` | الوقت | Time |
| `phone` | رقم الهاتف | Phone Number |
| `address` | العنوان | Address |
| `name` | الاسم | Name |

---

### 5.2 Bookings Translation Keys
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `bookings` | الحجوزات | Bookings |
| `bookings_header` | إدارة الحجوزات والجدول | Bookings & Schedule |
| `bookings_subtitle` | متابعة المواعيد اليومية، التعيينات، وحالات الحجوزات. | Track daily schedules, assignments, and booking statuses. |
| `add_booking` | حجز جديد | New Booking |
| `booking_details` | تفاصيل الحجز | Booking Details |
| `service_name` | اسم الخدمة | Service Name |
| `service_name_hint` | مثال: تنظيف منزلي، صيانة تكييف | e.g. Home Cleaning, AC Repair |
| `booking_type` | نوع الحجز | Booking Type |
| `one_time` | حجز لمرة واحدة | One Time |
| `recurring` | حجز متكرر | Recurring |
| `start_time` | وقت البداية | Start Time |
| `end_time` | وقت النهاية | End Time |
| `duration` | المدة | Duration |
| `hours` | ساعات | Hours |
| `hourly_rate` | سعر الساعة | Hourly Rate |
| `total_price` | الإجمالي | Total Price |
| `select_customer` | اختر العميل | Select Customer |
| `add_new_customer` | + إضافة عميل جديد | + Add New Customer |
| `assign_technician` | تعيين فني | Assign Technician |
| `unassigned` | غير معين | Unassigned |
| `change_technician` | تغيير الفني | Change Technician |
| `cancel_booking` | إلغاء الحجز | Cancel Booking |
| `mark_completed` | تحديد كمكتمل | Mark as Completed |
| `notes` | ملاحظات | Notes |
| `status_scheduled` | مجدول | Scheduled |
| `status_completed` | مكتمل | Completed |
| `status_cancelled` | ملغي | Cancelled |
| `payment_unpaid` | غير مدفوع | Unpaid |
| `payment_paid` | مدفوع | Paid |

---

### 5.3 Customers Translation Keys
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `customers` | العملاء | Customers |
| `customers_header` | إدارة العملاء | Customers Management |
| `customers_subtitle` | عرض بيانات العملاء وسجل الحجوزات. | View customer profiles and booking history. |
| `add_customer` | إضافة عميل | Add Customer |
| `edit_customer` | تعديل بيانات العميل | Edit Customer |
| `customer_details` | تفاصيل العميل | Customer Details |
| `total_bookings` | إجمالي الحجوزات | Total Bookings |
| `upcoming_bookings` | الحجوزات القادمة | Upcoming Bookings |
| `completed_bookings` | الحجوزات المكتملة | Completed Bookings |
| `booking_history` | سجل الحجوزات السابقة | Booking History |

---

### 5.4 Technicians Translation Keys
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `technicians` | الفنيين | Technicians |
| `technicians_header` | إدارة الفنيين | Technicians Management |
| `technicians_subtitle` | متابعة الفنيين، الجداول اليومية، والإجازات. | Monitor technicians, daily schedules, and leaves. |
| `add_technician` | إضافة فني | Add Technician |
| `edit_technician` | تعديل الفني | Edit Technician |
| `technician_details` | تفاصيل الفني | Technician Details |
| `age` | العمر | Age |
| `today_tasks` | مهام اليوم | Today's Tasks |
| `today_schedule` | جدول اليوم | Today's Schedule |
| `leaves` | الإجازات | Leaves |
| `add_leave` | إضافة إجازة | Add Leave |
| `leave_reason` | سبب الإجازة | Leave Reason |
| `start_date` | من تاريخ | Start Date |
| `end_date` | إلى تاريخ | End Date |
| `tech_status_available` | متاح | Available |
| `tech_status_busy` | مشغول | Busy |
| `tech_status_on_leave` | في إجازة | On Leave |
| `tech_delete_guard_msg` | لا يمكن حذف الفني لوجود حجوزات نشطة أو قادمة مسندة إليه. | Cannot delete technician with active or upcoming bookings. |

---

### 5.5 Settings Translation Keys
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `settings` | الإعدادات | Settings |
| `settings_header` | إعدادات النظام | System Settings |
| `settings_subtitle` | ضبط ساعات وأيام العمل، التسعير، والعطلات الخاصة. | Configure working hours, days, pricing, and special holidays. |
| `tab_company_info` | معلومات الشركة | Company Info |
| `tab_working_schedule` | جدول ومواعيد العمل | Working Schedule |
| `tab_pricing` | التسعير الافتراضي | Default Pricing |
| `tab_special_holidays` | العطلات الرسمية | Special Holidays |
| `tab_notifications` | الإشعارات والتذكير | Notifications |
| `company_name` | اسم الشركة | Company Name |
| `opening_time` | وقت بدء العمل | Opening Time |
| `closing_time` | وقت انتهاء العمل | Closing Time |
| `working_days` | أيام العمل الأسبوعية | Weekly Working Days |
| `default_hourly_rate` | سعر الساعة الافتراضي | Default Hourly Rate |
| `add_holiday` | إضافة عطلة رسمية | Add Holiday |
| `holiday_name` | اسم العطلة | Holiday Name |
| `holiday_name_hint` | مثال: عيد الفطر المبارك | e.g. Eid Al-Fitr |
| `reminder_enabled` | تفعيل تذكير الحجز | Enable Booking Reminder |
| `reminder_lead_time` | إرسال التذكير قبل (دقيقة) | Reminder lead time (minutes) |

---

### 5.6 Availability Validation Messages
| Key | `ar-EG` | `en-US` |
| :--- | :--- | :--- |
| `val_err_day_off` | التاريخ المحدد يوافق يوم عطلة أسبوعية للشركة. | Selected date is a weekly day off. |
| `val_err_holiday` | التاريخ المحدد يوافق عطلة رسمية خاصة بالشركة. | Selected date is a special company holiday. |
| `val_err_working_hours` | وقت الحجز خارج مواعيد العمل الرسمية للشركة. | Booking time is outside working hours. |
| `val_err_invalid_time` | وقت النهاية يجب أن يكون بعد وقت البداية. | End time must be after start time. |
| `val_err_tech_on_leave` | الفني المحدد في إجازة خلال هذا الوقت. | Assigned technician is on leave. |
| `val_err_tech_conflict` | الفني المحدد لديه حجز آخر متعارض في نفس الوقت. | Assigned technician has an overlapping booking. |

---

## 6. Responsive UI & Layout Strategy (Skills Alignment)

Every feature renders via an Adaptive View Component (`AdaptiveLayout` / `LayoutBuilder`):

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Screen Width Breakpoints                        │
│                                                                        │
│  [Mobile: < 700px]      [Tablet: 700px - 1000px]   [Desktop: >= 1000px]│
│  ─────────────────      ────────────────────────   ────────────────────│
│  - Drawer Navigation    - 100px Mini Rail Sidebar  - 270px Sidebar     │
│  - 1-Column Card List   - 2-Column Responsive Card - Full CustomTable  │
│  - Bottom Sheet Filters - Wrapped Filter Buttons   - Horizontal Scroll │
│  - Dialog.fullscreen    - Dialog (Width <= 650px)  - Dialog (Max 700px)│
└────────────────────────────────────────────────────────────────────────┘
```

### 6.1 Universal Adaptive Dialog Architecture (Mobile Fullscreen Standard)
> **MANDATORY ARCHITECTURAL LAW:**  
> On mobile devices (`AdaptiveLayout.isMobile(context)` / `width <= 700px`), EVERY dialog across all features (Add Customer, Add Technician, Create Booking, Assign Technician, Add Leave, Add Holiday, Confirmations) **MUST open in full screen** (`Dialog.fullscreen`). Small floating modals on mobile cause keyboard occlusion, bad aspect ratios, and nested scrolling glitches.  
> On tablet and desktop, dialogs open as centered modals constrained to `maxWidth: 650`–`700` and `maxHeight: 90%`.

```dart
Future<T?> showAdaptiveFeatureDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, bool isFullScreen) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useSafeArea: true,
    builder: (dialogContext) {
      final isMobile = AdaptiveLayout.isMobile(dialogContext);
      if (isMobile) {
        return Dialog.fullscreen(
          child: builder(dialogContext, true),
        );
      }
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 650,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
          ),
          child: builder(dialogContext, false),
        ),
      );
    },
  );
}
```

**Dialog Header & Body Behavior:**
- **Mobile (`isFullScreen == true`)**: Renders a dedicated top navigation bar or `AppBar` with close (`X`) or back icon, centered localized title, and primary save action button. Form fields scroll inside `SingleChildScrollView`.
- **Tablet / Desktop (`isFullScreen == false`)**: Renders a clean modal header with title, subtitle, and trailing close icon button.

---

## 7. Step-by-Step Implementation Execution Roadmap

```text
Phase 1: Foundations & Translations
├── 1. Add /bookings to lib/core/routing/routes.dart & app_router.dart
├── 2. Add Bookings item to layoutItems in lib/core/utils/constants/app_list.dart
├── 3. Populate all translation keys in assets/translations/ar-EG.json & en-US.json
└── 4. Register all feature Cubits in lib/core/dependency_injection/dependency_injection.dart

Phase 2: Company Settings Feature (The Validation Authority)
├── Data Layer: CompanySettingsModel, SpecialHolidayModel (All nullable!), SettingsRepoImpl
├── Domain Layer: SettingsRepo (pure Dart, returns Models) & UseCases
└── Presentation: SettingsCubit (The ONLY Cubit), SettingsPage (Tabs), Shimmer & Dialogs

Phase 3: Customers Feature
├── Data Layer: CustomerModel (Pure attributes, All nullable!), CustomersRepoImpl
├── Domain Layer: CustomersRepo & UseCases
└── Presentation: CustomersCubit (The ONLY Cubit), Adaptive Table/Cards, Details Page, Reusable AddCustomerDialog

Phase 4: Technicians Feature & Status Engine
├── Data Layer: TechnicianModel, TechnicianLeaveModel (Pure attributes, All nullable!), TechniciansRepoImpl
├── Domain Layer: TechniciansRepo & UseCases with Status Calculation Precedence
└── Presentation: TechniciansCubit (The ONLY Cubit), Adaptive Table/Cards, Schedule & Leave Dialog

Phase 5: Bookings Feature (The Core Engine)
├── Data Layer: BookingModel, RecurrenceRuleModel (All nullable!), BookingsRepoImpl
├── Domain Layer: BookingsRepo & Availability Validation UseCase
└── Presentation: BookingsCubit (The ONLY Cubit), Calendar Strip, Adaptive Table/Cards, Create Dialog with Inline Customer

Phase 6: Home Dashboard Landing Feature
├── Data Layer: DashboardKpiModel, RepoImpl
├── Domain Layer: HomeDashboardRepo & UseCases
└── Presentation: HomeDashboardCubit (The ONLY Cubit), Slivers via dashboard-section-builder
```

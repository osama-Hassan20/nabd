# Data, Models & UseCase Patterns Reference

This reference documents universal null-safe model guidelines, the strict NO-Entity policy, repository contracts, and use cases.

---

## 0. The Strict "NO-ENTITY" Policy

In this dashboard architecture:
1. **Never create `Entity` classes or `domain/entities/` directories.**
2. **`{Feature}Model` is used uniformly across Data, Domain, and Presentation layers.**
3. Abstract repositories in `domain/repo/` return `Future<Either<Failures, List<{Feature}Model>>>` or `Future<Either<Failures, {Feature}Model>>`.
4. Use cases in `domain/use_cases/` take `{Feature}Model` or request params and return `Either<Failures, {Feature}Model>`.
5. This eliminates redundant mapper functions (`toEntity()`, `toModel()`) and keeps the codebase agile and lightweight.

---

## 1. Universal 100% Null-Safe & All-Nullable Model Rules

To make models completely resilient across API updates and avoid runtime crashes:
1. **EVERY field MUST be nullable (`Type?`)**: Never assume the backend will return non-null values.
2. **NO `required` constructor parameters**: Every parameter in the model constructor should be optional (`this.property`).
3. **Use `num?` for numbers**: Supports both `int` and `double` seamlessly from JSON.
4. **Safe Defensive Parsing in `fromJson`**:
   - Handle `json == null` safely (`if (json == null) return const {Name}Model();`).
   - Use `.toString()` for IDs to handle string or numeric IDs.
   - Parse dates defensively via `DateTime.tryParse(json['date']?.toString() ?? '')`.
   - Parse numbers without force unwrapping (`json['amount'] as num?`).
5. **Conditional serialization in `toJson`**:
   - Use `if (field != null) 'key': field` to avoid sending unnecessary `null` values over the network.

### Model Template:
```dart
class AdminItemModel {
  final String? id;
  final String? name;
  final String? status;
  final num? amount;
  final DateTime? createdAt;
  final Map<String, dynamic>? extra;

  const AdminItemModel({
    this.id,
    this.name,
    this.status,
    this.amount,
    this.createdAt,
    this.extra,
  });

  factory AdminItemModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdminItemModel();
    return AdminItemModel(
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

## 2. Pure Entity Models (Zero Foreign Nesting) & FilterParam Queries

1. **NO Foreign Lists Inside Models**:
   - `CustomerModel` represents ONLY customer properties (`id`, `name`, `phone`, `address`). It must **never** contain `List<BookingModel>`.
   - `TechnicianModel` represents ONLY technician properties (`id`, `name`, `phone`, `age`, `image`). It must **never** contain `List<BookingModel>` or `List<TechnicianLeaveModel>`.
2. **Related Data Fetched Separately via `FilterParam`**:
   - To get a customer's bookings, call `GetBookingsUseCase` with:
     ```dart
     PaginationParams(
       filterList: [FilterParam(key: 'customer_id', value: customerId)],
     )
     ```
   - To get a technician's schedule, call `GetBookingsUseCase` with `FilterParam(key: 'technician_id', value: techId)`.
   - To get a technician's leaves, call `GetTechnicianLeavesUseCase` with `FilterParam(key: 'technician_id', value: techId)`.
3. **Derived Statistics Calculated Dynamically**:
   - Total bookings, upcoming bookings, and history are derived on the fly from the queried bookings list, maintaining pure separation of data concerns.

---

## 3. Mock Data Strategy (Prototyping Mode)

When building or reviewing UI sections before backend endpoints are ready or deployed:

```dart
class MockAdminItemData {
  static const List<AdminItemModel> dummyList = [
    AdminItemModel(
      id: '1',
      name: 'Item 1',
      status: 'active',
      amount: 150000,
    ),
    AdminItemModel(
      id: '2',
      name: 'Item 2',
      status: 'pending',
      amount: 250000,
    ),
  ];
}
```

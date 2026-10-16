---
name: dashboard-dialog-form
description: >-
  Use this skill when building, modifying, or debugging any dialog form (Add/Edit/Delete/Status)
  in this Flutter dashboard project. Covers 100% Cubit-driven form state via BookingFormState pattern,
  CustomTextFormField with headerText, CustomStackSelector for dropdowns, CustomAssetImage for all assets,
  CustomPushButton for buttons, Arabic time formatting, and zero ValueNotifier / setState / isDark in dialog code.
---

# Dashboard Dialog Form Skill

This skill defines the **non-negotiable** patterns for every dialog form in this project. Violating any rule here will cause rejections and rework.

---

## 0. Absolute Laws (NEVER BREAK THESE)

1. **ZERO `setState` in dialogs.** All business logic and reactive data live exclusively in the Cubit.
2. **ZERO `ValueNotifier` for business data.** Date, time, selected customer, technician, price — all live in `{Feature}FormState` inside the Cubit's state, not local `ValueNotifier`s.
3. **ZERO `isDark` / `context.isDarkMode`.** The app is **strictly light-mode** (`ThemeMode.light`). Never use theme-conditional colours. Always use hard `AppColors.*` tokens directly.
4. **ZERO raw `SvgPicture.asset`.** Always use `CustomAssetImage(path: AppIcons.xxx)` for every icon/image asset.
5. **ZERO floating `Text` labels above form fields.** Every `CustomTextFormField` has its own `headerText` parameter — use it. Never place a `Text(...)` widget directly above a field as a label.
6. **ZERO `ElevatedButton` / `TextButton` / `OutlinedButton` for primary/secondary actions.** Always use `CustomPushButton`.
7. **ZERO dropdown modals built from scratch.** Always use `CustomStackSelector<T>` for every dropdown/select field.
8. **ONE Cubit per feature.** Never create a separate cubit, provider, or notifier for a dialog/form.
9. **ZERO `ScaffoldMessenger` / `SnackBar` (STRICT LAW).** NEVER EVER use `ScaffoldMessenger.of(context).showSnackBar(...)` anywhere! ALWAYS use `CustomToast` from `lib/shared/widgets/custom_toast.dart`. For validation guards/errors use `CustomToast(context: context, header: '...').showErrorToast();`. For success/info use `CustomToast(context: context, header: '...').showTopToast();`. Violating this is strictly forbidden.
10. **ZERO `onChanged` on `CustomTextFormField` when using `TextEditingController`.** NEVER use `onChanged: (val) => cubit.updateForm...(val)` on text inputs that have a controller! Doing so emits Cubit states on every keystroke, causing unnecessary widget rebuilds that mess up cursors and typing experience. The `TextEditingController` already manages and holds the text. Read the controller's `.text` directly on form submission (e.g. `cubit.submitForm(field: controller.text.trim())`) or use local controller listeners if calculations between controllers are needed.

---

## 1. Form State Architecture

### 1.1 `{Feature}FormState` in `{Feature}State`

Every form that adds or edits data **must** have its own immutable state class inside the feature's `{Feature}State` file:

```dart
// In features/{feature}/presentation/manager/{feature}_state.dart

class {Feature}FormState extends Equatable {
  final String? entityId;          // null for create, non-null for edit
  final SomeModel? relatedEntity;  // nullable — cleared with clearX: true
  final String fieldName;
  final EnumType enumField;
  final DateTime date;
  final String startTime;          // Always stored as "HH:mm" (24hr string)
  final String endTime;
  final int durationMinutes;
  final num numericField;
  final String notes;

  const {Feature}FormState({
    this.entityId,
    this.relatedEntity,
    this.fieldName = '',
    this.enumField = EnumType.defaultVal,
    required this.date,
    this.startTime = '10:00',
    this.endTime = '12:00',
    this.durationMinutes = 120,
    this.numericField = 0,
    this.notes = '',
  });

  {Feature}FormState copyWith({ ... }) { ... }

  @override
  List<Object?> get props => [ ... ];
}

class {Feature}State extends Equatable {
  // ... existing fields ...
  final {Feature}FormState? formState;   // <- add this

  // ... in copyWith:
  //   {Feature}FormState? formState,
  //   bool clearFormState = false,
  //   formState: clearFormState ? null : (formState ?? this.formState),
}
```

### 1.2 Time Storage Convention

- **Always store times as `"HH:mm"` 24-hour strings** (e.g. `"10:00"`, `"14:30"`) in `{Feature}FormState`.
- **Never store `TimeOfDay`** in Cubit state.
- Convert between `TimeOfDay` and `"HH:mm"` in the **presentation widget** only.

---

## 2. Cubit Methods for Form Management

Add all of these to the feature's `{Feature}Cubit`:

```dart
// Initialize (called BEFORE showDialog, in show() static method)
void initForm(EntityModel? entity) {
  if (entity != null) {
    emit(state.copyWith(formState: {Feature}FormState(
      entityId: entity.id,
      fieldName: entity.fieldName ?? '',
      date: entity.date ?? DateTime.now(),
      startTime: entity.startTime ?? '10:00',
      endTime: entity.endTime ?? '12:00',
      // ...
    )));
  } else {
    emit(state.copyWith(formState: {Feature}FormState(
      date: DateTime.now(),
      // ... defaults using state.relatedList.firstOrNull
    )));
  }
}

// Per-field updaters
void updateFormFieldName(String value) {
  if (state.formState == null) return;
  emit(state.copyWith(formState: state.formState!.copyWith(fieldName: value)));
}

void updateFormDate(DateTime date) { ... }

void updateFormStartTime(String startTime) {
  if (state.formState == null) return;
  // Recalculate duration & price here in the Cubit
  final startMin = _timeToMinutes(startTime);
  final endMin   = _timeToMinutes(state.formState!.endTime);
  final duration = (endMin - startMin).clamp(1, 999999);
  final total    = (state.formState!.hourlyRate * (duration / 60)).round();
  emit(state.copyWith(formState: state.formState!.copyWith(
    startTime: startTime,
    durationMinutes: duration,
    totalPrice: total,
  )));
}

int _timeToMinutes(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

// Submit — builds the model and calls create or update
Future<bool> submitForm() async {
  final form = state.formState;
  if (form == null) return false;
  final model = EntityModel(id: form.entityId, ...);
  return form.entityId != null
      ? await updateEntity(model)
      : await createEntity(model);
}
```

---

## 3. Dialog `show()` Pattern

```dart
static Future<void> show({
  required BuildContext context,
  EntityModel? entity,
}) {
  final cubit = context.read<XxxCubit>();
  cubit.initForm(entity);   // <- ALWAYS call BEFORE showDialog

  return showDialog(
    context: context,
    builder: (dialogCtx) {
      final isMobile = AdaptiveLayout.isMobile(dialogCtx);
      final child = BlocProvider.value(
        value: cubit,
        child: AddEditXxxDialog(initialEntity: entity),
      );
      return isMobile
          ? Dialog.fullscreen(child: child)
          : Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.9,
                ),
                child: child,
              ),
            );
    },
  );
}
```

---

## 4. Widget State — Allowed vs Forbidden

### Allowed in `_XxxDialogState`:
- `GlobalKey<FormState> _formKey` — form validation only.
- `TextEditingController` — for display/interaction. Set `.text` from Cubit `formState` in `initState` / `didChangeDependencies`, then update imperatively after async pickers.
- `bool _initializedDateTimeFields` — one-time flag to populate formatted controllers.
- `_parseTimeOfDay(String hhmm)` helper.

### Forbidden in `_XxxDialogState`:
- `ValueNotifier<DateTime>`, `ValueNotifier<TimeOfDay>`, any `ValueNotifier` for business data.
- Local fields mirroring Cubit state (`BookingCustomerOption? _selectedCustomer`).
- Business logic (time diff, price calculation, validation rules).
- `setState((){})` for business state.

---

## 5. Controllers Initialization Pattern

```dart
@override
void initState() {
  super.initState();
  final cubit = context.read<XxxCubit>();
  var form = cubit.state.formState;
  if (form == null) {
    cubit.initForm(widget.initialEntity);
    form = cubit.state.formState;
  }

  _selectorController = TextEditingController(
    text: form?.relatedEntity != null
        ? "${form!.relatedEntity!.name} (${form.relatedEntity!.phone})"
        : '',
  );
  _enumSelectorController = TextEditingController(text: form?.enumField.label ?? '');

  // These are formatted in didChangeDependencies (need context for locale)
  _dateController      = TextEditingController();
  _startTimeController = TextEditingController();
  _endTimeController   = TextEditingController();

  _serviceController = TextEditingController(text: form?.fieldName ?? '');
  _priceController   = TextEditingController(text: (form?.numericField ?? 0).toString());
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initializedDateTimeFields) {
    _initializedDateTimeFields = true;
    final form = context.read<XxxCubit>().state.formState;
    if (form == null) return;
    _dateController.text      = BookingTimeFormatter.formatCompactDate(form.date, context);
    _startTimeController.text = BookingTimeFormatter.formatSingleTime(form.startTime, context);
    _endTimeController.text   = BookingTimeFormatter.formatSingleTime(form.endTime, context);
  }
}
```

---

## 6. Date & Time Picker Pattern

```dart
Future<void> _pickDate() async {
  final cubit = context.read<XxxCubit>();
  final picked = await showDatePicker(
    context: context,
    initialDate: cubit.state.formState?.date ?? DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
  if (picked != null) {
    cubit.updateFormDate(picked);
    if (mounted) {
      _dateController.text = BookingTimeFormatter.formatCompactDate(picked, context);
    }
  }
}

Future<void> _pickStartTime() async {
  final cubit = context.read<XxxCubit>();
  final initial = _parseTimeOfDay(cubit.state.formState?.startTime ?? '10:00');
  final picked  = await showTimePicker(context: context, initialTime: initial);
  if (picked != null) {
    final s = '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
    cubit.updateFormStartTime(s);
    if (mounted) {
      _startTimeController.text = BookingTimeFormatter.formatSingleTime(s, context);
      if (cubit.state.formState != null) {
        _priceController.text = cubit.state.formState!.totalPrice.toString();
      }
    }
  }
}

TimeOfDay _parseTimeOfDay(String hhmm) {
  final p = hhmm.split(':');
  return TimeOfDay(
    hour:   int.tryParse(p.isNotEmpty ? p[0] : '') ?? 10,
    minute: int.tryParse(p.length > 1 ? p[1] : '') ?? 0,
  );
}
```

---

## 7. Time Formatting — `BookingTimeFormatter`

**Never use `time.format(context)` from `TimeOfDay`.** Always use `BookingTimeFormatter`:

```dart
// Display compact date: "15 أكتوبر 2026"
BookingTimeFormatter.formatCompactDate(date, context)

// Display Arabic 12-hr time from "HH:mm" string: "10:00 ص" / "02:30 م"
BookingTimeFormatter.formatSingleTime("14:30", context) // -> "02:30 م"

// Display time range
BookingTimeFormatter.formatTimeRange("10:00", "14:00", context) // -> "10:00 ص - 02:00 م"
```

---

## 8. Form Field Rules

### CustomTextFormField

```dart
// CORRECT — headerText inside field, CustomAssetImage prefix
CustomTextFormField(
  controller: _dateController,
  headerText: 'date_and_time_label'.tr(),
  isReadOnly: true,
  onTap: _pickDate,
  prefixWidget: const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: CustomAssetImage(path: AppIcons.calendar, width: 18, height: 18, color: AppColors.primary),
  ),
)

// WRONG — floating Text label + manual InkWell Container
Text('التاريخ'),
SizedBox(height: 6),
InkWell(onTap: ..., child: Container(...))
```

### CustomStackSelector (all dropdowns)

```dart
// CORRECT
CustomStackSelector<BookingTypeEnum>(
  header: 'booking_type_label'.tr(),
  controller: _bookingTypeSelectorController,
  list: BookingTypeEnum.values,
  itemAsString: (t) => t.label,
  changeValue: (t) => cubit.updateFormBookingType(t),
)

// WRONG — DropdownButton, DropdownButtonFormField, or a custom-built modal
```

### CustomPushButton (all actions)

```dart
// CORRECT
CustomPushButton(
  height: 44, width: 120,
  backgroundColor: AppColors.primary,
  isLoading: state.actionStatus == RequestStatusEnum.loading,
  borderRadius: BorderRadius.circular(8),
  onTap: _submit,
  child: Text('save'.tr(), style: CustomAppFontStyle.semiBold14.copyWith(color: AppColors.white)),
)

// WRONG — ElevatedButton, TextButton, OutlinedButton
```

---

## 9. Submit Pattern

```dart
void _submit() {
  if (!_formKey.currentState!.validate()) return;
  context.read<XxxCubit>().submitForm();  // logic lives in Cubit
}

// BlocConsumer listener:
listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
listener: (context, state) {
  if (state.actionStatus == RequestStatusEnum.success) {
    CustomToast(
      context: context,
      header: 'تمت العملية بنجاح',
    ).showTopToast();
    Navigator.of(context).pop(true);
  } else if (state.actionStatus == RequestStatusEnum.failed) {
    CustomToast(
      context: context,
      header: state.actionErrorMessage ?? 'حدث خطأ غير متوقع',
    ).showErrorToast();
  }
},
```

---

### 9.1 Pre-Submit Validation & Guards (NO SnackBar allowed!)

If a form requires manual checks before submitting (e.g. required entity selection, time order check), **NEVER** use `ScaffoldMessenger.of(context).showSnackBar(...)`:

```dart
// WRONG - FORBIDDEN:
// ScaffoldMessenger.of(context).showSnackBar(...);

// CORRECT - MANDATORY:
if (form.customer == null) {
  CustomToast(
    context: context,
    header: 'يرجى اختيار العميل أولاً',
  ).showErrorToast();
  return;
}
```

---

## 10. Delete / Status-Change Dialogs

These are **simple confirmations only** — no form fields, no form state, no controllers needed:

```dart
showDialog(
  context: context,
  builder: (_) => BlocProvider.value(
    value: cubit,
    child: AlertDialog(
      title: Text('confirm_delete'.tr()),
      content: Text('delete_entity_confirm_msg'.tr()),
      actions: [
        CustomPushButton(onTap: () => context.pop(), child: Text('cancel'.tr())),
        BlocBuilder<XxxCubit, XxxState>(
          buildWhen: (p, c) => p.actionStatus != c.actionStatus,
          builder: (ctx, state) => CustomPushButton(
            isLoading: state.actionStatus == RequestStatusEnum.loading,
            onTap: () => ctx.read<XxxCubit>().deleteEntity(id),
            child: Text('delete'.tr()),
          ),
        ),
      ],
    ),
  ),
);
```

---

## 11. Colour Rules (Light Mode Only)

```dart
// CORRECT — hard tokens
AppColors.white
AppColors.darkText
AppColors.primary
AppColors.gray71717A
AppColors.grayE2E8F0
AppColors.grayf2
AppColors.fillDisableColor
AppColors.inputBorderColor

// WRONG — any theme-conditional colour
isDark ? AppColors.white : AppColors.black
context.isDarkMode ? ... : ...
final isDark = Theme.of(context).brightness == Brightness.dark;
```

---

## 12. Pre-Submission Checklist

- [ ] `cubit.initForm(entity)` called in `show()` BEFORE `showDialog`.
- [ ] All business data in `{Feature}FormState` in Cubit — zero `ValueNotifier` for data.
- [ ] Zero `setState` for business logic.
- [ ] Zero `isDark` / `context.isDarkMode`.
- [ ] Zero raw `SvgPicture.asset` — all `CustomAssetImage`.
- [ ] Zero floating `Text` labels above fields — `headerText` used in `CustomTextFormField`.
- [ ] All dropdowns via `CustomStackSelector`.
- [ ] All action buttons via `CustomPushButton`.
- [ ] ZERO `ScaffoldMessenger` / `SnackBar` — all notifications and validation feedback use `CustomToast` from `lib/shared/widgets/custom_toast.dart`.
- [ ] Time display via `BookingTimeFormatter.formatSingleTime()`.
- [ ] `if (mounted)` check after every `await` that accesses `context`.
- [ ] `flutter analyze lib/features/{feature}/` → **No issues found**.

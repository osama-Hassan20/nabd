import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/recurrence_rule_model.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_customer_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_footer_actions.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_header.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_notes_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_one_time_schedule.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_pricing_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_recurring_schedule.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_service_field.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_status_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_technicians_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_new_customer_dialog.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddEditBookingDialog extends StatefulWidget {
  final BookingModel? initialBooking;

  const AddEditBookingDialog({super.key, this.initialBooking});

  static Future<void> show({
    required BuildContext context,
    BookingModel? booking,
    BookingsCubit? bookingsCubit,
  }) {
    BookingsCubit? cubit = bookingsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<BookingsCubit>();
      } catch (_) {
        cubit = getIt<BookingsCubit>();
      }
    }
    cubit.initBookingForm(booking);

    return showDialog(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final dialogChild = BlocProvider.value(
          value: cubit!,
          child: AddEditBookingDialog(initialBooking: booking),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: dialogChild);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.9,
            ),
            child: dialogChild,
          ),
        );
      },
    );
  }

  @override
  State<AddEditBookingDialog> createState() => _AddEditBookingDialogState();
}

class _AddEditBookingDialogState extends State<AddEditBookingDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Stack Selectors
  late final TextEditingController _customerSelectorController;
  late final TextEditingController _technicianSelectorController;
  late final TextEditingController _bookingTypeSelectorController;
  late final TextEditingController _statusSelectorController;
  late final TextEditingController _paymentStatusSelectorController;

  // Controllers for Text Inputs
  late final TextEditingController _dateController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _serviceController;
  late final TextEditingController _notesController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _totalPriceController;

  bool _initializedDateTimeFields = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<BookingsCubit>();
    var form = cubit.state.formState;
    if (form == null) {
      cubit.initBookingForm(widget.initialBooking);
      form = cubit.state.formState;
    }

    final isEdit = widget.initialBooking != null;

    // In Add Mode: start completely fresh without prefilled customer/tech/times
    _customerSelectorController = TextEditingController(
      text: isEdit ? (form?.customer?.name ?? '') : '',
    );
    final initialTechs = form?.technicians ?? [];
    _technicianSelectorController = TextEditingController(
      text: isEdit
          ? (initialTechs.length == 1
                ? initialTechs.first.name
                : (initialTechs.isNotEmpty
                      ? '${initialTechs.length} فنيين (${initialTechs.map((t) => t.name).join('، ')})'
                      : ''))
          : '',
    );
    _bookingTypeSelectorController = TextEditingController(
      text: form?.bookingType.label ?? BookingTypeEnum.oneTime.label,
    );
    _statusSelectorController = TextEditingController(
      text: form?.status.label ?? BookingStatusEnum.scheduled.label,
    );
    _paymentStatusSelectorController = TextEditingController(
      text: form?.paymentStatus.label ?? PaymentStatusEnum.unpaid.label,
    );

    _dateController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();

    _serviceController = TextEditingController(
      text: isEdit ? (form?.serviceName ?? '') : '',
    );
    _notesController = TextEditingController(
      text: isEdit ? (form?.notes ?? '') : '',
    );
    _hourlyRateController = TextEditingController(
      text: isEdit && form != null && form.hourlyRate > 0
          ? form.hourlyRate.toString()
          : '',
    );
    _totalPriceController = TextEditingController(
      text: isEdit && form != null && form.totalPrice > 0
          ? form.totalPrice.toString()
          : '',
    );

    _hourlyRateController.addListener(_onHourlyRateChanged);
  }

  void _onHourlyRateChanged() {
    final rate = num.tryParse(_hourlyRateController.text.trim()) ?? 0;
    final cubit = context.read<BookingsCubit>();
    final form = cubit.state.formState;
    final duration = form?.durationMinutes ?? 0;
    if (rate > 0 && duration > 0) {
      final total = (rate * (duration / 60)).round();
      if (_totalPriceController.text != total.toString()) {
        _totalPriceController.text = total.toString();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDateTimeFields) {
      _initializedDateTimeFields = true;
      _updateDateTimeDisplay();
    }
  }

  void _updateDateTimeDisplay() {
    final form = context.read<BookingsCubit>().state.formState;
    if (form == null) return;
    if (widget.initialBooking != null) {
      _dateController.text = BookingTimeFormatter.formatCompactDate(
        form.date,
        context,
      );
      if (form.startTime.isNotEmpty) {
        _startTimeController.text = BookingTimeFormatter.formatSingleTime(
          form.startTime,
          context,
        );
      }
      if (form.endTime.isNotEmpty) {
        _endTimeController.text = BookingTimeFormatter.formatSingleTime(
          form.endTime,
          context,
        );
      }
    }
  }

  @override
  void dispose() {
    _hourlyRateController.removeListener(_onHourlyRateChanged);
    _customerSelectorController.dispose();
    _technicianSelectorController.dispose();
    _bookingTypeSelectorController.dispose();
    _statusSelectorController.dispose();
    _paymentStatusSelectorController.dispose();

    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _serviceController.dispose();
    _notesController.dispose();
    _hourlyRateController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  void _syncTechniciansController(List<BookingTechnicianOption> techs) {
    if (techs.isEmpty) {
      _technicianSelectorController.text = '';
    } else if (techs.length == 1) {
      _technicianSelectorController.text = techs.first.name;
    } else {
      _technicianSelectorController.text =
          '${techs.length} فنيين (${techs.map((t) => t.name).join('، ')})';
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 10,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  Future<void> _pickDate() async {
    final cubit = context.read<BookingsCubit>();
    final currentDate = cubit.state.formState?.date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      cubit.updateFormDate(picked);
      if (mounted) {
        _dateController.text = BookingTimeFormatter.formatCompactDate(
          picked,
          context,
        );
      }
    }
  }

  Future<void> _pickStartTime() async {
    final cubit = context.read<BookingsCubit>();
    final form = cubit.state.formState;
    final initial = (form != null && form.startTime.isNotEmpty)
        ? _parseTimeOfDay(form.startTime)
        : const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      cubit.updateFormStartTime(timeStr);
      if (mounted) {
        _startTimeController.text = BookingTimeFormatter.formatSingleTime(
          timeStr,
          context,
        );

        // If endTime is set and start >= end, automatically adjust end time to start + 2 hours
        if (_endTimeController.text.isNotEmpty &&
            form != null &&
            form.endTime.isNotEmpty) {
          final startMinutes = picked.hour * 60 + picked.minute;
          final endMinutes =
              _parseTimeOfDay(form.endTime).hour * 60 +
              _parseTimeOfDay(form.endTime).minute;
          if (startMinutes >= endMinutes) {
            final newEndHour = (picked.hour + 2) % 24;
            final newEndStr =
                '${newEndHour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            cubit.updateFormEndTime(newEndStr);
            _endTimeController.text = BookingTimeFormatter.formatSingleTime(
              newEndStr,
              context,
            );
          }
        }

        _onHourlyRateChanged();
      }
    }
  }

  Future<void> _pickEndTime() async {
    final cubit = context.read<BookingsCubit>();
    final form = cubit.state.formState;
    final initial = (form != null && form.endTime.isNotEmpty)
        ? _parseTimeOfDay(form.endTime)
        : const TimeOfDay(hour: 12, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      // Validate that picked end time is strictly after start time
      if (form != null && form.startTime.isNotEmpty) {
        final start = _parseTimeOfDay(form.startTime);
        final startMinutes = start.hour * 60 + start.minute;
        final endMinutes = picked.hour * 60 + picked.minute;
        if (endMinutes <= startMinutes) {
          if (mounted) {
            CustomToast(
              context: context,
              header: 'وقت الانتهاء يجب أن يكون بعد وقت البدء',
            ).showErrorToast();
          }
          return;
        }
      }

      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      cubit.updateFormEndTime(timeStr);
      if (mounted) {
        _endTimeController.text = BookingTimeFormatter.formatSingleTime(
          timeStr,
          context,
        );
        _onHourlyRateChanged();
      }
    }
  }

  Future<void> _pickRecurringTime(
    String dayKey,
    bool isStart,
    String currentTimeStr,
  ) async {
    final cubit = context.read<BookingsCubit>();
    final initial = currentTimeStr.isNotEmpty
        ? _parseTimeOfDay(currentTimeStr)
        : const TimeOfDay(hour: 10, minute: 0);

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        cubit.updateRecurringDayTime(dayKey, startTime: timeStr);
      } else {
        cubit.updateRecurringDayTime(dayKey, endTime: timeStr);
      }
    }
  }

  Future<void> _onAddNewCustomerPressed() async {
    final newCustomer = await AddNewCustomerDialog.show(context);
    if (!mounted) return;
    if (newCustomer != null) {
      final cubit = context.read<BookingsCubit>();
      cubit.addCustomerOption(newCustomer);
      cubit.updateFormCustomer(newCustomer);
      // Only set the customer's name in controller
      _customerSelectorController.text = newCustomer.name;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<BookingsCubit>();
    final form = cubit.state.formState;
    if (form == null) return;

    if (form.customer == null) {
      CustomToast(
        context: context,
        header: 'يرجى اختيار العميل أولاً',
      ).showErrorToast();
      return;
    }

    if (form.bookingType == BookingTypeEnum.recurring) {
      if (form.recurringSchedules.isEmpty) {
        CustomToast(
          context: context,
          header: 'recurring_days_empty_error'.tr(),
        ).showErrorToast();
        return;
      }
      for (final sched in form.recurringSchedules) {
        final dayOpt = DayOfWeekOption.fromKey(sched.day);
        final startMin =
            _parseTimeOfDay(sched.startTime).hour * 60 +
            _parseTimeOfDay(sched.startTime).minute;
        final endMin =
            _parseTimeOfDay(sched.endTime).hour * 60 +
            _parseTimeOfDay(sched.endTime).minute;
        if (startMin >= endMin) {
          CustomToast(
            context: context,
            header:
                '${dayOpt.getName(context)}: وقت البدء يجب أن يكون قبل وقت الانتهاء',
          ).showErrorToast();
          return;
        }
      }
    } else {
      if (form.startTime.isEmpty || form.endTime.isEmpty) {
        CustomToast(
          context: context,
          header: 'يرجى تحديد وقت البدء ووقت الانتهاء',
        ).showErrorToast();
        return;
      }

      final startMin =
          _parseTimeOfDay(form.startTime).hour * 60 +
          _parseTimeOfDay(form.startTime).minute;
      final endMin =
          _parseTimeOfDay(form.endTime).hour * 60 +
          _parseTimeOfDay(form.endTime).minute;
      if (startMin >= endMin) {
        CustomToast(
          context: context,
          header: 'وقت البدء يجب أن يكون قبل وقت الانتهاء',
        ).showErrorToast();
        return;
      }
    }

    cubit.submitBookingForm(
      serviceName: _serviceController.text.trim(),
      hourlyRate: num.tryParse(_hourlyRateController.text.trim()) ?? 0,
      totalPrice: num.tryParse(_totalPriceController.text.trim()) ?? 0,
      notes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialBooking != null;

    return BlocConsumer<BookingsCubit, BookingsState>(
      listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success) {
          Navigator.of(context).pop(true);
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: state.errMessage ?? 'حدث خطأ غير متوقع',
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;
        final form = state.formState;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Column(
              children: [
                // ─── Header ──────────────────────────────────────────────
                BookingFormHeader(isEdit: isEdit),

                // ─── Form Body ───────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Customer Selection & Add New Customer Button
                          BookingFormCustomerSection(
                            controller: _customerSelectorController,
                            onAddNewCustomer: _onAddNewCustomerPressed,
                          ),
                          const SizedBox(height: 16),

                          // 2. Service Name
                          BookingFormServiceField(
                            controller: _serviceController,
                          ),
                          const SizedBox(height: 16),

                          // 3. Technician Selection (Multi-technician Support)
                          BookingFormTechniciansSection(
                            controller: _technicianSelectorController,
                            onSyncController: _syncTechniciansController,
                          ),
                          const SizedBox(height: 16),

                          // 4. Booking Type & Status
                          BookingFormStatusSection(
                            bookingTypeController:
                                _bookingTypeSelectorController,
                            statusController: _statusSelectorController,
                            paymentStatusController:
                                _paymentStatusSelectorController,
                          ),
                          const SizedBox(height: 16),

                          // 5. Date & Time Selection (One-Time vs Recurring)
                          if (form?.bookingType ==
                              BookingTypeEnum.recurring) ...[
                            BookingFormRecurringSchedule(
                              dateController: _dateController,
                              onPickDate: _pickDate,
                              onPickRecurringTime: _pickRecurringTime,
                            ),
                          ] else ...[
                            BookingFormOneTimeSchedule(
                              dateController: _dateController,
                              startTimeController: _startTimeController,
                              endTimeController: _endTimeController,
                              onPickDate: _pickDate,
                              onPickStartTime: _pickStartTime,
                              onPickEndTime: _pickEndTime,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 6. Pricing (Hourly Rate & Total Price)
                          BookingFormPricingSection(
                            hourlyRateController: _hourlyRateController,
                            totalPriceController: _totalPriceController,
                          ),
                          const SizedBox(height: 16),

                          // 7. Notes
                          BookingFormNotesSection(controller: _notesController),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Actions Footer (CustomPushButton) ───────────────────
                BookingFormFooterActions(
                  isLoading: isLoading,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

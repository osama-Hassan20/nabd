import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/features/bookings/data/models/booking_form_options_model.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/helpers/booking_time_formatter.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_cubit.dart';
import 'package:eyadty/features/bookings/presentation/manager/bookings_state.dart';
import 'package:eyadty/features/bookings/data/models/enums/discount_type_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_discount_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_patient_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_footer_actions.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_header.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_notes_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_slot_picker_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_pricing_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_service_field.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_status_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_sections/booking_form_technicians_section.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_new_patient_dialog.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

import '../../../../core/utils/theme/custom_app_font_styles.dart';

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
  late final TextEditingController _serviceSelectorController;
  late final TextEditingController _serviceController;
  late final TextEditingController _notesController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _discountTypeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _discountReasonController;

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

    // In Add Mode: pre-fill doctor & service if cubit initialized them
    _customerSelectorController = TextEditingController(
      text: isEdit ? (form?.customer?.name ?? '') : '',
    );
    final initialTechs = form?.technicians ?? [];
    _technicianSelectorController = TextEditingController(
      text: initialTechs.length == 1
          ? initialTechs.first.name
          : (initialTechs.isNotEmpty
                ? '${initialTechs.length} أطباء (${initialTechs.map((t) => t.name).join('، ')})'
                : ''),
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

    _serviceSelectorController = TextEditingController(
      text: form?.serviceName ?? '',
    );
    _serviceController = TextEditingController(
      text: form?.serviceName ?? '',
    );
    _notesController = TextEditingController(
      text: form?.notes ?? '',
    );
    _hourlyRateController = TextEditingController(
      text: form != null && (form.consultationFee > 0 || form.hourlyRate > 0)
          ? (form.consultationFee > 0 ? form.consultationFee : form.hourlyRate).toString()
          : '',
    );
    _totalPriceController = TextEditingController(
      text: form != null && form.totalPrice > 0
          ? form.totalPrice.toString()
          : '',
    );
    _discountTypeController = TextEditingController(
      text: isEdit && form != null && form.discountType != DiscountTypeEnum.none
          ? form.discountType.localizedName
          : '',
    );
    _discountValueController = TextEditingController(
      text: isEdit && form != null && form.discountValue > 0
          ? form.discountValue.toString()
          : '',
    );
    _discountReasonController = TextEditingController(
      text: isEdit && form != null ? form.discountReason : '',
    );

    _hourlyRateController.addListener(_onHourlyRateChanged);
  }

  void _onHourlyRateChanged() {
    final fee = num.tryParse(_hourlyRateController.text.trim()) ?? 0;
    if (fee > 0) {
      if (_totalPriceController.text.isEmpty ||
          _totalPriceController.text == '0') {
        _totalPriceController.text = fee.toString();
      }
      context.read<BookingsCubit>().updateFormConsultationFee(fee);
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
    _serviceSelectorController.dispose();
    _serviceController.dispose();
    _notesController.dispose();
    _hourlyRateController.dispose();
    _totalPriceController.dispose();
    _discountTypeController.dispose();
    _discountValueController.dispose();
    _discountReasonController.dispose();
    super.dispose();
  }

  void _syncTechniciansController(List<BookingTechnicianOption> techs) {
    if (techs.isEmpty) {
      _technicianSelectorController.text = '';
    } else if (techs.length == 1) {
      _technicianSelectorController.text = techs.first.name;
    } else {
      _technicianSelectorController.text =
          '${techs.length} أطباء (${techs.map((t) => t.name).join('، ')})';
    }

    final cubit = context.read<BookingsCubit>();
    final form = cubit.state.formState;

    if (form?.serviceId != null) {
      final currentService = cubit.state.medicalServices.firstWhere(
        (s) => s.id == form!.serviceId,
        orElse: () => const MedicalServiceModel(),
      );
      if (currentService.assignedDoctorId != null &&
          currentService.assignedDoctorId!.isNotEmpty &&
          !techs.any((t) => t.id == currentService.assignedDoctorId)) {
        _serviceSelectorController.text = '';
        _hourlyRateController.text = '';
        _totalPriceController.text = '';
        CustomToast(
          context: context,
          header: 'service_changed_doctor_warning'.tr(),
        ).showErrorToast();
        return;
      }
    }

    // Sync service and pricing controllers if Cubit auto-selected a default service
    if (form?.serviceName.isNotEmpty ?? false) {
      _serviceSelectorController.text = form!.serviceName;
      _hourlyRateController.text =
          (form.consultationFee > 0 ? form.consultationFee : form.hourlyRate)
              .toString();
      _totalPriceController.text =
          form.totalPrice > 0 ? form.totalPrice.toString() : '';
    } else if (techs.isEmpty) {
      _serviceSelectorController.text = '';
      _hourlyRateController.text = '';
      _totalPriceController.text = '';
    }
  }

  Future<void> _onAddNewCustomerPressed({String? initialQuery}) async {
    final newCustomer =
        await AddNewPatientDialog.show(context, initialQuery: initialQuery);
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
        header: 'يرجى اختيار المريض أولاً',
      ).showErrorToast();
      return;
    }

    if (form.technicians.isEmpty) {
      CustomToast(
        context: context,
        header: 'select_doctor_first_hint'.tr(),
      ).showErrorToast();
      return;
    }

    if (form.serviceId == null || form.serviceId!.isEmpty) {
      CustomToast(
        context: context,
        header: 'select_service_first_hint'.tr(),
      ).showErrorToast();
      return;
    }

    if (form.startTime.isEmpty || form.endTime.isEmpty) {
      CustomToast(
        context: context,
        header: 'slot_picker_required'.tr(),
      ).showErrorToast();
      return;
    }

    // فحص تعارض مواعيد المريض: إظهار حوار التأكيد في حال عدم التأكيد المسبق
    if (cubit.state.hasPatientTimeConflict &&
        !cubit.state.isPatientConflictConfirmed) {
      final conflictingDoctor =
          cubit.state.patientConflictingBooking?.doctorName ?? '';
      final conflictingTime = cubit.state.patientConflictingBooking != null
          ? '${BookingTimeFormatter.formatSingleTime(cubit.state.patientConflictingBooking!.startTime, context)} - ${BookingTimeFormatter.formatSingleTime(cubit.state.patientConflictingBooking!.endTime, context)}'
          : '';

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            'patient_time_conflict_warning'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${'patient_time_conflict_requires_confirmation'.tr()}\n($conflictingDoctor $conflictingTime)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                cubit.confirmPatientTimeConflict();
                _submit();
              },
              child: Text('confirm_conflict_and_proceed'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    final fee = num.tryParse(_hourlyRateController.text.trim()) ?? 0;
    final total = num.tryParse(_totalPriceController.text.trim()) ?? fee;
    final resolvedServiceName = _serviceSelectorController.text.trim().isNotEmpty
        ? _serviceSelectorController.text.trim()
        : _serviceController.text.trim();

    cubit.submitBookingForm(
      serviceName: resolvedServiceName,
      consultationFee: fee,
      totalPrice: total,
      notes: _notesController.text.trim(),
    );
  }

  Widget _buildMedicalServiceSelector(
    BuildContext context,
    BookingsState state,
  ) {
    final cubit = context.read<BookingsCubit>();
    final form = state.formState;
    final selectedDoctorId = form?.technician?.id;

    if (!state.isSingleDoctorMode &&
        (selectedDoctorId == null || selectedDoctorId.isEmpty)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${'select_medical_service'.tr()} *',
            style: CustomAppFontStyle.bold14,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grayE2E8F0.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.gray71717A,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يرجى اختيار الطبيب المعالج أولاً لعرض الخدمات والأسعار المتاحة لهذا الطبيب.',
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final availableServices = state.medicalServices
        .where((s) => s.isServiceActive)
        .where((s) =>
            s.assignedDoctorId == null ||
            s.assignedDoctorId!.isEmpty ||
            s.assignedDoctorId == selectedDoctorId)
        .toList();

    return CustomStackSelector<MedicalServiceModel>(
      controller: _serviceSelectorController,
      header: '${'select_medical_service'.tr()} *',
      hintText: 'select_medical_service_hint'.tr(),
      list: availableServices,
      itemAsString: (srv) {
        final fee = srv.consultationFee ?? 0;
        final dur = srv.durationMinutes ?? 0;
        return '${srv.name ?? ''} (${AppFormatterHelper.formatCurrency(fee)} - ${AppFormatterHelper.formatMinutes(dur, context: context)})';
      },
      changeValue: (selectedService) {
        cubit.updateFormService(selectedService);
        _serviceSelectorController.text = selectedService.name ?? '';
        final fee = (selectedService.consultationFee ?? 0).toString();
        _hourlyRateController.text = fee;
        _totalPriceController.text = fee;
        if (form?.startTime.isNotEmpty ?? false) {
          _endTimeController.text = BookingTimeFormatter.formatSingleTime(
            cubit.state.formState?.endTime ?? '',
            context,
          );
        }
      },
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
                          // 1. Patient Selection & Add New Patient Button
                          BookingFormPatientSection(
                            controller: _customerSelectorController,
                            onAddNewPatient: _onAddNewCustomerPressed,
                          ),
                          const SizedBox(height: 16),

                          // 2. Technician Selection (Multi-technician Support)
                          BookingFormTechniciansSection(
                            controller: _technicianSelectorController,
                            onSyncController: _syncTechniciansController,
                          ),
                          const SizedBox(height: 16),

                          // 3. Medical Service Selection
                          _buildMedicalServiceSelector(context, state),
                          const SizedBox(height: 16),

                          // 4. Chief Complaint / Visit Reason
                          BookingFormServiceField(
                            controller: _serviceController,
                            isRequired: state.formState?.serviceId == null &&
                                _serviceSelectorController.text.trim().isEmpty,
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

                          // 5. Slot Picker Section (Phase 4B)
                          const BookingFormSlotPickerSection(),
                          const SizedBox(height: 16),

                          // 6. Pricing (Hourly Rate & Total Price)
                          BookingFormPricingSection(
                            hourlyRateController: _hourlyRateController,
                            totalPriceController: _totalPriceController,
                          ),
                          const SizedBox(height: 16),

                          // 6.1 Discount Section
                          BookingDiscountSection(
                            discountTypeController: _discountTypeController,
                            discountValueController: _discountValueController,
                            discountReasonController: _discountReasonController,
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

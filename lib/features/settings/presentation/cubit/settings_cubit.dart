import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import '../../data/models/company_settings_model.dart';
import '../../data/models/enums/clinic_type_enum.dart';
import '../../data/models/prescription_template_model.dart';
import '../../data/models/special_holiday_model.dart';
import '../../domain/use_cases/add_special_holiday_use_case.dart';
import '../../domain/use_cases/change_password_use_case.dart';
import '../../domain/use_cases/delete_special_holiday_use_case.dart';
import '../../domain/use_cases/get_company_settings_use_case.dart';
import '../../domain/use_cases/update_company_settings_use_case.dart';
import '../../domain/use_cases/update_print_settings_use_case.dart';
import 'settings_state.dart';

class SettingsCubit extends SafeCubit<SettingsState> {
  final GetCompanySettingsUseCase getCompanySettingsUseCase;
  final UpdateCompanySettingsUseCase updateCompanySettingsUseCase;
  final AddSpecialHolidayUseCase addSpecialHolidayUseCase;
  final DeleteSpecialHolidayUseCase deleteSpecialHolidayUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final UpdatePrintSettingsUseCase? updatePrintSettingsUseCase;

  SettingsCubit({
    required this.getCompanySettingsUseCase,
    required this.updateCompanySettingsUseCase,
    required this.addSpecialHolidayUseCase,
    required this.deleteSpecialHolidayUseCase,
    required this.changePasswordUseCase,
    this.updatePrintSettingsUseCase,
  }) : super(const SettingsState());

  void init() {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    emit(state.copyWith(status: RequestStatusEnum.loading));

    final result = await getCompanySettingsUseCase(NoParams());

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
      },
      (settings) {
        emit(
          state.copyWith(
            status: RequestStatusEnum.success,
            settings: settings,
            workingDays: settings.workingDays ?? state.workingDays,
            openingTime: settings.openingTime ?? state.openingTime,
            closingTime: settings.closingTime ?? state.closingTime,
            defaultHourlyRate:
                settings.defaultHourlyRate ?? state.defaultHourlyRate,
            notificationEnabled:
                settings.notificationEnabled ?? state.notificationEnabled,
            reminderMinutesBefore:
                settings.reminderMinutesBefore ?? state.reminderMinutesBefore,
          ),
        );
      },
    );
  }

  void changeTab(int index) {
    if (state.selectedTab == index) return;
    emit(state.copyWith(selectedTab: index));
  }

  Future<bool> updateCompanyInfo({
    required String name,
    required String phone,
    required String address,
    String? logo,
    ClinicTypeEnum? clinicType,
    String? prescriptionCustomizationScope,
  }) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final current = state.settings ?? const CompanySettingsModel();
    final updated = current.copyWith(
      companyName: name,
      phone: phone,
      address: address,
      logo: logo ?? current.logo,
      clinicType: clinicType ?? current.clinicType,
      prescriptionCustomizationScope:
          prescriptionCustomizationScope ?? current.prescriptionCustomizationScope,
    );

    final result = await updateCompanySettingsUseCase(updated);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSettings) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: savedSettings,
            successMessage: 'settings_saved_successfully',
          ),
        );
        return true;
      },
    );
  }

  void toggleWorkingDay(String day) {
    final currentList = List<String>.from(state.workingDays);
    if (currentList.contains(day)) {
      if (currentList.length > 1) {
        currentList.remove(day);
      }
    } else {
      currentList.add(day);
    }
    emit(state.copyWith(workingDays: currentList));
  }

  void updateOpeningTime(String time) {
    emit(state.copyWith(openingTime: time));
  }

  void updateClosingTime(String time) {
    emit(state.copyWith(closingTime: time));
  }

  Future<bool> saveWorkingSchedule({
    String? openingTime,
    String? closingTime,
  }) async {
    final effectiveOpening = openingTime ?? state.openingTime;
    final effectiveClosing = closingTime ?? state.closingTime;

    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final current = state.settings ?? const CompanySettingsModel();
    final updated = current.copyWith(
      workingDays: state.workingDays,
      openingTime: effectiveOpening,
      closingTime: effectiveClosing,
    );

    final result = await updateCompanySettingsUseCase(updated);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSettings) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: savedSettings,
            openingTime: effectiveOpening,
            closingTime: effectiveClosing,
            successMessage: 'settings_saved_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> savePricing(num hourlyRate) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final current = state.settings ?? const CompanySettingsModel();
    final updated = current.copyWith(defaultHourlyRate: hourlyRate);

    final result = await updateCompanySettingsUseCase(updated);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSettings) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: savedSettings,
            defaultHourlyRate: hourlyRate,
            successMessage: 'settings_saved_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> saveNotificationSettings({
    required bool enabled,
    required int reminderMinutes,
  }) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final current = state.settings ?? const CompanySettingsModel();
    final updated = current.copyWith(
      notificationEnabled: enabled,
      reminderMinutesBefore: reminderMinutes,
    );

    final result = await updateCompanySettingsUseCase(updated);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSettings) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: savedSettings,
            notificationEnabled: enabled,
            reminderMinutesBefore: reminderMinutes,
            successMessage: 'settings_saved_successfully',
          ),
        );
        return true;
      },
    );
  }

  void initHolidayForm([SpecialHolidayModel? holiday]) {
    final now = CairoTimeHelper.now();
    emit(
      state.copyWith(
        holidayFormState: HolidayFormState(
          holidayId: holiday?.id,
          name: holiday?.name ?? '',
          startDate: holiday?.startDate ?? now,
          endDate: holiday?.endDate ?? now,
        ),
      ),
    );
  }

  void updateHolidayFormDates({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (state.holidayFormState == null) return;
    emit(
      state.copyWith(
        holidayFormState: state.holidayFormState!.copyWith(
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }

  Future<bool> saveHoliday({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final form = state.holidayFormState;
    final effectiveStart = startDate ?? form?.startDate ?? CairoTimeHelper.now();
    final effectiveEnd = endDate ?? form?.endDate ?? effectiveStart;

    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final model = SpecialHolidayModel(
      id: form?.holidayId,
      name: name,
      startDate: effectiveStart,
      endDate: effectiveEnd,
    );

    final result = await addSpecialHolidayUseCase(model);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (holiday) {
        final currentHolidays = List<SpecialHolidayModel>.from(
          state.settings?.specialHolidays ?? [],
        );
        final index = currentHolidays.indexWhere((h) => h.id == holiday.id);
        if (index >= 0) {
          currentHolidays[index] = holiday;
        } else {
          currentHolidays.insert(0, holiday);
        }
        final updatedSettings = state.settings?.copyWith(
          specialHolidays: currentHolidays,
        );

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: updatedSettings,
            clearHolidayFormState: true,
            successMessage: 'holiday_added_successfully',
          ),
        );
        return true;
      },
    );
  }

  void initDeleteHoliday(SpecialHolidayModel holiday) {
    emit(state.copyWith(holidayToDelete: holiday));
  }

  Future<bool> confirmDeleteHoliday() async {
    final holiday = state.holidayToDelete;
    if (holiday?.id == null) return false;

    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await deleteSpecialHolidayUseCase(holiday!.id!);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        final currentHolidays = List<SpecialHolidayModel>.from(
          state.settings?.specialHolidays ?? [],
        );
        currentHolidays.removeWhere((h) => h.id == holiday.id);
        final updatedSettings = state.settings?.copyWith(
          specialHolidays: currentHolidays,
        );

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: updatedSettings,
            clearHolidayToDelete: true,
            successMessage: 'holiday_deleted_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final result = await changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            successMessage: 'password_changed_successfully',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updatePrintSettings({
    String? receiptPrintFormat,
    String? shiftReportPrintFormat,
    String? prescriptionPrintFormat,
    String? branchId,
  }) async {
    final useCase = updatePrintSettingsUseCase;
    if (useCase == null) {
      emit(
        state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: 'use_case_not_available',
        ),
      );
      return false;
    }

    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await useCase(
      UpdatePrintSettingsParams(
        branchId: branchId,
        receiptPrintFormat: receiptPrintFormat,
        shiftReportPrintFormat: shiftReportPrintFormat,
        prescriptionPrintFormat: prescriptionPrintFormat,
      ),
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (saved) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: saved,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updatePrescriptionTemplate(
    PrescriptionTemplateModel template,
  ) async {
    emit(
      state.copyWith(
        actionStatus: RequestStatusEnum.loading,
        clearErrMessage: true,
        clearSuccessMessage: true,
      ),
    );

    final current = state.settings ?? const CompanySettingsModel();
    final updated = current.copyWith(prescriptionTemplate: template);

    final result = await updateCompanySettingsUseCase(updated);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (savedSettings) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            settings: savedSettings,
            successMessage: 'settings_saved_successfully',
          ),
        );
        return true;
      },
    );
  }
}

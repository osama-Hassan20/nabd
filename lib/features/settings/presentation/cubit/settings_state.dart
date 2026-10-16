import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/company_settings_model.dart';
import '../../data/models/special_holiday_model.dart';

class HolidayFormState extends Equatable {
  final String? holidayId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  const HolidayFormState({
    this.holidayId,
    this.name = '',
    required this.startDate,
    required this.endDate,
  });

  HolidayFormState copyWith({
    String? holidayId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HolidayFormState(
      holidayId: holidayId ?? this.holidayId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [holidayId, name, startDate, endDate];
}

class SettingsState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final CompanySettingsModel? settings;
  final int selectedTab;
  final List<String> workingDays;
  final String openingTime;
  final String closingTime;
  final num defaultHourlyRate;
  final bool notificationEnabled;
  final int reminderMinutesBefore;
  final HolidayFormState? holidayFormState;
  final SpecialHolidayModel? holidayToDelete;
  final String? errMessage;
  final String? successMessage;

  const SettingsState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.settings,
    this.selectedTab = 0,
    this.workingDays = const [
      'saturday',
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
    ],
    this.openingTime = '08:00',
    this.closingTime = '20:00',
    this.defaultHourlyRate = 100,
    this.notificationEnabled = true,
    this.reminderMinutesBefore = 60,
    this.holidayFormState,
    this.holidayToDelete,
    this.errMessage,
    this.successMessage,
  });

  SettingsState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    CompanySettingsModel? settings,
    int? selectedTab,
    List<String>? workingDays,
    String? openingTime,
    String? closingTime,
    num? defaultHourlyRate,
    bool? notificationEnabled,
    int? reminderMinutesBefore,
    HolidayFormState? holidayFormState,
    bool clearHolidayFormState = false,
    SpecialHolidayModel? holidayToDelete,
    bool clearHolidayToDelete = false,
    String? errMessage,
    bool clearErrMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      settings: settings ?? this.settings,
      selectedTab: selectedTab ?? this.selectedTab,
      workingDays: workingDays ?? this.workingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      holidayFormState: clearHolidayFormState
          ? null
          : (holidayFormState ?? this.holidayFormState),
      holidayToDelete: clearHolidayToDelete
          ? null
          : (holidayToDelete ?? this.holidayToDelete),
      errMessage: clearErrMessage ? null : (errMessage ?? this.errMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    actionStatus,
    settings,
    selectedTab,
    workingDays,
    openingTime,
    closingTime,
    defaultHourlyRate,
    notificationEnabled,
    reminderMinutesBefore,
    holidayFormState,
    holidayToDelete,
    errMessage,
    successMessage,
  ];
}

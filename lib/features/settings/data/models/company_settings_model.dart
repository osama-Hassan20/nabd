import 'special_holiday_model.dart';

class CompanySettingsModel {
  final String? id;
  final String? companyName;
  final String? logo;
  final String? phone;
  final String? address;
  final num? defaultHourlyRate;
  final List<String>? workingDays;
  final String? openingTime;
  final String? closingTime;
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
      workingDays: (json['workingDays'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
      if (specialHolidays != null)
        'specialHolidays': specialHolidays?.map((e) => e.toJson()).toList(),
      if (notificationEnabled != null)
        'notificationEnabled': notificationEnabled,
      if (reminderMinutesBefore != null)
        'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  CompanySettingsModel copyWith({
    String? id,
    String? companyName,
    String? logo,
    String? phone,
    String? address,
    num? defaultHourlyRate,
    List<String>? workingDays,
    String? openingTime,
    String? closingTime,
    List<SpecialHolidayModel>? specialHolidays,
    bool? notificationEnabled,
    int? reminderMinutesBefore,
  }) {
    return CompanySettingsModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      logo: logo ?? this.logo,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      workingDays: workingDays ?? this.workingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      specialHolidays: specialHolidays ?? this.specialHolidays,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }
}

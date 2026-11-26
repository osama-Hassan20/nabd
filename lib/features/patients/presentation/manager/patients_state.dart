import 'package:equatable/equatable.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import '../../data/models/enums/blood_group_enum.dart';
import '../../data/models/enums/gender_enum.dart';
import '../../data/models/enums/marital_status_enum.dart';
import '../../data/models/medical_catalog_item_model.dart';
import '../../data/models/patient_model.dart';

class PatientFormState extends Equatable {
  final String? id;
  final String? fileNumber;
  final String name;
  final String phone;
  final bool phoneHasWhatsapp;
  final DateTime? dateOfBirth;
  final GenderEnum? gender;
  final BloodGroupEnum? bloodGroup;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final num? heightCm;
  final num? weightKg;
  final bool isPregnant;
  final bool isNursing;
  final DateTime? lastMenstrualPeriodDate;
  final MaritalStatus? maritalStatus;
  final DateTime? estimatedDueDate;
  final int? nursingBabyAgeMonths;
  final int? gravidaCount;
  final int? paraCount;
  final int? miscarriageCount;
  final int? cesareanCount;
  final String contraceptionMethod;
  final bool isMenopause;
  final bool hasPregnancyAllergyWarning;
  final bool pregnantAndNursingConfirmed;
  final String? governorate;
  final String city;
  final String detailedAddress;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String guardianName;
  final String guardianPhone;
  final String guardianRelation;
  final String insuranceCompany;
  final String insurancePolicyNumber;
  final num? insuranceCoveragePercent;
  final String internalNotes;

  const PatientFormState({
    this.id,
    this.fileNumber,
    this.name = '',
    this.phone = '',
    this.phoneHasWhatsapp = true,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.heightCm,
    this.weightKg,
    this.isPregnant = false,
    this.isNursing = false,
    this.lastMenstrualPeriodDate,
    this.maritalStatus,
    this.estimatedDueDate,
    this.nursingBabyAgeMonths,
    this.gravidaCount,
    this.paraCount,
    this.miscarriageCount,
    this.cesareanCount,
    this.contraceptionMethod = '',
    this.isMenopause = false,
    this.hasPregnancyAllergyWarning = false,
    this.pregnantAndNursingConfirmed = false,
    this.governorate,
    this.city = '',
    this.detailedAddress = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.guardianName = '',
    this.guardianPhone = '',
    this.guardianRelation = '',
    this.insuranceCompany = '',
    this.insurancePolicyNumber = '',
    this.insuranceCoveragePercent,
    this.internalNotes = '',
  });

  String get address => detailedAddress.isNotEmpty
      ? detailedAddress
      : (city.isNotEmpty
          ? (governorate != null ? '$governorate - $city' : city)
          : (governorate ?? ''));

  int? get ageYears {
    if (dateOfBirth == null) return null;
    final now = CairoTimeHelper.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years >= 0 ? years : 0;
  }

  int? get ageMonths {
    if (dateOfBirth == null) return null;
    final now = CairoTimeHelper.now();
    int months =
        (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
    if (now.day < dateOfBirth!.day) months--;
    return months >= 0 ? months : 0;
  }

  bool get isChild => ageYears != null && ageYears! < 18;

  double? get calculatedBmi {
    if (heightCm == null ||
        weightKg == null ||
        heightCm! <= 0 ||
        weightKg! <= 0) {
      return null;
    }
    final meters = heightCm! / 100.0;
    return weightKg! / (meters * meters);
  }

  PatientFormState copyWith({
    String? id,
    String? fileNumber,
    String? name,
    String? phone,
    bool? phoneHasWhatsapp,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    GenderEnum? gender,
    bool clearGender = false,
    BloodGroupEnum? bloodGroup,
    bool clearBloodGroup = false,
    List<String>? allergies,
    List<String>? chronicDiseases,
    num? heightCm,
    bool clearHeight = false,
    num? weightKg,
    bool clearWeight = false,
    bool? isPregnant,
    bool? isNursing,
    DateTime? lastMenstrualPeriodDate,
    bool clearLmpDate = false,
    MaritalStatus? maritalStatus,
    bool clearMaritalStatus = false,
    DateTime? estimatedDueDate,
    bool clearEddDate = false,
    int? nursingBabyAgeMonths,
    int? gravidaCount,
    int? paraCount,
    int? miscarriageCount,
    int? cesareanCount,
    String? contraceptionMethod,
    bool? isMenopause,
    bool? hasPregnancyAllergyWarning,
    bool? pregnantAndNursingConfirmed,
    String? governorate,
    bool clearGovernorate = false,
    String? city,
    String? detailedAddress,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? guardianName,
    String? guardianPhone,
    String? guardianRelation,
    String? insuranceCompany,
    String? insurancePolicyNumber,
    num? insuranceCoveragePercent,
    bool clearInsuranceCoverage = false,
    String? internalNotes,
    bool clearId = false,
  }) {
    return PatientFormState(
      id: clearId ? null : (id ?? this.id),
      fileNumber: fileNumber ?? this.fileNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneHasWhatsapp: phoneHasWhatsapp ?? this.phoneHasWhatsapp,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      bloodGroup: clearBloodGroup ? null : (bloodGroup ?? this.bloodGroup),
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      isPregnant: isPregnant ?? this.isPregnant,
      isNursing: isNursing ?? this.isNursing,
      lastMenstrualPeriodDate: clearLmpDate
          ? null
          : (lastMenstrualPeriodDate ?? this.lastMenstrualPeriodDate),
      maritalStatus: clearMaritalStatus
          ? null
          : (maritalStatus ?? this.maritalStatus),
      estimatedDueDate: clearEddDate
          ? null
          : (estimatedDueDate ?? this.estimatedDueDate),
      nursingBabyAgeMonths: nursingBabyAgeMonths ?? this.nursingBabyAgeMonths,
      gravidaCount: gravidaCount ?? this.gravidaCount,
      paraCount: paraCount ?? this.paraCount,
      miscarriageCount: miscarriageCount ?? this.miscarriageCount,
      cesareanCount: cesareanCount ?? this.cesareanCount,
      contraceptionMethod: contraceptionMethod ?? this.contraceptionMethod,
      isMenopause: isMenopause ?? this.isMenopause,
      hasPregnancyAllergyWarning:
          hasPregnancyAllergyWarning ?? this.hasPregnancyAllergyWarning,
      pregnantAndNursingConfirmed:
          pregnantAndNursingConfirmed ?? this.pregnantAndNursingConfirmed,
      governorate: clearGovernorate ? null : (governorate ?? this.governorate),
      city: city ?? this.city,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceCoveragePercent: clearInsuranceCoverage
          ? null
          : (insuranceCoveragePercent ?? this.insuranceCoveragePercent),
      internalNotes: internalNotes ?? this.internalNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileNumber,
        name,
        phone,
        phoneHasWhatsapp,
        dateOfBirth,
        gender,
        bloodGroup,
        allergies,
        chronicDiseases,
        heightCm,
        weightKg,
        isPregnant,
        isNursing,
        lastMenstrualPeriodDate,
        maritalStatus,
        estimatedDueDate,
        nursingBabyAgeMonths,
        gravidaCount,
        paraCount,
        miscarriageCount,
        cesareanCount,
        contraceptionMethod,
        isMenopause,
        hasPregnancyAllergyWarning,
        pregnantAndNursingConfirmed,
        governorate,
        city,
        detailedAddress,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        guardianName,
        guardianPhone,
        guardianRelation,
        insuranceCompany,
        insurancePolicyNumber,
        insuranceCoveragePercent,
        internalNotes,
      ];
}

class PatientsState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final RequestStatusEnum detailsStatus;
  final List<PatientModel> items;
  final PatientModel? selectedPatient;
  final PatientModel? lastSavedPatient;
  final String? errMessage;
  final String? actionErrMessage;
  final String? detailsErrMessage;
  final int totalPages;
  final int totalCount;
  final PatientFormState? formState;
  final int activeFormTab;
  final Set<int> formTabsWithErrors;

  // ─── Medical Catalog ───────────────────────────────────────────
  final List<MedicalCatalogItemModel> allergyCatalog;
  final List<MedicalCatalogItemModel> chronicDiseaseCatalog;
  final bool isCatalogLoading;

  // ─── Patient Details Bookings & KPI ─────────────────────────────
  final List<BookingModel> patientBookings;
  final List<BookingModel> filteredPatientBookings;
  final BookingStatusEnum? selectedBookingStatusFilter;
  final String patientBookingSearchQuery;
  final int patientTotalBookingsCount;
  final int patientUpcomingBookingsCount;
  final int patientCompletedBookingsCount;
  final num patientTotalSpentAmount;
  final BookingStatusEnum? dialogStatus;
  final Set<String> dialogDoctorIds;

  // ─── Patient Visits & EMR Details ───────────────────────────────
  final List<VisitModel> patientVisits;
  final int activeDetailsTab;

  // ─── Duplicate Phone Warning ────────────────────────────────────
  final List<DuplicatePhonePatientInfo> duplicatePhonePatients;
  final bool hasPendingDuplicatePhoneWarning;

  const PatientsState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.detailsStatus = RequestStatusEnum.initial,
    this.items = const [],
    this.selectedPatient,
    this.lastSavedPatient,
    this.errMessage,
    this.actionErrMessage,
    this.detailsErrMessage,
    this.totalPages = 1,
    this.totalCount = 0,
    this.formState,
    this.activeFormTab = 0,
    this.formTabsWithErrors = const {},
    this.allergyCatalog = const [],
    this.chronicDiseaseCatalog = const [],
    this.isCatalogLoading = false,
    this.patientBookings = const [],
    this.filteredPatientBookings = const [],
    this.selectedBookingStatusFilter,
    this.patientBookingSearchQuery = '',
    this.patientTotalBookingsCount = 0,
    this.patientUpcomingBookingsCount = 0,
    this.patientCompletedBookingsCount = 0,
    this.patientTotalSpentAmount = 0,
    this.dialogStatus,
    this.dialogDoctorIds = const {},
    this.patientVisits = const [],
    this.activeDetailsTab = 0,
    this.duplicatePhonePatients = const [],
    this.hasPendingDuplicatePhoneWarning = false,
  });

  PatientsState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    RequestStatusEnum? detailsStatus,
    List<PatientModel>? items,
    PatientModel? selectedPatient,
    PatientModel? lastSavedPatient,
    String? errMessage,
    String? actionErrMessage,
    String? detailsErrMessage,
    int? totalPages,
    int? totalCount,
    PatientFormState? formState,
    bool clearFormState = false,
    int? activeFormTab,
    Set<int>? formTabsWithErrors,
    List<MedicalCatalogItemModel>? allergyCatalog,
    List<MedicalCatalogItemModel>? chronicDiseaseCatalog,
    bool? isCatalogLoading,
    List<BookingModel>? patientBookings,
    List<BookingModel>? filteredPatientBookings,
    BookingStatusEnum? selectedBookingStatusFilter,
    bool clearBookingStatusFilter = false,
    String? patientBookingSearchQuery,
    int? patientTotalBookingsCount,
    int? patientUpcomingBookingsCount,
    int? patientCompletedBookingsCount,
    num? patientTotalSpentAmount,
    BookingStatusEnum? dialogStatus,
    Set<String>? dialogDoctorIds,
    List<VisitModel>? patientVisits,
    int? activeDetailsTab,
    List<DuplicatePhonePatientInfo>? duplicatePhonePatients,
    bool? hasPendingDuplicatePhoneWarning,
    bool clearDuplicatePhoneWarning = false,
  }) {
    return PatientsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      detailsStatus: detailsStatus ?? this.detailsStatus,
      items: items ?? this.items,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      lastSavedPatient: lastSavedPatient ?? this.lastSavedPatient,
      errMessage: errMessage ?? this.errMessage,
      actionErrMessage: actionErrMessage ?? this.actionErrMessage,
      detailsErrMessage: detailsErrMessage ?? this.detailsErrMessage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      formState: clearFormState ? null : (formState ?? this.formState),
      activeFormTab: activeFormTab ?? this.activeFormTab,
      formTabsWithErrors: formTabsWithErrors ?? this.formTabsWithErrors,
      allergyCatalog: allergyCatalog ?? this.allergyCatalog,
      chronicDiseaseCatalog:
          chronicDiseaseCatalog ?? this.chronicDiseaseCatalog,
      isCatalogLoading: isCatalogLoading ?? this.isCatalogLoading,
      patientBookings: patientBookings ?? this.patientBookings,
      filteredPatientBookings:
          filteredPatientBookings ?? this.filteredPatientBookings,
      selectedBookingStatusFilter: clearBookingStatusFilter
          ? null
          : (selectedBookingStatusFilter ?? this.selectedBookingStatusFilter),
      patientBookingSearchQuery:
          patientBookingSearchQuery ?? this.patientBookingSearchQuery,
      patientTotalBookingsCount:
          patientTotalBookingsCount ?? this.patientTotalBookingsCount,
      patientUpcomingBookingsCount:
          patientUpcomingBookingsCount ?? this.patientUpcomingBookingsCount,
      patientCompletedBookingsCount:
          patientCompletedBookingsCount ?? this.patientCompletedBookingsCount,
      patientTotalSpentAmount:
          patientTotalSpentAmount ?? this.patientTotalSpentAmount,
      dialogStatus: dialogStatus ?? this.dialogStatus,
      dialogDoctorIds: dialogDoctorIds ?? this.dialogDoctorIds,
      patientVisits: patientVisits ?? this.patientVisits,
      activeDetailsTab: activeDetailsTab ?? this.activeDetailsTab,
      duplicatePhonePatients: clearDuplicatePhoneWarning
          ? const []
          : (duplicatePhonePatients ?? this.duplicatePhonePatients),
      hasPendingDuplicatePhoneWarning: clearDuplicatePhoneWarning
          ? false
          : (hasPendingDuplicatePhoneWarning ?? this.hasPendingDuplicatePhoneWarning),
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        detailsStatus,
        items,
        selectedPatient,
        lastSavedPatient,
        errMessage,
        actionErrMessage,
        detailsErrMessage,
        totalPages,
        totalCount,
        formState,
        activeFormTab,
        formTabsWithErrors,
        allergyCatalog,
        chronicDiseaseCatalog,
        isCatalogLoading,
        patientBookings,
        filteredPatientBookings,
        selectedBookingStatusFilter,
        patientBookingSearchQuery,
        patientTotalBookingsCount,
        patientUpcomingBookingsCount,
        patientCompletedBookingsCount,
        patientTotalSpentAmount,
        dialogStatus,
        dialogDoctorIds,
        patientVisits,
        activeDetailsTab,
        duplicatePhonePatients,
        hasPendingDuplicatePhoneWarning,
      ];
}

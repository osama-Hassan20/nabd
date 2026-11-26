import 'package:flutter/material.dart';
import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/mixins/search_mixin.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/bookings_response_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/data/models/enums/payment_status_enum.dart';
import 'package:eyadty/features/bookings/domain/use_cases/change_booking_status_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/delete_booking_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/get_bookings_use_case.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/change_booking_status_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/params/reassign_technician_params.dart';
import 'package:eyadty/features/bookings/domain/use_cases/reassign_technician_use_case.dart';
import 'package:eyadty/features/visits/data/models/visit_model.dart';
import 'package:eyadty/features/visits/domain/repo/visits_repo.dart';
import '../../data/models/clinical_record_models.dart';
import '../../data/models/enums/blood_group_enum.dart';
import '../../data/models/enums/gender_enum.dart';
import '../../data/models/enums/marital_status_enum.dart';
import '../../domain/helpers/female_intake_validator.dart';
import '../../data/models/enums/medical_catalog_type_enum.dart';
import '../../data/models/medical_catalog_item_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/patient_treatment_plan_model.dart';
import '../../domain/repo/patients_repo.dart';
import '../../domain/use_cases/add_medical_catalog_item_use_case.dart';
import '../../domain/use_cases/add_patient_use_case.dart';
import '../../domain/use_cases/archive_patient_use_case.dart';
import '../../domain/use_cases/delete_patient_use_case.dart';
import '../../domain/use_cases/find_patients_by_phone_use_case.dart';
import '../../domain/use_cases/get_medical_catalog_items_use_case.dart';
import '../../domain/use_cases/get_patient_by_id_use_case.dart';
import '../../domain/use_cases/get_patients_use_case.dart';
import '../../domain/use_cases/unarchive_patient_use_case.dart';
import '../../domain/use_cases/update_patient_use_case.dart';
import 'patients_state.dart';

class PatientsCubit extends SafeCubit<PatientsState> with SearchMixin {
  final GetPatientsUseCase getPatientsUseCase;
  final GetPatientByIdUseCase getPatientByIdUseCase;
  final AddPatientUseCase addPatientUseCase;
  final UpdatePatientUseCase updatePatientUseCase;
  final DeletePatientUseCase deletePatientUseCase;
  final ArchivePatientUseCase? archivePatientUseCase;
  final UnarchivePatientUseCase? unarchivePatientUseCase;
  final FindPatientsByPhoneUseCase? findPatientsByPhoneUseCase;
  final GetMedicalCatalogItemsUseCase? getMedicalCatalogItemsUseCase;
  final AddMedicalCatalogItemUseCase? addMedicalCatalogItemUseCase;
  final GetBookingsUseCase getBookingsUseCase;
  final ChangeBookingStatusUseCase changeBookingStatusUseCase;
  final ReassignTechnicianUseCase reassignTechnicianUseCase;
  final DeleteBookingUseCase deleteBookingUseCase;
  final PatientsRepo? patientsRepo;

  PatientsCubit({
    required this.getPatientsUseCase,
    required this.getPatientByIdUseCase,
    required this.addPatientUseCase,
    required this.updatePatientUseCase,
    required this.deletePatientUseCase,
    this.archivePatientUseCase,
    this.unarchivePatientUseCase,
    this.findPatientsByPhoneUseCase,
    this.getMedicalCatalogItemsUseCase,
    this.addMedicalCatalogItemUseCase,
    required this.getBookingsUseCase,
    required this.changeBookingStatusUseCase,
    required this.reassignTechnicianUseCase,
    required this.deleteBookingUseCase,
    this.patientsRepo,
  }) : super(const PatientsState());

  PaginationParams paginationParams = PaginationParams(page: 1, limit: 10);
  final TextEditingController patientBookingsSearchController =
      TextEditingController();

  void init() {
    addSearchListener(() {
      fetchPatients(resetPage: true);
    });
    patientBookingsSearchController.addListener(() {
      searchPatientBookings(patientBookingsSearchController.text);
    });
    fetchPatients();
  }

  @override
  Future<void> close() {
    patientBookingsSearchController.dispose();
    disposeSearch();
    return super.close();
  }

  // ─── Patients List Flow ──────────────────────────────────────────────────
  Future<void> fetchPatients({bool resetPage = false}) async {
    if (resetPage) {
      paginationParams = paginationParams.copyWith(page: 1);
    }

    paginationParams = paginationParams.copyWith(
      filterList: [
        if (searchQuery.trim().isNotEmpty)
          FilterParam(key: 'search', value: searchQuery.trim()),
      ],
    );

    emit(state.copyWith(
      status: RequestStatusEnum.loading,
      actionStatus: RequestStatusEnum.initial,
    ));

    final result = await getPatientsUseCase(paginationParams);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ),
      ),
      (response) => emit(
        state.copyWith(
          status: (response.items ?? []).isEmpty
              ? RequestStatusEnum.empty
              : RequestStatusEnum.success,
          items: response.items ?? [],
          totalPages: response.totalPages ?? 1,
          totalCount: response.totalCount ?? 0,
        ),
      ),
    );
  }

  void changePage(int newPage) {
    if (newPage < 1 || newPage > state.totalPages) return;
    paginationParams = paginationParams.copyWith(page: newPage);
    fetchPatients();
  }

  // ─── Patient Form Management ─────────────────────────────────────────────
  void initPatientForm(PatientModel? patient) {
    if (patient != null) {
      emit(state.copyWith(
        formState: PatientFormState(
          id: patient.id,
          fileNumber: patient.fileNumber,
          name: patient.name ?? '',
          phone: patient.phone ?? '',
          phoneHasWhatsapp: patient.phoneHasWhatsapp ?? true,
          dateOfBirth: patient.dateOfBirth,
          gender: patient.gender,
          bloodGroup: patient.bloodGroup,
          allergies: patient.allergies ?? const [],
          chronicDiseases: patient.chronicDiseases ?? const [],
          heightCm: patient.heightCm,
          weightKg: patient.weightKg,
          isPregnant: patient.isPregnant ?? false,
          isNursing: patient.isNursing ?? false,
          lastMenstrualPeriodDate: patient.lastMenstrualPeriodDate,
          maritalStatus: patient.maritalStatus,
          estimatedDueDate: patient.estimatedDueDate,
          nursingBabyAgeMonths: patient.nursingBabyAgeMonths,
          gravidaCount: patient.gravidaCount,
          paraCount: patient.paraCount,
          miscarriageCount: patient.miscarriageCount,
          cesareanCount: patient.cesareanCount,
          contraceptionMethod: patient.contraceptionMethod ?? '',
          isMenopause: patient.isMenopause ?? false,
          hasPregnancyAllergyWarning: patient.hasPregnancyAllergyWarning ?? false,
          governorate: patient.governorate,
          city: patient.city ?? '',
          detailedAddress: patient.detailedAddress ?? '',
          emergencyContactName: patient.emergencyContactName ?? '',
          emergencyContactPhone: patient.emergencyContactPhone ?? '',
          emergencyContactRelation: patient.emergencyContactRelation ?? '',
          guardianName: patient.guardianName ?? '',
          guardianPhone: patient.guardianPhone ?? '',
          guardianRelation: patient.guardianRelation ?? '',
          insuranceCompany: patient.insuranceCompany ?? '',
          insurancePolicyNumber: patient.insurancePolicyNumber ?? '',
          insuranceCoveragePercent: patient.insuranceCoveragePercent,
          internalNotes: patient.internalNotes ?? '',
        ),
        activeFormTab: 0,
        actionStatus: RequestStatusEnum.initial,
        formTabsWithErrors: const {},
      ));
    } else {
      emit(state.copyWith(
        formState: const PatientFormState(phoneHasWhatsapp: true),
        actionStatus: RequestStatusEnum.initial,
        activeFormTab: 0,
        formTabsWithErrors: const {},
      ));
    }
    loadMedicalCatalog();
  }

  Future<void> loadMedicalCatalog() async {
    if (getMedicalCatalogItemsUseCase == null) return;
    emit(state.copyWith(isCatalogLoading: true));
    final allergiesRes = await getMedicalCatalogItemsUseCase!(
      const GetMedicalCatalogParams(type: 'allergy'),
    );
    final chronicRes = await getMedicalCatalogItemsUseCase!(
      const GetMedicalCatalogParams(type: 'chronic_disease'),
    );

    List<MedicalCatalogItemModel> allergies = [];
    List<MedicalCatalogItemModel> chronic = [];

    allergiesRes.fold((_) {}, (items) => allergies = items);
    chronicRes.fold((_) {}, (items) => chronic = items);

    emit(state.copyWith(
      isCatalogLoading: false,
      allergyCatalog: allergies,
      chronicDiseaseCatalog: chronic,
    ));
  }

  Future<MedicalCatalogItemModel?> addMedicalCatalogItem({
    required String name,
    required MedicalCatalogTypeEnum type,
  }) async {
    if (addMedicalCatalogItemUseCase == null) return null;
    final res = await addMedicalCatalogItemUseCase!(
      AddMedicalCatalogItemParams(
        name: name.trim(),
        type: type.value,
      ),
    );
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return null;
      },
      (created) {
        if (type == MedicalCatalogTypeEnum.allergy) {
          final updated =
              List<MedicalCatalogItemModel>.from(state.allergyCatalog)
                ..add(created);
          emit(state.copyWith(allergyCatalog: updated));
        } else {
          final updated =
              List<MedicalCatalogItemModel>.from(state.chronicDiseaseCatalog)
                ..add(created);
          emit(state.copyWith(chronicDiseaseCatalog: updated));
        }
        return created;
      },
    );
  }

  void updateFormActiveTab(int index) {
    emit(state.copyWith(activeFormTab: index));
  }

  void updateFormName(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(name: value),
    ));
  }

  void updateFormPhone(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(phone: value),
    ));
  }

  void updateFormPhoneHasWhatsapp(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(phoneHasWhatsapp: value),
    ));
  }

  void updateFormDateOfBirth(DateTime? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        dateOfBirth: value,
        clearDateOfBirth: value == null,
      ),
    ));
  }

  void updateFormGender(GenderEnum? value) {
    final isNotFemale = value != GenderEnum.female;
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        gender: value,
        clearGender: value == null,
        isPregnant: isNotFemale ? false : state.formState?.isPregnant,
        isNursing: isNotFemale ? false : state.formState?.isNursing,
        clearLmpDate: isNotFemale,
      ),
    ));
  }

  void updateFormLastMenstrualPeriodDate(DateTime? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        lastMenstrualPeriodDate: value,
        clearLmpDate: value == null,
      ),
    ));
  }

  void updateFormBloodGroup(BloodGroupEnum? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        bloodGroup: value,
        clearBloodGroup: value == null,
      ),
    ));
  }

  void addAllergy(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    final current = List<String>.from(state.formState?.allergies ?? const []);
    if (!current.contains(trimmed)) {
      current.add(trimmed);
      emit(state.copyWith(
        formState: state.formState?.copyWith(allergies: current),
      ));
    }
  }

  void removeAllergy(String item) {
    final current = List<String>.from(state.formState?.allergies ?? const []);
    current.remove(item);
    emit(state.copyWith(
      formState: state.formState?.copyWith(allergies: current),
    ));
  }

  void addChronicDisease(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    final current =
        List<String>.from(state.formState?.chronicDiseases ?? const []);
    if (!current.contains(trimmed)) {
      current.add(trimmed);
      emit(state.copyWith(
        formState: state.formState?.copyWith(chronicDiseases: current),
      ));
    }
  }

  void removeChronicDisease(String item) {
    final current =
        List<String>.from(state.formState?.chronicDiseases ?? const []);
    current.remove(item);
    emit(state.copyWith(
      formState: state.formState?.copyWith(chronicDiseases: current),
    ));
  }

  void updateFormHeight(num? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        heightCm: value,
        clearHeight: value == null,
      ),
    ));
  }

  void updateFormWeight(num? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        weightKg: value,
        clearWeight: value == null,
      ),
    ));
  }

  void updateFormIsPregnant(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(isPregnant: value),
    ));
  }

  void updateFormIsNursing(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(isNursing: value),
    ));
  }

  void updateFormMaritalStatus(MaritalStatus? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        maritalStatus: value,
        clearMaritalStatus: value == null,
      ),
    ));
  }

  void updateFormEstimatedDueDate(DateTime? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        estimatedDueDate: value,
        clearEddDate: value == null,
      ),
    ));
  }

  void updateFormNursingBabyAgeMonths(int? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(nursingBabyAgeMonths: value),
    ));
  }

  void updateFormGravidaCount(int? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(gravidaCount: value),
    ));
  }

  void updateFormParaCount(int? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(paraCount: value),
    ));
  }

  void updateFormMiscarriageCount(int? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(miscarriageCount: value),
    ));
  }

  void updateFormCesareanCount(int? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(cesareanCount: value),
    ));
  }

  void updateFormContraceptionMethod(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(contraceptionMethod: value),
    ));
  }

  void updateFormIsMenopause(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(isMenopause: value),
    ));
  }

  void updateFormPregnancyAllergyWarning(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(hasPregnancyAllergyWarning: value),
    ));
  }

  void updateFormPregnantAndNursingConfirmed(bool value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(pregnantAndNursingConfirmed: value),
    ));
  }

  void updateFormGovernorate(String? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        governorate: value,
        clearGovernorate: value == null,
      ),
    ));
  }

  void updateFormCity(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(city: value),
    ));
  }

  void updateFormDetailedAddress(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(detailedAddress: value),
    ));
  }

  void updateFormEmergencyName(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(emergencyContactName: value),
    ));
  }

  void updateFormEmergencyPhone(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(emergencyContactPhone: value),
    ));
  }

  void updateFormEmergencyRelation(String? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(emergencyContactRelation: value),
    ));
  }

  void updateFormGuardianName(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(guardianName: value),
    ));
  }

  void updateFormGuardianPhone(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(guardianPhone: value),
    ));
  }

  void updateFormGuardianRelation(String? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(guardianRelation: value),
    ));
  }

  void updateFormInsuranceCompany(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(insuranceCompany: value),
    ));
  }

  void updateFormInsurancePolicyNumber(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(insurancePolicyNumber: value),
    ));
  }

  void updateFormInsuranceCoveragePercent(num? value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(
        insuranceCoveragePercent: value,
        clearInsuranceCoverage: value == null,
      ),
    ));
  }

  void updateFormInternalNotes(String value) {
    emit(state.copyWith(
      formState: state.formState?.copyWith(internalNotes: value),
    ));
  }

  Set<int> validateAllTabs() {
    final form = state.formState;
    if (form == null) return {};
    final errors = <int>{};

    // Tab 0: Basic Info
    final nameValid = form.name.trim().length >= 2;
    final phoneValid = form.phone.trim().isNotEmpty &&
        EgyptianPhoneHelper.isValid(form.phone.trim());
    bool dobValid = true;
    bool guardianValid = true;

    final now = CairoTimeHelper.now();
    if (form.dateOfBirth != null) {
      if (form.dateOfBirth!.isAfter(now)) {
        dobValid = false;
      }
      int age = now.year - form.dateOfBirth!.year;
      if (now.month < form.dateOfBirth!.month ||
          (now.month == form.dateOfBirth!.month &&
              now.day < form.dateOfBirth!.day)) {
        age--;
      }
      if (age < 18) {
        if (form.guardianName.trim().isEmpty ||
            form.guardianPhone.trim().isEmpty ||
            !EgyptianPhoneHelper.isValid(form.guardianPhone.trim())) {
          guardianValid = false;
        }
      }
    }

    if (!nameValid || !phoneValid || !dobValid || !guardianValid) {
      errors.add(0);
    }

    // Tab 1: Medical Info
    if (form.gender == GenderEnum.female &&
        form.lastMenstrualPeriodDate != null) {
      final lmp = form.lastMenstrualPeriodDate!;
      if (lmp.isAfter(now)) {
        errors.add(1);
      }
      if (form.dateOfBirth != null && !lmp.isAfter(form.dateOfBirth!)) {
        errors.add(1);
      }
    }

    // Tab 2: Contact & Insurance
    if (form.insuranceCoveragePercent != null) {
      final p = form.insuranceCoveragePercent!;
      if (p < 0 || p > 100) {
        errors.add(2);
      }
    }
    if (form.emergencyContactPhone.trim().isNotEmpty) {
      if (!EgyptianPhoneHelper.isValid(form.emergencyContactPhone.trim())) {
        errors.add(2);
      }
    }

    return errors;
  }

  Future<bool> savePatient({
    String? name,
    String? phone,
    String? address,
    bool allowDuplicatePhone = false,
  }) async {
    final form = state.formState;
    if (form == null) return false;

    final femaleValidation = FemaleIntakeValidator.validate(
      gender: form.gender,
      dateOfBirth: form.dateOfBirth,
      isPregnant: form.isPregnant,
      isNursing: form.isNursing,
      lmpDate: form.lastMenstrualPeriodDate,
      eddDate: form.estimatedDueDate,
      pregnantAndNursingConfirmed: form.pregnantAndNursingConfirmed,
    );
    if (!femaleValidation.isValid) {
      emit(state.copyWith(
        formTabsWithErrors: const {1},
        activeFormTab: 1,
        actionStatus: RequestStatusEnum.failure,
        actionErrMessage: femaleValidation.errors.first,
      ));
      return false;
    }

    // Multi-tab validation
    final invalidTabs = validateAllTabs();
    if (invalidTabs.isNotEmpty) {
      emit(state.copyWith(
        formTabsWithErrors: invalidTabs,
        activeFormTab: invalidTabs.first,
        actionStatus: RequestStatusEnum.failure,
        actionErrMessage: 'يرجى تصحيح الأخطاء في التبويبات المحددة',
      ));
      return false;
    }
    emit(state.copyWith(formTabsWithErrors: const {}));

    final isEditing = form.id != null;

    emit(state.copyWith(
      actionStatus: RequestStatusEnum.loading,
      clearDuplicatePhoneWarning: allowDuplicatePhone,
    ));

    final finalName = (name ?? form.name).trim();
    final finalPhone = (phone ?? form.phone).trim();
    final finalAddress = (address ?? form.detailedAddress).trim();

    final effectiveGender = (form.gender == null || form.gender == GenderEnum.unknown) &&
            (form.isPregnant || form.isNursing)
        ? GenderEnum.female
        : form.gender;

    final patientModel = PatientModel(
      id: form.id,
      fileNumber: form.fileNumber,
      name: finalName,
      phone: finalPhone,
      phoneHasWhatsapp: form.phoneHasWhatsapp,
      dateOfBirth: form.dateOfBirth,
      gender: effectiveGender,
      bloodGroup: form.bloodGroup,
      allergies: form.allergies,
      chronicDiseases: form.chronicDiseases,
      heightCm: form.heightCm,
      weightKg: form.weightKg,
      isPregnant: form.isPregnant,
      isNursing: form.isNursing,
      lastMenstrualPeriodDate: form.lastMenstrualPeriodDate,
      maritalStatus: form.maritalStatus,
      estimatedDueDate: form.estimatedDueDate ??
          (form.isPregnant && form.lastMenstrualPeriodDate != null
              ? form.lastMenstrualPeriodDate!.add(const Duration(days: 280))
              : null),
      nursingBabyAgeMonths: form.nursingBabyAgeMonths,
      gravidaCount: form.gravidaCount,
      paraCount: form.paraCount,
      miscarriageCount: form.miscarriageCount,
      cesareanCount: form.cesareanCount,
      contraceptionMethod:
          form.contraceptionMethod.isNotEmpty ? form.contraceptionMethod : null,
      isMenopause: form.isMenopause,
      hasPregnancyAllergyWarning: form.hasPregnancyAllergyWarning,
      governorate: form.governorate,
      city: form.city.isNotEmpty ? form.city : null,
      detailedAddress: finalAddress,
      emergencyContactName: form.emergencyContactName.isNotEmpty
          ? form.emergencyContactName
          : null,
      emergencyContactPhone: form.emergencyContactPhone.isNotEmpty
          ? form.emergencyContactPhone
          : null,
      emergencyContactRelation: form.emergencyContactRelation.isNotEmpty
          ? form.emergencyContactRelation
          : null,
      guardianName: form.guardianName.isNotEmpty ? form.guardianName : null,
      guardianPhone: form.guardianPhone.isNotEmpty ? form.guardianPhone : null,
      guardianRelation:
          form.guardianRelation.isNotEmpty ? form.guardianRelation : null,
      insuranceCompany:
          form.insuranceCompany.isNotEmpty ? form.insuranceCompany : null,
      insurancePolicyNumber: form.insurancePolicyNumber.isNotEmpty
          ? form.insurancePolicyNumber
          : null,
      insuranceCoveragePercent: form.insuranceCoveragePercent,
      internalNotes: form.internalNotes.isNotEmpty ? form.internalNotes : null,
    );

    final result = isEditing
        ? await updatePatientUseCase(patientModel, allowDuplicatePhone: allowDuplicatePhone)
        : await addPatientUseCase(patientModel, allowDuplicatePhone: allowDuplicatePhone);

    return result.fold(
      (failure) {
        if (failure is DuplicatePhoneWarningFailure) {
          emit(state.copyWith(
            actionStatus: RequestStatusEnum.initial,
            duplicatePhonePatients: failure.matchingPatients,
            hasPendingDuplicatePhoneWarning: true,
          ));
          return false;
        }

        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
          clearDuplicatePhoneWarning: true,
        ));
        return false;
      },
      (saved) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          clearFormState: true,
          clearDuplicatePhoneWarning: true,
          selectedPatient: saved,
          lastSavedPatient: saved,
        ));
        fetchPatients();
        return true;
      },
    );
  }

  void clearDuplicatePhoneWarning() {
    emit(state.copyWith(clearDuplicatePhoneWarning: true));
  }

  Future<bool> confirmSaveWithDuplicatePhone() async {
    return savePatient(allowDuplicatePhone: true);
  }

  Future<List<PatientModel>> searchPatientsByPhone(
    String phone, {
    String? excludePatientId,
  }) async {
    if (findPatientsByPhoneUseCase != null) {
      final res = await findPatientsByPhoneUseCase!(
        phone: phone,
        excludePatientId: excludePatientId,
      );
      return res.fold((_) => [], (list) => list);
    }
    final repo = getIt<PatientsRepo>();
    final res = await repo.findPatientsByPhone(
      phone: phone,
      excludePatientId: excludePatientId,
    );
    return res.fold((_) => [], (list) => list);
  }

  Future<bool> archivePatient(String id, {String? reason}) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    if (archivePatientUseCase != null) {
      final res = await archivePatientUseCase!(
        ArchivePatientParams(id: id, reason: reason),
      );
      return res.fold(
        (failure) {
          emit(state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ));
          return false;
        },
        (_) {
          emit(state.copyWith(actionStatus: RequestStatusEnum.success));
          fetchPatients();
          return true;
        },
      );
    }

    final repo = getIt<PatientsRepo>();
    final res = await repo.archivePatient(id: id, reason: reason);
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        fetchPatients();
        return true;
      },
    );
  }

  Future<bool> unarchivePatient(String id) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    if (unarchivePatientUseCase != null) {
      final res = await unarchivePatientUseCase!(id);
      return res.fold(
        (failure) {
          emit(state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ));
          return false;
        },
        (_) {
          emit(state.copyWith(actionStatus: RequestStatusEnum.success));
          fetchPatients();
          return true;
        },
      );
    }

    final repo = getIt<PatientsRepo>();
    final res = await repo.unarchivePatient(id: id);
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          actionErrMessage: failure.errMessage,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        fetchPatients();
        return true;
      },
    );
  }

  Future<bool> deletePatient(String id) async {
    return archivePatient(id, reason: 'حذف عبر النظام');
  }

  // ─── Patient Details Flow ────────────────────────────────────────────────
  Future<void> fetchPatientDetails(String patientId) async {
    emit(
      state.copyWith(
        detailsStatus: RequestStatusEnum.loading,
      ),
    );

    final results = await Future.wait([
      getPatientByIdUseCase(patientId),
      getBookingsUseCase(
        PaginationParams(
          limit: 100,
          filterList: [FilterParam(key: 'customerId', value: patientId)],
        ),
      ),
    ]);

    final patientResult = results[0];
    final bookingsResult = results[1];

    PatientModel? patient;
    String? errMessage;

    patientResult.fold(
      (failure) => errMessage = failure.errMessage,
      (p) => patient = p as PatientModel,
    );

    if (patient == null) {
      emit(
        state.copyWith(
          detailsStatus: RequestStatusEnum.failure,
          detailsErrMessage: errMessage ?? 'تعذر تحميل بيانات المريض',
        ),
      );
      return;
    }

    List<BookingModel> bookings = [];
    bookingsResult.fold(
      (_) => bookings = [],
      (resp) {
        if (resp is BookingsResponseModel) {
          bookings = resp.bookings ?? [];
        }
      },
    );

    // Fetch previous consultations and prescriptions for this patient
    List<VisitModel> visits = [];
    if (getIt.isRegistered<VisitsRepo>()) {
      final visitsRes = await getIt<VisitsRepo>().getVisitsByPatientId(patientId: patientId);
      visitsRes.fold((_) => null, (v) => visits = v);
    }

    // Calculate dynamic KPI metrics
    final totalBookings = bookings.length;
    final upcomingBookings = bookings
        .where((b) => b.status == BookingStatusEnum.scheduled)
        .length;
    final completedBookings = bookings
        .where((b) => b.status == BookingStatusEnum.completed)
        .length;
    final totalSpent = bookings
        .where(
          (b) =>
              b.status == BookingStatusEnum.completed ||
              b.paymentStatus == PaymentStatusEnum.paid,
        )
        .fold<num>(0, (sum, b) => sum + (b.totalPrice ?? b.consultationFee ?? 0));

    final filtered = _applyPatientBookingFilters(
      bookings: bookings,
      statusFilter: state.selectedBookingStatusFilter,
      search: state.patientBookingSearchQuery,
    );

    if (getIt.isRegistered<AuditLogger>()) {
      final session = getIt.isRegistered<SessionCubit>() ? getIt<SessionCubit>() : null;
      final currentUser = session?.currentUser;
      final activeBranch = session?.activeBranchId;

      getIt<AuditLogger>().log(
        eventType: 'view_patient_profile',
        targetUserId: patient?.id,
        targetUserName: patient?.name,
        performedByUserId: currentUser?.id,
        performedByUserName: currentUser?.fullName,
        branchId: activeBranch,
        details: 'استعراض ملف المريض: ${patient?.name ?? ''} (${patient?.id ?? ''})',
      );
    }

    emit(
      state.copyWith(
        detailsStatus: RequestStatusEnum.success,
        selectedPatient: patient,
        patientBookings: bookings,
        filteredPatientBookings: filtered,
        patientVisits: visits,
        patientTotalBookingsCount: totalBookings,
        patientUpcomingBookingsCount: upcomingBookings,
        patientCompletedBookingsCount: completedBookings,
        patientTotalSpentAmount: totalSpent,
      ),
    );
  }

  void changeDetailsTab(int index) {
    emit(state.copyWith(activeDetailsTab: index));
  }

  Future<void> addActiveMedication(ActiveMedicationModel medication) async {
    final patient = state.selectedPatient;
    if (patient == null) return;
    final updatedMeds = <ActiveMedicationModel>[...(patient.activeMedications ?? []), medication];
    final updatedPatient = patient.copyWith(activeMedications: updatedMeds);
    emit(state.copyWith(selectedPatient: updatedPatient));
  }

  Future<void> addSurgicalProcedure(SurgicalProcedureModel procedure) async {
    final patient = state.selectedPatient;
    if (patient == null) return;
    final updatedHistory = <SurgicalProcedureModel>[...(patient.surgicalHistory ?? []), procedure];
    final updatedPatient = patient.copyWith(surgicalHistory: updatedHistory);
    emit(state.copyWith(selectedPatient: updatedPatient));
  }

  Future<void> addLabRadiologyRecord(LabRadiologyModel record) async {
    final patient = state.selectedPatient;
    if (patient == null) return;
    final updatedRecords = <LabRadiologyModel>[...(patient.labAndRadiology ?? []), record];
    final updatedPatient = patient.copyWith(labAndRadiology: updatedRecords);
    emit(state.copyWith(selectedPatient: updatedPatient));
  }

  Future<void> addEyeExam(EyeTrackingExamModel exam) async {
    final patient = state.selectedPatient;
    if (patient == null) return;
    final updatedExams = <EyeTrackingExamModel>[...(patient.eyeExams ?? []), exam];
    final updatedPatient = patient.copyWith(eyeExams: updatedExams);
    emit(state.copyWith(selectedPatient: updatedPatient));
  }

  Future<void> addBeforeAfterGalleryItem(BeforeAfterGalleryItemModel item) async {
    final patient = state.selectedPatient;
    if (patient == null) return;
    final updatedGallery = <BeforeAfterGalleryItemModel>[...(patient.beforeAfterGallery ?? []), item];
    final updatedPatient = patient.copyWith(beforeAfterGallery: updatedGallery);
    emit(state.copyWith(selectedPatient: updatedPatient));
  }

  void filterPatientBookingsByStatus(BookingStatusEnum? status) {
    final filtered = _applyPatientBookingFilters(
      bookings: state.patientBookings,
      statusFilter: status,
      search: state.patientBookingSearchQuery,
    );
    emit(
      state.copyWith(
        selectedBookingStatusFilter: status,
        clearBookingStatusFilter: status == null,
        filteredPatientBookings: filtered,
      ),
    );
  }

  void searchPatientBookings(String query) {
    final filtered = _applyPatientBookingFilters(
      bookings: state.patientBookings,
      statusFilter: state.selectedBookingStatusFilter,
      search: query,
    );
    emit(
      state.copyWith(
        patientBookingSearchQuery: query,
        filteredPatientBookings: filtered,
      ),
    );
  }

  List<BookingModel> _applyPatientBookingFilters({
    required List<BookingModel> bookings,
    BookingStatusEnum? statusFilter,
    String search = '',
  }) {
    List<BookingModel> result = bookings;

    if (statusFilter != null) {
      result = result.where((b) => b.status == statusFilter).toList();
    }

    final query = search.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((b) {
        final idMatch = (b.id ?? '').toLowerCase().contains(query);
        final doctorMatch = (b.doctorName ?? '').toLowerCase().contains(query);
        final serviceMatch =
            (b.serviceName ?? '').toLowerCase().contains(query);
        return idMatch || doctorMatch || serviceMatch;
      }).toList();
    }

    return result;
  }

  // ─── Status Dialog ────────────────────────────────────────────────────────
  void initChangeStatusDialog(BookingStatusEnum currentStatus) {
    emit(state.copyWith(dialogStatus: currentStatus));
  }

  void setDialogStatus(BookingStatusEnum status) {
    emit(state.copyWith(dialogStatus: status));
  }

  Future<bool> changeBookingStatus(
    String bookingId,
    BookingStatusEnum newStatus,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await changeBookingStatusUseCase(
      ChangeBookingStatusParams(
        bookingId: bookingId,
        newStatus: newStatus,
      ),
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedPatient?.id != null) {
          fetchPatientDetails(state.selectedPatient!.id!);
        }
        return true;
      },
    );
  }

  // ─── Reassign Doctors Dialog ──────────────────────────────────────────
  void initReassignDoctorsDialog(List<String> currentIds) {
    emit(state.copyWith(dialogDoctorIds: currentIds.toSet()));
  }

  void toggleReassignDoctor(String doctorId) {
    final updated = Set<String>.from(state.dialogDoctorIds);
    if (updated.contains(doctorId)) {
      if (updated.length > 1) updated.remove(doctorId);
    } else {
      updated.add(doctorId);
    }
    emit(state.copyWith(dialogDoctorIds: updated));
  }

  Future<bool> reassignDoctors(
    String bookingId,
    List<String> doctorIds,
    List<String> doctorNames,
  ) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await reassignTechnicianUseCase(
      ReassignTechnicianParams(
        bookingId: bookingId,
        newTechnicianIds: doctorIds,
        newTechnicianNames: doctorNames,
      ),
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedPatient?.id != null) {
          fetchPatientDetails(state.selectedPatient!.id!);
        }
        return true;
      },
    );
  }

  // ─── Delete Booking ───────────────────────────────────────────────────────
  Future<bool> deleteBooking(String bookingId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final result = await deleteBookingUseCase(bookingId);

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(actionStatus: RequestStatusEnum.success));
        if (state.selectedPatient?.id != null) {
          fetchPatientDetails(state.selectedPatient!.id!);
        }
        return true;
      },
    );
  }

  // ─── Treatment Plans & Multi-Session Services ─────────────────────────────────
  Future<bool> addTreatmentPlan(PatientTreatmentPlanModel plan) async {
    final patientId = state.selectedPatient?.id;
    if (patientId == null) return false;
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final repo = patientsRepo ?? getIt<PatientsRepo>();
    final result = await repo.addTreatmentPlan(patientId: patientId, plan: plan);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (newPlan) {
        final currentPlans = List<PatientTreatmentPlanModel>.from(
          state.selectedPatient?.treatmentPlans ?? [],
        )..insert(0, newPlan);
        final updatedPatient = state.selectedPatient!.copyWith(
          treatmentPlans: currentPlans,
        );
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedPatient: updatedPatient,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updateTreatmentPlan(PatientTreatmentPlanModel plan) async {
    final patientId = state.selectedPatient?.id;
    if (patientId == null) return false;
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final repo = patientsRepo ?? getIt<PatientsRepo>();
    final result = await repo.updateTreatmentPlan(patientId: patientId, plan: plan);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updatedPlan) {
        final currentPlans = List<PatientTreatmentPlanModel>.from(
          state.selectedPatient?.treatmentPlans ?? [],
        );
        final idx = currentPlans.indexWhere((p) => p.id == updatedPlan.id);
        if (idx != -1) currentPlans[idx] = updatedPlan;
        final updatedPatient = state.selectedPatient!.copyWith(
          treatmentPlans: currentPlans,
        );
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedPatient: updatedPatient,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> recordTreatmentSession({
    required String planId,
    required TreatmentSessionRecordModel session,
  }) async {
    final patientId = state.selectedPatient?.id;
    if (patientId == null) return false;
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final repo = patientsRepo ?? getIt<PatientsRepo>();
    final result = await repo.recordTreatmentSession(
      patientId: patientId,
      planId: planId,
      session: session,
    );
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updatedPlan) {
        final currentPlans = List<PatientTreatmentPlanModel>.from(
          state.selectedPatient?.treatmentPlans ?? [],
        );
        final idx = currentPlans.indexWhere((p) => p.id == updatedPlan.id);
        if (idx != -1) currentPlans[idx] = updatedPlan;
        final updatedPatient = state.selectedPatient!.copyWith(
          treatmentPlans: currentPlans,
        );
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedPatient: updatedPatient,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> recordTreatmentPayment({
    required String planId,
    required TreatmentPaymentRecordModel payment,
  }) async {
    final patientId = state.selectedPatient?.id;
    if (patientId == null) return false;
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));
    final repo = patientsRepo ?? getIt<PatientsRepo>();
    final result = await repo.recordTreatmentPayment(
      patientId: patientId,
      planId: planId,
      payment: payment,
    );
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            actionErrMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updatedPlan) {
        final currentPlans = List<PatientTreatmentPlanModel>.from(
          state.selectedPatient?.treatmentPlans ?? [],
        );
        final idx = currentPlans.indexWhere((p) => p.id == updatedPlan.id);
        if (idx != -1) currentPlans[idx] = updatedPlan;
        final updatedPatient = state.selectedPatient!.copyWith(
          treatmentPlans: currentPlans,
        );
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            selectedPatient: updatedPatient,
          ),
        );
        return true;
      },
    );
  }
}

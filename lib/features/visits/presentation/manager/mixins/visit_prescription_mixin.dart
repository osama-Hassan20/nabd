import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../../core/base/safe_cubit.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../../../drugs/data/models/drug_model.dart';
import '../../../../drugs/data/models/prescription_template_model.dart';
import '../../../../drugs/domain/helpers/drug_allergy_matcher.dart';
import '../../../../patients/data/models/medical_catalog_item_model.dart';
import '../../../../patients/data/models/patient_model.dart';
import '../../../../settings/data/models/company_settings_model.dart';
import '../../../../settings/data/models/enums/print_format_enum.dart';
import '../../../data/models/prescription_item_model.dart';
import '../../../domain/use_cases/add_visit_addendum_use_case.dart';
import '../../../domain/use_cases/print_prescription_use_case.dart';
import '../visits_state.dart';

mixin VisitPrescriptionMixin on SafeCubit<VisitsState> {
  AddVisitAddendumUseCase? get addVisitAddendumUseCase;
  PrintPrescriptionUseCase? get printPrescriptionUseCase;

  static const int maxPrescriptionItems = 20;

  static String? checkPregnancyLactationWarning({
    required DrugModel drug,
    PatientModel? patient,
  }) {
    if (patient == null) return null;
    final warnings = <String>[];
    if (patient.isPregnant == true && drug.unsafeInPregnancy) {
      warnings.add('تحذير: الدواء "${drug.name ?? ''}" غير آمن أثناء الحمل.');
    }
    if (patient.isNursing == true && drug.unsafeInLactation) {
      warnings.add('تحذير: الدواء "${drug.name ?? ''}" غير آمن أثناء الرضاعة.');
    }
    if (warnings.isEmpty) return null;
    return warnings.join('\n');
  }

  bool addPrescriptionItem(PrescriptionItemModel item) {
    final currentItems = List<PrescriptionItemModel>.from(
      state.formState.prescriptionItems ?? const [],
    );

    if (currentItems.length >= maxPrescriptionItems) {
      emit(
        state.copyWith(
          errorMessage: 'rx_max_items_reached',
        ),
      );
      return false;
    }

    final now = CairoTimeHelper.now();
    final itemId = item.id ??
        'RXI-${now.millisecondsSinceEpoch}-${currentItems.length + 1}';

    final newItem = item.copyWith(
      id: itemId,
      orderIndex: currentItems.length + 1,
      createdAt: item.createdAt ?? now,
    );

    currentItems.add(newItem);

    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          prescriptionItems: currentItems,
          isDirty: true,
          clearEditingItem: true,
          isAllergyWarningDismissed: false,
        ),
      ),
    );
    return true;
  }

  void updatePrescriptionItem(PrescriptionItemModel item) {
    if (item.id == null) return;
    final currentItems = List<PrescriptionItemModel>.from(
      state.formState.prescriptionItems ?? const [],
    );

    final idx = currentItems.indexWhere((element) => element.id == item.id);
    if (idx != -1) {
      currentItems[idx] = item;
      emit(
        state.copyWith(
          formState: state.formState.copyWith(
            prescriptionItems: currentItems,
            isDirty: true,
            clearEditingItem: true,
          ),
        ),
      );
    }
  }

  void removePrescriptionItem(String itemId) {
    final currentItems = List<PrescriptionItemModel>.from(
      state.formState.prescriptionItems ?? const [],
    );

    final initialCount = currentItems.length;
    currentItems.removeWhere((item) => item.id == itemId);

    if (currentItems.length != initialCount) {
      // Re-index remaining items
      final reindexed = <PrescriptionItemModel>[];
      for (var i = 0; i < currentItems.length; i++) {
        reindexed.add(currentItems[i].copyWith(orderIndex: i + 1));
      }

      emit(
        state.copyWith(
          formState: state.formState.copyWith(
            prescriptionItems: reindexed,
            isDirty: true,
          ),
        ),
      );
    }
  }

  void setEditingPrescriptionItem(PrescriptionItemModel? item) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          editingItem: item,
          clearEditingItem: item == null,
        ),
      ),
    );
  }

  void clearEditingPrescriptionItem() {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(clearEditingItem: true),
      ),
    );
  }

  void dismissAllergyWarning() {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(isAllergyWarningDismissed: true),
      ),
    );
  }

  void clearPrescription() {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          prescriptionItems: const [],
          isDirty: true,
          clearEditingItem: true,
          isAllergyWarningDismissed: false,
        ),
      ),
    );
  }

  int applyPrescriptionTemplate(
    PrescriptionTemplateModel template, {
    List<DrugModel>? catalog,
  }) {
    final currentItems = List<PrescriptionItemModel>.from(
      state.formState.prescriptionItems ?? const [],
    );

    int skippedCount = 0;
    final now = CairoTimeHelper.now();

    for (final templateItem in template.items ?? const []) {
      if (currentItems.length >= maxPrescriptionItems) {
        break;
      }

      // If catalog provided, check if the drug is archived / inactive
      if (catalog != null && templateItem.drugId != null) {
        final drug = catalog
            .where((d) => d.id == templateItem.drugId)
            .firstOrNull;
        if (drug != null && drug.isActive == false) {
          skippedCount++;
          continue;
        }
      }

      final newItem = PrescriptionItemModel(
        id: 'RXI-${now.millisecondsSinceEpoch}-${currentItems.length + 1}',
        drugId: templateItem.drugId,
        tradeName: templateItem.drugName,
        scientificName: templateItem.scientificName,
        concentration: templateItem.concentration,
        dosage: templateItem.dosage,
        frequency: templateItem.frequency,
        duration: templateItem.duration,
        instructions: templateItem.instructions,
        orderIndex: currentItems.length + 1,
        createdAt: now,
      );

      currentItems.add(newItem);
    }

    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          prescriptionItems: currentItems,
          isDirty: true,
        ),
      ),
    );

    return skippedCount;
  }

  AllergyMatchResult checkDrugAllergy({
    required DrugModel drug,
    List<MedicalCatalogItemModel>? catalogItems,
  }) {
    return DrugAllergyMatcher.checkAllergy(
      drugName: drug.name ?? '',
      scientificName: drug.scientificName,
      patientAllergies: state.patientAllergies,
      allergyCatalogItems: catalogItems,
    );
  }

  Future<bool> addAddendum(AddVisitAddendumParams params) async {
    if (addVisitAddendumUseCase == null) return false;

    final res = await addVisitAddendumUseCase!(params);
    return res.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.errMessage));
        return false;
      },
      (updatedVisit) {
        emit(
          state.copyWith(
            activeVisit: updatedVisit,
            formState: state.formState.copyWith(
              addenda: updatedVisit.addenda,
              isDirty: false,
            ),
          ),
        );
        return true;
      },
    );
  }

  Future<Either<Failures, Uint8List>?> printActivePrescription({
    CompanySettingsModel? settings,
    PrintFormat? format,
    ByteData? fontData,
    PatientModel? patient,
  }) async {
    final visit = state.activeVisit;
    if (visit == null || printPrescriptionUseCase == null) return null;

    return printPrescriptionUseCase!(
      PrintPrescriptionParams(
        visit: visit,
        patient: patient,
        settings: settings,
        format: format,
        fontData: fontData,
      ),
    );
  }
}

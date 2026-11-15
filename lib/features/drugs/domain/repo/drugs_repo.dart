import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import '../../data/models/drug_category_model.dart';
import '../../data/models/drug_model.dart';
import '../../data/models/enums/review_status_enum.dart';
import '../../data/models/prescription_template_model.dart';

abstract class DrugsRepo {
  /// Fetches catalog drugs with optional query, category filter, review status filter, and archive inclusion.
  Future<Either<Failures, List<DrugModel>>> getDrugs({
    String? query,
    String? categoryId,
    String? reviewFilter,
    bool includeArchived = false,
  });

  /// Fetches all active drug categories.
  Future<Either<Failures, List<DrugCategoryModel>>> getCategories();

  /// Adds a new drug to the general catalog.
  Future<Either<Failures, DrugModel>> addDrug(DrugModel drug);

  /// Updates an existing drug in the catalog.
  Future<Either<Failures, DrugModel>> updateDrug(DrugModel drug);

  /// Soft-archives (deactivates) a drug from the catalog.
  Future<Either<Failures, Unit>> archiveDrug(String drugId);

  /// Adds a new uncataloged drug quickly from the consultation screen with pending review status.
  Future<Either<Failures, DrugModel>> quickAddDrug({
    required String name,
    required String visitId,
    required String doctorId,
    String? concentration,
    String? dosage,
    String? frequency,
    String? duration,
  });

  /// Reviews a quick-added drug (approve, reject, or merge).
  Future<Either<Failures, DrugModel>> reviewQuickAddDrug({
    required String drugId,
    required ReviewStatusEnum decision,
    required String reviewedByUserId,
    String? mergeTargetDrugId,
  });

  /// Updates allergy aliases for a catalog item.
  Future<Either<Failures, Unit>> updateAllergyAliases({
    required String catalogItemId,
    required List<String> aliases,
  });

  /// Fetches the map of all allergy aliases.
  Future<Either<Failures, Map<String, List<String>>>> getAllergyAliases();

  /// Fetches prescription templates belonging exclusively to the specified doctor.
  Future<Either<Failures, List<PrescriptionTemplateModel>>> getDoctorTemplates(
    String doctorId,
  );

  /// Saves (creates or updates) a prescription template owned by a doctor.
  Future<Either<Failures, PrescriptionTemplateModel>> savePrescriptionTemplate(
    PrescriptionTemplateModel template,
  );

  /// Deletes (soft deletes) a prescription template owned by a doctor.
  Future<Either<Failures, Unit>> deletePrescriptionTemplate(
    String templateId,
    String doctorId,
  );

  /// Atomically imports a batch of drugs into the catalog.
  Future<Either<Failures, int>> importDrugsBatch(List<DrugModel> drugs);
}

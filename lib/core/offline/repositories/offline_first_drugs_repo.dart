import 'package:dartz/dartz.dart';
import 'package:eyadty/core/errors/failures.dart';
import 'package:eyadty/core/offline/data_mode_service.dart';
import 'package:eyadty/core/offline/models/local_entity_record.dart';
import 'package:eyadty/core/offline/models/outbox_entry.dart';
import 'package:eyadty/core/offline/models/sync_status.dart';
import 'package:eyadty/core/offline/store/transactional_local_store.dart';
import 'package:eyadty/features/drugs/data/models/drug_category_model.dart';
import 'package:eyadty/features/drugs/data/models/drug_model.dart';
import 'package:eyadty/features/drugs/data/models/enums/drug_source_enum.dart';
import 'package:eyadty/features/drugs/data/models/enums/review_status_enum.dart';
import 'package:eyadty/features/drugs/data/models/prescription_template_model.dart';
import 'package:eyadty/features/drugs/domain/repo/drugs_repo.dart';

class OfflineFirstDrugsRepo implements DrugsRepo {
  final TransactionalLocalStore localStore;
  final DataModeService dataModeService;
  final DrugsRepo remoteRepo;
  final String Function() getCurrentAccountId;
  final String Function() getCurrentBranchId;

  OfflineFirstDrugsRepo({
    required this.localStore,
    required this.dataModeService,
    required this.remoteRepo,
    required this.getCurrentAccountId,
    required this.getCurrentBranchId,
  });

  @override
  Future<Either<Failures, List<DrugModel>>> getDrugs({
    String? query,
    String? categoryId,
    String? reviewFilter,
    bool includeArchived = false,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();

    // 1. Fetch seed/remote drugs from fallback repository
    List<DrugModel> baseDrugs = [];
    final remoteRes = await remoteRepo.getDrugs(
      query: query,
      categoryId: categoryId,
      reviewFilter: reviewFilter,
      includeArchived: includeArchived,
    );
    remoteRes.fold((_) {}, (list) => baseDrugs = List.from(list));

    // 2. Fetch locally stored drugs from transactional local store
    final localRecords = await localStore.getEntities(
      entityType: 'drug',
      accountId: accountId,
      branchId: branchId,
      includeTombstones: true,
    );

    final Set<String> tombstonedIds = {};
    final Map<String, DrugModel> localDrugMap = {};

    for (final rec in localRecords) {
      if (rec.isTombstone) {
        tombstonedIds.add(rec.localId);
      } else {
        try {
          final drug = DrugModel.fromJson(rec.payload);
          if (drug.id != null) {
            localDrugMap[drug.id!] = drug;
          }
        } catch (_) {}
      }
    }

    // 3. Merge: Filter out tombstones and override base with local drafts
    final merged = <DrugModel>[];

    // Add local additions first so newly created drugs appear at top
    for (final localDrug in localDrugMap.values) {
      if (!tombstonedIds.contains(localDrug.id)) {
        merged.add(localDrug);
      }
    }

    for (final baseDrug in baseDrugs) {
      if (baseDrug.id != null) {
        if (tombstonedIds.contains(baseDrug.id)) continue;
        if (localDrugMap.containsKey(baseDrug.id)) continue; // Already added
      }
      merged.add(baseDrug);
    }

    // Apply filtering if provided
    var result = merged;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((d) {
        final name = (d.name ?? '').toLowerCase();
        final sciName = (d.scientificName ?? '').toLowerCase();
        return name.contains(q) || sciName.contains(q);
      }).toList();
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((d) => d.categoryId == categoryId).toList();
    }

    if (reviewFilter != null && reviewFilter.isNotEmpty) {
      result = result.where((d) => d.reviewStatus?.name == reviewFilter).toList();
    }

    if (!includeArchived) {
      result = result.where((d) => d.isActive != false).toList();
    }

    return Right(result);
  }

  @override
  Future<Either<Failures, List<DrugCategoryModel>>> getCategories() {
    return remoteRepo.getCategories();
  }

  @override
  Future<Either<Failures, DrugModel>> addDrug(DrugModel drug) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final localId = drug.id ?? 'drug_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final drugWithId = drug.copyWith(
      id: localId,
      createdAt: now,
      source: drug.source ?? DrugSourceEnum.custom,
      reviewStatus: drug.reviewStatus ?? ReviewStatusEnum.approved,
    );

    final isProvisional = !dataModeService.isOnline;
    final operationId = 'op_drug_add_${localId}_${now.microsecondsSinceEpoch}';

    // 1. Write atomically to Local Store + Outbox
    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'drug',
          accountId: accountId,
          branchId: branchId,
          payload: drugWithId.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'drug',
          localId: localId,
          operation: OutboxOperationType.create,
          payload: drugWithId.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    // 2. Also save to fallback repo in memory
    try {
      await remoteRepo.addDrug(drugWithId);
    } catch (_) {}

    return Right(drugWithId);
  }

  @override
  Future<Either<Failures, DrugModel>> quickAddDrug({
    required String name,
    required String visitId,
    required String doctorId,
    String? concentration,
    String? dosage,
    String? frequency,
    String? duration,
  }) async {
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final localId = 'drug_quick_${now.millisecondsSinceEpoch}';

    final drug = DrugModel(
      id: localId,
      name: name.trim(),
      concentration: concentration?.trim(),
      defaultDosage: dosage?.trim(),
      defaultFrequency: frequency?.trim(),
      defaultDuration: duration?.trim(),
      isQuickAdded: true,
      reviewStatus: ReviewStatusEnum.pending,
      source: DrugSourceEnum.quickAdd,
      createdByUserId: doctorId,
      createdAt: now,
    );

    final isProvisional = !dataModeService.isOnline;
    final operationId = 'op_drug_quick_${localId}_${now.microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: localId,
          entityType: 'drug',
          accountId: accountId,
          branchId: branchId,
          payload: drug.toJson(),
          localRevision: 1,
          syncStatus: isProvisional ? SyncStatus.pending : SyncStatus.synced,
          isProvisional: isProvisional,
          createdAt: now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'drug',
          localId: localId,
          operation: OutboxOperationType.create,
          payload: drug.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.quickAddDrug(
        name: name,
        visitId: visitId,
        doctorId: doctorId,
        concentration: concentration,
        dosage: dosage,
        frequency: frequency,
        duration: duration,
      );
    } catch (_) {}

    return Right(drug);
  }

  @override
  Future<Either<Failures, DrugModel>> updateDrug(DrugModel drug) async {
    if (drug.id == null) {
      return const Left(ServerFailure(errMessage: 'Drug ID is required for update.'));
    }
    final accountId = getCurrentAccountId();
    final branchId = getCurrentBranchId();
    final now = DateTime.now();
    final operationId = 'op_drug_upd_${drug.id}_${now.microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.upsertEntity(
        LocalEntityRecord(
          localId: drug.id!,
          entityType: 'drug',
          accountId: accountId,
          branchId: branchId,
          payload: drug.toJson(),
          localRevision: 2,
          syncStatus: SyncStatus.pending,
          isProvisional: !dataModeService.isOnline,
          createdAt: drug.createdAt ?? now,
          updatedAt: now,
        ),
      );

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'drug',
          localId: drug.id!,
          operation: OutboxOperationType.update,
          payload: drug.toJson(),
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.updateDrug(drug);
    } catch (_) {}

    return Right(drug);
  }

  @override
  Future<Either<Failures, Unit>> archiveDrug(String drugId) async {
    final now = DateTime.now();
    final operationId = 'op_drug_del_${drugId}_${now.microsecondsSinceEpoch}';

    await localStore.runInTransaction((txn) async {
      txn.markTombstone(drugId);

      txn.insertOutbox(
        OutboxEntry(
          operationId: operationId,
          entityType: 'drug',
          localId: drugId,
          operation: OutboxOperationType.delete,
          payload: {'id': drugId},
          baseRevision: 1,
          createdAt: now,
          status: OutboxStatus.pending,
        ),
      );
    });

    try {
      await remoteRepo.archiveDrug(drugId);
    } catch (_) {}

    return const Right(unit);
  }

  @override
  Future<Either<Failures, DrugModel>> reviewQuickAddDrug({
    required String drugId,
    required ReviewStatusEnum decision,
    required String reviewedByUserId,
    String? mergeTargetDrugId,
  }) {
    return remoteRepo.reviewQuickAddDrug(
      drugId: drugId,
      decision: decision,
      reviewedByUserId: reviewedByUserId,
      mergeTargetDrugId: mergeTargetDrugId,
    );
  }

  @override
  Future<Either<Failures, Unit>> updateAllergyAliases({
    required String catalogItemId,
    required List<String> aliases,
  }) {
    return remoteRepo.updateAllergyAliases(
      catalogItemId: catalogItemId,
      aliases: aliases,
    );
  }

  @override
  Future<Either<Failures, Map<String, List<String>>>> getAllergyAliases() {
    return remoteRepo.getAllergyAliases();
  }

  @override
  Future<Either<Failures, List<PrescriptionTemplateModel>>> getDoctorTemplates(
    String doctorId,
  ) {
    return remoteRepo.getDoctorTemplates(doctorId);
  }

  @override
  Future<Either<Failures, PrescriptionTemplateModel>> savePrescriptionTemplate(
    PrescriptionTemplateModel template,
  ) {
    return remoteRepo.savePrescriptionTemplate(template);
  }

  @override
  Future<Either<Failures, Unit>> deletePrescriptionTemplate(
    String templateId,
    String doctorId,
  ) {
    return remoteRepo.deletePrescriptionTemplate(templateId, doctorId);
  }

  @override
  Future<Either<Failures, int>> importDrugsBatch(List<DrugModel> drugs) {
    return remoteRepo.importDrugsBatch(drugs);
  }
}

import 'package:eyadty/core/base/safe_cubit.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/services/audit_logger.dart';
import 'package:eyadty/core/services/permission_evaluator.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:eyadty/features/patients/domain/repo/medical_catalog_repo.dart';
import '../../data/models/drug_model.dart';
import '../../data/models/enums/review_status_enum.dart';
import '../../data/models/prescription_template_model.dart';
import '../../domain/repo/drugs_repo.dart';
import '../../domain/use_cases/add_drug_use_case.dart';
import '../../domain/use_cases/archive_drug_use_case.dart';
import '../../domain/use_cases/delete_prescription_template_use_case.dart';
import '../../domain/use_cases/get_doctor_templates_use_case.dart';
import '../../domain/use_cases/get_drugs_catalog_use_case.dart';
import '../../domain/use_cases/review_quick_add_drug_use_case.dart';
import '../../domain/use_cases/save_prescription_template_use_case.dart';
import '../../domain/use_cases/update_allergy_aliases_use_case.dart';
import '../../domain/use_cases/update_drug_use_case.dart';
import 'drugs_state.dart';

class DrugsCubit extends SafeCubit<DrugsState> {
  final DrugsRepo repo;
  final MedicalCatalogRepo medicalCatalogRepo;
  final GetDrugsCatalogUseCase getDrugsCatalogUseCase;
  final AddDrugUseCase addDrugUseCase;
  final UpdateDrugUseCase updateDrugUseCase;
  final ArchiveDrugUseCase archiveDrugUseCase;
  final ReviewQuickAddDrugUseCase reviewQuickAddDrugUseCase;
  final GetDoctorTemplatesUseCase getDoctorTemplatesUseCase;
  final SavePrescriptionTemplateUseCase savePrescriptionTemplateUseCase;
  final DeletePrescriptionTemplateUseCase deletePrescriptionTemplateUseCase;
  final UpdateAllergyAliasesUseCase updateAllergyAliasesUseCase;
  final PermissionEvaluator permissionEvaluator;
  final CurrentUserProvider userProvider;
  final AuditLogger? auditLogger;

  DrugsCubit({
    required this.repo,
    required this.medicalCatalogRepo,
    required this.getDrugsCatalogUseCase,
    required this.addDrugUseCase,
    required this.updateDrugUseCase,
    required this.archiveDrugUseCase,
    required this.reviewQuickAddDrugUseCase,
    required this.getDoctorTemplatesUseCase,
    required this.savePrescriptionTemplateUseCase,
    required this.deletePrescriptionTemplateUseCase,
    required this.updateAllergyAliasesUseCase,
    required this.permissionEvaluator,
    required this.userProvider,
    this.auditLogger,
  }) : super(DrugsState.initial());

  Future<void> loadData() async {
    emit(state.copyWith(status: RequestStatusEnum.loading));

    final doctorId = userProvider.currentUser?.linkedDoctorId ?? '';

    final results = await Future.wait([
      getDrugsCatalogUseCase(const GetDrugsParams(includeArchived: false)),
      repo.getCategories(),
      doctorId.isNotEmpty
          ? getDoctorTemplatesUseCase(doctorId)
          : repo.getDoctorTemplates(''),
      medicalCatalogRepo.getCatalogItems(type: 'allergy'),
      repo.getAllergyAliases(),
    ]);

    final drugsRes = results[0];
    final categoriesRes = results[1];
    final templatesRes = results[2];
    final allergyItemsRes = results[3];
    final aliasesMapRes = results[4];

    List<DrugModel> loadedDrugs = [];
    drugsRes.fold((_) {}, (r) => loadedDrugs = r as List<DrugModel>);

    List<dynamic> loadedCategories = [];
    categoriesRes.fold((_) {}, (r) => loadedCategories = r as List<dynamic>);

    List<PrescriptionTemplateModel> loadedTemplates = [];
    templatesRes.fold((_) {}, (r) => loadedTemplates = r as List<PrescriptionTemplateModel>);

    List<MedicalCatalogItemModel> loadedAllergyItems = [];
    allergyItemsRes.fold((_) {}, (r) => loadedAllergyItems = r as List<MedicalCatalogItemModel>);

    Map<String, List<String>> loadedAliasesMap = {};
    aliasesMapRes.fold((_) {}, (r) => loadedAliasesMap = r as Map<String, List<String>>);

    // Merge aliases from repo into allergy items if present
    final mergedAllergyItems = loadedAllergyItems.map((item) {
      if (item.id != null && loadedAliasesMap.containsKey(item.id)) {
        return item.copyWith(aliases: loadedAliasesMap[item.id]);
      }
      return item;
    }).toList();

    emit(
      state.copyWith(
        status: RequestStatusEnum.success,
        drugs: loadedDrugs,
        categories: loadedCategories.cast(),
        templates: loadedTemplates,
        allergyItems: mergedAllergyItems,
        allergyAliasesMap: loadedAliasesMap,
      ),
    );
  }

  void setActiveTab(int index) {
    emit(state.copyWith(activeTab: index));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setSelectedCategory(String? categoryId) {
    if (categoryId == null) {
      emit(state.copyWith(clearSelectedCategory: true));
    } else {
      emit(state.copyWith(selectedCategoryId: categoryId));
    }
  }

  void setReviewFilter(String filter) {
    emit(state.copyWith(reviewFilter: filter));
  }

  Future<bool> addDrug(DrugModel drug) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final currentUserId = userProvider.currentUser?.id ?? '';
    final res = await addDrugUseCase(
      AddDrugParams(drug: drug, userId: currentUserId),
    );
    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (newDrug) {
        final updatedList = [newDrug, ...state.drugs];
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            drugs: updatedList,
            successMessage: 'drug_added_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updateDrug(DrugModel drug) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final currentUserId = userProvider.currentUser?.id ?? '';
    final res = await updateDrugUseCase(
      UpdateDrugParams(
        drug: drug,
        updatedFields: const [
          'name',
          'scientificName',
          'concentration',
          'defaultDosage',
          'defaultFrequency',
          'defaultDuration',
        ],
        userId: currentUserId,
      ),
    );
    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (updatedDrug) {
        final updatedList = state.drugs.map((d) {
          return d.id == updatedDrug.id ? updatedDrug : d;
        }).toList();

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            drugs: updatedList,
            successMessage: 'drug_updated_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> archiveDrug(String drugId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final currentUserId = userProvider.currentUser?.id ?? '';
    final res = await archiveDrugUseCase(
      ArchiveDrugParams(drugId: drugId, userId: currentUserId),
    );
    return res.fold(
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
        final updatedList = state.drugs.where((d) => d.id != drugId).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            drugs: updatedList,
            successMessage: 'drug_archived_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> reviewQuickAdd({
    required String drugId,
    required ReviewStatusEnum decision,
    String? mergeTargetDrugId,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await reviewQuickAddDrugUseCase(
      ReviewQuickAddDrugParams(
        drugId: drugId,
        decision: decision,
        reviewedByUserId: userProvider.currentUser?.id ?? '',
        mergeTargetDrugId: mergeTargetDrugId,
      ),
    );

    return res.fold(
      (failure) {
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.failure,
            errMessage: failure.errMessage,
          ),
        );
        return false;
      },
      (reviewedDrug) {
        List<DrugModel> updatedList;
        if (decision == ReviewStatusEnum.rejected) {
          updatedList = state.drugs.where((d) => d.id != drugId).toList();
        } else {
          updatedList = state.drugs.map((d) {
            return d.id == drugId ? reviewedDrug : d;
          }).toList();
        }

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            drugs: updatedList,
            successMessage: 'drug_reviewed_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> updateAliases({
    required String catalogItemId,
    required List<String> aliases,
  }) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final currentAliases = state.allergyAliasesMap[catalogItemId] ?? [];

    final res = await updateAllergyAliasesUseCase(
      UpdateAllergyAliasesParams(
        catalogItemId: catalogItemId,
        aliases: aliases,
        aliasesCountBefore: currentAliases.length,
        userId: userProvider.currentUser?.id ?? '',
      ),
    );

    return res.fold(
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
        final updatedMap = Map<String, List<String>>.from(state.allergyAliasesMap);
        updatedMap[catalogItemId] = List<String>.from(aliases);

        final updatedItems = state.allergyItems.map((item) {
          if (item.id == catalogItemId) {
            return item.copyWith(aliases: aliases);
          }
          return item;
        }).toList();

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            allergyAliasesMap: updatedMap,
            allergyItems: updatedItems,
            successMessage: 'aliases_updated_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> saveTemplate(PrescriptionTemplateModel template) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final res = await savePrescriptionTemplateUseCase(template);
    return res.fold(
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
        final existingIdx = state.templates.indexWhere((t) => t.id == saved.id);
        List<PrescriptionTemplateModel> updatedList;
        if (existingIdx != -1) {
          updatedList = List.from(state.templates)..[existingIdx] = saved;
        } else {
          updatedList = [saved, ...state.templates];
        }

        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            templates: updatedList,
            successMessage: 'template_saved_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> deleteTemplate(String templateId) async {
    emit(state.copyWith(actionStatus: RequestStatusEnum.loading));

    final doctorId = userProvider.currentUser?.linkedDoctorId ?? '';
    final res = await deletePrescriptionTemplateUseCase(
      DeleteTemplateParams(
        templateId: templateId,
        doctorId: doctorId,
      ),
    );

    return res.fold(
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
        final updatedList = state.templates.where((t) => t.id != templateId).toList();
        emit(
          state.copyWith(
            actionStatus: RequestStatusEnum.success,
            templates: updatedList,
            successMessage: 'template_deleted_success',
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  bool get canManageCatalog =>
      permissionEvaluator.can(StaffPermissionEnum.manageDrugCatalog);
}

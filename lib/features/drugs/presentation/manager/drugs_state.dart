import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../patients/data/models/medical_catalog_item_model.dart';
import '../../data/models/drug_category_model.dart';
import '../../data/models/drug_model.dart';
import '../../data/models/enums/review_status_enum.dart';
import '../../data/models/prescription_template_model.dart';

class DrugsState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final List<DrugModel> drugs;
  final List<DrugCategoryModel> categories;
  final List<PrescriptionTemplateModel> templates;
  final List<MedicalCatalogItemModel> allergyItems;
  final Map<String, List<String>> allergyAliasesMap;
  final int activeTab; // 0: Catalog, 1: Templates, 2: Allergy Aliases
  final String searchQuery;
  final String? selectedCategoryId;
  final String reviewFilter; // 'all' | 'pending' | 'approved'
  final String? errMessage;
  final String? successMessage;

  const DrugsState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.drugs = const [],
    this.categories = const [],
    this.templates = const [],
    this.allergyItems = const [],
    this.allergyAliasesMap = const {},
    this.activeTab = 0,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.reviewFilter = 'all',
    this.errMessage,
    this.successMessage,
  });

  factory DrugsState.initial() => const DrugsState();

  List<DrugModel> get filteredDrugs {
    return drugs.where((drug) {
      if (selectedCategoryId != null &&
          drug.categoryId != selectedCategoryId) {
        return false;
      }
      if (reviewFilter == 'pending' &&
          drug.reviewStatus != ReviewStatusEnum.pending) {
        return false;
      }
      if (reviewFilter == 'approved' &&
          drug.reviewStatus != ReviewStatusEnum.approved) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final nameMatches = (drug.name ?? '').toLowerCase().contains(q);
        final scientificMatches =
            (drug.scientificName ?? '').toLowerCase().contains(q);
        if (!nameMatches && !scientificMatches) return false;
      }
      return true;
    }).toList();
  }

  DrugsState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    List<DrugModel>? drugs,
    List<DrugCategoryModel>? categories,
    List<PrescriptionTemplateModel>? templates,
    List<MedicalCatalogItemModel>? allergyItems,
    Map<String, List<String>>? allergyAliasesMap,
    int? activeTab,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? reviewFilter,
    String? errMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return DrugsState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      drugs: drugs ?? this.drugs,
      categories: categories ?? this.categories,
      templates: templates ?? this.templates,
      allergyItems: allergyItems ?? this.allergyItems,
      allergyAliasesMap: allergyAliasesMap ?? this.allergyAliasesMap,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      reviewFilter: reviewFilter ?? this.reviewFilter,
      errMessage: clearError ? null : (errMessage ?? this.errMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        drugs,
        categories,
        templates,
        allergyItems,
        allergyAliasesMap,
        activeTab,
        searchQuery,
        selectedCategoryId,
        reviewFilter,
        errMessage,
        successMessage,
      ];
}

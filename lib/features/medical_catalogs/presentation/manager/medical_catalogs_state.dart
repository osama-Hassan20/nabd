import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/enums/medical_catalog_kind_enum.dart';
import '../../data/models/medical_catalog_entry_model.dart';

class MedicalCatalogsState extends Equatable {
  final RequestStatusEnum status;
  final MedicalCatalogKindEnum kind;
  final List<MedicalCatalogEntryModel> entries;
  final List<String> availableCategories;
  final String selectedCategory;
  final String searchQuery;
  final String statusFilter; // 'all', 'active', 'inactive'
  final RequestStatusEnum actionStatus;
  final String? errMessage;
  final String? successMessage;

  const MedicalCatalogsState({
    this.status = RequestStatusEnum.initial,
    this.kind = MedicalCatalogKindEnum.radiology,
    this.entries = const [],
    this.availableCategories = const ['الكل'],
    this.selectedCategory = 'الكل',
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.actionStatus = RequestStatusEnum.initial,
    this.errMessage,
    this.successMessage,
  });

  int get totalCount => entries.length;
  int get activeCount => entries.where((e) => e.isActive).length;
  int get inactiveCount => entries.where((e) => !e.isActive).length;

  List<MedicalCatalogEntryModel> get displayedEntries {
    if (statusFilter == 'active') {
      return entries.where((e) => e.isActive).toList();
    } else if (statusFilter == 'inactive') {
      return entries.where((e) => !e.isActive).toList();
    }
    return entries;
  }

  MedicalCatalogsState copyWith({
    RequestStatusEnum? status,
    MedicalCatalogKindEnum? kind,
    List<MedicalCatalogEntryModel>? entries,
    List<String>? availableCategories,
    String? selectedCategory,
    String? searchQuery,
    String? statusFilter,
    RequestStatusEnum? actionStatus,
    String? errMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MedicalCatalogsState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      entries: entries ?? this.entries,
      availableCategories: availableCategories ?? this.availableCategories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      actionStatus: actionStatus ?? this.actionStatus,
      errMessage: clearMessages ? null : (errMessage ?? this.errMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        kind,
        entries,
        availableCategories,
        selectedCategory,
        searchQuery,
        statusFilter,
        actionStatus,
        errMessage,
        successMessage,
      ];
}

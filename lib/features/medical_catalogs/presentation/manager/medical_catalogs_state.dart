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
    this.actionStatus = RequestStatusEnum.initial,
    this.errMessage,
    this.successMessage,
  });

  int get totalCount => entries.length;
  int get activeCount => entries.where((e) => e.isActive).length;
  int get inactiveCount => entries.where((e) => !e.isActive).length;

  MedicalCatalogsState copyWith({
    RequestStatusEnum? status,
    MedicalCatalogKindEnum? kind,
    List<MedicalCatalogEntryModel>? entries,
    List<String>? availableCategories,
    String? selectedCategory,
    String? searchQuery,
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
        actionStatus,
        errMessage,
        successMessage,
      ];
}

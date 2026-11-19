import 'package:eyadty/core/base/safe_cubit.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/enums/medical_catalog_kind_enum.dart';
import '../../data/models/medical_catalog_entry_model.dart';
import '../../domain/repo/medical_catalogs_repo.dart';
import 'medical_catalogs_state.dart';

class MedicalCatalogsCubit extends SafeCubit<MedicalCatalogsState> {
  final MedicalCatalogsRepo _repo;

  MedicalCatalogsCubit({
    required MedicalCatalogsRepo repo,
    MedicalCatalogKindEnum initialKind = MedicalCatalogKindEnum.radiology,
  })  : _repo = repo,
        super(MedicalCatalogsState(
          kind: initialKind,
          availableCategories: ['الكل', ...initialKind.defaultCategories],
        ));

  void setKind(MedicalCatalogKindEnum newKind) {
    if (state.kind == newKind) return;
    emit(state.copyWith(
      kind: newKind,
      selectedCategory: 'الكل',
      searchQuery: '',
      statusFilter: 'all',
      availableCategories: ['الكل', ...newKind.defaultCategories],
      clearMessages: true,
    ));
    loadEntries();
  }

  void setStatusFilter(String filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void toggleStatusFilter(String filter) {
    if (state.statusFilter == filter) {
      emit(state.copyWith(statusFilter: 'all'));
    } else {
      emit(state.copyWith(statusFilter: filter));
    }
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));
    loadEntries();
  }

  void onCategorySelected(String category) {
    emit(state.copyWith(selectedCategory: category));
    loadEntries();
  }

  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (!state.availableCategories.contains(trimmed)) {
      final updated = List<String>.from(state.availableCategories)..add(trimmed);
      emit(state.copyWith(
        availableCategories: updated,
        selectedCategory: trimmed,
      ));
      loadEntries();
    } else {
      onCategorySelected(trimmed);
    }
  }

  Future<void> loadEntries() async {
    emit(state.copyWith(status: RequestStatusEnum.loading, clearMessages: true));
    final res = await _repo.getEntries(
      kind: state.kind,
      query: state.searchQuery,
      category: state.selectedCategory,
    );
    res.fold(
      (failure) {
        emit(state.copyWith(
          status: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ));
      },
      (list) {
        // Collect all distinct categories from seeds and defaults
        final dynamicCats = list.map((e) => e.category).toSet();
        final allCats = <String>{'الكل', ...state.kind.defaultCategories, ...dynamicCats};

        emit(state.copyWith(
          status: RequestStatusEnum.success,
          entries: list,
          availableCategories: allCats.toList(),
        ));
      },
    );
  }

  Future<bool> addEntry({
    required String name,
    String code = '',
    required String category,
    String? notes,
  }) async {
    emit(state.copyWith(
      actionStatus: RequestStatusEnum.loading,
      clearMessages: true,
    ));

    final newEntry = MedicalCatalogEntryModel(
      id: '',
      name: name,
      code: code,
      kind: state.kind,
      category: category,
      notes: notes,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final res = await _repo.addEntry(newEntry);
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ));
        return false;
      },
      (created) {
        final updatedList = List<MedicalCatalogEntryModel>.from(state.entries)
          ..insert(0, created);
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          entries: updatedList,
          successMessage: 'تم إضافة «${created.name}» بنجاح',
        ));
        return true;
      },
    );
  }

  Future<bool> updateEntry(MedicalCatalogEntryModel entry) async {
    emit(state.copyWith(
      actionStatus: RequestStatusEnum.loading,
      clearMessages: true,
    ));

    final res = await _repo.updateEntry(entry);
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ));
        return false;
      },
      (updated) {
        final updatedList = state.entries.map((e) {
          return e.id == updated.id ? updated : e;
        }).toList();

        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          entries: updatedList,
          successMessage: 'تم تعديل البيانات بنجاح',
        ));
        return true;
      },
    );
  }

  Future<void> toggleActive(MedicalCatalogEntryModel entry) async {
    final nextStatus = !entry.isActive;
    final res = await _repo.toggleActive(
      id: entry.id,
      isActive: nextStatus,
    );
    res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ));
      },
      (updated) {
        final updatedList = state.entries.map((e) {
          return e.id == updated.id ? updated : e;
        }).toList();

        emit(state.copyWith(
          entries: updatedList,
          successMessage: updated.isActive
              ? 'تم تفعيل «${updated.name}»'
              : 'تم تعطيل «${updated.name}»',
        ));
      },
    );
  }

  Future<bool> deleteEntry(String id) async {
    emit(state.copyWith(
      actionStatus: RequestStatusEnum.loading,
      clearMessages: true,
    ));

    final res = await _repo.deleteEntry(id);
    return res.fold(
      (failure) {
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.failure,
          errMessage: failure.errMessage,
        ));
        return false;
      },
      (_) {
        final updatedList =
            state.entries.where((e) => e.id != id).toList();
        emit(state.copyWith(
          actionStatus: RequestStatusEnum.success,
          entries: updatedList,
          successMessage: 'تم حذف العنصر بنجاح',
        ));
        return true;
      },
    );
  }
}

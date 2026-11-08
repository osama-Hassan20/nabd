import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/branch_model.dart';

class BranchesState extends Equatable {
  final RequestStatusEnum status;
  final List<BranchModel> branches;
  final String searchQuery;
  final String activeFilter; // 'all', 'active', 'inactive'
  final String? errMessage;
  final String? successMessage;

  const BranchesState({
    this.status = RequestStatusEnum.initial,
    this.branches = const [],
    this.searchQuery = '',
    this.activeFilter = 'all',
    this.errMessage,
    this.successMessage,
  });

  List<BranchModel> get filteredBranches {
    return branches.where((branch) {
      // 1. Status Filter
      if (activeFilter == 'active' && branch.isBranchActive != true) {
        return false;
      }
      if (activeFilter == 'inactive' && branch.isBranchActive != false) {
        return false;
      }

      // 2. Search Query Filter
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final name = (branch.name ?? '').toLowerCase();
        final address = (branch.address ?? '').toLowerCase();
        final phone = (branch.phone ?? '').toLowerCase();
        final email = (branch.email ?? '').toLowerCase();

        final matches = name.contains(query) ||
            address.contains(query) ||
            phone.contains(query) ||
            email.contains(query);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  BranchesState copyWith({
    RequestStatusEnum? status,
    List<BranchModel>? branches,
    String? searchQuery,
    String? activeFilter,
    String? errMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BranchesState(
      status: status ?? this.status,
      branches: branches ?? this.branches,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      errMessage: clearError ? null : (errMessage ?? this.errMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        branches,
        searchQuery,
        activeFilter,
        errMessage,
        successMessage,
      ];
}


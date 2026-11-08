import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../data/models/role_definition_model.dart';
import '../../data/models/staff_user_model.dart';

enum StaffUserStatusFilter { all, active, inactive }

class StaffUsersState extends Equatable {
  final RequestStatusEnum status;
  final RequestStatusEnum actionStatus;
  final List<StaffUserModel> users;
  final List<RoleDefinitionModel> roles;
  final String searchQuery;
  final StaffUserStatusFilter statusFilter;
  final String? branchFilter;
  final String? roleFilter;
  final StaffUserModel? selectedUser;
  final String? errMessage;
  final String? successMessage;

  const StaffUsersState({
    this.status = RequestStatusEnum.initial,
    this.actionStatus = RequestStatusEnum.initial,
    this.users = const [],
    this.roles = const [],
    this.searchQuery = '',
    this.statusFilter = StaffUserStatusFilter.all,
    this.branchFilter,
    this.roleFilter,
    this.selectedUser,
    this.errMessage,
    this.successMessage,
  });

  int get totalCount => users.where((u) => u.isDeleted != true).length;
  int get activeCount =>
      users.where((u) => u.isDeleted != true && u.isActive == true).length;
  int get inactiveCount =>
      users.where((u) => u.isDeleted != true && u.isActive != true).length;

  List<StaffUserModel> get filteredUsers {
    var result = List<StaffUserModel>.from(users);

    // Always exclude soft-deleted
    result = result.where((u) => u.isDeleted != true).toList();

    // Filter by status tab
    if (statusFilter == StaffUserStatusFilter.active) {
      result = result.where((u) => u.isActive == true).toList();
    } else if (statusFilter == StaffUserStatusFilter.inactive) {
      result = result.where((u) => u.isActive != true).toList();
    }

    // Filter by branch
    if (branchFilter != null && branchFilter!.isNotEmpty) {
      result = result.where((u) {
        if (u.isOwner == true) return true; // Owner has universal branch access
        return u.branchAssignments?.any((b) => b.branchId == branchFilter) ??
            false;
      }).toList();
    }

    // Filter by role
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      result = result.where((u) {
        return u.branchAssignments
                ?.any((b) => b.roleIds?.contains(roleFilter) ?? false) ??
            false;
      }).toList();
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((u) {
        final name = (u.fullName ?? '').toLowerCase();
        final email = (u.email ?? '').toLowerCase();
        final phone = (u.phone ?? '').toLowerCase();
        final job = (u.jobTitle ?? '').toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            job.contains(q);
      }).toList();
    }

    return result;
  }

  StaffUsersState copyWith({
    RequestStatusEnum? status,
    RequestStatusEnum? actionStatus,
    List<StaffUserModel>? users,
    List<RoleDefinitionModel>? roles,
    String? searchQuery,
    StaffUserStatusFilter? statusFilter,
    String? branchFilter,
    bool clearBranchFilter = false,
    String? roleFilter,
    bool clearRoleFilter = false,
    StaffUserModel? selectedUser,
    bool clearSelectedUser = false,
    String? errMessage,
    String? successMessage,
  }) {
    return StaffUsersState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      users: users ?? this.users,
      roles: roles ?? this.roles,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      branchFilter:
          clearBranchFilter ? null : (branchFilter ?? this.branchFilter),
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      selectedUser:
          clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      errMessage: errMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        users,
        roles,
        searchQuery,
        statusFilter,
        branchFilter,
        roleFilter,
        selectedUser,
        errMessage,
        successMessage,
      ];
}


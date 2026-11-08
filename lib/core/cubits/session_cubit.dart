import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/staff_permission_enum.dart';
import '../enums/user_role_enum.dart';
import '../services/permission_evaluator.dart';
import '../../features/users_management/data/models/branch_assignment_model.dart';
import '../../features/users_management/data/models/role_definition_model.dart';
import '../../features/users_management/data/models/staff_user_model.dart';

export '../enums/user_role_enum.dart' show CurrentRoleProvider;

class SessionState extends Equatable {
  final UserRoleEnum? currentRole;
  final String? userId;
  final String? userName;
  final StaffUserModel? currentUser;
  final String? activeBranchId;
  final List<String>? availableBranchIds;

  const SessionState({
    this.currentRole,
    this.userId,
    this.userName,
    this.currentUser,
    this.activeBranchId,
    this.availableBranchIds,
  });

  factory SessionState.initial() {
    return const SessionState(
      currentUser: StaffUserModel(
        id: 'USER-OWNER',
        fullName: 'د. طارق المنشاوي (المالك)',
        email: 'owner@eyadty.com',
        phone: '01000000001',
        jobTitle: 'المدير التنفيذي وصاحب المنشأة',
        isOwner: true,
        isActive: true,
        branchAssignments: [
          BranchAssignmentModel(
            branchId: 'branch_1',
            isPrimary: true,
            roleIds: [RoleIds.branchManager],
          ),
          BranchAssignmentModel(
            branchId: 'branch_2',
            isPrimary: false,
            roleIds: [RoleIds.branchManager],
          ),
          BranchAssignmentModel(
            branchId: 'branch_3',
            isPrimary: false,
            roleIds: [RoleIds.branchManager],
          ),
        ],
      ),
      userId: 'USER-OWNER',
      userName: 'د. طارق المنشاوي (المالك)',
      activeBranchId: 'branch_1',
      availableBranchIds: ['branch_1', 'branch_2', 'branch_3'],
    );
  }

  bool get isAuthenticated =>
      currentUser != null && currentUser!.canAuthenticate;

  SessionState copyWith({
    UserRoleEnum? currentRole,
    String? userId,
    String? userName,
    StaffUserModel? currentUser,
    String? activeBranchId,
    List<String>? availableBranchIds,
  }) {
    return SessionState(
      currentRole: currentRole ?? this.currentRole,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      currentUser: currentUser ?? this.currentUser,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      availableBranchIds: availableBranchIds ?? this.availableBranchIds,
    );
  }

  @override
  List<Object?> get props => [
        currentRole,
        userId,
        userName,
        currentUser,
        activeBranchId,
        availableBranchIds,
      ];
}

class SessionCubit extends Cubit<SessionState>
    implements CurrentRoleProvider, CurrentUserProvider, RolesProvider {
  List<RoleDefinitionModel> _cachedRoles;

  SessionCubit(
    super.initialState, {
    List<RoleDefinitionModel>? initialRoles,
  }) : _cachedRoles = initialRoles ?? RoleDefinitionModel.defaultSystemRoles();

  @override
  StaffUserModel? get currentUser => state.currentUser;

  @override
  String? get activeBranchId => state.activeBranchId;

  @override
  List<RoleDefinitionModel> get currentRoles => List.unmodifiable(_cachedRoles);

  void updateCachedRoles(List<RoleDefinitionModel> roles) {
    _cachedRoles = List.from(roles);
    emit(state.copyWith()); // Trigger rebuild for subscribers
  }

  late final PermissionEvaluator permissionEvaluator = PermissionEvaluator(
    userProvider: this,
    rolesProvider: this,
  );

  bool can(
    StaffPermissionEnum permission, {
    String? branchId,
    Set<String>? patientDoctorIds,
  }) {
    return permissionEvaluator.can(
      permission,
      branchId: branchId,
      patientDoctorIds: patientDoctorIds,
    );
  }

  @override
  UserRoleEnum get currentRole {
    final user = state.currentUser;
    if (user != null) {
      if (user.isOwner == true) return UserRoleEnum.admin;
      final branchId = state.activeBranchId;
      final assignment = user.branchAssignments
          ?.where((b) => b.branchId == branchId)
          .firstOrNull ??
          user.branchAssignments?.firstOrNull;
      final roleIds = assignment?.roleIds ?? [];
      if (roleIds.contains(RoleIds.branchManager)) return UserRoleEnum.admin;
      if (roleIds.contains(RoleIds.doctor)) return UserRoleEnum.doctor;
      if (roleIds.contains(RoleIds.reception)) return UserRoleEnum.reception;
    }
    return state.currentRole ?? UserRoleEnum.admin;
  }

  void switchRole(UserRoleEnum role) {
    emit(state.copyWith(currentRole: role));
  }

  void switchBranch(String branchId) {
    emit(state.copyWith(activeBranchId: branchId));
  }

  void switchMockUser(StaffUserModel user) {
    final activeBranch = user.branchAssignments
            ?.where((b) => b.isPrimary == true)
            .firstOrNull
            ?.branchId ??
        user.branchAssignments?.firstOrNull?.branchId ??
        'branch_1';

    final branches = user.isOwner == true
        ? ['branch_1', 'branch_2', 'branch_3']
        : (user.branchAssignments?.map((b) => b.branchId!).toList() ?? [activeBranch]);

    emit(
      state.copyWith(
        currentUser: user,
        userId: user.id,
        userName: user.fullName,
        activeBranchId: activeBranch,
        availableBranchIds: branches,
      ),
    );
  }

  void logout() {
    emit(
      const SessionState(
        currentUser: null,
        userId: null,
        userName: null,
        activeBranchId: null,
        availableBranchIds: null,
      ),
    );
  }
}

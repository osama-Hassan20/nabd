enum UserRoleEnum {
  admin,
  doctor,
  reception;

  /// Whether user has permission to apply manual discount on consultation fee.
  bool get canApplyManualDiscount => this == UserRoleEnum.admin;

  /// Whether user has permission to access sensitive audit logs.
  bool get canViewAuditLogs => this == UserRoleEnum.admin;

  /// Whether user has permission to manage system and facility settings.
  bool get canManageSettings => this == UserRoleEnum.admin;

  /// Whether user has permission to manage the medical services catalog.
  bool get canManageServices => this == UserRoleEnum.admin;
}

/// Lightweight interface decoupling data repositories and services from SessionCubit.
abstract class CurrentRoleProvider {
  UserRoleEnum get currentRole;
}


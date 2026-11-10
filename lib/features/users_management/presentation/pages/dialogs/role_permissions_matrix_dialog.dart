import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';

class RolePermissionsMatrixDialog extends StatefulWidget {
  const RolePermissionsMatrixDialog({super.key});

  @override
  State<RolePermissionsMatrixDialog> createState() =>
      _RolePermissionsMatrixDialogState();
}

class _RolePermissionsMatrixDialogState
    extends State<RolePermissionsMatrixDialog> {
  String _selectedRoleId = RoleIds.branchManager;
  final Map<String, Set<StaffPermissionEnum>> _editedPermissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<StaffUsersCubit>();
    for (final role in cubit.state.roles) {
      if (role.id != null) {
        _editedPermissions[role.id!] =
            Set<StaffPermissionEnum>.from(role.permissions ?? []);
      }
    }
  }

  static const Map<String, List<StaffPermissionEnum>> _categories = {
    'الحجوزات والاستقبال': [
      StaffPermissionEnum.accessLiveQueue,
      StaffPermissionEnum.createBooking,
      StaffPermissionEnum.editBooking,
      StaffPermissionEnum.cancelBooking,
      StaffPermissionEnum.reorderQueue,
    ],
    'المرضى والسجلات الطبية': [
      StaffPermissionEnum.accessPatients,
      StaffPermissionEnum.createPatient,
      StaffPermissionEnum.editPatient,
      StaffPermissionEnum.viewVisitsQueue,
      StaffPermissionEnum.startConsultation,
      StaffPermissionEnum.recordVitals,
      StaffPermissionEnum.viewMedicalRecordDiagnostics,
      StaffPermissionEnum.viewAllDoctorsMedicalRecords,
      StaffPermissionEnum.editMedicalDiagnosis,
      StaffPermissionEnum.issuePrescription,
    ],
    'الأطباء والعيادات': [
      StaffPermissionEnum.accessDoctors,
      StaffPermissionEnum.manageDoctorSchedules,
      StaffPermissionEnum.manageDoctorLeaves,
      StaffPermissionEnum.approveLeavesAndReferrals,
      StaffPermissionEnum.viewClinicalPerformance,
    ],
    'الخزينة والماليات': [
      StaffPermissionEnum.accessCashier,
      StaffPermissionEnum.collectPayment,
      StaffPermissionEnum.refundPayment,
      StaffPermissionEnum.viewCashierShift,
      StaffPermissionEnum.applyManualDiscount,
    ],
    'الموارد البشرية والمستحقات': [
      StaffPermissionEnum.accessHr,
      StaffPermissionEnum.calculateDoctorSettlement,
    ],
    'التقارير والإحصائيات': [
      StaffPermissionEnum.accessAnalytics,
      StaffPermissionEnum.viewFinancialReports,
    ],
    'الإعدادات والحوكمة': [
      StaffPermissionEnum.accessSettings,
      StaffPermissionEnum.manageMedicalServices,
      StaffPermissionEnum.manageRolesAndPermissions,
      StaffPermissionEnum.createStaffUser,
      StaffPermissionEnum.editStaffUser,
      StaffPermissionEnum.deleteStaffUser,
      StaffPermissionEnum.toggleStaffUserStatus,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final sessionCubit = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>()
        : null;
    final currentUserId = sessionCubit?.currentUser?.id ?? 'USER-OWNER';
    final cubit = context.read<StaffUsersCubit>();
    final roles = cubit.state.roles;

    final selectedPerms =
        _editedPermissions[_selectedRoleId] ?? <StaffPermissionEnum>{};

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grayE2E8F0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'role_permissions_matrix'.tr(),
                          style: CustomAppFontStyle.bold18.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        Text(
                          'role_permissions_matrix_desc'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.gray71717A),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // ─── Roles Selector Chips ────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: roles.map((r) {
                    final isSelected = r.id == _selectedRoleId;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(r.nameAr ?? r.id ?? ''),
                        selected: isSelected,
                        selectedColor: const Color(0xFFEEF2FF),
                        labelStyle: CustomAppFontStyle.semiBold13.copyWith(
                          color: isSelected
                              ? const Color(0xFF4338CA)
                              : AppColors.gray71717A,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.lightBackground,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : AppColors.grayE2E8F0,
                        ),
                        onSelected: (selected) {
                          if (selected && r.id != null) {
                            setState(() => _selectedRoleId = r.id!);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Permissions List by Category ────────────────────────
              Expanded(
                child: ListView(
                  children: _categories.entries.map((entry) {
                    final categoryName = entry.key;
                    final perms = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grayE2E8F0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              border: Border(
                                bottom: BorderSide(color: AppColors.grayE2E8F0),
                              ),
                            ),
                            child: Text(
                              categoryName,
                              style: CustomAppFontStyle.semiBold13.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: perms.map((perm) {
                                final isChecked =
                                    selectedPerms.contains(perm);
                                return FilterChip(
                                  label: Text(perm.name),
                                  selected: isChecked,
                                  selectedColor: const Color(0xFFEFF6FF),
                                  checkmarkColor: const Color(0xFF2563EB),
                                  labelStyle:
                                      CustomAppFontStyle.regular12.copyWith(
                                    color: isChecked
                                        ? const Color(0xFF1D4ED8)
                                        : AppColors.darkText,
                                    fontWeight: isChecked
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  backgroundColor: AppColors.white,
                                  side: BorderSide(
                                    color: isChecked
                                        ? const Color(0xFF3B82F6)
                                        : AppColors.grayE2E8F0,
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        selectedPerms.add(perm);
                                      } else {
                                        selectedPerms.remove(perm);
                                      }
                                      _editedPermissions[_selectedRoleId] =
                                          selectedPerms;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // ─── Actions ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: AppColors.white,
                      boxBorder: Border.all(color: AppColors.grayE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isLoading ? null : () => context.pop(),
                      child: Center(
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                      isLoading: _isLoading,
                      onTap: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);

                              final selectedRole = roles.firstWhere(
                                (r) => r.id == _selectedRoleId,
                                orElse: () => RoleDefinitionModel(
                                    id: _selectedRoleId),
                              );

                              final updatedRole = selectedRole.copyWith(
                                permissions: selectedPerms.toList(),
                              );

                              final ok = await cubit.saveRole(
                                role: updatedRole,
                                currentUserId: currentUserId,
                              );

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (ok && context.mounted) {
                                sessionCubit?.updateCachedRoles(cubit.state.roles);
                                Navigator.of(context).pop();
                              }
                            },
                      child: Center(
                        child: Text(
                          'save_changes'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

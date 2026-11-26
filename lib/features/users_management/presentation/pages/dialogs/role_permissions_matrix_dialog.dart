import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/staff_permission_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/users_management/domain/use_cases/params/update_role_discount_policy_params.dart';
import 'package:eyadty/features/users_management/domain/use_cases/update_role_discount_policy_use_case.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
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
  final Map<String, num?> _roleMaxDiscounts = {};
  final Map<String, bool> _roleCanFreeConsultations = {};
  late final TextEditingController _maxDiscountController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _maxDiscountController = TextEditingController();
    final cubit = context.read<StaffUsersCubit>();
    for (final role in cubit.state.roles) {
      if (role.id != null) {
        _editedPermissions[role.id!] =
            Set<StaffPermissionEnum>.from(role.permissions ?? []);
        _roleMaxDiscounts[role.id!] = role.maxDiscountPercent;
        _roleCanFreeConsultations[role.id!] =
            role.canGrantFreeConsultation ?? false;
      }
    }
    _maxDiscountController.text =
        _roleMaxDiscounts[_selectedRoleId]?.toString() ?? '';
  }

  @override
  void dispose() {
    _maxDiscountController.dispose();
    super.dispose();
  }

  static const Map<String, List<StaffPermissionEnum>> _categories = {
    'الحجوزات والاستقبال': [
      StaffPermissionEnum.accessLiveQueue,
      StaffPermissionEnum.createBooking,
      StaffPermissionEnum.editBooking,
      StaffPermissionEnum.cancelBooking,
      StaffPermissionEnum.reorderQueue,
      StaffPermissionEnum.applyBookingDiscount,
    ],
    'المرضى والسجلات الطبية': [
      StaffPermissionEnum.accessPatients,
      StaffPermissionEnum.createPatient,
      StaffPermissionEnum.editPatient,
      StaffPermissionEnum.viewVisitsQueue,
      StaffPermissionEnum.startConsultation,
      StaffPermissionEnum.recordVitals,
      StaffPermissionEnum.viewMedicalRecordDiagnostics,
      StaffPermissionEnum.viewConsultationNotes,
      StaffPermissionEnum.viewAllDoctorsMedicalRecords,
      StaffPermissionEnum.editMedicalDiagnosis,
      StaffPermissionEnum.issuePrescription,
      StaffPermissionEnum.manageDrugCatalog,
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
      StaffPermissionEnum.manageCashierShifts,
      StaffPermissionEnum.manageDrawerMovements,
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
    final colors = context.themeColors;
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
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
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
                      color: colors.isDark
                          ? colors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: colors.primary,
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
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'role_permissions_matrix_desc'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: colors.textSecondary),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
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
                        selectedColor: colors.isDark
                            ? colors.primary.withValues(alpha: 0.2)
                            : const Color(0xFFEEF2FF),
                        labelStyle: CustomAppFontStyle.semiBold13.copyWith(
                          color: isSelected
                              ? colors.primary
                              : colors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: colors.surfaceLevel1,
                        side: BorderSide(
                          color: isSelected
                              ? colors.primary
                              : colors.borderSubtle,
                        ),
                        onSelected: (selected) {
                          if (selected && r.id != null) {
                            setState(() {
                              _selectedRoleId = r.id!;
                              _maxDiscountController.text =
                                  _roleMaxDiscounts[_selectedRoleId]
                                          ?.toString() ??
                                      '';
                            });
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
                  children: [
                    ..._categories.entries.map((entry) {
                      final categoryName = entry.key;
                      final perms = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.surfaceLevel2,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                border: Border(
                                  bottom: BorderSide(color: colors.borderSubtle),
                                ),
                              ),
                              child: Text(
                                categoryName,
                                style: CustomAppFontStyle.semiBold13.copyWith(
                                  color: colors.textPrimary,
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
                                    label: Text(perm.localizedName),
                                    selected: isChecked,
                                    selectedColor: colors.isDark
                                        ? colors.primary.withValues(alpha: 0.2)
                                        : const Color(0xFFEFF6FF),
                                    checkmarkColor: colors.primary,
                                    labelStyle:
                                        CustomAppFontStyle.regular12.copyWith(
                                      color: isChecked
                                          ? colors.primary
                                          : colors.textPrimary,
                                      fontWeight: isChecked
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    backgroundColor: colors.cardBackground,
                                    side: BorderSide(
                                      color: isChecked
                                          ? colors.primary
                                          : colors.borderSubtle,
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
                    }),

                    // ─── Discount Policy Section (Owner only) ─────────────
                    if (sessionCubit?.currentUser?.isOwner == true)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.surfaceLevel2,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                border: Border(
                                  bottom: BorderSide(color: colors.borderSubtle),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'disc_policy_title'.tr(),
                                    style: CustomAppFontStyle.semiBold13.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextFormField(
                                    controller: _maxDiscountController,
                                    headerText: 'disc_policy_max_pct'.tr(),
                                    hintText: '100',
                                    textInputType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (val) {
                                      final trimmed = val?.trim() ?? '';
                                      _roleMaxDiscounts[_selectedRoleId] =
                                          num.tryParse(trimmed);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Material(
                                    color: Colors.transparent,
                                    child: SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'disc_policy_can_free'.tr(),
                                        style: CustomAppFontStyle.medium13.copyWith(
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      value: _roleCanFreeConsultations[_selectedRoleId] ?? false,
                                      activeThumbColor: colors.primary,
                                      onChanged: (val) {
                                        setState(() {
                                          _roleCanFreeConsultations[_selectedRoleId] = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 16),

              // ─── Actions ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: colors.surfaceLevel1,
                      boxBorder: Border.all(color: colors.borderSubtle),
                      borderRadius: BorderRadius.circular(10),
                      onTap: _isLoading ? null : () => context.pop(),
                      child: Center(
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.semiBold14.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPushButton(
                      height: 44,
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                      isLoading: _isLoading,
                      onTap: (_isLoading || sessionCubit?.currentUser?.isOwner != true)
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

                              if (sessionCubit?.currentUser?.isOwner == true &&
                                  ok &&
                                  getIt.isRegistered<
                                      UpdateRoleDiscountPolicyUseCase>()) {
                                final updatePolicyUseCase =
                                    getIt<UpdateRoleDiscountPolicyUseCase>();
                                await updatePolicyUseCase(
                                  UpdateRoleDiscountPolicyParams(
                                    roleId: _selectedRoleId,
                                    maxDiscountPercent:
                                        _roleMaxDiscounts[_selectedRoleId],
                                    canGrantFreeConsultation:
                                        _roleCanFreeConsultations[
                                            _selectedRoleId],
                                    currentUserId: currentUserId,
                                  ),
                                );
                                await cubit.loadData(showLoading: false);
                              }

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

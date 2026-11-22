import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/features/users_management/data/models/branch_assignment_model.dart';
import 'package:eyadty/features/users_management/data/models/role_definition_model.dart';
import 'package:eyadty/features/users_management/data/models/staff_user_model.dart';
import 'package:eyadty/features/users_management/presentation/cubit/staff_users_cubit.dart';

class AddEditStaffUserDialog extends StatefulWidget {
  final StaffUserModel? user;

  const AddEditStaffUserDialog({
    super.key,
    this.user,
  });

  @override
  State<AddEditStaffUserDialog> createState() => _AddEditStaffUserDialogState();
}

class _AddEditStaffUserDialogState extends State<AddEditStaffUserDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _tempPasswordController;
  late final TextEditingController _primaryBranchController;
  late final TextEditingController _linkedDoctorController;

  String _primaryBranchId = 'branch_1';
  String _selectedRoleId = RoleIds.reception;
  String? _linkedDoctorId;
  bool _isLoading = false;

  bool get isEdit => widget.user != null;

  static const List<(String, String)> _availableDoctors = [
    ('DOC-01', 'د. أحمد عبد العزيز (استشاري أمراض القلب)'),
    ('DOC-02', 'د. سارة العوضي (استشارية طب وجراحة العيون)'),
    ('DOC-03', 'د. مصطفى الشناوي (أخصائي طب وجراحة الأسنان)'),
    ('DOC-04', 'د. هبة حبيب (استشارية طب الأطفال وحديثي الولادة)'),
    ('DOC-05', 'د. ريم عبد السلام (أخصائية جلدية وتجميل وليزر)'),
    ('DOC-06', 'د. طارق العوضي (استشاري جراحة الأنف والأذن والحنجرة)'),
  ];

  static const List<(String, String)> _availableBranches = [
    ('branch_1', 'branch_main'),
    ('branch_2', 'branch_second'),
    ('branch_3', 'branch_third'),
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?.fullName ?? '');
    _emailController = TextEditingController(text: u?.email ?? '');
    _phoneController = TextEditingController(text: u?.phone ?? '');
    _jobTitleController = TextEditingController(text: u?.jobTitle ?? '');
    _tempPasswordController = TextEditingController(text: 'Eyadty2026!');

    if (u != null) {
      _linkedDoctorId = u.linkedDoctorId;
      final primary = u.branchAssignments?.firstWhere(
        (b) => b.isPrimary == true,
        orElse: () => u.branchAssignments?.isNotEmpty == true
            ? u.branchAssignments!.first
            : const BranchAssignmentModel(branchId: 'branch_1'),
      );
      _primaryBranchId = primary?.branchId ?? 'branch_1';
      if (primary?.roleIds != null && primary!.roleIds!.isNotEmpty) {
        _selectedRoleId = primary.roleIds!.first;
      } else {
        _selectedRoleId = RoleIds.reception;
      }
    } else {
      _selectedRoleId = RoleIds.reception;
    }

    final branchMatch = _availableBranches.where((b) => b.$1 == _primaryBranchId);
    _primaryBranchController = TextEditingController(
      text: branchMatch.isNotEmpty ? branchMatch.first.$2.tr() : _primaryBranchId,
    );
    final docMatch = _availableDoctors.where((d) => d.$1 == _linkedDoctorId);
    _linkedDoctorController = TextEditingController(
      text: docMatch.isNotEmpty ? docMatch.first.$2 : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _tempPasswordController.dispose();
    _primaryBranchController.dispose();
    _linkedDoctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final cubit = context.read<StaffUsersCubit>();
    final state = cubit.state;

    final colors = context.themeColors;
    final isDoctorRoleSelected = _selectedRoleId == RoleIds.doctor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
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
                              isEdit
                                  ? 'edit_user'.tr()
                                  : 'add_new_user'.tr(),
                              style: CustomAppFontStyle.bold18.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'staff_user_details_prompt'.tr(),
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
                  const SizedBox(height: 20),
                  Divider(height: 1, color: colors.borderSubtle),
                  const SizedBox(height: 20),

                  // ─── Basic Info ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: _nameController,
                          headerText: 'full_name'.tr(),
                          hintText: 'name_hint'.tr(),
                          prefixWidget: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: AppColors.gray71717A,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'please_enter_name'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextFormField(
                          controller: _jobTitleController,
                          headerText: 'job_title'.tr(),
                          hintText: 'job_title_hint'.tr(),
                          prefixWidget: const Icon(
                            Icons.work_outline_rounded,
                            size: 18,
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: _emailController,
                          headerText: 'email'.tr(),
                          hintText: 'email_hint'.tr(),
                          prefixWidget: const Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.gray71717A,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'please_enter_email'.tr();
                            }
                            if (!val.contains('@')) {
                              return 'invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextFormField(
                          controller: _phoneController,
                          headerText: 'phone'.tr(),
                          hintText: '01xxxxxxxxx',
                          prefixWidget: const Icon(
                            Icons.phone_rounded,
                            size: 18,
                            color: AppColors.gray71717A,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'please_enter_phone'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!isEdit) ...[
                    CustomTextFormField(
                      controller: _tempPasswordController,
                      headerText: 'temporary_password'.tr(),
                      hintText: 'password_hint'.tr(),
                      prefixWidget: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.gray71717A,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'please_enter_password'.tr();
                        }
                        if (val.length < 8) {
                          return 'password_must_be_8_chars'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Primary Branch ──────────────────────────────────────
                  CustomStackSelector<(String, String)>(
                    controller: _primaryBranchController,
                    header: 'primary_branch'.tr(),
                    list: _availableBranches,
                    itemAsString: (b) => b.$2.tr(),
                    changeValue: (b) {
                      setState(() {
                        _primaryBranchId = b.$1;
                        _primaryBranchController.text = b.$2.tr();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Assign Role (Single Primary Role) ──────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الدور الوظيفي والصلاحية',
                        style: CustomAppFontStyle.semiBold13.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.roles.map((r) {
                          final isSelected = _selectedRoleId == r.id;
                          return ChoiceChip(
                            label: Text(r.nameAr ?? r.id ?? ''),
                            selected: isSelected,
                            selectedColor: colors.primary,
                            showCheckmark: isSelected,
                            checkmarkColor: Colors.white,
                            labelStyle: CustomAppFontStyle.semiBold12.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                            backgroundColor: colors.surfaceLevel1,
                            side: BorderSide(
                              color: isSelected
                                  ? colors.primary
                                  : colors.borderSubtle,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRoleId = r.id!;
                                  if (_selectedRoleId != RoleIds.doctor) {
                                    _linkedDoctorId = null;
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Linked Doctor (Required if Doctor role selected) ─────
                  if (isDoctorRoleSelected) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? Colors.blue.shade900.withValues(alpha: 0.25)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.isDark
                              ? Colors.blue.shade700.withValues(alpha: 0.4)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_rounded,
                                size: 16,
                                color: colors.isDark ? Colors.blue.shade300 : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'link_doctor_profile_required'.tr(),
                                style: CustomAppFontStyle.semiBold13.copyWith(
                                  color: colors.isDark ? Colors.blue.shade200 : const Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomStackSelector<(String, String)?>(
                            controller: _linkedDoctorController,
                            hintText: 'select_doctor_profile'.tr(),
                            list: const [null, ..._availableDoctors],
                            itemAsString: (doc) =>
                                doc != null ? doc.$2 : 'select_doctor_profile'.tr(),
                            changeValue: (doc) {
                              setState(() {
                                _linkedDoctorId = doc?.$1;
                                _linkedDoctorController.text = doc != null
                                    ? doc.$2
                                    : 'select_doctor_profile'.tr();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 10),

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
                          onTap: _isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  if (isDoctorRoleSelected &&
                                      (_linkedDoctorId == null ||
                                          _linkedDoctorId!.isEmpty)) {
                                    CustomToast(
                                      context: context,
                                      header:
                                          'please_select_doctor_profile'.tr(),
                                    ).showErrorToast();
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  final updatedAssignments = [
                                    BranchAssignmentModel(
                                      branchId: _primaryBranchId,
                                      isPrimary: true,
                                      roleIds: [_selectedRoleId],
                                    ),
                                  ];

                                  final staffUser = (widget.user ??
                                          const StaffUserModel())
                                      .copyWith(
                                    fullName: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    jobTitle: _jobTitleController.text.trim(),
                                    linkedDoctorId: isDoctorRoleSelected
                                        ? _linkedDoctorId
                                        : null,
                                    branchAssignments: updatedAssignments,
                                    isActive: widget.user?.isActive ?? true,
                                    isOwner: widget.user?.isOwner ?? false,
                                  );

                                  final ok = await cubit.saveUser(
                                    user: staffUser,
                                    temporaryPassword:
                                        _tempPasswordController.text.trim(),
                                    currentUserId: currentUserId,
                                  );

                                  if (!mounted) return;
                                  setState(() => _isLoading = false);
                                  if (ok && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: Center(
                            child: Text(
                              isEdit ? 'save_changes'.tr() : 'add_user'.tr(),
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
        ),
      ),
    );
  }
}

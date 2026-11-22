import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/cubits/session_cubit.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/branches/data/models/branch_model.dart';
import 'package:eyadty/features/branches/presentation/cubit/branches_cubit.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class AddEditBranchDialog extends StatefulWidget {
  final BranchModel? branch;

  const AddEditBranchDialog({
    super.key,
    this.branch,
  });

  @override
  State<AddEditBranchDialog> createState() => _AddEditBranchDialogState();
}

class _AddEditBranchDialogState extends State<AddEditBranchDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _openingTimeController;
  late final TextEditingController _closingTimeController;

  bool _isMain = false;
  bool _isLoading = false;
  final Set<String> _selectedDays = {
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
  };

  static const List<String> _allDays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameController = TextEditingController(text: b?.name ?? '');
    _addressController = TextEditingController(text: b?.address ?? '');
    _phoneController = TextEditingController(text: b?.phone ?? '');
    _emailController = TextEditingController(text: b?.email ?? '');
    _openingTimeController = TextEditingController(text: b?.openingTime ?? '09:00');
    _closingTimeController = TextEditingController(text: b?.closingTime ?? '22:00');
    _isMain = b?.isMain == true;

    if (b?.workingDays != null && b!.workingDays!.isNotEmpty) {
      _selectedDays.clear();
      _selectedDays.addAll(b.workingDays!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final initial = isOpening ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 22, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minStr';
      setState(() {
        if (isOpening) {
          _openingTimeController.text = timeStr;
        } else {
          _closingTimeController.text = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;
    final cubit = context.read<BranchesCubit>();
    final currentUserId = getIt.isRegistered<SessionCubit>()
        ? getIt<SessionCubit>().currentUser?.id ?? 'USER-OWNER'
        : 'USER-OWNER';
    final colors = context.themeColors;

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
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.business_rounded,
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
                            isEdit ? 'edit_branch'.tr() : 'add_branch'.tr(),
                            style: CustomAppFontStyle.bold16.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'branch_details_prompt'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderSubtle),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        CustomTextFormField(
                          controller: _nameController,
                          headerText: 'branch_name'.tr(),
                          hintText: 'branch_name_hint'.tr(),
                          prefixWidget: Icon(
                            Icons.store_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'please_enter_branch_name'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Address
                        CustomTextFormField(
                          controller: _addressController,
                          headerText: 'address'.tr(),
                          hintText: 'address_hint'.tr(),
                          prefixWidget: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'please_enter_address'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone & Email Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextFormField(
                                controller: _phoneController,
                                headerText: 'phone'.tr(),
                                hintText: '01xxxxxxxxx',
                                prefixWidget: Icon(
                                  Icons.phone_rounded,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'please_enter_phone'.tr();
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextFormField(
                                controller: _emailController,
                                headerText: 'email'.tr(),
                                hintText: 'email_hint'.tr(),
                                prefixWidget: Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Opening & Closing Time Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isOpening: true),
                                child: CustomTextFormField(
                                  controller: _openingTimeController,
                                  headerText: 'opening_time'.tr(),
                                  isReadOnly: true,
                                  prefixWidget: Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isOpening: false),
                                child: CustomTextFormField(
                                  controller: _closingTimeController,
                                  headerText: 'closing_time'.tr(),
                                  isReadOnly: true,
                                  prefixWidget: Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 18,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Working Days
                        Text(
                          'working_days'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allDays.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    if (_selectedDays.length > 1) {
                                      _selectedDays.remove(day);
                                    }
                                  } else {
                                    _selectedDays.add(day);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.surfaceLevel1,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? colors.primary : colors.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  day.tr(),
                                  style: CustomAppFontStyle.medium12.copyWith(
                                    color: isSelected ? Colors.white : colors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Set as Main Branch Switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'is_main_branch'.tr(),
                                      style: CustomAppFontStyle.semiBold13.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'main_branch_desc'.tr(),
                                      style: CustomAppFontStyle.regular11.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isMain,
                                activeThumbColor: colors.primary,
                                onChanged: (val) {
                                  setState(() => _isMain = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(height: 1, color: colors.borderSubtle),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPushButton(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: colors.surfaceLevel1,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'cancel'.tr(),
                          style: CustomAppFontStyle.medium13.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomPushButton(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      backgroundColor: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      isLoading: _isLoading,
                      onTap: () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isLoading = true);

                        final branchToSave = (widget.branch ?? const BranchModel()).copyWith(
                          name: _nameController.text.trim(),
                          address: _addressController.text.trim(),
                          phone: _phoneController.text.trim(),
                          email: _emailController.text.trim(),
                          openingTime: _openingTimeController.text.trim(),
                          closingTime: _closingTimeController.text.trim(),
                          workingDays: _selectedDays.toList(),
                          isMain: _isMain,
                        );

                        final ok = isEdit
                            ? await cubit.updateBranch(branchToSave, currentUserId: currentUserId)
                            : await cubit.createBranch(branchToSave, currentUserId: currentUserId);

                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Center(
                        child: Text(
                          isEdit ? 'save_changes'.tr() : 'add_branch'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/enums/medical_specialty_enum.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/features/settings/domain/use_cases/get_company_settings_use_case.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/enums/doctor_gender_enum.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddEditDoctorDialog extends StatefulWidget {
  final DoctorModel? doctor;
  final bool isFullScreen;
  final DoctorsCubit doctorsCubit;

  const AddEditDoctorDialog({
    super.key,
    this.doctor,
    this.isFullScreen = false,
    required this.doctorsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    DoctorModel? doctor,
    DoctorsCubit? doctorsCubit,
  }) {
    DoctorsCubit? cubit = doctorsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<DoctorsCubit>();
      } catch (_) {
        cubit = getIt<DoctorsCubit>();
      }
    }
    cubit.initDoctorForm(doctor);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddEditDoctorDialog(
            doctor: doctor,
            isFullScreen: isMobile,
            doctorsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AddEditDoctorDialog> createState() => _AddEditDoctorDialogState();
}

class _AddEditDoctorDialogState extends State<AddEditDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _genderController;
  late DoctorGenderEnum _selectedGender;
  late Set<MedicalSpecialty> _selectedSpecialties;
  List<MedicalSpecialty> _availableSpecialties = MedicalSpecialty.values;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.doctor?.name ?? '');

    var initialPhone = widget.doctor?.phone ?? '';
    if (initialPhone.startsWith('+20')) {
      initialPhone = initialPhone.replaceFirst('+20', '').trim();
    } else if (initialPhone.startsWith('+974')) {
      initialPhone = initialPhone.replaceFirst('+974', '').trim();
    }
    _phoneController = TextEditingController(text: initialPhone);
    _selectedSpecialties =
        Set<MedicalSpecialty>.from(widget.doctor?.effectiveSpecialties ?? []);
    if (widget.doctor == null) {
      _selectedSpecialties = {MedicalSpecialty.generalPractice};
    }
    _specialtyController = TextEditingController(
      text: widget.doctor?.specialty ??
          _selectedSpecialties.map((s) => s.labelKey.tr()).join('، '),
    );
    _selectedGender = widget.doctor?.gender ?? DoctorGenderEnum.male;
    _genderController = TextEditingController(text: _selectedGender.label);
    _loadEnabledSpecialties();
  }

  Future<void> _loadEnabledSpecialties() async {
    if (!getIt.isRegistered<GetCompanySettingsUseCase>()) return;
    final res = await getIt<GetCompanySettingsUseCase>()(NoParams());
    res.fold((_) {}, (settings) {
      if (mounted && settings.enabledSpecialties.isNotEmpty) {
        setState(() {
          _availableSpecialties = settings.enabledSpecialties;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final formattedPhone = CustomPhoneField.formatWithCountryCode(
      _phoneController.text,
      countryCode: '+20',
    );

    if (_selectedSpecialties.isEmpty) {
      CustomToast(
        context: context,
        header: 'field_required'.tr(),
      ).showErrorToast();
      return;
    }

    final success = await widget.doctorsCubit.saveDoctor(
      name: _nameController.text.trim(),
      phone: formattedPhone,
      specialty: _selectedSpecialties.map((s) => s.labelKey.tr()).join('، '),
      specialties: _selectedSpecialties.toList(),
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      final msg = widget.doctorsCubit.state.successMessage ??
          (widget.doctor == null
              ? 'doctor_added_successfully'
              : 'doctor_updated_successfully');
      CustomToast(context: context, header: msg.tr()).showTopToast();
      Navigator.of(context).pop(true);
    } else {
      final err = widget.doctorsCubit.state.errMessage;
      CustomToast(
        context: context,
        header: err != null ? err.tr() : 'failed_to_load'.tr(),
      ).showErrorToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doctor != null;
    final titleText =
        isEditing ? 'edit_doctor'.tr() : 'add_doctor'.tr();

    return BlocBuilder<DoctorsCubit, DoctorsState>(
      bloc: widget.doctorsCubit,
      builder: (context, state) {
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(widget.isFullScreen ? 0 : 16),
            border: widget.isFullScreen
                ? null
                : Border.all(color: AppColors.grayE2E8F0),
          ),
          child: Column(
            mainAxisSize:
                widget.isFullScreen ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, titleText),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Field
                        CustomTextFormField(
                          controller: _nameController,
                          headerText: 'doctor_name'.tr(),
                          hintText: 'doctor_name_hint'.tr(),
                          isRequired: true,
                          prefixWidget: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: CustomAssetImage(
                              path: AppIcons.user,
                              width: 18,
                              height: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'field_required'.tr();
                            }
                            if (value.trim().length < 2) {
                              return 'name_too_short'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Specialties Multi-Select
                        Text(
                          'specialty'.tr(),
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSpecialties.map((spec) {
                            final isSelected = _selectedSpecialties.contains(spec);
                            return FilterChip(
                              avatar: Icon(
                                spec.icon,
                                size: 16,
                                color: isSelected ? AppColors.primary : AppColors.gray,
                              ),
                              label: Text(spec.labelKey.tr()),
                              selected: isSelected,
                              selectedColor: AppColors.primaryLight,
                              checkmarkColor: AppColors.primary,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSpecialties.add(spec);
                                  } else if (_selectedSpecialties.length > 1) {
                                    _selectedSpecialties.remove(spec);
                                  }
                                  _specialtyController.text = _selectedSpecialties
                                      .map((s) => s.labelKey.tr())
                                      .join('، ');
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Phone Field
                        CustomPhoneField(
                          phoneController: _phoneController,
                          header: 'doctor_phone'.tr(),
                          phoneCode: '+20',
                          hintText: '010 1234 5678',
                        ),
                        const SizedBox(height: 20),

                        // Gender Field
                        CustomStackSelector<DoctorGenderEnum>(
                          header: 'gender'.tr(),
                          controller: _genderController,
                          list: DoctorGenderEnum.values,
                          itemAsString: (g) => g.label,
                          hintText: 'select_gender'.tr(),
                          changeValue: (g) {
                            _selectedGender = g;
                            _genderController.text = g.label;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              _buildFooter(context, isLoading),
            ],
          ),
        );

        if (widget.isFullScreen) {
          return Scaffold(backgroundColor: AppColors.white, body: content);
        }

        return content;
      },
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.employees,
              width: 20,
              height: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: CustomAppFontStyle.semiBold18.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ),
          const CloseButton(),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.grayf2,
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Text(
                  'cancel'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.grayMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CustomPushButton(
              height: 44,
              backgroundColor: AppColors.primary,
              isLoading: isLoading,
              borderRadius: BorderRadius.circular(8),
              onTap: isLoading ? null : _handleSubmit,
              child: Center(
                child: Text(
                  'save'.tr(),
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/technicians/data/models/enums/technician_gender_enum.dart';
import 'package:eyadty/features/technicians/data/models/technician_model.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:eyadty/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class AddEditTechnicianDialog extends StatefulWidget {
  final TechnicianModel? technician;
  final bool isFullScreen;
  final TechniciansCubit techniciansCubit;

  const AddEditTechnicianDialog({
    super.key,
    this.technician,
    this.isFullScreen = false,
    required this.techniciansCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    TechnicianModel? technician,
    TechniciansCubit? techniciansCubit,
  }) {
    TechniciansCubit? cubit = techniciansCubit;
    if (cubit == null) {
      try {
        cubit = context.read<TechniciansCubit>();
      } catch (_) {
        cubit = getIt<TechniciansCubit>();
      }
    }
    cubit.initTechnicianForm(technician);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddEditTechnicianDialog(
            technician: technician,
            isFullScreen: isMobile,
            techniciansCubit: cubit,
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
  State<AddEditTechnicianDialog> createState() =>
      _AddEditTechnicianDialogState();
}

class _AddEditTechnicianDialogState extends State<AddEditTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _genderController;
  late TechnicianGenderEnum _selectedGender;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.technician?.name ?? '');

    var initialPhone = widget.technician?.phone ?? '';
    if (initialPhone.startsWith('+974')) {
      initialPhone = initialPhone.replaceFirst('+974', '').trim();
    }
    _phoneController = TextEditingController(text: initialPhone);
    _selectedGender = widget.technician?.gender ?? TechnicianGenderEnum.male;
    _genderController = TextEditingController(text: _selectedGender.label);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final formattedPhone = CustomPhoneField.formatWithCountryCode(
      _phoneController.text,
      countryCode: '+974',
    );

    final success = await widget.techniciansCubit.saveTechnician(
      name: _nameController.text.trim(),
      phone: formattedPhone,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      final msg = widget.techniciansCubit.state.successMessage ??
          (widget.technician == null
              ? 'technician_added_successfully'
              : 'technician_updated_successfully');
      CustomToast(context: context, header: msg.tr()).showTopToast();
      Navigator.of(context).pop(true);
    } else {
      final err = widget.techniciansCubit.state.errMessage;
      CustomToast(
        context: context,
        header: err != null ? err.tr() : 'failed_to_load'.tr(),
      ).showErrorToast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.technician != null;
    final titleText =
        isEditing ? 'edit_technician'.tr() : 'add_technician'.tr();

    return BlocBuilder<TechniciansCubit, TechniciansState>(
      bloc: widget.techniciansCubit,
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
                          headerText: 'technician_name'.tr(),
                          hintText: 'technician_name_hint'.tr(),
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

                        // Phone Field
                        CustomPhoneField(
                          phoneController: _phoneController,
                          header: 'technician_phone'.tr(),
                          phoneCode: '+974',
                          hintText: '55XX XXXX',
                        ),
                        const SizedBox(height: 20),

                        // Gender Field
                        CustomStackSelector<TechnicianGenderEnum>(
                          header: 'gender'.tr(),
                          controller: _genderController,
                          list: TechnicianGenderEnum.values,
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

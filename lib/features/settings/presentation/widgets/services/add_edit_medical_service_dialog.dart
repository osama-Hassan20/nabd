import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/uses_cases/params.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_switcher.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/domain/repo/doctors_repo.dart';
import 'package:eyadty/features/settings/data/models/medical_service_model.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_cubit.dart';
import 'package:eyadty/features/settings/presentation/cubit/medical_services_state.dart';

class AddEditMedicalServiceDialog extends StatefulWidget {
  final MedicalServicesCubit cubit;
  final List<DoctorModel> availableDoctors;

  const AddEditMedicalServiceDialog({
    super.key,
    required this.cubit,
    required this.availableDoctors,
  });

  static Future<void> show(
    BuildContext context, {
    MedicalServiceModel? service,
    required MedicalServicesCubit cubit,
  }) async {
    cubit.initForm(service);

    List<DoctorModel> doctors = [];
    try {
      final doctorsResult = await getIt<DoctorsRepo>().getDoctors(
        params: const PaginationParams(page: 1, limit: 100),
      );
      doctors = doctorsResult.fold((_) => [], (resp) => resp.doctors);
    } catch (_) {}

    if (!context.mounted) return;

    final isMobile = AdaptiveLayout.isMobile(context);
    final dialogContent = AddEditMedicalServiceDialog(
      cubit: cubit,
      availableDoctors: doctors,
    );

    return showDialog(
      context: context,
      useSafeArea: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        if (isMobile) {
          final colors = dialogContext.themeColors;
          return Dialog.fullscreen(
            child: Scaffold(
              backgroundColor: colors.scaffoldBackground,
              body: SafeArea(child: dialogContent),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: dialogContent,
          ),
        );
      },
    );
  }

  @override
  State<AddEditMedicalServiceDialog> createState() =>
      _AddEditMedicalServiceDialogState();
}

class _AddEditMedicalServiceDialogState
    extends State<AddEditMedicalServiceDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _feeController;
  late final TextEditingController _durationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _doctorSelectorController;

  @override
  void initState() {
    super.initState();
    final form =
        widget.cubit.state.formState ?? const MedicalServiceFormState();
    _nameController = TextEditingController(text: form.name);
    _feeController = TextEditingController(
      text: form.fee > 0 ? form.fee.toString() : '',
    );
    _durationController = TextEditingController(
      text: form.durationMinutes > 0 ? form.durationMinutes.toString() : '30',
    );
    _descriptionController = TextEditingController(text: form.description);
    _doctorSelectorController = TextEditingController(
      text: (form.assignedDoctorName != null &&
              form.assignedDoctorName!.isNotEmpty)
          ? form.assignedDoctorName!
          : 'all_doctors_general'.tr(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _doctorSelectorController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fee = num.tryParse(_feeController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;

    widget.cubit.saveForm(
      name: _nameController.text.trim(),
      fee: fee,
      durationMinutes: duration,
      description: _descriptionController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocConsumer<MedicalServicesCubit, MedicalServicesState>(
        listenWhen: (prev, curr) => prev.actionStatus != curr.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == RequestStatusEnum.success) {
            CustomToast(
              context: context,
              header: 'saved_successfully'.tr(),
            ).showTopToast();
            context.pop();
          } else if (state.actionStatus == RequestStatusEnum.failure) {
            CustomToast(
              context: context,
              header: state.errMessage ?? 'failed_to_save'.tr(),
            ).showErrorToast();
          }
        },
        builder: (context, state) {
          final form = state.formState ?? const MedicalServiceFormState();
          final isEdit = form.isEdit;
          final isLoading = state.actionStatus == RequestStatusEnum.loading;

          // Build doctor list including "General / All Doctors"
          final generalDoctorOption = DoctorModel(
            id: '',
            name: 'all_doctors_general'.tr(),
          );
          final doctorOptions = [generalDoctorOption, ...widget.availableDoctors];

          return Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: CustomAssetImage(
                                  path: AppIcons.service,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isEdit
                                      ? 'edit_medical_service'.tr()
                                      : 'add_medical_service'.tr(),
                                  style: CustomAppFontStyle.semiBold18.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Body Fields ────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Service Name
                          CustomTextFormField(
                            controller: _nameController,
                            isRequired: true,
                            headerText: 'service_name_label'.tr(),
                            hintText: 'service_name_hint'.tr(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'required_field'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Fee & Duration (2-columns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextFormField(
                                  controller: _feeController,
                                  isRequired: true,
                                  headerText: 'service_fee_label'.tr(),
                                  hintText: 'service_fee_hint'.tr(),
                                  textInputType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'required_field'.tr();
                                    }
                                    final numVal = num.tryParse(val.trim());
                                    if (numVal == null || numVal < 0) {
                                      return 'invalid_amount'.tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextFormField(
                                  controller: _durationController,
                                  isRequired: true,
                                  headerText: 'service_duration_label'.tr(),
                                  hintText: 'service_duration_hint'.tr(),
                                  textInputType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'required_field'.tr();
                                    }
                                    final d = int.tryParse(val.trim());
                                    if (d == null || d < 5 || d > 240) {
                                      return '5-240';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Doctor Assignment Dropdown
                          CustomStackSelector<DoctorModel>(
                            controller: _doctorSelectorController,
                            header: 'assigned_doctor_label'.tr(),
                            hintText: 'all_doctors_general'.tr(),
                            list: doctorOptions,
                            itemAsString: (doc) => doc.name ?? '',
                            changeValue: (selectedDoc) {
                              if (selectedDoc.id == null ||
                                  selectedDoc.id!.isEmpty) {
                                widget.cubit.updateFormDoctor();
                                _doctorSelectorController.text =
                                    'all_doctors_general'.tr();
                              } else {
                                widget.cubit.updateFormDoctor(
                                  doctorId: selectedDoc.id,
                                  doctorName: selectedDoc.name,
                                );
                                _doctorSelectorController.text =
                                    selectedDoc.name ?? '';
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          CustomTextFormField(
                            controller: _descriptionController,
                            headerText: 'service_description_label'.tr(),
                            hintText: 'service_description_hint'.tr(),
                            maxLine: 3,
                            minLine: 2,
                          ),
                          const SizedBox(height: 20),

                          // Active Switcher Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceLevel1,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'service_status_active'.tr(),
                                      style: CustomAppFontStyle.semiBold14
                                          .copyWith(
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      form.isActive
                                          ? 'service_status_active'.tr()
                                          : 'service_status_inactive'.tr(),
                                      style: CustomAppFontStyle.regular12
                                          .copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                CustomSwitcher(
                                  isActive: form.isActive,
                                  onChanged: (val) {
                                    widget.cubit.updateFormIsActive(val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Footer Actions ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomPushButton(
                          height: 42,
                          width: 100,
                          backgroundColor: colors.surfaceLevel1,
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.pop(),
                          child: Center(
                            child: Text(
                              'cancel'.tr(),
                              style: CustomAppFontStyle.medium14.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomPushButton(
                          height: 42,
                          width: 130,
                          backgroundColor: colors.primary,
                          borderRadius: BorderRadius.circular(8),
                          onTap: isLoading ? () {} : _handleSubmit,
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    'save'.tr(),
                                    style:
                                        CustomAppFontStyle.medium14.copyWith(
                                      color: AppColors.white,
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
          );
        },
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/egyptian_governorates.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/medical_catalog_type_enum.dart';
import 'package:eyadty/features/patients/data/models/kinship_relations.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_stack_selector.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'dialogs/duplicate_phone_warning_dialog.dart';
import 'form_components/blood_group_selector.dart';
import 'form_components/kinship_chips_selector.dart';
import 'form_components/searchable_catalog_multi_selector.dart';

class AddEditPatientDialog extends StatefulWidget {
  final PatientModel? patient;
  final bool isFullScreen;
  final PatientsCubit patientsCubit;

  const AddEditPatientDialog({
    super.key,
    this.patient,
    this.isFullScreen = false,
    required this.patientsCubit,
  });

  static Future<bool?> show({
    required BuildContext context,
    PatientModel? patient,
    PatientsCubit? patientsCubit,
  }) {
    PatientsCubit? cubit = patientsCubit;
    if (cubit == null) {
      try {
        cubit = context.read<PatientsCubit>();
      } catch (_) {
        cubit = getIt<PatientsCubit>();
      }
    }
    cubit.initPatientForm(patient);

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: cubit!,
          child: AddEditPatientDialog(
            patient: patient,
            isFullScreen: isMobile,
            patientsCubit: cubit,
          ),
        );

        if (isMobile) {
          return Dialog.fullscreen(child: child);
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.sizeOf(dialogCtx).height * 0.9,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AddEditPatientDialog> createState() => _AddEditPatientDialogState();
}

class _AddEditPatientDialogState extends State<AddEditPatientDialog> {
  late final TextEditingController _governorateController;

  PatientsCubit get patientsCubit => widget.patientsCubit;
  PatientModel? get patient => widget.patient;
  bool get isFullScreen => widget.isFullScreen;

  @override
  void initState() {
    super.initState();
    final form = widget.patientsCubit.state.formState;
    final govKey = form?.governorate;
    _governorateController = TextEditingController(
      text: (govKey != null && govKey.isNotEmpty) ? govKey.tr() : '',
    );
  }

  @override
  void dispose() {
    _governorateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(
    BuildContext context,
    DateTime? current,
  ) async {
    final now = CairoTimeHelper.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      patientsCubit.updateFormDateOfBirth(picked);
    }
  }

  Future<void> _selectLmpDate(
    BuildContext context,
    DateTime? current,
    DateTime? dob,
  ) async {
    final now = CairoTimeHelper.now();
    final firstAllowed = dob ?? DateTime(now.year - 60);
    final initial = current ?? now;
    final safeInitial = initial.isAfter(now)
        ? now
        : (initial.isBefore(firstAllowed) ? firstAllowed : initial);

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstAllowed,
      lastDate: now,
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      patientsCubit.updateFormLastMenstrualPeriodDate(picked);
    }
  }

  void _submit(BuildContext context, PatientFormState form) {
    patientsCubit.savePatient();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = patient != null;
    final titleText =
        isEditing ? 'edit_patient_title'.tr() : 'add_patient_title'.tr();
    final isMobile = AdaptiveLayout.isMobile(context);

    return BlocConsumer<PatientsCubit, PatientsState>(
      bloc: patientsCubit,
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, state) {
        final form = state.formState;
        if (form != null) {
          final govKey = form.governorate;
          final govText =
              (govKey != null && govKey.isNotEmpty) ? govKey.tr() : '';
          if (_governorateController.text != govText) {
            _governorateController.text = govText;
          }
        }
        if (state.actionStatus == RequestStatusEnum.success) {
          CustomToast(
            context: context,
            header: 'patient_saved_successfully'.tr(),
          ).showTopToast();
          Navigator.of(context).pop(true);
        } else if (state.hasPendingDuplicatePhoneWarning) {
          DuplicatePhoneWarningDialog.show(
            context: context,
            matchingPatients: state.duplicatePhonePatients,
            onContinueWithSharedPhone: () {
              patientsCubit.confirmSaveWithDuplicatePhone();
            },
            onSelectExistingPatient: (patientInfo) {
              Navigator.of(context).pop();
              if (patientInfo.id != null) {
                context.go('/patients/${patientInfo.id}');
              }
            },
            onCancel: () {
              patientsCubit.clearDuplicatePhoneWarning();
            },
          );
        } else if (state.actionStatus == RequestStatusEnum.failure) {
          CustomToast(
            context: context,
            header: state.actionErrMessage ?? 'error_occurred'.tr(),
          ).showErrorToast();
        }
      },
      builder: (context, state) {
        final form = state.formState ?? const PatientFormState();
        final isLoading = state.actionStatus == RequestStatusEnum.loading;

        final content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
            border:
                isFullScreen ? null : Border.all(color: AppColors.grayE2E8F0),
            boxShadow: isFullScreen
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: CustomAssetImage(
                        path: AppIcons.users,
                        width: 20,
                        height: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: CustomAppFontStyle.semiBold18.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          form.fileNumber != null
                              ? '${'file_number'.tr()}: ${form.fileNumber}'
                              : 'patient_info'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.gray71717A,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grayE2E8F0),
              const SizedBox(height: 16),

              // ─── Tab Navigation Bar ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.grayf2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'tab_basic_info'.tr(),
                      icon: Icons.person_outline_rounded,
                      activeIndex: state.activeFormTab,
                      hasError: state.formTabsWithErrors.contains(0),
                    ),
                    _buildTabButton(
                      index: 1,
                      label: 'tab_medical_info'.tr(),
                      icon: Icons.medical_services_outlined,
                      activeIndex: state.activeFormTab,
                      hasError: state.formTabsWithErrors.contains(1),
                    ),
                    _buildTabButton(
                      index: 2,
                      label: 'tab_contact_insurance'.tr(),
                      icon: Icons.contact_phone_outlined,
                      activeIndex: state.activeFormTab,
                      hasError: state.formTabsWithErrors.contains(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Tab Body ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey<int>(state.activeFormTab),
                      child: _buildActiveTabContent(
                          context, state, form, isMobile),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Footer Action Buttons ──────────────────────────────
              _buildFooter(context, state, form, isLoading, isMobile),
            ],
          ),
        );

        if (isFullScreen) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              title: Text(
                titleText,
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: AppColors.darkText),
              ),
            ),
            body: SafeArea(child: content),
          );
        }

        return content;
      },
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required int activeIndex,
    required bool hasError,
  }) {
    final isActive = index == activeIndex;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => patientsCubit.updateFormActiveTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.gray71717A,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomAppFontStyle.medium13.copyWith(
                        color:
                            isActive ? AppColors.primary : AppColors.gray71717A,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (hasError)
                      Positioned(
                        top: -2,
                        left: -8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
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

  Widget _buildActiveTabContent(
    BuildContext context,
    PatientsState state,
    PatientFormState form,
    bool isMobile,
  ) {
    switch (state.activeFormTab) {
      case 0:
        return _buildTab1Basic(context, state, form);
      case 1:
        return _buildTab2Medical(context, state, form, isMobile);
      case 2:
      default:
        return _buildTab3ContactInsurance(context, state, form);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Tab 1: Basic Info
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTab1Basic(
    BuildContext context,
    PatientsState state,
    PatientFormState form,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        CustomTextFormField(
          initialValue: form.name,
          headerText: 'name'.tr(),
          hintText: 'patient_name_hint'.tr(),
          isRequired: true,
          prefixWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child:
                Icon(Icons.person_outline, size: 18, color: AppColors.primary),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          onChanged: (v) => patientsCubit.updateFormName(v ?? ''),
        ),
        const SizedBox(height: 16),

        // Primary Phone (+20)
        CustomPhoneField(
          initialValue: CustomPhoneField.extractLocalDigits(form.phone),
          header: 'patient_phone'.tr(),
          phoneCode: '+20',
          hintText: 'patient_phone_hint'.tr(),
          onChanged: (v) {
            final formatted = CustomPhoneField.formatWithCountryCode(
              v ?? '',
              countryCode: '+20',
            );
            patientsCubit.updateFormPhone(formatted);
          },
        ),
        const SizedBox(height: 8),

        // WhatsApp Switch/Checkbox
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: form.phoneHasWhatsapp,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (v) =>
                    patientsCubit.updateFormPhoneHasWhatsapp(v ?? true),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => patientsCubit.updateFormPhoneHasWhatsapp(
                !form.phoneHasWhatsapp,
              ),
              child: Text(
                'phone_has_whatsapp'.tr(),
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date of Birth & Live Age
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${'date_of_birth'.tr()} (${'optional_field'.tr()})',
                  style: CustomAppFontStyle.medium14.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                if (form.ageYears != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: form.isChild
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      form.isChild
                          ? '${form.ageYears} ${'age_years'.tr()} • ${'child_patient'.tr()}'
                          : '${form.ageYears} ${'age_years'.tr()}',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: form.isChild
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectDateOfBirth(context, form.dateOfBirth),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grayE2E8F0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      form.dateOfBirth != null
                          ? DateFormat('yyyy-MM-dd').format(form.dateOfBirth!)
                          : 'date_of_birth_hint'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: form.dateOfBirth != null
                            ? AppColors.darkText
                            : AppColors.gray71717A,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gender Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'gender'.tr()} (${'optional_field'.tr()})',
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        patientsCubit.updateFormGender(GenderEnum.male),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: form.gender == GenderEnum.male
                            ? AppColors.primaryLight
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: form.gender == GenderEnum.male
                              ? AppColors.primary
                              : AppColors.grayE2E8F0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.male_rounded,
                            size: 18,
                            color: form.gender == GenderEnum.male
                                ? AppColors.primary
                                : AppColors.gray71717A,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'gender_male'.tr(),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: form.gender == GenderEnum.male
                                  ? AppColors.primary
                                  : AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        patientsCubit.updateFormGender(GenderEnum.female),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: form.gender == GenderEnum.female
                            ? AppColors.primaryLight
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: form.gender == GenderEnum.female
                              ? AppColors.primary
                              : AppColors.grayE2E8F0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.female_rounded,
                            size: 18,
                            color: form.gender == GenderEnum.female
                                ? AppColors.primary
                                : AppColors.gray71717A,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'gender_female'.tr(),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: form.gender == GenderEnum.female
                                  ? AppColors.primary
                                  : AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Guardian Section for Children (<18)
        if (form.isChild) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.escalator_warning_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'guardian_header'.tr(),
                        style: CustomAppFontStyle.semiBold14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  initialValue: form.guardianName,
                  headerText: 'guardian_name'.tr(),
                  hintText: 'patient_name_hint'.tr(),
                  isRequired: true,
                  onChanged: (v) =>
                      patientsCubit.updateFormGuardianName(v ?? ''),
                ),
                const SizedBox(height: 12),
                CustomPhoneField(
                  initialValue: CustomPhoneField.extractLocalDigits(
                    form.guardianPhone,
                  ),
                  header: 'guardian_phone'.tr(),
                  phoneCode: '+20',
                  hintText: 'patient_phone_hint'.tr(),
                  onChanged: (v) {
                    final formatted = CustomPhoneField.formatWithCountryCode(
                      v ?? '',
                      countryCode: '+20',
                    );
                    patientsCubit.updateFormGuardianPhone(formatted);
                  },
                ),
                const SizedBox(height: 12),
                KinshipChipsSelector(
                  header: 'guardian_relation'.tr(),
                  selectedRelation: form.guardianRelation,
                  options: KinshipRelations.guardianOptions,
                  onChanged: (val) =>
                      patientsCubit.updateFormGuardianRelation(val),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Tab 2: Medical Info
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTab2Medical(
    BuildContext context,
    PatientsState state,
    PatientFormState form,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Blood Group Selector
        BloodGroupSelector(
          selected: form.bloodGroup,
          onSelected: (bg) => patientsCubit.updateFormBloodGroup(bg),
          isCompact: isMobile,
        ),
        const SizedBox(height: 20),

        // Female Only Section (Neutral styling box: Pregnancy, Nursing, LMP)
        if (form.gender == GenderEnum.female) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.grayf6,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grayE2E8F0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.female_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'female_health_details'.tr(),
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Checkbox(
                            value: form.isPregnant,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) =>
                                patientsCubit.updateFormIsPregnant(v ?? false),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => patientsCubit
                                .updateFormIsPregnant(!form.isPregnant),
                            child: Text(
                              'is_pregnant'.tr(),
                              style: CustomAppFontStyle.medium13.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Checkbox(
                            value: form.isNursing,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) =>
                                patientsCubit.updateFormIsNursing(v ?? false),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => patientsCubit
                                .updateFormIsNursing(!form.isNursing),
                            child: Text(
                              'is_nursing'.tr(),
                              style: CustomAppFontStyle.medium13.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'last_menstrual_period_date'.tr(),
                      style: CustomAppFontStyle.medium13.copyWith(
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _selectLmpDate(
                              context,
                              form.lastMenstrualPeriodDate,
                              form.dateOfBirth,
                            ),
                            child: Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.grayE2E8F0),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    form.lastMenstrualPeriodDate != null
                                        ? DateFormat('yyyy-MM-dd').format(
                                            form.lastMenstrualPeriodDate!,
                                          )
                                        : 'select_date'.tr(),
                                    style:
                                        CustomAppFontStyle.regular13.copyWith(
                                      color:
                                          form.lastMenstrualPeriodDate != null
                                              ? AppColors.darkText
                                              : AppColors.gray71717A,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (form.lastMenstrualPeriodDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.gray71717A,
                            ),
                            onPressed: () => patientsCubit
                                .updateFormLastMenstrualPeriodDate(null),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Allergies Tag Section (Catalog multi-select)
        SearchableCatalogMultiSelector(
          header: 'allergies'.tr(),
          hintText: 'allergies_hint'.tr(),
          icon: Icons.coronavirus_outlined,
          catalogItems: state.allergyCatalog,
          selectedItems: form.allergies,
          onItemAdded: (item) => patientsCubit.addAllergy(item),
          onItemRemoved: (item) => patientsCubit.removeAllergy(item),
          onAddNewToCatalog: (name) async {
            await patientsCubit.addMedicalCatalogItem(
              name: name,
              type: MedicalCatalogTypeEnum.allergy,
            );
          },
        ),
        const SizedBox(height: 20),

        // Chronic Diseases Tag Section (Catalog multi-select)
        SearchableCatalogMultiSelector(
          header: 'chronic_diseases'.tr(),
          hintText: 'chronic_diseases_hint'.tr(),
          icon: Icons.healing_outlined,
          catalogItems: state.chronicDiseaseCatalog,
          selectedItems: form.chronicDiseases,
          onItemAdded: (item) => patientsCubit.addChronicDisease(item),
          onItemRemoved: (item) => patientsCubit.removeChronicDisease(item),
          onAddNewToCatalog: (name) async {
            await patientsCubit.addMedicalCatalogItem(
              name: name,
              type: MedicalCatalogTypeEnum.chronicDisease,
            );
          },
        ),
        const SizedBox(height: 20),

        // Vitals (Height & Weight -> live BMI)
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                initialValue: form.heightCm?.toString(),
                headerText: 'height_cm'.tr(),
                hintText: '170',
                textInputType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  final numVal = v != null ? num.tryParse(v) : null;
                  patientsCubit.updateFormHeight(numVal);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextFormField(
                initialValue: form.weightKg?.toString(),
                headerText: 'weight_kg'.tr(),
                hintText: '70',
                textInputType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  final numVal = v != null ? num.tryParse(v) : null;
                  patientsCubit.updateFormWeight(numVal);
                },
              ),
            ),
          ],
        ),

        // Live BMI Result Card
        if (form.calculatedBmi != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  '${'bmi'.tr()}: ${form.calculatedBmi!.toStringAsFixed(1)} kg/m²',
                  style: CustomAppFontStyle.semiBold14.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void emitAllergies(List<String> items) {
    patientsCubit.emit(
      patientsCubit.state.copyWith(
        formState: patientsCubit.state.formState?.copyWith(allergies: items),
      ),
    );
  }

  void emitChronicDiseases(List<String> items) {
    patientsCubit.emit(
      patientsCubit.state.copyWith(
        formState:
            patientsCubit.state.formState?.copyWith(chronicDiseases: items),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Tab 3: Address, Contact & Insurance
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTab3ContactInsurance(
    BuildContext context,
    PatientsState state,
    PatientFormState form,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Governorate Selector (Cairo, Giza, Alexandria first, then alphabetical)
        CustomStackSelector<String>(
          controller: _governorateController,
          header: 'governorate'.tr(),
          list: EgyptianGovernorates.keys.toList(),
          itemAsString: (key) => key.tr(),
          displayStringForController: (key) => key.tr(),
          hintText: 'select_governorate'.tr(),
          enableSearch: true,
          changeValue: (key) => patientsCubit.updateFormGovernorate(key),
        ),
        const SizedBox(height: 16),

        // City
        CustomTextFormField(
          initialValue: form.city,
          headerText: 'city'.tr(),
          hintText: 'city_hint'.tr(),
          onChanged: (v) => patientsCubit.updateFormCity(v ?? ''),
        ),
        const SizedBox(height: 16),

        // Detailed Address
        CustomTextFormField(
          initialValue: form.detailedAddress,
          headerText: 'detailed_address'.tr(),
          hintText: 'detailed_address_hint'.tr(),
          prefixWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.location_on_outlined,
                size: 18, color: AppColors.primary),
          ),
          onChanged: (v) => patientsCubit.updateFormDetailedAddress(v ?? ''),
        ),
        const SizedBox(height: 20),

        // Emergency Contact Section (Optional)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grayf2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'emergency_contact_header'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                initialValue: form.emergencyContactName,
                headerText: 'emergency_contact_name'.tr(),
                hintText: 'patient_name_hint'.tr(),
                onChanged: (v) =>
                    patientsCubit.updateFormEmergencyName(v ?? ''),
              ),
              const SizedBox(height: 12),
              CustomPhoneField(
                initialValue: CustomPhoneField.extractLocalDigits(
                  form.emergencyContactPhone,
                ),
                header: 'emergency_contact_phone'.tr(),
                phoneCode: '+20',
                hintText: 'patient_phone_hint'.tr(),
                onChanged: (v) {
                  final formatted = CustomPhoneField.formatWithCountryCode(
                    v ?? '',
                    countryCode: '+20',
                  );
                  patientsCubit.updateFormEmergencyPhone(formatted);
                },
              ),
              const SizedBox(height: 12),
              KinshipChipsSelector(
                header: 'emergency_contact_relation'.tr(),
                selectedRelation: form.emergencyContactRelation,
                options: KinshipRelations.emergencyContactOptions,
                onChanged: (val) =>
                    patientsCubit.updateFormEmergencyRelation(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Health Insurance Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.grayf2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'insurance_company'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                initialValue: form.insuranceCompany,
                headerText: 'insurance_company'.tr(),
                hintText: 'insurance_company_hint'.tr(),
                onChanged: (v) =>
                    patientsCubit.updateFormInsuranceCompany(v ?? ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextFormField(
                      initialValue: form.insurancePolicyNumber,
                      headerText: 'insurance_policy_number'.tr(),
                      hintText: 'BUP-EG-99214',
                      onChanged: (v) =>
                          patientsCubit.updateFormInsurancePolicyNumber(v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: CustomTextFormField(
                      initialValue: form.insuranceCoveragePercent?.toString(),
                      headerText: 'insurance_coverage_percent'.tr(),
                      hintText: '80',
                      textInputType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) {
                        final val = v != null ? num.tryParse(v) : null;
                        patientsCubit
                            .updateFormInsuranceCoveragePercent(val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Internal Administrative Notes
        CustomTextFormField(
          initialValue: form.internalNotes,
          headerText: 'internal_notes'.tr(),
          hintText: 'internal_notes_hint'.tr(),
          maxLine: 3,
          onChanged: (v) => patientsCubit.updateFormInternalNotes(v ?? ''),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Footer Action Buttons (2 rows on mobile, 1 row on desktop)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(
    BuildContext context,
    PatientsState state,
    PatientFormState form,
    bool isLoading,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (state.activeFormTab < 2) ...[
                Expanded(
                  child: CustomPushButton(
                    height: 44,
                    backgroundColor: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => patientsCubit
                        .updateFormActiveTab(state.activeFormTab + 1),
                    child: Center(
                      child: Text(
                        'next'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: state.activeFormTab < 2 ? 1 : 2,
                child: CustomPushButton(
                  height: 44,
                  backgroundColor: AppColors.primary,
                  isLoading: isLoading,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _submit(context, form),
                  child: Center(
                    child: Text(
                      'save_patient'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (state.activeFormTab > 0) ...[
                Expanded(
                  child: CustomPushButton(
                    height: 44,
                    backgroundColor: AppColors.grayf2,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => patientsCubit
                        .updateFormActiveTab(state.activeFormTab - 1),
                    child: Center(
                      child: Text(
                        'previous'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: CustomPushButton(
                  height: 44,
                  backgroundColor: AppColors.grayf2,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.pop(),
                  child: Center(
                    child: Text(
                      'cancel'.tr(),
                      style: CustomAppFontStyle.medium14.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomPushButton(
          height: 44,
          width: 100,
          backgroundColor: AppColors.grayf2,
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.pop(),
          child: Center(
            child: Text(
              'cancel'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (state.activeFormTab > 0) ...[
          CustomPushButton(
            height: 44,
            width: 90,
            backgroundColor: AppColors.grayf2,
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                patientsCubit.updateFormActiveTab(state.activeFormTab - 1),
            child: Center(
              child: Text(
                'previous'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (state.activeFormTab < 2) ...[
          CustomPushButton(
            height: 44,
            width: 90,
            backgroundColor: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                patientsCubit.updateFormActiveTab(state.activeFormTab + 1),
            child: Center(
              child: Text(
                'next'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: CustomPushButton(
            height: 44,
            backgroundColor: AppColors.primary,
            isLoading: isLoading,
            borderRadius: BorderRadius.circular(8),
            onTap: () => _submit(context, form),
            child: Center(
              child: Text(
                'save_patient'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

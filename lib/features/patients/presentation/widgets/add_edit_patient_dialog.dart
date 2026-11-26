import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/egyptian_governorates.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/enums/marital_status_enum.dart';
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
import 'package:eyadty/shared/widgets/app_date_time_picker.dart';
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
  bool _hasHandledSuccess = false;
  late final TextEditingController _governorateController;
  late final TextEditingController _cityController;

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
    _cityController = TextEditingController(
      text: form?.city ?? '',
    );
  }

  @override
  void dispose() {
    _governorateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(
    BuildContext context,
    DateTime? current,
  ) async {
    final now = CairoTimeHelper.now();
    final picked = await showAppDatePicker(
      context,
      initial: current ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      title: 'تاريخ الميلاد',
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

    final picked = await showAppDatePicker(
      context,
      initial: safeInitial,
      firstDate: firstAllowed,
      lastDate: now,
      title: 'تاريخ آخر دورة شهرية (LMP)',
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
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.hasPendingDuplicatePhoneWarning !=
              curr.hasPendingDuplicatePhoneWarning ||
          prev.formState?.governorate != curr.formState?.governorate ||
          prev.formState?.city != curr.formState?.city,
      listener: (context, state) {
        final form = state.formState;
        if (form != null) {
          final govKey = form.governorate;
          final govText =
              (govKey != null && govKey.isNotEmpty) ? govKey.tr() : '';
          if (_governorateController.text != govText) {
            _governorateController.text = govText;
          }
          if (_cityController.text != form.city) {
            _cityController.text = form.city;
          }
        }
        if (state.actionStatus == RequestStatusEnum.success && !_hasHandledSuccess) {
          _hasHandledSuccess = true;
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
        final colors = context.themeColors;

        final content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius:
                isFullScreen ? BorderRadius.zero : BorderRadius.circular(16),
            border:
                isFullScreen ? null : Border.all(color: colors.borderSubtle),
            boxShadow: isFullScreen
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.35 : 0.08),
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
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          form.fileNumber != null
                              ? '${'file_number'.tr()}: ${form.fileNumber}'
                              : 'patient_info'.tr(),
                          style: CustomAppFontStyle.regular12.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.close,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.borderSubtle),
              const SizedBox(height: 16),

              // ─── Tab Navigation Bar ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      context: context,
                      index: 0,
                      label: 'tab_basic_info'.tr(),
                      icon: Icons.person_outline_rounded,
                      activeIndex: state.activeFormTab,
                      hasError: state.formTabsWithErrors.contains(0),
                    ),
                    _buildTabButton(
                      context: context,
                      index: 1,
                      label: 'tab_medical_info'.tr(),
                      icon: Icons.medical_services_outlined,
                      activeIndex: state.activeFormTab,
                      hasError: state.formTabsWithErrors.contains(1),
                    ),
                    _buildTabButton(
                      context: context,
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
            backgroundColor: colors.cardBackground,
            appBar: AppBar(
              backgroundColor: colors.cardBackground,
              elevation: 0,
              title: Text(
                titleText,
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.close, color: colors.textPrimary),
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
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required int activeIndex,
    required bool hasError,
  }) {
    final colors = context.themeColors;
    final isActive = index == activeIndex;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => patientsCubit.updateFormActiveTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? colors.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
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
                color: isActive ? colors.primary : colors.textSecondary,
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
                            isActive ? colors.primary : colors.textSecondary,
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
    final colors = context.themeColors;
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
                  color: colors.textPrimary,
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
                    color: colors.textPrimary,
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
                          : colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      form.isChild
                          ? '${form.ageYears} ${'age_years'.tr()} • ${'child_patient'.tr()}'
                          : '${form.ageYears} ${'age_years'.tr()}',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: form.isChild
                            ? AppColors.warning
                            : colors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ), const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectDateOfBirth(context, form.dateOfBirth),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      form.dateOfBirth != null
                          ? DateFormat('yyyy-MM-dd').format(form.dateOfBirth!)
                          : 'date_of_birth_hint'.tr(),
                      style: CustomAppFontStyle.regular14.copyWith(
                        color: form.dateOfBirth != null
                            ? colors.textPrimary
                            : colors.textSecondary,
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
                color: colors.textPrimary,
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
                            ? colors.primaryLight
                            : colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: form.gender == GenderEnum.male
                              ? colors.primary
                              : colors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.male_rounded,
                            size: 18,
                            color: form.gender == GenderEnum.male
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'gender_male'.tr(),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: form.gender == GenderEnum.male
                                  ? colors.primary
                                  : colors.textPrimary,
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
                            ? colors.primaryLight
                            : colors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: form.gender == GenderEnum.female
                              ? colors.primary
                              : colors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.female_rounded,
                            size: 18,
                            color: form.gender == GenderEnum.female
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'gender_female'.tr(),
                            style: CustomAppFontStyle.medium14.copyWith(
                              color: form.gender == GenderEnum.female
                                  ? colors.primary
                                  : colors.textPrimary,
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
              color: colors.surfaceLevel1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.borderSubtle,
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
                          color: colors.textPrimary,
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
    final colors = context.themeColors;
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

        // Female Only Section (بيانات الأنثى)
        if (form.gender == GenderEnum.female) ...[
          Builder(
            builder: (context) {
              final ageYears = form.ageYears;
              final hidePregnancyFields = ageYears != null && ageYears < 12;
              final computedEdd = form.estimatedDueDate ??
                  form.lastMenstrualPeriodDate?.add(const Duration(days: 280));
              final lmpForCalc = form.lastMenstrualPeriodDate ??
                  computedEdd?.subtract(const Duration(days: 280));
              int? gestWeeks;
              int? gestMonth;
              if (form.isPregnant && lmpForCalc != null) {
                final days = CairoTimeHelper.now().difference(lmpForCalc).inDays;
                gestWeeks = (days ~/ 7).clamp(0, 42);
                gestMonth = (gestWeeks / 4.3).ceil().clamp(1, 9);
              }

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceLevel1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        Icon(
                          Icons.female_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'female_health_details'.tr(),
                          style: CustomAppFontStyle.semiBold13.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Marital status chips
                    Text(
                      'الحالة الاجتماعية',
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: MaritalStatus.values.map((m) {
                        final selected = form.maritalStatus == m;
                        return ChoiceChip(
                          label: Text(m.femaleLabel()),
                          selected: selected,
                          onSelected: (val) => patientsCubit
                              .updateFormMaritalStatus(val ? m : null),
                        );
                      }).toList(),
                    ),
                    if (!hidePregnancyFields) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: form.isPregnant,
                              title: Text('حامل', style: CustomAppFontStyle.medium13),
                              onChanged: (v) =>
                                  patientsCubit.updateFormIsPregnant(v ?? false),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: form.isNursing,
                              title: Text('مرضع', style: CustomAppFontStyle.medium13),
                              onChanged: (v) =>
                                  patientsCubit.updateFormIsNursing(v ?? false),
                            ),
                          ),
                        ],
                      ),
                      if (form.isPregnant && form.isNursing)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: form.pregnantAndNursingConfirmed,
                          title: Text(
                            'تأكيد تسجيل الحمل والرضاعة معاً',
                            style: CustomAppFontStyle.medium12.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                          onChanged: (v) => patientsCubit
                              .updateFormPregnantAndNursingConfirmed(v ?? false),
                        ),
                      if (form.isPregnant) ...[
                        const SizedBox(height: 8),
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
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'تاريخ آخر دورة (LMP)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    form.lastMenstrualPeriodDate != null
                                        ? DateFormat('yyyy-MM-dd').format(
                                            form.lastMenstrualPeriodDate!,
                                          )
                                        : 'اختر التاريخ',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  final now = CairoTimeHelper.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: computedEdd ??
                                        now.add(const Duration(days: 140)),
                                    firstDate: now,
                                    lastDate: now.add(const Duration(days: 300)),
                                  );
                                  if (picked != null) {
                                    patientsCubit
                                        .updateFormEstimatedDueDate(picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'تاريخ الولادة المتوقع (EDD)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    computedEdd != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(computedEdd)
                                        : 'يحسب تلقائياً أو بالسونار',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (gestWeeks != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'عمر الحمل: الأسبوع $gestWeeks (الشهر $gestMonth من 9)',
                              style: CustomAppFontStyle.semiBold12.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (form.isNursing) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue:
                              form.nursingBabyAgeMonths?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'عمر الرضيع (بالشهور - اختياري)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => patientsCubit
                              .updateFormNursingBabyAgeMonths(int.tryParse(v)),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  form.gravidaCount?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الحمل (G)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => patientsCubit
                                  .updateFormGravidaCount(int.tryParse(v)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: form.paraCount?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الولادات (P)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => patientsCubit
                                  .updateFormParaCount(int.tryParse(v)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  form.miscarriageCount?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'إجهاض',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => patientsCubit
                                  .updateFormMiscarriageCount(int.tryParse(v)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue:
                                  form.cesareanCount?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'قيصري',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => patientsCubit
                                  .updateFormCesareanCount(int.tryParse(v)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: form.contraceptionMethod,
                        decoration: const InputDecoration(
                          labelText: 'وسيلة منع الحمل (اختياري)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: patientsCubit.updateFormContraceptionMethod,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: form.isMenopause,
                              title: Text('انقطاع الطمث',
                                  style: CustomAppFontStyle.medium12),
                              onChanged: (v) => patientsCubit
                                  .updateFormIsMenopause(v ?? false),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: form.hasPregnancyAllergyWarning,
                              title: Text('تحذير حساسية بالحمل',
                                  style: CustomAppFontStyle.medium12),
                              onChanged: (v) => patientsCubit
                                  .updateFormPregnancyAllergyWarning(v ?? false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                ),
              );
            },
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
    final colors = context.themeColors;
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
          changeValue: (key) {
            patientsCubit.updateFormGovernorate(key);
            final newCities = EgyptianGovernorates.getCitiesForGovernorate(key);
            if (!newCities.contains(_cityController.text)) {
              _cityController.clear();
              patientsCubit.updateFormCity('');
            }
          },
        ),
        const SizedBox(height: 16),

        // City / District (Filtered per Governorate with CustomStackSelector)
        CustomStackSelector<String>(
          controller: _cityController,
          header: 'city'.tr(),
          list: EgyptianGovernorates.getCitiesForGovernorate(form.governorate),
          itemAsString: (city) => city,
          displayStringForController: (city) => city,
          hintText: 'city_hint'.tr(),
          enableSearch: true,
          prefixWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.location_city_outlined,
                size: 18, color: AppColors.primary),
          ),
          changeValue: (city) => patientsCubit.updateFormCity(city),
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
            color: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'emergency_contact_header'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
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
            color: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'insurance_company'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: colors.textPrimary,
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
    final colors = context.themeColors;
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
                    backgroundColor: colors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => patientsCubit
                        .updateFormActiveTab(state.activeFormTab + 1),
                    child: Center(
                      child: Text(
                        'next'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: colors.primary,
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
                  backgroundColor: colors.primary,
                  isLoading: isLoading,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _submit(context, form),
                  child: Center(
                    child: Text(
                      'save_patient'.tr(),
                      style: CustomAppFontStyle.semiBold14.copyWith(
                        color: Colors.white,
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
                    backgroundColor: colors.surfaceLevel1,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => patientsCubit
                        .updateFormActiveTab(state.activeFormTab - 1),
                    child: Center(
                      child: Text(
                        'previous'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: colors.textPrimary,
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
        if (state.activeFormTab > 0) ...[
          CustomPushButton(
            height: 44,
            width: 90,
            backgroundColor: colors.surfaceLevel1,
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                patientsCubit.updateFormActiveTab(state.activeFormTab - 1),
            child: Center(
              child: Text(
                'previous'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.textPrimary,
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
            backgroundColor: colors.primaryLight,
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                patientsCubit.updateFormActiveTab(state.activeFormTab + 1),
            child: Center(
              child: Text(
                'next'.tr(),
                style: CustomAppFontStyle.medium14.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: CustomPushButton(
            height: 44,
            backgroundColor: colors.primary,
            isLoading: isLoading,
            borderRadius: BorderRadius.circular(8),
            onTap: () => _submit(context, form),
            child: Center(
              child: Text(
                'save_patient'.tr(),
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

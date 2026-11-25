import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/cairo_time_helper.dart';
import 'package:eyadty/core/utils/helpers/egyptian_phone_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/enums/gender_enum.dart';
import 'package:eyadty/features/patients/data/models/patient_model.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/auth/presentation/widgets/login_widgets/custom_phone_field.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'package:eyadty/shared/widgets/app_date_time_picker.dart';
import 'dialogs/duplicate_phone_warning_dialog.dart';

class QuickAddPatientDialog extends StatefulWidget {
  final PatientsCubit cubit;
  final bool isFullScreen;

  const QuickAddPatientDialog({
    super.key,
    required this.cubit,
    this.isFullScreen = false,
  });

  static Future<PatientModel?> show({
    required BuildContext context,
    PatientsCubit? patientsCubit,
    String? initialQuery,
  }) {
    PatientsCubit? effectiveCubit = patientsCubit;
    if (effectiveCubit == null) {
      try {
        effectiveCubit = context.read<PatientsCubit>();
      } catch (_) {
        effectiveCubit = getIt<PatientsCubit>();
      }
    }

    effectiveCubit.initPatientForm(null);
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      final q = initialQuery.trim();
      final isDigits =
          RegExp(r'^(\+?[0-9]+)$').hasMatch(q.replaceAll(' ', ''));
      if (isDigits) {
        effectiveCubit.updateFormPhone(q);
      } else {
        effectiveCubit.updateFormName(q);
      }
    }

    return showDialog<PatientModel>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = BlocProvider.value(
          value: effectiveCubit!,
          child: QuickAddPatientDialog(
            cubit: effectiveCubit,
            isFullScreen: isMobile,
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
            constraints: const BoxConstraints(maxWidth: 580),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<QuickAddPatientDialog> createState() => _QuickAddPatientDialogState();
}

class _QuickAddPatientDialogState extends State<QuickAddPatientDialog> {
  bool _hasHandledSuccess = false;

  PatientsCubit get cubit => widget.cubit;
  bool get isFullScreen => widget.isFullScreen;

  Future<void> _selectDateOfBirth(BuildContext context, DateTime? current) async {
    final now = CairoTimeHelper.now();
    final picked = await showAppDatePicker(
      context,
      initial: current ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      title: 'تاريخ الميلاد',
    );
    if (picked != null) {
      cubit.updateFormDateOfBirth(picked);
    }
  }

  void _submit(BuildContext context, PatientFormState form) {
    // 1. Full name validation (required)
    if (form.name.trim().length < 2) {
      CustomToast(
        context: context,
        header: 'name_min_chars'.tr(),
      ).showErrorToast();
      return;
    }

    // 2. Phone validation (required)
    final phone = form.phone.trim();
    if (!EgyptianPhoneHelper.isValid(phone)) {
      CustomToast(
        context: context,
        header: 'invalid_phone'.tr(),
      ).showErrorToast();
      return;
    }

    // 3. Guardian validation (only if DOB is entered and patient is a child < 18)
    if (form.isChild) {
      if (form.guardianName.trim().isEmpty ||
          form.guardianPhone.trim().isEmpty) {
        CustomToast(
          context: context,
          header: 'guardian_header'.tr(),
        ).showErrorToast();
        return;
      }
    }

    cubit.savePatient();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientsCubit, PatientsState>(
      bloc: cubit,
      listenWhen: (prev, curr) =>
          prev.actionStatus != curr.actionStatus ||
          prev.hasPendingDuplicatePhoneWarning !=
              curr.hasPendingDuplicatePhoneWarning,
      listener: (context, state) {
        if (state.actionStatus == RequestStatusEnum.success && !_hasHandledSuccess) {
          _hasHandledSuccess = true;
          CustomToast(
            context: context,
            header: 'patient_saved_successfully'.tr(),
          ).showTopToast();
          Navigator.of(context).pop(state.lastSavedPatient);
        } else if (state.hasPendingDuplicatePhoneWarning) {
          DuplicatePhoneWarningDialog.show(
            context: context,
            matchingPatients: state.duplicatePhonePatients,
            onContinueWithSharedPhone: () {
              cubit.confirmSaveWithDuplicatePhone();
            },
            onSelectExistingPatient: (patientInfo) {
              PatientModel? selected;
              if (patientInfo.id != null) {
                selected = state.items.firstWhere(
                  (p) => p.id == patientInfo.id,
                  orElse: () => PatientModel(
                    id: patientInfo.id,
                    name: patientInfo.name,
                    fileNumber: patientInfo.fileNumber,
                    phone: patientInfo.phone,
                  ),
                );
              }
              Navigator.of(context).pop(selected);
            },
            onCancel: () {
              cubit.clearDuplicatePhoneWarning();
            },
          );
        }
      },
      builder: (context, state) {
        final form = state.formState ?? const PatientFormState();
        final isLoading = state.actionStatus == RequestStatusEnum.loading;
        final hasError = state.actionStatus == RequestStatusEnum.failure;
        final isDuplicate = hasError &&
            (state.actionErrMessage?.contains('مسجل بالفعل') ?? false);

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
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: SingleChildScrollView(
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
                            'quick_add_patient'.tr(),
                            style: CustomAppFontStyle.semiBold18.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'quick_add_patient_desc'.tr(),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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

                // ─── Duplicate Warning Banner ───────────────────────────
                if (hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
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
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.actionErrMessage ?? 'error_occurred'.tr(),
                                style: CustomAppFontStyle.medium13.copyWith(
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isDuplicate) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: CustomPushButton(
                              height: 32,
                              backgroundColor: AppColors.warning,
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                final normPhone = EgyptianPhoneHelper.normalize(form.phone);
                                final matched = state.items.firstWhere(
                                  (p) =>
                                      p.phone != null &&
                                      EgyptianPhoneHelper.normalize(p.phone) ==
                                          normPhone,
                                  orElse: () => const PatientModel(),
                                );
                                if (matched.id != null) {
                                  Navigator.of(context).pop(matched);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Center(
                                  child: Text(
                                    'patient_select_registered'.tr(),
                                    style: CustomAppFontStyle.semiBold12.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Patient Name ────────────────────────────────────────
                CustomTextFormField(
                  initialValue: form.name,
                  headerText: 'name'.tr(),
                  hintText: 'patient_name_hint'.tr(),
                  isRequired: true,
                  prefixWidget: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: CustomAssetImage(
                      path: AppIcons.user,
                      width: 16,
                      height: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                  onChanged: (v) => cubit.updateFormName(v ?? ''),
                ),
                const SizedBox(height: 16),

                // ─── Patient Phone (+20 Egypt) ───────────────────────────
                CustomPhoneField(
                  initialValue: CustomPhoneField.extractLocalDigits(form.phone),
                  header: 'patient_phone'.tr(),
                  phoneCode: '+20',
                  hintText: 'patient_phone_hint'.tr(),
                  onChanged: (v) {
                    final normalized = CustomPhoneField.formatWithCountryCode(
                      v ?? '',
                      countryCode: '+20',
                    );
                    cubit.updateFormPhone(normalized);
                  },
                ),
                const SizedBox(height: 8),
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
                            cubit.updateFormPhoneHasWhatsapp(v ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => cubit.updateFormPhoneHasWhatsapp(
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

                // ─── Date of Birth & Age ─────────────────────────────────
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

                // ─── Gender Selection ────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${'gender'.tr()} (${'optional_field'.tr()})',
                          style: CustomAppFontStyle.medium14.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => cubit.updateFormGender(GenderEnum.male),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: form.gender == GenderEnum.male
                                    ? colors.primary.withValues(alpha: 0.12)
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
                            onTap: () => cubit.updateFormGender(GenderEnum.female),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: form.gender == GenderEnum.female
                                    ? colors.primary.withValues(alpha: 0.12)
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

                // ─── Dynamic Guardian Section for Children (<18) ────────
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
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          onChanged: (v) => cubit.updateFormGuardianName(v ?? ''),
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
                            final formatted =
                                CustomPhoneField.formatWithCountryCode(
                              v ?? '',
                              countryCode: '+20',
                            );
                            cubit.updateFormGuardianPhone(formatted);
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextFormField(
                          initialValue: form.guardianRelation,
                          headerText: 'guardian_relation'.tr(),
                          hintText: 'emergency_contact_relation'.tr(),
                          isRequired: false,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(40),
                          ],
                          onChanged: (v) => cubit.updateFormGuardianRelation(v ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 26),

                // ─── Action Buttons ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomPushButton(
                      height: 44,
                      width: 100,
                      backgroundColor: AppColors.grayf2,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
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
                ),
              ],
            ),
          ),
        );

        if (isFullScreen) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              title: Text(
                'quick_add_patient'.tr(),
                style: CustomAppFontStyle.semiBold18.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.darkText,
                  size: 20,
                ),
              ),
            ),
            body: SafeArea(child: content),
          );
        }

        return content;
      },
    );
  }
}

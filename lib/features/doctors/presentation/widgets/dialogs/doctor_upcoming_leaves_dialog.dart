import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/helpers/app_formatter_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/data/models/doctor_leave_model.dart';
import 'package:eyadty/features/doctors/data/models/doctor_model.dart';
import 'package:eyadty/features/doctors/domain/use_cases/get_doctor_leaves_use_case.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class DoctorUpcomingLeavesDialog extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorUpcomingLeavesDialog({
    super.key,
    required this.doctor,
  });

  static Future<void> show({
    required BuildContext context,
    required DoctorModel doctor,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (dialogCtx) {
        final isMobile = AdaptiveLayout.isMobile(dialogCtx);
        final child = DoctorUpcomingLeavesDialog(doctor: doctor);

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
  State<DoctorUpcomingLeavesDialog> createState() =>
      _DoctorUpcomingLeavesDialogState();
}

class _DoctorUpcomingLeavesDialogState
    extends State<DoctorUpcomingLeavesDialog> {
  bool _isLoading = true;
  List<DoctorLeaveModel> _upcomingLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    final doctorId = widget.doctor.id ?? '';
    if (doctorId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final useCase = getIt<GetDoctorLeavesUseCase>();
    final result = await useCase(doctorId);

    if (!mounted) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    result.fold(
      (_) => setState(() => _isLoading = false),
      (leaves) {
        final filtered = leaves.where((l) {
          if (l.endDate == null) return false;
          final end = DateTime(
            l.endDate!.year,
            l.endDate!.month,
            l.endDate!.day,
            23,
            59,
            59,
          );
          return end.isAfter(todayStart);
        }).toList()
          ..sort((a, b) =>
              (a.startDate ?? DateTime.now())
                  .compareTo(b.startDate ?? DateTime.now()));

        setState(() {
          _upcomingLeaves = filtered;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context),

          const Divider(height: 1, color: AppColors.grayE2E8F0),

          // Content
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : _upcomingLeaves.isEmpty
                    ? _buildEmptyState()
                    : _buildLeavesList(),
          ),

          const Divider(height: 1, color: AppColors.grayE2E8F0),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CustomPushButton(
                height: 38,
                width: 100,
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.pop(),
                child: Center(
                  child: Text(
                    'cancel'.tr(),
                    style: CustomAppFontStyle.medium14.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const CustomAssetImage(
              path: AppIcons.calendar,
              width: 20,
              height: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'upcoming_leaves'.tr(),
                  style: CustomAppFontStyle.bold16.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
                if (widget.doctor.name != null)
                  Text(
                    widget.doctor.name!,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.grayE2E8F0.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.gray71717A,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_upcoming_leaves'.tr(),
            style: CustomAppFontStyle.semiBold15.copyWith(
              color: AppColors.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'doctor_has_no_scheduled_leaves'.tr(),
            style: CustomAppFontStyle.regular13.copyWith(
              color: AppColors.gray71717A,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _upcomingLeaves.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final leave = _upcomingLeaves[index];
        final isActive = leave.isCurrentlyActive();

        return CustomContainer(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.grayE2E8F0,
          ),
          backGroundColor: isActive
              ? AppColors.warning.withValues(alpha: 0.04)
              : AppColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'active_leave'.tr() : 'scheduled_leave'.tr(),
                      style: CustomAppFontStyle.medium11.copyWith(
                        color: isActive ? AppColors.warning : AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${leave.durationDays} ${'days_label'.tr()}',
                    style: CustomAppFontStyle.semiBold13.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 15,
                    color: AppColors.gray71717A,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppFormatterHelper.formatDate(leave.startDate)} - ${AppFormatterHelper.formatDate(leave.endDate)}',
                    style: CustomAppFontStyle.medium13.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              if (leave.reason != null && leave.reason!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'reason'.tr()}: ',
                      style: CustomAppFontStyle.regular12.copyWith(
                        color: AppColors.gray71717A,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        leave.reason!,
                        style: CustomAppFontStyle.regular12.copyWith(
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


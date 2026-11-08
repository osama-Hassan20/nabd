import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';
import 'doctors_schedule_card.dart';
import 'doctors_schedule_shimmer.dart';
import 'doctors_schedule_table.dart';

class DoctorsScheduleTab extends StatefulWidget {
  const DoctorsScheduleTab({super.key});

  @override
  State<DoctorsScheduleTab> createState() => _DoctorsScheduleTabState();
}

class _DoctorsScheduleTabState extends State<DoctorsScheduleTab> {
  late final DoctorsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<DoctorsCubit>()..fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<DoctorsCubit, DoctorsState>(
        builder: (context, state) {
          if (state.status == RequestStatusEnum.loading &&
              state.items.isEmpty) {
            return const DoctorsScheduleShimmer();
          }

          if (state.status == RequestStatusEnum.failure &&
              state.items.isEmpty) {
            return _buildErrorView();
          }

          final isMobile = AdaptiveLayout.isMobile(context);
          final doctors = state.items;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'doctors_schedule_title'.tr(),
                          style: CustomAppFontStyle.semiBold16.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'doctors_schedule_subtitle'.tr(),
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content: Table or Cards
              Expanded(
                child: doctors.isEmpty
                    ? _buildEmptyState()
                    : isMobile
                        ? ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doc = doctors[index];
                              return DoctorsScheduleCard(
                                doctor: doc,
                                schedule: state.doctorSchedules[doc.id],
                                cubit: _cubit,
                              );
                            },
                          )
                        : SingleChildScrollView(
                            child: DoctorsScheduleTable(
                              doctors: doctors,
                              schedules: state.doctorSchedules,
                              cubit: _cubit,
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: AppColors.gray71717A,
            ),
            const SizedBox(height: 12),
            Text(
              'no_data_available'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.gray71717A,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'failed_to_load'.tr(),
            style: CustomAppFontStyle.medium14.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          CustomPushButton(
            height: 38,
            width: 120,
            backgroundColor: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            onTap: () => _cubit.fetchDoctors(),
            child: Text(
              'retry'.tr(),
              style: CustomAppFontStyle.medium14.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


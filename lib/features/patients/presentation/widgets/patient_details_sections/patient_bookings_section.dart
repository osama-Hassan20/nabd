import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/bookings/data/models/booking_model.dart';
import 'package:eyadty/features/bookings/data/models/enums/booking_status_enum.dart';
import 'package:eyadty/features/bookings/presentation/widgets/add_edit_booking_dialog.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_action_dialogs.dart';
import 'package:eyadty/features/bookings/presentation/widgets/booking_card.dart';
import 'package:eyadty/features/bookings/presentation/widgets/bookings_table.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_cubit.dart';
import 'package:eyadty/features/patients/presentation/manager/patients_state.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_tab_bar.dart';
import 'package:eyadty/shared/widgets/responsive_helper/adaptive_layout.dart';

class PatientBookingsSection extends StatefulWidget {
  const PatientBookingsSection({super.key});

  @override
  State<PatientBookingsSection> createState() =>
      _PatientBookingsSectionState();
}

class _PatientBookingsSectionState extends State<PatientBookingsSection>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const List<BookingStatusEnum?> _tabStatuses = [
    null,
    BookingStatusEnum.scheduled,
    BookingStatusEnum.completed,
    BookingStatusEnum.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final cubit = context.read<PatientsCubit>();
    final status = _tabStatuses[_tabController.index];
    cubit.filterPatientBookingsByStatus(status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PatientsCubit>();

    return BlocBuilder<PatientsCubit, PatientsState>(
      buildWhen: (prev, curr) =>
          prev.filteredPatientBookings != curr.filteredPatientBookings ||
          prev.selectedBookingStatusFilter !=
              curr.selectedBookingStatusFilter ||
          prev.patientBookingSearchQuery !=
              curr.patientBookingSearchQuery ||
          prev.actionStatus != curr.actionStatus,
      builder: (context, state) {
        return CustomContainer(
          backGroundColor: AppColors.lightBackground,
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ──────────────────────────────────────────
              Row(
                children: [
                  const CustomAssetImage(
                    path: AppIcons.calendar,
                    width: 20,
                    height: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'patient_bookings'.tr(),
                    style: CustomAppFontStyle.bold16.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const Spacer(),
                  // Direct Action to add booking for this patient
                  IconButton(
                    onPressed: () async {
                      final p = state.selectedPatient;
                      if (p == null) return;
                      await AddEditBookingDialog.show(
                        context: context,
                        booking: BookingModel(
                          patientId: p.id,
                          patientName: p.name,
                          patientPhone: p.phone,
                        ),
                      );
                      if (p.id != null && context.mounted) {
                        cubit.fetchPatientDetails(p.id!);
                      }
                    },
                    icon: const CustomAssetImage(
                      path: AppIcons.add,
                      width: 18,
                      height: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: 'create_booking_for_patient'.tr(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Filter Tabs & Search Bar ─────────────────────────
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CustomTabBar(
                    controller: _tabController,
                    tabs: [
                      'all'.tr(),
                      'scheduled'.tr(),
                      'completed'.tr(),
                      'cancelled'.tr(),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: TextField(
                      controller: cubit.patientBookingsSearchController,
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.darkText,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'search_bookings_hint'.tr(),
                        hintStyle: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.gray71717A,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: CustomAssetImage(
                            path: AppIcons.search,
                            width: 16,
                            height: 16,
                            color: AppColors.gray71717A,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.grayE2E8F0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.grayE2E8F0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Bookings Table / Cards ───────────────────────────
              if (state.filteredPatientBookings.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const CustomAssetImage(
                        path: AppIcons.calendar,
                        width: 48,
                        height: 48,
                        color: AppColors.gray71717A,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_patient_bookings'.tr(),
                        style: CustomAppFontStyle.medium14.copyWith(
                          color: AppColors.gray71717A,
                        ),
                      ),
                    ],
                  ),
                )
              else
                AdaptiveLayout(
                  desktopLayout: (context) => BookingsTable(
                    bookings: state.filteredPatientBookings,
                    onViewDetails: (b) {
                      if (b.id != null) {
                        context.go('${AppRouter.bookings}/${b.id}');
                      }
                    },
                    onEdit: (b) async {
                      await AddEditBookingDialog.show(
                        context: context,
                        booking: b,
                      );
                      if (state.selectedPatient?.id != null &&
                          context.mounted) {
                        cubit.fetchPatientDetails(state.selectedPatient!.id!);
                      }
                    },
                    onChangeStatus: (b) => _showChangeStatusDialog(context, b),
                    onReassignTechnician: (b) =>
                        _showReassignDoctorDialog(context, b),
                    onDelete: (b) => _showDeleteBookingDialog(context, b),
                  ),
                  tabletLayout: (context) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredPatientBookings.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 480,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 310,
                    ),
                    itemBuilder: (context, index) {
                      final b = state.filteredPatientBookings[index];
                      return BookingCard(
                        booking: b,
                        onViewDetails: () {
                          if (b.id != null) {
                            context.go('${AppRouter.bookings}/${b.id}');
                          }
                        },
                        onEdit: () async {
                          await AddEditBookingDialog.show(
                            context: context,
                            booking: b,
                          );
                          if (state.selectedPatient?.id != null &&
                              context.mounted) {
                            cubit.fetchPatientDetails(
                                state.selectedPatient!.id!);
                          }
                        },
                        onChangeStatus: () =>
                            _showChangeStatusDialog(context, b),
                        onReassignTechnician: () =>
                            _showReassignDoctorDialog(context, b),
                        onDelete: () => _showDeleteBookingDialog(context, b),
                      );
                    },
                  ),
                  mobileLayout: (context) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredPatientBookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = state.filteredPatientBookings[index];
                      return BookingCard(
                        booking: b,
                        onViewDetails: () {
                          if (b.id != null) {
                            context.go('${AppRouter.bookings}/${b.id}');
                          }
                        },
                        onEdit: () async {
                          await AddEditBookingDialog.show(
                            context: context,
                            booking: b,
                          );
                          if (state.selectedPatient?.id != null &&
                              context.mounted) {
                            cubit.fetchPatientDetails(
                                state.selectedPatient!.id!);
                          }
                        },
                        onChangeStatus: () =>
                            _showChangeStatusDialog(context, b),
                        onReassignTechnician: () =>
                            _showReassignDoctorDialog(context, b),
                        onDelete: () => _showDeleteBookingDialog(context, b),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeStatusDialog(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showChangeStatusDialog(
      context: context,
      booking: booking,
    );
  }

  void _showReassignDoctorDialog(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showReassignTechnicianDialog(
      context: context,
      booking: booking,
    );
  }

  void _showDeleteBookingDialog(BuildContext context, BookingModel booking) {
    BookingActionDialogs.showDeleteDialog(
      context: context,
      booking: booking,
    );
  }
}

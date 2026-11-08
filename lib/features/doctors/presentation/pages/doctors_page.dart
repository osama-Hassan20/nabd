import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/layout_adaptive/widgets/pagination_table.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/sliver_extentions.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_cubit.dart';
import 'package:eyadty/features/doctors/presentation/cubit/doctors_state.dart';
import 'package:eyadty/features/doctors/presentation/widgets/adaptive_doctors_view.dart';
import 'package:eyadty/features/doctors/presentation/widgets/doctors_filter_bar.dart';
import 'package:eyadty/features/doctors/presentation/widgets/doctors_shimmer.dart';
import 'package:eyadty/shared/widgets/custom_empty_widget.dart';
import 'package:eyadty/shared/widgets/error_page.dart';

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DoctorsCubit>()..init(),
      child: BlocBuilder<DoctorsCubit, DoctorsState>(
        builder: (context, state) {
          final cubit = context.read<DoctorsCubit>();

          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => cubit.fetchDoctors(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const DoctorsFilterBar().toSliver(),
                        const SizedBox(height: 16).toSliver(),

                        if (state.status == RequestStatusEnum.loading)
                          const AdaptiveDoctorsShimmer().toSliver()
                        else if (state.status == RequestStatusEnum.failure)
                          ErrorPage(
                            errorMessage:
                                state.errMessage ?? 'failed_to_load'.tr(),
                            onPressed: () => cubit.fetchDoctors(),
                          ).toSliver()
                        else if (state.status == RequestStatusEnum.empty ||
                            state.items.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ColoredBox(
                              color: Colors.white,
                              child: CustomEmptyWidget(
                                title: 'no_technicians_found'.tr(),
                              ),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: AdaptiveDoctorsView(
                              doctors: state.items,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (state.status == RequestStatusEnum.success &&
                    state.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CustomPaginationTable(
                    onTapNext: () => cubit.changePage(
                      (cubit.paginationParams.page ?? 1) + 1,
                    ),
                    onTapPrevious: () => cubit.changePage(
                      (cubit.paginationParams.page ?? 1) - 1,
                    ),
                    onTapNumber: (pageNum) => cubit.changePage(pageNum),
                    pagesCount: state.totalPages,
                    currentPage: cubit.paginationParams.page ?? 1,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}


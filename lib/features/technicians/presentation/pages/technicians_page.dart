import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purexo/core/dependency_injection/dependency_injection.dart';
import 'package:purexo/core/layout_adaptive/widgets/pagination_table.dart';
import 'package:purexo/core/utils/enums/request_status_enum.dart';
import 'package:purexo/core/utils/extensions/sliver_extentions.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_cubit.dart';
import 'package:purexo/features/technicians/presentation/cubit/technicians_state.dart';
import 'package:purexo/features/technicians/presentation/widgets/adaptive_technicians_view.dart';
import 'package:purexo/features/technicians/presentation/widgets/technicians_filter_bar.dart';
import 'package:purexo/features/technicians/presentation/widgets/technicians_shimmer.dart';
import 'package:purexo/shared/widgets/custom_empty_widget.dart';
import 'package:purexo/shared/widgets/error_page.dart';

class TechniciansPage extends StatelessWidget {
  const TechniciansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TechniciansCubit>()..init(),
      child: BlocBuilder<TechniciansCubit, TechniciansState>(
        builder: (context, state) {
          final cubit = context.read<TechniciansCubit>();

          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => cubit.fetchTechnicians(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const TechniciansFilterBar().toSliver(),
                        const SizedBox(height: 16).toSliver(),

                        if (state.status == RequestStatusEnum.loading)
                          const AdaptiveTechniciansShimmer().toSliver()
                        else if (state.status == RequestStatusEnum.failure)
                          ErrorPage(
                            errorMessage:
                                state.errMessage ?? 'failed_to_load'.tr(),
                            onPressed: () => cubit.fetchTechnicians(),
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
                            child: AdaptiveTechniciansView(
                              technicians: state.items,
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

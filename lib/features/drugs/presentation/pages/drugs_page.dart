import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/dependency_injection/dependency_injection.dart';
import '../../../../core/utils/enums/request_status_enum.dart';
import '../../../../core/utils/theme/app_colors.dart';
import '../../../../core/utils/theme/custom_app_font_styles.dart';
import '../../../../shared/widgets/custom_push_container_button.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../manager/drugs_cubit.dart';
import '../manager/drugs_state.dart';
import '../widgets/dialogs/add_drug_dialog.dart';
import '../widgets/tabs/allergy_aliases_tab.dart';
import '../widgets/tabs/drugs_catalog_tab.dart';
import '../widgets/tabs/prescription_templates_tab.dart';

class DrugsPage extends StatefulWidget {
  final DrugsCubit? cubit;

  const DrugsPage({super.key, this.cubit});

  @override
  State<DrugsPage> createState() => _DrugsPageState();
}

class _DrugsPageState extends State<DrugsPage>
    with SingleTickerProviderStateMixin {
  late final DrugsCubit _cubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? getIt<DrugsCubit>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _cubit.setActiveTab(_tabController.index);
      }
    });
    _cubit.loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<DrugsCubit, DrugsState>(
        listener: (context, state) {
          if (state.errMessage != null && state.errMessage!.isNotEmpty) {
            CustomToast(
              context: context,
              header: state.errMessage!.tr(),
            ).showTopToast();
          }
          if (state.successMessage != null &&
              state.successMessage!.isNotEmpty) {
            CustomToast(
              context: context,
              header: state.successMessage!.tr(),
            ).showTopToast();
          }
        },
        builder: (context, state) {
          final canManage = _cubit.canManageCatalog;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'drugs_title'.tr(),
                              style: CustomAppFontStyle.bold24.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'drugs_page_subtitle'.tr(),
                              style: CustomAppFontStyle.regular13.copyWith(
                                color: AppColors.gray71717A,
                              ),
                            ),
                          ],
                        ),
                        if (canManage)
                          CustomPushButton(
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            backgroundColor: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              AddDrugDialog.show(
                                context: context,
                                cubit: _cubit,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add,
                                    color: AppColors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'drugs_add_drug'.tr(),
                                  style: CustomAppFontStyle.bold13.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── TabBar ──────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.white,
                        unselectedLabelColor: AppColors.darkText,
                        labelStyle: CustomAppFontStyle.bold14,
                        unselectedLabelStyle: CustomAppFontStyle.medium14,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'drugs_catalog_tab'.tr()),
                          Tab(text: 'drugs_templates_tab'.tr()),
                          Tab(text: 'drugs_allergies_tab'.tr()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Body Tabs ───────────────────────────────────────────
                    Expanded(
                      child: state.status == RequestStatusEnum.loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                DrugsCatalogTab(cubit: _cubit, state: state),
                                PrescriptionTemplatesTab(
                                  cubit: _cubit,
                                  state: state,
                                ),
                                AllergyAliasesTab(
                                  cubit: _cubit,
                                  state: state,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

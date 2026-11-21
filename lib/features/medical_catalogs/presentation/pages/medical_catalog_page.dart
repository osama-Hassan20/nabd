import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_cards/summary_card.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:eyadty/shared/widgets/custom_toast.dart';
import '../../data/models/enums/medical_catalog_kind_enum.dart';
import '../../data/models/medical_catalog_entry_model.dart';
import '../manager/medical_catalogs_cubit.dart';
import '../manager/medical_catalogs_state.dart';
import '../widgets/add_edit_medical_catalog_dialog.dart';

class MedicalCatalogPage extends StatefulWidget {
  final MedicalCatalogKindEnum kind;
  final MedicalCatalogsCubit? cubit;

  const MedicalCatalogPage({
    super.key,
    required this.kind,
    this.cubit,
  });

  @override
  State<MedicalCatalogPage> createState() => _MedicalCatalogPageState();
}

class _MedicalCatalogPageState extends State<MedicalCatalogPage> {
  late final MedicalCatalogsCubit _cubit;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? getIt<MedicalCatalogsCubit>();
    _cubit.setKind(widget.kind);
    _cubit.loadEntries();
  }

  @override
  void didUpdateWidget(MedicalCatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _cubit.setKind(widget.kind);
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, MedicalCatalogEntryModel entry) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final colors = dialogCtx.themeColors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderSubtle),
          ),
          title: Text(
            'تأكيد الحذف',
            style: CustomAppFontStyle.bold16.copyWith(color: AppColors.error),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في حذف «${entry.name}» من ${widget.kind.title}؟',
            style: CustomAppFontStyle.regular14.copyWith(color: colors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('cancel'.tr(), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _cubit.deleteEntry(entry.id);
              },
              child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MedicalCatalogsCubit, MedicalCatalogsState>(
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
          final colors = context.themeColors;
          return Scaffold(
            backgroundColor: colors.scaffoldBackground,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header ──────────────────────────────────────────────
                    _buildHeader(context, state),
                    const SizedBox(height: 20),

                    // ─── Stat Cards ──────────────────────────────────────────
                    _buildStatCards(state),
                    const SizedBox(height: 20),

                    // ─── Filter & Search Bar ─────────────────────────────────
                    _buildFilterBar(state),
                    const SizedBox(height: 16),

                    // ─── Content Table / List ────────────────────────────────
                    Expanded(
                      child: _buildContentBody(context, state),
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

  Widget _buildHeader(BuildContext context, MedicalCatalogsState state) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomAssetImage(
                  path: widget.kind.iconPath,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.kind.title,
                    style: CustomAppFontStyle.bold20.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.kind.subtitle,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomPushButton(
            height: 42,
            backgroundColor: colors.primary,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: () {
              AddEditMedicalCatalogDialog.show(
                context: context,
                cubit: _cubit,
                kind: widget.kind,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.kind.addItemButtonTitle,
                  style: CustomAppFontStyle.bold13.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(MedicalCatalogsState state) {
    final items = [
      SummaryCard(
        title: '${state.totalCount}',
        subTitle: 'إجمالي ${widget.kind.title}',
        iconPath: widget.kind.iconPath,
        gradient: AppGradient.primaryGradient,
        activeBorderColor: AppColors.white,
        isSelected: state.statusFilter == 'all',
        onTap: () => _cubit.setStatusFilter('all'),
      ),
      SummaryCard(
        title: '${state.activeCount}',
        subTitle: 'عناصر نشطة ومتاحة',
        iconPath: AppIcons.checkmarkCircle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2E9A68), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        activeBorderColor: AppColors.white,
        isSelected: state.statusFilter == 'active',
        onTap: () => _cubit.toggleStatusFilter('active'),
      ),
      SummaryCard(
        title: '${state.inactiveCount}',
        subTitle: 'معطلة / غير مستخدمة',
        iconPath: AppIcons.close,
        gradient: const LinearGradient(
          colors: [Color(0xFFE54848), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        activeBorderColor: AppColors.white,
        isSelected: state.statusFilter == 'inactive',
        onTap: () => _cubit.toggleStatusFilter('inactive'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 220,
                child: items[index],
              ),
            ),
          );
        }

        return Row(
          children: items
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SizedBox(
                      height: 98,
                      child: card,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFilterBar(MedicalCatalogsState state) {
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _searchController,
                  hintText: 'ابحث بالاسم الطبي، الكود، أو التصنيف...',
                  prefixWidget: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 18, color: colors.textSecondary),
                  ),
                  suffixWidget: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: colors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _cubit.onSearchChanged('');
                          },
                        )
                      : null,
                  onChanged: (v) => _cubit.onSearchChanged(v ?? ''),
                ),
              ),
            ],
          ),
          if (state.availableCategories.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...state.availableCategories.map((category) {
                    final isSelected = state.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _cubit.onCategorySelected(category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : colors.surfaceLevel1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            category,
                            style: CustomAppFontStyle.medium12.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  _buildAddCategoryChip(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentBody(BuildContext context, MedicalCatalogsState state) {
    final colors = context.themeColors;

    if (state.status == RequestStatusEnum.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayed = state.displayedEntries;

    if (displayed.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 54, color: colors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text(
                'لا توجد عناصر مطابقة',
                style: CustomAppFontStyle.bold16.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك تغيير كلمات البحث أو إضافة عنصر جديد إلى هذا الدليل',
                style: CustomAppFontStyle.regular13.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              CustomPushButton(
                height: 40,
                backgroundColor: colors.primary,
                borderRadius: BorderRadius.circular(10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onTap: () {
                  AddEditMedicalCatalogDialog.show(
                    context: context,
                    cubit: _cubit,
                    kind: widget.kind,
                  );
                },
                child: Text(
                  widget.kind.addItemButtonTitle,
                  style: CustomAppFontStyle.bold13.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Table Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: colors.tableHeaderBackground,
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text('الكود',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('الاسم الطبي / الفحص',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('التصنيف',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('ملاحظات وإرشادات',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text('الحالة',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text('الإجراءات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),

            // Table Rows
            Expanded(
              child: ListView.separated(
                itemCount: displayed.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: colors.borderSubtle),
                itemBuilder: (context, index) {
                  final entry = displayed[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Code badge
                        SizedBox(
                          width: 90,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.surfaceLevel1,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.code,
                              style: CustomAppFontStyle.bold11.copyWith(
                                color: colors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.name,
                            style: CustomAppFontStyle.semiBold14.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),

                        // Category chip
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.category,
                                style: CustomAppFontStyle.medium11.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Notes
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.notes ?? '—',
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: colors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Status badge (clickable to toggle)
                        SizedBox(
                          width: 90,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _cubit.toggleActive(entry),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.isActive
                                    ? (context.isDarkMode ? const Color(0xFF132A20) : const Color(0xFFECFDF5))
                                    : colors.surfaceLevel1,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: entry.isActive
                                      ? (context.isDarkMode ? const Color(0xFF34D399).withValues(alpha: 0.3) : const Color(0xFFA7F3D0))
                                      : colors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                entry.isActive ? 'نشط' : 'معطل',
                                style: CustomAppFontStyle.bold11.copyWith(
                                  color: entry.isActive
                                      ? (context.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                                      : colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),

                        // Action Buttons
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    size: 18, color: colors.primary),
                                tooltip: 'تعديل',
                                onPressed: () {
                                  AddEditMedicalCatalogDialog.show(
                                    context: context,
                                    cubit: _cubit,
                                    kind: widget.kind,
                                    entry: entry,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                tooltip: 'حذف',
                                onPressed: () =>
                                    _confirmDelete(context, entry),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryChip(BuildContext context) {
    final colors = context.themeColors;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showAddCategoryDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              'إضافة تصنيف',
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final colors = dialogCtx.themeColors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderSubtle),
          ),
          title: Text(
            'إضافة تصنيف جديد لـ ${widget.kind.title}',
            style: CustomAppFontStyle.bold16.copyWith(color: colors.textPrimary),
          ),
          content: SizedBox(
            width: 360,
            child: CustomTextFormField(
              controller: controller,
              headerText: 'اسم التصنيف',
              hintText: 'مثال: ${widget.kind.defaultCategories.first}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('cancel'.tr(),
                  style: TextStyle(color: colors.textSecondary)),
            ),
            CustomPushButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              backgroundColor: colors.primary,
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  _cubit.addCategory(text);
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: Text(
                'إضافة',
                style: CustomAppFontStyle.bold13.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

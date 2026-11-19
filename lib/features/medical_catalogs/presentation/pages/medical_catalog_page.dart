import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/enums/request_status_enum.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
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
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد الحذف',
          style: CustomAppFontStyle.bold16.copyWith(color: AppColors.error),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف «${entry.name}» من ${widget.kind.title}؟',
          style: CustomAppFontStyle.regular14.copyWith(color: AppColors.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('cancel'.tr(), style: const TextStyle(color: AppColors.gray71717A)),
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
      ),
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
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0),
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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomAssetImage(
                  path: widget.kind.iconPath,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.kind.title,
                    style: CustomAppFontStyle.bold20.copyWith(
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.kind.subtitle,
                    style: CustomAppFontStyle.regular13.copyWith(
                      color: AppColors.gray71717A,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomPushButton(
            height: 42,
            backgroundColor: AppColors.primary,
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
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'إجمالي ${widget.kind.title}',
            value: state.totalCount.toString(),
            subtitle: 'عنصر مسجل في النظام',
            color: AppColors.primary,
            icon: Icons.folder_copy_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'عناصر نشطة ومتاحة',
            value: state.activeCount.toString(),
            subtitle: 'مفعلة في ملفات المرضى',
            color: const Color(0xFF059669),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'معطلة / غير مستخدمة',
            value: state.inactiveCount.toString(),
            subtitle: 'تم إيقاف تفعيلها مؤقتاً',
            color: AppColors.gray71717A,
            icon: Icons.pause_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CustomAppFontStyle.medium12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: CustomAppFontStyle.bold22.copyWith(
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: CustomAppFontStyle.regular11.copyWith(
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(MedicalCatalogsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grayE2E8F0),
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
                  prefixWidget: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, size: 18, color: AppColors.gray71717A),
                  ),
                  suffixWidget: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
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
                                ? AppColors.primary
                                : AppColors.grayF8FAFC,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grayE2E8F0,
                            ),
                          ),
                          child: Text(
                            category,
                            style: CustomAppFontStyle.medium12.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkText,
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
    if (state.status == RequestStatusEnum.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayE2E8F0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 54, color: AppColors.gray71717A.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text(
                'لا توجد عناصر مطابقة',
                style: CustomAppFontStyle.bold16.copyWith(
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك تغيير كلمات البحث أو إضافة عنصر جديد إلى هذا الدليل',
                style: CustomAppFontStyle.regular13.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              const SizedBox(height: 18),
              CustomPushButton(
                height: 40,
                backgroundColor: AppColors.primary,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayE2E8F0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Table Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.grayF8FAFC,
              child: Row(
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text('الكود',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text('الاسم الطبي / الفحص',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text('التصنيف',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text('ملاحظات وإرشادات',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                  const SizedBox(
                    width: 90,
                    child: Text('الحالة',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Text('الإجراءات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray71717A)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grayE2E8F0),

            // Table Rows
            Expanded(
              child: ListView.separated(
                itemCount: state.entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.grayF1F5F9),
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
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
                              color: AppColors.grayF1F5F9,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.code,
                              style: CustomAppFontStyle.bold11.copyWith(
                                color: AppColors.darkText,
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
                              color: AppColors.darkText,
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
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.category,
                                style: CustomAppFontStyle.medium11.copyWith(
                                  color: AppColors.primary,
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
                              color: AppColors.gray71717A,
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
                                    ? const Color(0xFFECFDF5)
                                    : AppColors.grayF1F5F9,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: entry.isActive
                                      ? const Color(0xFFA7F3D0)
                                      : AppColors.grayE2E8F0,
                                ),
                              ),
                              child: Text(
                                entry.isActive ? 'نشط' : 'معطل',
                                style: CustomAppFontStyle.bold11.copyWith(
                                  color: entry.isActive
                                      ? const Color(0xFF059669)
                                      : AppColors.gray71717A,
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
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.primary),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showAddCategoryDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'إضافة تصنيف',
              style: CustomAppFontStyle.semiBold12.copyWith(
                color: AppColors.primary,
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
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إضافة تصنيف جديد لـ ${widget.kind.title}',
          style: CustomAppFontStyle.bold16.copyWith(color: AppColors.darkText),
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
                style: const TextStyle(color: AppColors.gray71717A)),
          ),
          CustomPushButton(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            backgroundColor: AppColors.primary,
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
      ),
    );
  }
}

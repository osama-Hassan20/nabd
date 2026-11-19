import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';

class SearchableCatalogMultiSelector extends StatefulWidget {
  final String header;
  final String hintText;
  final IconData icon;
  final List<String> selectedItems;
  final List<MedicalCatalogItemModel> catalogItems;
  final ValueChanged<String> onItemAdded;
  final ValueChanged<String> onItemRemoved;
  final Future<void> Function(String name) onAddNewToCatalog;

  const SearchableCatalogMultiSelector({
    super.key,
    required this.header,
    required this.hintText,
    required this.icon,
    required this.selectedItems,
    required this.catalogItems,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.onAddNewToCatalog,
  });

  @override
  State<SearchableCatalogMultiSelector> createState() =>
      _SearchableCatalogMultiSelectorState();
}

class _SearchableCatalogMultiSelectorState
    extends State<SearchableCatalogMultiSelector> {
  final TextEditingController _displayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(SearchableCatalogMultiSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems != widget.selectedItems) {
      _updateDisplayText();
    }
  }

  void _updateDisplayText() {
    if (widget.selectedItems.isEmpty) {
      _displayController.text = '';
    } else {
      _displayController.text =
          'تم اختيار (${widget.selectedItems.length}) عنصر';
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  void _handleOpenPopover() {
    FocusManager.instance.primaryFocus?.unfocus();
    final isDark = context.isDarkMode;

    showPopover(
      context: context,
      bodyBuilder: (popoverContext) => _CatalogPopoverBody(
        catalogItems: widget.catalogItems,
        selectedItems: widget.selectedItems,
        hintText: widget.hintText,
        onToggleItem: (item) {
          if (widget.selectedItems.contains(item)) {
            widget.onItemRemoved(item);
          } else {
            widget.onItemAdded(item);
          }
          setState(() {
            _updateDisplayText();
          });
        },
        onAddNew: (name) async {
          await widget.onAddNewToCatalog(name);
          widget.onItemAdded(name);
          setState(() {
            _updateDisplayText();
          });
        },
      ),
      direction: PopoverDirection.bottom,
      width: 340,
      height: 340,
      arrowHeight: 10,
      arrowWidth: 20,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      barrierColor: Colors.black26,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popover trigger box styled identically to CustomStackSelector
        CustomTextFormField(
          onTap: _handleOpenPopover,
          headerText: widget.header,
          hintText: widget.hintText,
          controller: _displayController,
          isReadOnly: true,
          prefixWidget: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(widget.icon, size: 18, color: AppColors.primary),
          ),
          suffixWidget: const Icon(
            Icons.keyboard_arrow_down_outlined,
            color: AppColors.gray7A828E,
          ),
        ),

        // Selected Chips underneath
        if (widget.selectedItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedItems.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: CustomAppFontStyle.medium12.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        widget.onItemRemoved(name);
                        setState(() {
                          _updateDisplayText();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _CatalogPopoverBody extends StatefulWidget {
  final List<MedicalCatalogItemModel> catalogItems;
  final List<String> selectedItems;
  final String hintText;
  final ValueChanged<String> onToggleItem;
  final Future<void> Function(String name) onAddNew;

  const _CatalogPopoverBody({
    required this.catalogItems,
    required this.selectedItems,
    required this.hintText,
    required this.onToggleItem,
    required this.onAddNew,
  });

  @override
  State<_CatalogPopoverBody> createState() => _CatalogPopoverBodyState();
}

class _CatalogPopoverBodyState extends State<_CatalogPopoverBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Set<String> _localSelected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _localSelected = Set<String>.from(widget.selectedItems);
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.catalogItems.where((item) {
      if (item.name == null) return false;
      if (_query.isEmpty) return true;
      return ArabicTextHelper.containsNormalized(item.name!, _query);
    }).toList();

    final hasExactMatch = _query.isNotEmpty &&
        filtered.any(
          (item) =>
              ArabicTextHelper.normalize(item.name) ==
              ArabicTextHelper.normalize(_query),
        );

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(10),
          child: CustomTextFormField(
            controller: _searchController,
            hintText: 'بحث في القائمة...',
            prefixWidget: const Icon(Icons.search, size: 18, color: AppColors.gray71717A),
            suffixWidget: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.gray71717A),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
        const Divider(height: 1, color: AppColors.grayE2E8F0),

        // Items list
        Expanded(
          child: filtered.isEmpty && !hasExactMatch && _query.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'لا توجد عناصر مطابقة لـ "$_query"',
                      style: CustomAppFontStyle.regular13.copyWith(
                        color: AppColors.gray71717A,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final itemName = item.name ?? '';
                    final isSelected = _localSelected.contains(itemName);

                    return InkWell(
                      onTap: () {
                        if (isSelected) {
                          _localSelected.remove(itemName);
                        } else {
                          _localSelected.add(itemName);
                        }
                        widget.onToggleItem(itemName);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight.withValues(alpha: 0.35)
                              : Colors.transparent,
                          border:  Border(
                            bottom: BorderSide(
                              color: AppColors.grayF1F5F9,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray71717A,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                itemName,
                                style: CustomAppFontStyle.medium13.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.darkText,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Add new item if searched & not present
        if (_query.isNotEmpty && !hasExactMatch) ...[
          const Divider(height: 1, color: AppColors.grayE2E8F0),
          InkWell(
            onTap: () async {
              await widget.onAddNew(_query);
              _searchController.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: AppColors.primaryLight.withValues(alpha: 0.25),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إضافة «$_query» كعنصر جديد',
                      style: CustomAppFontStyle.semiBold13.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Bottom Done Button
        const Divider(height: 1, color: AppColors.grayE2E8F0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المحدد: ${_localSelected.length}',
                style: CustomAppFontStyle.medium12.copyWith(
                  color: AppColors.gray71717A,
                ),
              ),
              CustomPushButton(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                backgroundColor: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'تم',
                  style: CustomAppFontStyle.semiBold13.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

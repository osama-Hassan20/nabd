import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/helpers/arabic_text_helper.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/features/patients/data/models/medical_catalog_item_model.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectItem(String name) {
    if (!widget.selectedItems.contains(name)) {
      widget.onItemAdded(name);
    }
    _searchController.clear();
    _focusNode.unfocus();
  }

  Future<void> _addNew(String name) async {
    await widget.onAddNewToCatalog(name);
    _searchController.clear();
    _focusNode.unfocus();
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

    final showDropdown = _isSearching && _query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(widget.icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              widget.header,
              style: CustomAppFontStyle.semiBold14.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Search Input Field
        CustomTextFormField(
          controller: _searchController,
          focusNode: _focusNode,
          hintText: widget.hintText,
          prefixWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, size: 18, color: AppColors.gray71717A),
          ),
          suffixWidget: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.gray71717A),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),

        // Search Suggestions Dropdown
        if (showDropdown) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grayE2E8F0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (filtered.isEmpty) ...[
                  // No results: show Add button immediately
                  _buildAddNewTile(_query),
                ] else ...[
                  ...filtered.map((item) {
                    final isAlreadySelected =
                        widget.selectedItems.contains(item.name);
                    return InkWell(
                      onTap: () {
                        if (item.name != null) {
                          _selectItem(item.name!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        color: isAlreadySelected
                            ? AppColors.primaryLight.withValues(alpha: 0.4)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name ?? '',
                                style: CustomAppFontStyle.medium13.copyWith(
                                  color: isAlreadySelected
                                      ? AppColors.primary
                                      : AppColors.darkText,
                                ),
                              ),
                            ),
                            if (isAlreadySelected)
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (!hasExactMatch) ...[
                    const Divider(height: 1, color: AppColors.grayE2E8F0),
                    _buildAddNewTile(_query),
                  ],
                ],
              ],
            ),
          ),
        ],

        // Selected Chips
        if (widget.selectedItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedItems.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
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
                      onTap: () => widget.onItemRemoved(name),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
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

  Widget _buildAddNewTile(String name) {
    return InkWell(
      onTap: () => _addNew(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${'add'.tr()} «$name»',
                style: CustomAppFontStyle.semiBold13.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


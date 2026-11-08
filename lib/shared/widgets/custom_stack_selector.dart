import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:popover/popover.dart';

class CustomStackSelector<T> extends StatefulWidget {
  const CustomStackSelector({
    super.key,
    required this.controller,
    required this.list,
    required this.itemAsString,
    this.changeValue,
    this.header,
    this.hintText,
    this.itemValidator,
    this.fillDisableColor,
    this.isLoadingMore = false,
    this.scrollController,
    this.onTap,
    this.prefixWidget,
    this.enableSearch = false,
    this.besideHeader,
    this.itemBuilder,
    this.displayStringForController,
    this.actionHeaderWidget,
    this.closeOnSelect = true,
    this.emptySearchBuilder,
  });

  final TextEditingController? controller;
  final List<T> list;
  final String Function(T) itemAsString;
  final void Function(T)? changeValue;
  final String? header;
  final String? hintText;
  final String? Function(String?)? itemValidator;
  final Color? fillDisableColor;
  final bool isLoadingMore;
  final ScrollController? scrollController;
  final VoidCallback? onTap;
  final Widget? prefixWidget;
  final bool enableSearch;
  final Widget? besideHeader;
  final Widget Function(BuildContext, T)? itemBuilder;
  final String Function(T)? displayStringForController;
  final Widget? actionHeaderWidget;
  final bool closeOnSelect;
  final Widget Function(BuildContext context, String query, VoidCallback close)?
      emptySearchBuilder;

  @override
  State<CustomStackSelector<T>> createState() => _CustomStackSelectorState<T>();
}

class _CustomStackSelectorState<T> extends State<CustomStackSelector<T>> {
  late ValueNotifier<_SelectorData<T>> _dataNotifier;
  late ScrollController _scrollController;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _dataNotifier = ValueNotifier(
      _SelectorData(widget.list, widget.isLoadingMore, _revision),
    );
  }

  @override
  void didUpdateWidget(CustomStackSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revision++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dataNotifier.value = _SelectorData(
          widget.list,
          widget.isLoadingMore,
          _revision,
        );
      }
    });
  }

  @override
  void dispose() {
    _dataNotifier.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();

    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (widget.list.isNotEmpty || widget.isLoadingMore) {
      final isDark = context.isDarkMode;
      final baseHeight = widget.enableSearch ? 300.0 : 250.0;
      final extraHeight = !widget.closeOnSelect ? 50.0 : 0.0;
      showPopover(
        context: context,
        bodyBuilder: (context) => _buildPopoverContent(),
        direction: PopoverDirection.bottom,
        width: 320,
        height: baseHeight + extraHeight,
        arrowHeight: 10,
        arrowWidth: 20,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        barrierColor: Colors.black26,
      );
    }
  }

  Widget _buildPopoverContent() {
    return ValueListenableBuilder<_SelectorData<T>>(
      valueListenable: _dataNotifier,
      builder: (context, data, _) {
        return _PopoverContentBody<T>(
          list: data.list,
          isLoading: data.isLoading,
          itemAsString: widget.itemAsString,
          changeValue: widget.changeValue,
          controller: widget.controller,
          enableSearch: widget.enableSearch,
          scrollController: _scrollController,
          itemBuilder: widget.itemBuilder,
          displayStringForController: widget.displayStringForController,
          actionHeaderWidget: widget.actionHeaderWidget,
          closeOnSelect: widget.closeOnSelect,
          emptySearchBuilder: widget.emptySearchBuilder,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      onTap: _handleTap,
      prefixWidget: widget.prefixWidget,
      fillDisableColor: widget.fillDisableColor,
      controller: widget.controller,
      headerText: widget.header,
      besideHeader: widget.besideHeader,
      hintText: widget.hintText,
      validator: widget.itemValidator,
      isReadOnly: true,
      disabledBorder: InputBorder.none,
      focusFillColor: widget.fillDisableColor,
      suffixWidget: const Icon(
        Icons.keyboard_arrow_down_outlined,
        color: AppColors.gray7A828E,
      ),
    );
  }
}

class _SelectorData<T> {
  final List<T> list;
  final bool isLoading;
  final int revision;

  _SelectorData(this.list, this.isLoading, [this.revision = 0]);
}

class _PopoverContentBody<T> extends StatefulWidget {
  final List<T> list;
  final bool isLoading;
  final String Function(T) itemAsString;
  final void Function(T)? changeValue;
  final TextEditingController? controller;
  final bool enableSearch;
  final ScrollController scrollController;
  final Widget Function(BuildContext, T)? itemBuilder;
  final String Function(T)? displayStringForController;
  final Widget? actionHeaderWidget;
  final bool closeOnSelect;
  final Widget Function(BuildContext context, String query, VoidCallback close)?
      emptySearchBuilder;

  const _PopoverContentBody({
    required this.list,
    required this.isLoading,
    required this.itemAsString,
    this.changeValue,
    this.controller,
    required this.enableSearch,
    required this.scrollController,
    this.itemBuilder,
    this.displayStringForController,
    this.actionHeaderWidget,
    this.closeOnSelect = true,
    this.emptySearchBuilder,
  });

  @override
  State<_PopoverContentBody<T>> createState() => _PopoverContentBodyState<T>();
}

class _PopoverContentBodyState<T> extends State<_PopoverContentBody<T>> {
  late List<T> _filteredList;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredList = widget.list;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(_PopoverContentBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.list != oldWidget.list) {
      _filterList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterList();
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredList = widget.list;
      } else {
        _filteredList = widget.list.where((item) {
          final str = widget.itemAsString(item).toLowerCase();
          return str.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      children: [
        if (widget.enableSearch)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextFormField(
              controller: _searchController,
              hintText: 'بحث...',
              prefixWidget: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: CustomAssetImage(
                  path: AppIcons.search,
                  width: 18,
                  height: 18,
                  color: AppColors.gray71717A,
                ),
              ),
            ),
          ),
        if (widget.actionHeaderWidget != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: widget.actionHeaderWidget!,
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
          ),
        ],
        if (_filteredList.isEmpty && !widget.isLoading)
          Expanded(
            child: widget.emptySearchBuilder != null
                ? widget.emptySearchBuilder!(
                    context,
                    _searchController.text,
                    () => Navigator.of(context).pop(),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'no_search_results'.tr(),
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: isDark ? AppColors.grayE2E8F0 : AppColors.gray71717A,
                        ),
                      ),
                    ),
                  ),
          )
        else
          Expanded(
            child: Scrollbar(
              controller: widget.scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                controller: widget.scrollController,
                itemCount: _filteredList.length + (widget.isLoading ? 1 : 0),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
                ),
                itemBuilder: (context, index) {
                  if (index == _filteredList.length) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  }
                  final item = _filteredList[index];
                  return InkWell(
                    onTap: () {
                      if (widget.closeOnSelect) {
                        final text = widget.displayStringForController != null
                            ? widget.displayStringForController!(item)
                            : widget.itemAsString(item);
                        widget.controller?.text = text;
                        widget.changeValue?.call(item);
                        Navigator.of(context).pop();
                      } else {
                        widget.changeValue?.call(item);
                        setState(() {});
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: widget.itemBuilder != null
                          ? widget.itemBuilder!(context, item)
                          : Text(
                              widget.itemAsString(item),
                              style: CustomAppFontStyle.regular14.copyWith(
                                color: isDark ? AppColors.white : AppColors.darkText,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (!widget.closeOnSelect) ...[
          Divider(
            height: 1,
            color: isDark ? AppColors.gray334155 : AppColors.grayE2E8F0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomPushButton(
                  height: 32,
                  backgroundColor: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'done'.tr(),
                        style: CustomAppFontStyle.semiBold12.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

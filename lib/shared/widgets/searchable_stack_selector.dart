import 'dart:async';

import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

/// A searchable, paginated dropdown selector built on top of [CustomTextFormField].
///
/// **Key features:**
/// - Built-in debounced search — just pass [onSearch] and the widget handles
///   the timer + "text didn't change / is empty" guard for you.
/// - Separate [isLoading] flag shows a spinner at the bottom while results load.
/// - The list updates reactively via [ValueNotifier], so the open popover
///   reflects new data without closing/re-opening.
/// - Scroll controller support for infinite-scroll / pagination.
///
/// **Minimal usage:**
/// ```dart
/// CustomStackSelectorPro<City>(
///   controller: _cityController,
///   list: _cities,
///   itemAsString: (c) => c.name,
///   changeValue: (c) => setState(() => _selectedCity = c),
///   onSearch: (query) async {
///     final results = await _api.searchCities(query);
///     setState(() => _cities = results);
///   },
/// )
/// ```
class CustomSearchableSelector<T> extends StatefulWidget {
  const CustomSearchableSelector({
    super.key,
    required this.controller,
    required this.list,
    required this.itemAsString,
    this.changeValue,
    this.header,
    this.hintText,
    this.itemValidator,
    this.fillDisableColor,
    this.isLoading = false,
    this.scrollController,
    this.onTap,
    this.prefixWidget,
    // ── Search ──────────────────────────────────────────────────────────────
    this.onSearch,
    this.searchHintText = 'بحث...',
    this.debounceDuration = const Duration(milliseconds: 400),
    // ── Popover dimensions ──────────────────────────────────────────────────
    this.popoverWidth = 300,
    this.popoverHeight = 300,
    this.isEnabled = true,
    this.searchController,
  });

  /// Text controller that holds the *selected* value label.
  final TextEditingController? controller;

  /// Current list of items to display (can change while the popover is open).
  final List<T> list;

  /// Converts an item to its display string.
  final String Function(T) itemAsString;

  /// Called when the user taps an item.
  final void Function(T)? changeValue;

  final String? header;
  final String? hintText;
  final String? Function(String?)? itemValidator;
  final Color? fillDisableColor;

  /// When `true` a [CupertinoActivityIndicator] row is appended to the list.
  final bool isLoading;

  final ScrollController? scrollController;

  /// Extra tap callback (e.g. to trigger an initial data fetch).
  final VoidCallback? onTap;
  final Widget? prefixWidget;

  // ── Search ────────────────────────────────────────────────────────────────

  /// Called with the debounced, non-empty search query.
  /// The parent should update [list] (and [isLoading]) in response.
  /// If `null`, the search bar is hidden and the widget behaves like the
  /// original [CustomStackSelector].
  final Future<void> Function(String query)? onSearch;

  /// Placeholder text shown inside the search field.
  final String searchHintText;

  /// How long to wait after the user stops typing before calling [onSearch].
  final Duration debounceDuration;

  final double popoverWidth;
  final double popoverHeight;
  final bool isEnabled;

  /// External search controller to manage search text from outside.
  final TextEditingController? searchController;

  @override
  State<CustomSearchableSelector<T>> createState() =>
      _CustomSearchableSelectorState<T>();
}

class _CustomSearchableSelectorState<T>
    extends State<CustomSearchableSelector<T>> {
  // ── Reactive data shared with the open popover ────────────────────────────
  late final ValueNotifier<_SelectorData<T>> _dataNotifier;

  // ── Search debounce ───────────────────────────────────────────────────────
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _dataNotifier = ValueNotifier(_SelectorData(widget.list, widget.isLoading));
  }

  @override
  void didUpdateWidget(CustomSearchableSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Push update into the popover without closing it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dataNotifier.value = _SelectorData(widget.list, widget.isLoading);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    _dataNotifier.dispose();
    super.dispose();
  }

  // ── Search logic ──────────────────────────────────────────────────────────

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(widget.debounceDuration, () {
      // Guard: text changed again while timer was running
      if (_searchController.text != text) return;
      // Guard: same query as last time
      if (text == _lastQuery) return;

      _lastQuery = text;
      widget.onSearch?.call(text.trim());
    });
  }

  // ── Popover ───────────────────────────────────────────────────────────────

  void _handleTap() {
    widget.onTap?.call();
    FocusManager.instance.primaryFocus?.unfocus();

    // Reset search state each time the popover opens.
    _searchController.clear();
    _lastQuery = '';
    _debounceTimer?.cancel();

    showPopover(
      context: context,
      bodyBuilder: (ctx) => _PopoverContent<T>(
        dataNotifier: _dataNotifier,
        searchController: _searchController,
        scrollController: widget.scrollController,
        itemAsString: widget.itemAsString,
        onSearch: widget.onSearch != null ? _onSearchChanged : null,
        searchHintText: widget.searchHintText,
        onItemTap: (item) {
          widget.controller?.text = widget.itemAsString(item);
          widget.changeValue?.call(item);
          Navigator.of(ctx).pop();
        },
      ),
      direction: PopoverDirection.bottom,
      width: widget.popoverWidth,
      height: widget.popoverHeight,
      arrowHeight: 10,
      arrowWidth: 20,
      backgroundColor: AppColors.white,
      barrierColor: Colors.black12,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      onTap: widget.isEnabled ? _handleTap : null,
      isEnabled: widget.isEnabled,
      prefixWidget: widget.prefixWidget,
      fillDisableColor: widget.fillDisableColor,
      controller: widget.controller,
      headerText: widget.header,
      hintText: widget.hintText,
      validator: widget.itemValidator,
      isReadOnly: true,
      disabledBorder: InputBorder.none,
      focusFillColor: widget.fillDisableColor,
      suffixWidget: const Icon(
        Icons.keyboard_arrow_down_outlined,
        color: AppColors.gray6C6C6C,
      ),
    );
  }
}

// ── Popover content (extracted for cleanliness) ───────────────────────────────

class _PopoverContent<T> extends StatelessWidget {
  const _PopoverContent({
    required this.dataNotifier,
    required this.searchController,
    required this.scrollController,
    required this.itemAsString,
    required this.onItemTap,
    required this.searchHintText,
    this.onSearch,
  });

  final ValueNotifier<_SelectorData<T>> dataNotifier;
  final TextEditingController searchController;
  final ScrollController? scrollController;
  final String Function(T) itemAsString;
  final void Function(T) onItemTap;
  final void Function(String)? onSearch;
  final String searchHintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar (only when onSearch is wired up) ───────────────────
        if (onSearch != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: CustomTextFormField(
              controller: searchController,
              autofocus: true,
              onChanged: (val) => onSearch!(val ?? ''),
              hintText: searchHintText,
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
          const Divider(height: 1),
        ],

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: ValueListenableBuilder<_SelectorData<T>>(
            valueListenable: dataNotifier,
            builder: (context, data, _) {
              final list = data.list;
              final isLoading = data.isLoading;

              // Full-area spinner when list is empty and still loading.
              if (isLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }

              // Empty state (not loading, nothing found).
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'لا يوجد نتائج',
                    style: CustomAppFontStyle.regular16.copyWith(
                      color: AppColors.gray6C6C6C,
                    ),
                  ),
                );
              }

              return Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  controller: scrollController,
                  // +1 for optional loading row at the bottom.
                  itemCount: list.length + (isLoading ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // Bottom loading row (pagination / load-more).
                    if (index == list.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }

                    final item = list[index];
                    return InkWell(
                      onTap: () => onItemTap(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          itemAsString(item),
                          style: CustomAppFontStyle.regular16.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Internal state model ──────────────────────────────────────────────────────

class _SelectorData<T> {
  const _SelectorData(this.list, this.isLoading);

  final List<T> list;
  final bool isLoading;
}

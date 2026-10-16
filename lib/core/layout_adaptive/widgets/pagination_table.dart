import 'package:eyadty/core/layout_adaptive/widgets/custom_text.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/shared/widgets/custom_text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

class CustomPaginationTable extends StatefulWidget {
  const CustomPaginationTable({
    super.key,
    required this.onTapNext,
    required this.onTapPrevious,
    required this.onTapNumber,
    required this.pagesCount,
    required this.currentPage,
  });

  final void Function() onTapNext;
  final void Function() onTapPrevious;
  final void Function(int number) onTapNumber;
  final int pagesCount;
  final int currentPage;

  @override
  State<CustomPaginationTable> createState() => _CustomPaginationTableState();
}

class _CustomPaginationTableState extends State<CustomPaginationTable> {
  List<int> buildPages({
    required int pagesCount,
    required int currentPage,
    int delta = 2,
  }) {
    if (pagesCount <= 8) {
      return List.generate(pagesCount, (i) => i + 1);
    }

    final List<int> pages = [];
    pages.add(1);

    final int start = (currentPage - delta).clamp(2, pagesCount - 1);
    final int end = (currentPage + delta).clamp(2, pagesCount - 1);

    if (start > 2) {
      pages.add(-1); // ellipsis
    }

    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    if (end < pagesCount - 1) {
      pages.add(-1); // ellipsis
    }

    pages.add(pagesCount);
    return pages;
  }

  void _showPageJumpDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(isSelectable: false, "الانتقال إلى الصفحة"),
            SizedBox(width: 20),
            IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.close, color: AppColors.darkBackground),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextFormField(
              controller: controller,
              hintText: "أدخل رقم الصفحة (1-${widget.pagesCount})",
              onFieldSubmitted: (value) {
                final pageNum = int.tryParse(controller.text);
                if (pageNum != null &&
                    pageNum >= 1 &&
                    pageNum <= widget.pagesCount) {
                  Navigator.pop(context);
                  widget.onTapNumber(pageNum);
                }
              },
              validator: (value) {
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(
              isSelectable: false,
              "cancel".tr(),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.red,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenMuted,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final pageNum = int.tryParse(controller.text);
              if (pageNum != null &&
                  pageNum >= 1 &&
                  pageNum <= widget.pagesCount) {
                Navigator.pop(context);
                widget.onTapNumber(pageNum);
              }
            },
            child: const CustomText(
              isSelectable: false,
              "انتقال",
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    final pagesToDisplay = buildPages(
      pagesCount: widget.pagesCount,
      currentPage: widget.currentPage,
    );

    if (widget.pagesCount == 0) {
      return const SizedBox.shrink();
    }

    final Color inactiveColor = isDark
        ? AppColors.gray334155.withValues(alpha: 0.4)
        : AppColors.gray334155.withValues(alpha: 0.1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // PREVIOUS BUTTON (hidden on first page)
          if (widget.currentPage > 1)
            InkWell(
              onTap: widget.onTapPrevious,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: inactiveColor),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_outlined,
                    color: isDark ? AppColors.white : AppColors.gray334155,
                    size: 18,
                  ),
                ),
              ),
            ),
          if (widget.currentPage > 1) const SizedBox(width: 20),

          // Jump to page button (for large page counts)
          if (widget.pagesCount > 20)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: _showPageJumpDialog,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: inactiveColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: inactiveColor),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        AppIcons.search,
                        colorFilter: ColorFilter.mode(
                          AppColors.gray334155,
                          BlendMode.srcIn,
                        ),
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        isSelectable: false,
                        "الانتقال",
                        color: AppColors.gray334155,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // PAGE NUMBERS
          ...pagesToDisplay.map((page) {
            if (page == -1) {
              // Ellipsis start
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray334155,
                  ),
                ),
              );
            } else {
              // Actual page number
              return TablePaginationContainer(
                onTap: () {
                  if (page == widget.currentPage) return;
                  widget.onTapNumber(page);
                },
                number: "$page",
                selected: widget.currentPage == page,
              );
            }
          }),

          const SizedBox(width: 20),

          // NEXT BUTTON (hidden on last page)
          if (widget.currentPage < widget.pagesCount)
            InkWell(
              onTap: widget.onTapNext,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: inactiveColor),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: isDark ? AppColors.white : AppColors.gray334155,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TablePaginationContainer extends StatelessWidget {
  const TablePaginationContainer({
    super.key,
    required this.onTap,
    required this.number,
    this.selected = false,
  });

  final Function()? onTap;
  final String number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    final Color inactiveColor = isDark
        ? AppColors.gray334155.withValues(alpha: 0.4)
        : AppColors.gray334155.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: selected ? null : inactiveColor,
            gradient: selected ? AppGradient.greenGradient : null,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.transparent : inactiveColor,
              width: 1.5,
            ),
          ),
          child: Center(
            child: FittedBox(
              child: CustomText(
                isSelectable: false,
                " $number ",
                color: selected
                    ? AppColors.white
                    : (isDark ? AppColors.white : AppColors.gray334155),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

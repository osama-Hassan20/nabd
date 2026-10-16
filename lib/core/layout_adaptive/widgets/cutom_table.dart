import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/shimmer/custom_shimmer_container.dart';
import 'package:flutter/material.dart';

class CustomTable extends StatelessWidget {
  const CustomTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.minWidth = 1000,
    this.backgroundColor,
    this.headerColor = AppColors.grayf4,
  });

  /// The titles for the top of the table.
  final List<String> headers;

  /// The data rows. Each inner list represents a row and must have the same length as [headers].
  final List<List<Widget>> rows;

  /// Custom widths for columns. Example: `{0: FixedColumnWidth(100)}`
  final Map<int, TableColumnWidth>? columnWidths;

  /// Minimum width of the table before it becomes scrollable.
  final double minWidth;

  /// Optional background color for the entire table.
  final Color? backgroundColor;

  /// Optional color for the header row background.
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Validate that each row has the same number of elements as headers
    for (var row in rows) {
      assert(
        row.length == headers.length,
        'Each row must have exactly ${headers.length} children to match the headers.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomContainer(
          backGroundColor: isDark
              ? AppColors.darkBackground.withValues(alpha: .4)
              : AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > minWidth
                    ? constraints.maxWidth
                    : minWidth,
              ),
              child: Table(
                columnWidths: columnWidths,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header Row
                  TableRow(
                    decoration: BoxDecoration(color: headerColor),
                    children: headers.map((title) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Center(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomAppFontStyle.regular14.copyWith(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.gray71717A,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Data Rows
                  ...rows.map((rowWidgets) {
                    // final int index = rows.indexOf(rowWidgets);
                    // final isLast = index == rows.length - 1;

                    return TableRow(
                      decoration: BoxDecoration(
                        // border: Border(
                        //   bottom: isLast
                        //       ? BorderSide.none
                        //       : BorderSide(
                        //           color: isDark
                        //               ? AppColors.gray46
                        //               : AppColors.blueBB.withValues(alpha: .2),
                        //         ),
                        // ),
                      ),
                      children: rowWidgets.map((cellWidget) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: cellWidget,
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomTableShimmer extends StatelessWidget {
  const CustomTableShimmer({
    super.key,
    required this.headers,
    this.rowCount = 7,
    this.columnWidths,
    this.minWidth = 1000,
  });

  final List<String> headers;
  final int rowCount;
  final Map<int, TableColumnWidth>? columnWidths;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    return CustomTable(
      headers: headers,
      columnWidths: columnWidths,
      minWidth: minWidth,
      backgroundColor: isDark
          ? AppColors.darkBackground.withValues(alpha: .4)
          : AppColors.white,
      rows: List.generate(
        rowCount,
        (index) => List.generate(
          headers.length,
          (colIndex) => const CustomShimmerContainer(
            height: 20,
            width: double.infinity,
            borderRadius: 4,
          ),
        ),
      ),
    );
  }
}

import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/shimmer/custom_shimmer_container.dart';
import 'package:flutter/material.dart';

class CustomTable extends StatefulWidget {
  const CustomTable({
    super.key,
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.minWidth = 1000,
    this.backgroundColor,
    this.headerColor,
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
  State<CustomTable> createState() => _CustomTableState();
}

class _CustomTableState extends State<CustomTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;

    for (var row in widget.rows) {
      assert(
        row.length == widget.headers.length,
        'Each row must have exactly ${widget.headers.length} children to match the headers.',
      );
    }

    final effectiveHeaderColor =
        widget.headerColor ?? colors.tableHeaderBackground;
    final cardBg = widget.backgroundColor ?? colors.cardBackground;

    return LayoutBuilder(
      builder: (context, constraints) {
        final needsScroll = constraints.maxWidth < widget.minWidth;
        final tableWidget = ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth > widget.minWidth
                ? constraints.maxWidth
                : widget.minWidth,
            maxWidth: constraints.maxWidth > widget.minWidth
                ? constraints.maxWidth
                : widget.minWidth,
          ),
          child: Table(
            columnWidths: widget.columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: effectiveHeaderColor),
                children: widget.headers.map((title) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Center(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CustomAppFontStyle.bold13.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...widget.rows.asMap().entries.map((entry) {
                final int index = entry.key;
                final List<Widget> rowWidgets = entry.value;
                final isLast = index == widget.rows.length - 1;

                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : BorderSide(
                              color: colors.borderSubtle,
                              width: 1,
                            ),
                    ),
                  ),
                  children: rowWidgets.map((cellWidget) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: colors.textPrimary),
                        child: cellWidget,
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        );

        final scrollable = Scrollbar(
          controller: _horizontalController,
          thumbVisibility: needsScroll,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: tableWidget,
          ),
        );

        return CustomContainer(
          backGroundColor: cardBg,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: needsScroll
                ? Stack(
                    children: [
                      scrollable,
                      Positioned.directional(
                        textDirection: Directionality.of(context),
                        top: 0,
                        bottom: 0,
                        end: 0,
                        width: 24,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: AlignmentDirectional.centerStart
                                    .resolve(Directionality.of(context)),
                                end: AlignmentDirectional.centerEnd
                                    .resolve(Directionality.of(context)),
                                colors: [
                                  cardBg.withValues(alpha: 0.0),
                                  cardBg.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : scrollable,
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
    final colors = context.themeColors;
    return CustomTable(
      headers: headers,
      columnWidths: columnWidths,
      minWidth: minWidth,
      backgroundColor: colors.cardBackground,
      headerColor: colors.tableHeaderBackground,
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

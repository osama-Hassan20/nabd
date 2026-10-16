import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/app_gradient.dart';
import 'package:purexo/shared/widgets/custom_container.dart';
import 'package:flutter/material.dart';

class EnhancedTable extends StatelessWidget {
  const EnhancedTable({
    super.key,
    required this.isDark,
    required this.header,
    required this.rows,
    this.minWidth = 900,
    this.rowDividerColor,
    this.boxShadow,
  });

  final bool isDark;

  /// The header widget — rendered at full (possibly scrolled) width.
  final Widget header;

  /// Each element is one data row widget.
  final List<Widget> rows;

  /// Minimum width before horizontal scrolling kicks in.
  final double minWidth;

  /// Divider color between rows. Defaults to theme-appropriate gray.
  final Color? rowDividerColor;

  /// Optional shadow override for the outer card.
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        rowDividerColor ??
        (isDark
            ? AppColors.gray334155.withValues(alpha: .4)
            : AppColors.gray334155.withValues(alpha: .6));

    return CustomContainer(
      padding: EdgeInsets.zero,
      enableShadow: boxShadow == null,
      boxShadow:
          boxShadow ??
          [
            BoxShadow(
              color: isDark
                  ? AppColors.black.withValues(alpha: .3)
                  : AppColors.gray334155.withValues(alpha: .07),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth > minWidth
                ? constraints.maxWidth
                : minWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    header,
                    const Divider(height: 1),
                    // ── Rows ───────────────────────────────────────────────
                    ...rows.asMap().entries.map((entry) {
                      final isLast = entry.key == rows.length - 1;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          entry.value,
                          if (!isLast) Divider(height: 1, color: dividerColor),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EnhancedTableHeader
//
// Reusable gradient header container. Pass your Row of column labels as child.
// ─────────────────────────────────────────────────────────────────────────────
class EnhancedTableHeader extends StatelessWidget {
  const EnhancedTableHeader({
    super.key,
    required this.isDark,
    required this.child,
    this.padding,
  });

  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(gradient: AppGradient.greenGradient),
      child: child,
    );
  }
}

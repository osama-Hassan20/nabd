import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breadcrumb item model
class BreadcrumbItem {
  final String label;
  final String? route;
  final bool isActive;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.isActive = false,
  });
}

/// Breadcrumb navigation widget
class CustomBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Widget? separator;

  const CustomBreadcrumb({super.key, required this.items, this.separator});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _buildBreadcrumbItems(context),
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context) {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      // Add breadcrumb item
      widgets.add(
        _BreadcrumbItemWidget(
          item: item,
          isLast: isLast,
          onTap: item.route != null && !isLast
              ? () => context.go(item.route!)
              : null,
        ),
      );

      // Add separator (except for last item)
      if (!isLast) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child:
                separator ??
                Icon(Icons.chevron_right, size: 18, color: AppColors.grayMuted),
          ),
        );
      }
    }

    return widgets;
  }
}

class _BreadcrumbItemWidget extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isLast;
  final VoidCallback? onTap;

  const _BreadcrumbItemWidget({
    required this.item,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = onTap != null;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap != null
            ? () {
                onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            item.label,
            style: CustomAppFontStyle.regular14.copyWith(
              color: isLast ? AppColors.black : AppColors.grayMuted,
              fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
              decoration: isClickable ? TextDecoration.underline : null,
              decorationColor: AppColors.grayMuted,
            ),
          ),
        ),
      ),
    );
  }
}


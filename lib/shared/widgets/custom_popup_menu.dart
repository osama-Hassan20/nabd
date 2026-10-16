import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:flutter/material.dart';

class CustomPopupActionItem {
  final String label;
  final String icon;
  final VoidCallback? onTap;
  final Color? color;
  final dynamic value;

  CustomPopupActionItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.color,
    this.value,
  });
}

class CustomPopupMenu extends StatelessWidget {
  final List<CustomPopupActionItem> items;
  final Widget? trigger;
  final void Function(dynamic)? onSelected;

  const CustomPopupMenu({
    super.key,
    required this.items,
    this.trigger,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      onSelected: (value) {
        onSelected?.call(value);

        // Find the item that matches the value. 
        // If the item doesn't have a value, we used its index in itemBuilder.
        CustomPopupActionItem? selectedItem;
        for (int i = 0; i < items.length; i++) {
          final itemValue = items[i].value ?? i;
          if (itemValue == value) {
            selectedItem = items[i];
            break;
          }
        }

        selectedItem?.onTap?.call();
      },
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        final List<PopupMenuEntry<dynamic>> menuEntries = [];
        for (int i = 0; i < items.length; i++) {
          menuEntries.add(
            PopupMenuItem(
              value: items[i].value ?? i,
              child: Row(
                spacing: 8,
                children: [
                  CustomAssetImage(
                    path: items[i].icon,
                  //  color: items[i].color ?? AppColors.gray334155,
                  ),
                  Text(
                    items[i].label,
                    style: CustomAppFontStyle.regular14.copyWith(
                      color: items[i].color ?? AppColors.gray334155,
                    ),
                  ),
                ],
              ),
            ),
          );
          if (i < items.length - 1) {
            menuEntries.add(
              const PopupMenuDivider(height: 1, color: AppColors.grayE2E8F0),
            );
          }
        }
        return menuEntries;
      },
      child: trigger ??
          const Icon(
            Icons.more_vert_rounded,
            color: AppColors.primary,
          ),
    );
  }
}

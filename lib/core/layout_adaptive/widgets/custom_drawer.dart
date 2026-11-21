import 'package:flutter/material.dart';
import 'package:eyadty/core/layout_adaptive/widgets/custom_side_bar.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({
    super.key,
    required this.scaffoldKey,
    required this.items,
    this.currentPath,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<SideBarItemModel> items;
  final String? currentPath;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: CustomSideBarList(
          isMobile: false,
          isTablet: false,
          items: items,
          scaffoldKey: scaffoldKey,
          onToggle: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

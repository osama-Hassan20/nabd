import 'package:eyadty/core/layout_adaptive/widgets/customer_action_button.dart';
import 'package:eyadty/core/routing/routes.dart';
import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/app_gradient.dart';
import 'package:eyadty/core/utils/theme/app_icons.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_asset_image.dart';
import 'package:eyadty/shared/widgets/custom_list_tile.dart';
import 'package:eyadty/shared/widgets/custom_logout_sheet.dart';
import 'package:eyadty/shared/cubit/basic_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CustomSideBarList extends StatelessWidget {
  const CustomSideBarList({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.items,
    this.enableLogout = true,
    this.currentPath,
    required this.onToggle,
    required this.scaffoldKey,
  });

  final List<SideBarItemModel> items;
  final bool isMobile;
  final bool isTablet;
  final bool enableLogout;
  final String? currentPath;
  final VoidCallback? onToggle;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final effectivePath = currentPath ?? GoRouterState.of(context).uri.path;
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isMobile)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GradientText(
                            text: "عيا",
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondary,
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            style: CustomAppFontStyle.bold14.copyWith(
                              fontSize: isTablet ? 12 : 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          _GradientText(
                            text: "دتي",
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primary],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            style: CustomAppFontStyle.bold14.copyWith(
                              fontSize: isTablet ? 12 : 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: isTablet ? 32 : 40,
                    minHeight: isTablet ? 32 : 40,
                  ),
                  icon: const CustomAssetImage(path: AppIcons.drawer),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<BasicCubit, BasicState>(
              builder: (context, state) {
                return ListView.builder(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  // separatorBuilder: (context, index) =>
                  //     const SizedBox(height: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    // --- Permission Check ---
                    if (item.requiredPermissions != null &&
                        item.requiredPermissions!.isNotEmpty) {
                      final hasAny = item.requiredPermissions!.any(
                        (p) => context.read<BasicCubit>().hasPermission(p),
                      );
                      if (!hasAny) {
                        return const SizedBox.shrink();
                      }
                    }

                    final isSelected =
                        item.routePath != null &&
                        effectivePath.startsWith(item.routePath!) &&
                        (item.routePath == '/' ? effectivePath == '/' : true);

                    if (isTablet) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomActionButton(
                          borderRadius: 14,
                          icon: isSelected
                              ? item.selectedIconPath
                              : item.iconPath,
                          onPressed: item.onTap,
                          tooltip: item.title,
                          gradient: isSelected
                              ? AppGradient.greenGradient
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          iconColor: isSelected
                              ? AppColors.white
                              : (isDark
                                    ? AppColors.white
                                    : AppColors.gray7A828E),
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomLeft: Radius.circular(2),
                        ),
                        gradient: isSelected ? AppGradient.greenGradient : null,
                      ),
                      child: CustomListTile(
                        enableSelectableText: false,
                        onTap: () {
                          item.onTap!();
                          scaffoldKey.currentState?.closeDrawer();
                        },
                        backgroundColor: Colors.transparent,
                        border: Border.all(color: Colors.transparent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        horizontalSpacing: 8,
                        leadingIconInstead: CustomAssetImage(
                          height: 24,
                          width: 24,
                          path: isSelected
                              ? item.selectedIconPath
                              : item.iconPath,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.gray7A828E,
                        ),
                        title: item.title,
                        titleTextStyle: CustomAppFontStyle.regular14.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.gray7A828E,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (enableLogout)
            isTablet
                ? CustomActionButton(
                    width: double.infinity,
                    borderRadius: 14,

                    icon: AppIcons.logout,
                    padding: EdgeInsets.only(left: 16),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CustomLogOutSheet(
                          onTap: () => context.go(AppRouter.login),
                        ),
                      );
                    },
                    tooltip: "تسجيل الخروج",
                    color: AppColors.red1A,
                    iconColor: AppColors.red,
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(vertical: 12)
                        .copyWith(left: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.red1A,
                    ),
                    child: CustomListTile(
                      enableSelectableText: false,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => CustomLogOutSheet(
                            onTap: () => context.go(AppRouter.login),
                          ),
                        );
                      },
                      backgroundColor: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      horizontalSpacing: 8,
                      leadingIconInstead: CustomAssetImage(
                        path: AppIcons.logout,
                        color: AppColors.red,
                      ),
                      title: "تسجيل الخروج",
                      titleTextStyle: CustomAppFontStyle.regular14.copyWith(
                        color: AppColors.red,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}

class SideBarItemModel {
  final String title;
  final String iconPath;
  final String id;
  final String? routePath;
  final VoidCallback? onTap;
  final String selectedIconPath;
  final String? subtitle;
  final String? header;
  final List<Enum>? requiredPermissions;

  const SideBarItemModel({
    required this.title,
    required this.iconPath,
    required this.id,
    this.routePath,
    this.onTap,
    required this.selectedIconPath,
    this.subtitle,
    this.header,
    this.requiredPermissions,
  });
}

class _GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle style;

  const _GradientText({
    required this.text,
    required this.gradient,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/utils/theme/app_colors.dart';
import '../../core/utils/theme/custom_app_font_styles.dart';
import '../../core/utils/theme/app_gradient.dart';
import 'custom_asset_image.dart';
import 'custom_push_container_button.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final TabController controller;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final EdgeInsets? tabPadding;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? textStyle;
  final TextStyle? selectedTextStyle;
  final List<String>? icons;
  final ScrollPhysics? physics;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.width,
    this.height = 45,
    this.padding,
    this.radius,
    this.tabPadding,
    this.labelPadding,
    this.textStyle,
    this.selectedTextStyle,
    this.icons,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicator: const BoxDecoration(),
        isScrollable: true,
        physics: physics ?? const BouncingScrollPhysics(),
        labelPadding: labelPadding ?? const EdgeInsets.symmetric(horizontal: 4),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabAlignment: TabAlignment.start,
        tabs: List.generate(tabs.length, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final isSelected = controller.index == index;
              final hasIcon = icons != null && index < icons!.length;
              return CustomPushButton(
                height: height,
                backgroundColor: isSelected ? null : AppColors.white,
                border: isSelected
                    ? null
                    : const BorderSide(color: AppColors.grayE2E8F0),
                radius: radius ?? 2,
                onTap: () => controller.animateTo(index),
                padding: tabPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasIcon) ...[
                      CustomAssetImage(
                        path: icons![index],
                        width: 16,
                        height: 16,
                        color: isSelected ? AppColors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tabs[index],
                      style: isSelected
                          ? (selectedTextStyle ??
                              CustomAppFontStyle.regular16.copyWith(
                                color: AppColors.white,
                              ))
                          : (textStyle ??
                              CustomAppFontStyle.regular16.copyWith(
                                color: AppColors.gray334155,
                              )),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 45);
}

class CustomUnderlineTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final TabController controller;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomUnderlineTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.width,
    this.height = 50,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: height,
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.lightGreen35BEAA,
                width: 3,
              ),
            ),
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.lightGreen35BEAA,
          unselectedLabelColor: AppColors.gray334155,
          labelStyle: CustomAppFontStyle.regular16,
          unselectedLabelStyle: CustomAppFontStyle.regular16,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: List.generate(tabs.length, (index) {
            return Tab(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final bool isSelected = controller.index == index;
                  if (isSelected) {
                    return ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradient.greenGradient.createShader(bounds),
                      child: Text(
                        tabs[index],
                        style: CustomAppFontStyle.regular16.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  return Text(
                    tabs[index],
                    style: CustomAppFontStyle.regular16.copyWith(
                      color: AppColors.gray334155,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 50);
}

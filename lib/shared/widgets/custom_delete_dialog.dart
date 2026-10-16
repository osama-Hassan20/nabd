// import 'package:eyadty/core/utils/extensions/theme_mode_extensions.dart';
// import 'package:eyadty/core/utils/theme/app_colors.dart';
// import 'package:eyadty/core/utils/theme/app_gradient.dart';
// import 'package:eyadty/core/utils/theme/app_icons.dart';
// import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
// import 'package:eyadty/shared/widgets/custom_asset_image.dart';
// import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// class CustomDeleteDialog extends StatelessWidget {
//   const CustomDeleteDialog({
//     super.key,
//     required this.title,
//     required this.subtitle,
//     required this.onDelete,
//     this.deleteLabel,
//     this.cancelLabel,
//     this.isLoading = false,
//     this.iconPath,
//     this.backgroundColor,
//   });

//   final String title;
//   final String subtitle;
//   final VoidCallback onDelete;
//   final String? deleteLabel;
//   final String? cancelLabel;
//   final bool isLoading;
//   final String? iconPath;
//   final Color? backgroundColor;

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = context.isDarkMode;

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       backgroundColor: isDark
//           ? AppColors.darkBackground
//           : AppColors.lightBackground,
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         constraints: const BoxConstraints(maxWidth: 500, minWidth: 400),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Icon Header
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: backgroundColor ?? AppColors.red.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: CustomAssetImage(
//                 path: iconPath ?? AppIcons.delete,
//                 width: 40,
//                 height: 40,
//                 color: backgroundColor ?? AppColors.red,
//               ),
//             ),
//             const SizedBox(height: 24),
//             // Title
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: CustomAppFontStyle.regular20.copyWith(
//                 color: isDark ? AppColors.white : AppColors.black,
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Subtitle
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: CustomAppFontStyle.regular16.copyWith(
//                 color: isDark ? AppColors.white : AppColors.gray334155,
//               ),
//             ),
//             const SizedBox(height: 32),
//             // Actions
//             Row(
//               spacing: 12,
//               children: [
//                 // Cancel Button
//                 Expanded(
//                   child: CustomPushButton(
//                     height: 45,
//                     backgroundColor: AppColors.grayf4,
//                     onTap: () => context.pop(),
//                     child: Text(
//                       cancelLabel ?? "تراجع",
//                       style: CustomAppFontStyle.regular14.copyWith(
//                         color: isDark ? AppColors.white : AppColors.black,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Delete Button (Gradient)
//                 Expanded(
//                   child: CustomPushButton(
//                     height: 45,
//                     onTap: onDelete,
//                     gradient: AppGradient.redGradient,
//                     isLoading: isLoading,
//                     child: Text(
//                       deleteLabel ?? "حذف",
//                       style: CustomAppFontStyle.regular14.copyWith(
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

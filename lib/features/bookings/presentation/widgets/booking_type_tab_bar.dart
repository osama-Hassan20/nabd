import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purexo/core/utils/theme/app_colors.dart';
import 'package:purexo/core/utils/theme/custom_app_font_styles.dart';
import 'package:purexo/features/bookings/data/models/enums/booking_type_enum.dart';
import 'package:purexo/shared/widgets/custom_asset_image.dart';

class BookingTypeTabBar extends StatelessWidget {
  final BookingTypeEnum activeTab;
  final ValueChanged<BookingTypeEnum> onTabChanged;
  final int? oneTimeBadgeCount;
  final int? recurringBadgeCount;

  const BookingTypeTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.oneTimeBadgeCount,
    this.recurringBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grayE2E8F0,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabItem(
            type: BookingTypeEnum.oneTime,
            title: 'one_time_bookings_tab'.tr(),
            icon: BookingTypeEnum.oneTime.icon,
            isSelected: activeTab == BookingTypeEnum.oneTime,
            badgeCount: oneTimeBadgeCount,
            onTap: () => onTabChanged(BookingTypeEnum.oneTime),
          ),
          const SizedBox(width: 4),
          _TabItem(
            type: BookingTypeEnum.recurring,
            title: 'recurring_bookings_tab'.tr(),
            icon: BookingTypeEnum.recurring.icon,
            isSelected: activeTab == BookingTypeEnum.recurring,
            badgeCount: recurringBadgeCount,
            onTap: () => onTabChanged(BookingTypeEnum.recurring),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final BookingTypeEnum type;
  final String title;
  final String icon;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _TabItem({
    required this.type,
    required this.title,
    required this.icon,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomAssetImage(
                path: icon,
                width: 18,
                height: 18,
                color: isSelected ? AppColors.white : AppColors.gray71717A,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: CustomAppFontStyle.semiBold14.copyWith(
                  color: isSelected ? AppColors.white : AppColors.gray71717A,
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white.withValues(alpha: 0.25)
                        : AppColors.grayE2E8F0,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: CustomAppFontStyle.bold12.copyWith(
                      color: isSelected ? AppColors.white : AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

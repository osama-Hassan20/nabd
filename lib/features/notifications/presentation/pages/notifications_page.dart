import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyadty/core/dependency_injection/dependency_injection.dart';
import 'package:eyadty/core/utils/theme/app_colors.dart';
import 'package:eyadty/core/utils/theme/custom_app_font_styles.dart';
import 'package:eyadty/shared/widgets/custom_container.dart';
import 'package:eyadty/shared/widgets/custom_push_container_button.dart';
import '../../data/models/notification_item_model.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<NotificationsCubit>();

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: cubit,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row with Mark All Read
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notifications'.tr(),
                          style: CustomAppFontStyle.bold24.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'متابعة الإشعارات المباشرة وإشارات الاستقبال',
                          style: CustomAppFontStyle.regular13.copyWith(
                            color: AppColors.gray71717A,
                          ),
                        ),
                      ],
                    ),
                    if (state.unreadCount > 0)
                      CustomPushButton(
                        height: 38,
                        radius: 10,
                        backgroundColor: AppColors.primaryLight,
                        onTap: () => cubit.markAllAsRead(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'تحديد الكل كمقروء',
                                style: CustomAppFontStyle.semiBold13.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab Bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.gray71717A,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: CustomAppFontStyle.semiBold14,
                  unselectedLabelStyle: CustomAppFontStyle.regular14,
                  tabs: [
                    Tab(text: 'الكل (${state.notifications.length})'),
                    Tab(text: 'إشارات الاستقبال (${state.receptionSignals.length})'),
                    Tab(text: 'غير مقروء (${state.unreadCount})'),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsList(state.notifications, cubit),
                      _buildNotificationsList(state.receptionSignals, cubit),
                      _buildNotificationsList(
                        state.notifications.where((n) => !n.isRead).toList(),
                        cubit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(
    List<NotificationItemModel> list,
    NotificationsCubit cubit,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: AppColors.gray7A828E,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد إشعارات حالياً',
              style: CustomAppFontStyle.semiBold16.copyWith(
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSignal = item.type == NotificationTypeEnum.receptionSignal;

        Color iconColor = AppColors.primary;
        Color bgColor = AppColors.primaryLight;
        IconData icon = Icons.notifications_rounded;

        switch (item.type) {
          case NotificationTypeEnum.receptionSignal:
            iconColor = const Color(0xFF7C3AED); // Purple
            bgColor = const Color(0xFFEDE9FE);
            icon = Icons.campaign_rounded;
            break;
          case NotificationTypeEnum.patientAlert:
            iconColor = AppColors.error;
            bgColor = const Color(0xFFFEE2E2);
            icon = Icons.warning_rounded;
            break;
          case NotificationTypeEnum.booking:
            iconColor = AppColors.secondary;
            bgColor = const Color(0xFFE0F2FE);
            icon = Icons.calendar_today_rounded;
            break;
          case NotificationTypeEnum.system:
            iconColor = AppColors.primary;
            bgColor = AppColors.primaryLight;
            icon = Icons.info_outline_rounded;
            break;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => cubit.markAsRead(item.id),
          child: CustomContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead
                  ? AppColors.grayE2E8F0
                  : iconColor.withValues(alpha: 0.4),
              width: item.isRead ? 1 : 1.5,
            ),
            backGroundColor: item.isRead
                ? AppColors.white
                : iconColor.withValues(alpha: 0.03),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: CustomAppFontStyle.bold14.copyWith(
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item.createdAt),
                            style: CustomAppFontStyle.regular12.copyWith(
                              color: AppColors.gray71717A,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: CustomAppFontStyle.regular13.copyWith(
                          color: AppColors.gray71717A,
                          height: 1.4,
                        ),
                      ),
                      if (isSignal && item.targetAudience != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'المستهدف: ${item.targetAudience}',
                            style: CustomAppFontStyle.medium12.copyWith(
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return DateFormat('yyyy/MM/dd HH:mm').format(time);
  }
}

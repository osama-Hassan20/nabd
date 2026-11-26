import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/audit_logger.dart';
import '../../../../core/storage/cache_helper.dart';
import '../../../../core/utils/helpers/cairo_time_helper.dart';
import '../../data/models/notification_item_model.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final AuditLogger? auditLogger;
  static const String readNotificationsKey = 'eyadty_read_notifications_ids';

  NotificationsCubit({this.auditLogger})
      : super(
          NotificationsState(
            notifications: _loadNotifications(),
          ),
        );

  static List<NotificationItemModel> _loadNotifications() {
    final seeded = _seedInitialNotifications();
    try {
      final readIdsStr = AppSharedPreferences.getString(key: readNotificationsKey);
      if (readIdsStr != null && readIdsStr.isNotEmpty) {
        final readIds = readIdsStr.split(',').toSet();
        return seeded.map((n) {
          if (readIds.contains(n.id)) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
      }
    } catch (_) {}
    return seeded;
  }

  static List<NotificationItemModel> _seedInitialNotifications() {
    final now = CairoTimeHelper.now();
    return [
      NotificationItemModel(
        id: 'notif_01',
        title: 'كشف جديد في الانتظار',
        body: 'المريض سارة أحمد وصلت إلى العيادة وهي الآن في صالة الانتظار.',
        type: NotificationTypeEnum.booking,
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      NotificationItemModel(
        id: 'notif_02',
        title: 'تنبيه علامات حيوية حرجة',
        body: 'تم تسجيل ضغط دم مرتفع (180/110) للمريض يوسف إبراهيم.',
        type: NotificationTypeEnum.patientAlert,
        createdAt: now.subtract(const Duration(minutes: 45)),
        isRead: false,
      ),
      NotificationItemModel(
        id: 'notif_03',
        title: 'تحديث نظام العيادة',
        body: 'تم تفعيل نظام القفل المحلي والشاشات التكيفية بنجاح.',
        type: NotificationTypeEnum.system,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
    ];
  }

  /// Sends a live reception buzzer signal
  void sendReceptionSignal({
    required String title,
    required String body,
    required String targetAudience,
    required String actionKey,
    required String senderName,
  }) {
    final now = CairoTimeHelper.now();
    final newSignal = NotificationItemModel(
      id: 'signal_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationTypeEnum.receptionSignal,
      createdAt: now,
      isRead: false,
      senderName: senderName,
      targetAudience: targetAudience,
      actionKey: actionKey,
    );

    auditLogger?.log(
      eventType: 'RECEPTION_BUZZER_SIGNAL',
      performedByUserName: senderName,
      details: 'إرسال إشارة: $title إلى $targetAudience بواسطة $senderName',
    );

    emit(
      state.copyWith(
        notifications: [newSignal, ...state.notifications],
        lastSentSignal: title,
      ),
    );
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    _persistReadIds(updated);
    emit(state.copyWith(notifications: updated));
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    _persistReadIds(updated);
    emit(state.copyWith(notifications: updated));
  }

  void _persistReadIds(List<NotificationItemModel> list) {
    try {
      final readIds = list.where((n) => n.isRead).map((n) => n.id).join(',');
      AppSharedPreferences.setString(key: readNotificationsKey, value: readIds);
    } catch (_) {}
  }

  void clearAll() {
    emit(state.copyWith(notifications: const []));
  }
}

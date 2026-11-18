import 'package:equatable/equatable.dart';
import '../../data/models/notification_item_model.dart';

class NotificationsState extends Equatable {
  final List<NotificationItemModel> notifications;
  final bool isLoading;
  final String? lastSentSignal;

  const NotificationsState({
    required this.notifications,
    this.isLoading = false,
    this.lastSentSignal,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationItemModel> get receptionSignals => notifications
      .where((n) => n.type == NotificationTypeEnum.receptionSignal)
      .toList();

  NotificationsState copyWith({
    List<NotificationItemModel>? notifications,
    bool? isLoading,
    String? lastSentSignal,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      lastSentSignal: lastSentSignal ?? this.lastSentSignal,
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, lastSentSignal];
}

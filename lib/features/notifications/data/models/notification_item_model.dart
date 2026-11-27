import 'package:equatable/equatable.dart';

enum NotificationTypeEnum {
  receptionSignal,
  booking,
  system,
  patientAlert,
}

class NotificationItemModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationTypeEnum type;
  final DateTime createdAt;
  final bool isRead;
  final String? senderName;
  final String? targetAudience;
  final String? actionKey;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.senderName,
    this.targetAudience,
    this.actionKey,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationTypeEnum? type,
    DateTime? createdAt,
    bool? isRead,
    String? senderName,
    String? targetAudience,
    String? actionKey,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      targetAudience: targetAudience ?? this.targetAudience,
      actionKey: actionKey ?? this.actionKey,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: NotificationTypeEnum.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationTypeEnum.system,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      senderName: json['senderName'] as String?,
      targetAudience: json['targetAudience'] as String?,
      actionKey: json['actionKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        if (senderName != null) 'senderName': senderName,
        if (targetAudience != null) 'targetAudience': targetAudience,
        if (actionKey != null) 'actionKey': actionKey,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        createdAt,
        isRead,
        senderName,
        targetAudience,
        actionKey,
      ];
}

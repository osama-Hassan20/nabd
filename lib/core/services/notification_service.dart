class NotificationService {
  Future<String?> initAndGetToken() async {
    return null;
  }

  void listenForegroundMessages(void Function(dynamic) onMessage) {}

  void listenNotificationOpened(void Function(dynamic) onOpen) {}

  Future<void> removeTokenFromBackend() async {}
}

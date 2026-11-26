import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get isPlatformOnline => html.window.navigator.onLine ?? true;

Stream<bool> get platformConnectivityStream {
  late StreamController<bool> controller;
  StreamSubscription? onlineSub;
  StreamSubscription? offlineSub;

  controller = StreamController<bool>.broadcast(
    onListen: () {
      onlineSub = html.window.onOnline.listen((_) => controller.add(true));
      offlineSub = html.window.onOffline.listen((_) => controller.add(false));
    },
    onCancel: () {
      onlineSub?.cancel();
      offlineSub?.cancel();
    },
  );

  return controller.stream;
}

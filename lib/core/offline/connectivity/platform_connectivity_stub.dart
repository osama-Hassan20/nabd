import 'dart:async';

bool get isPlatformOnline => true;

Stream<bool> get platformConnectivityStream => const Stream.empty();

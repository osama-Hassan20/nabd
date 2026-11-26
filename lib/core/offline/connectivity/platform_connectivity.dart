import 'platform_connectivity_stub.dart'
    if (dart.library.html) 'platform_connectivity_web.dart' as impl;

bool get isPlatformOnline => impl.isPlatformOnline;
Stream<bool> get platformConnectivityStream => impl.platformConnectivityStream;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NavigationModeService {
  static const MethodChannel _channel =
      MethodChannel('com.koshkparmage.purexo/navigation_mode');
  static bool _is3ButtonNavigation = false;

  /// Reactive notifier to rebuild widgets without setState
  static final ValueNotifier<bool> is3ButtonNavNotifier =
      ValueNotifier<bool>(false);

  /// Synchronous getter for current state
  static bool get is3ButtonNavigation => _is3ButtonNavigation;

  /// Invokes native Android platform channel
  static Future<bool> check3ButtonNavigation() async {
    if (kIsWeb || !Platform.isAndroid) {
      _is3ButtonNavigation = false;
      is3ButtonNavNotifier.value = false;
      return false;
    }
    try {
      final bool? is3Button = await _channel.invokeMethod<bool>('is3ButtonNav');
      final result = is3Button ?? false;
      _is3ButtonNavigation = result;
      is3ButtonNavNotifier.value = result;
      return result;
    } catch (_) {
      _is3ButtonNavigation = false;
      is3ButtonNavNotifier.value = false;
      return false;
    }
  }
}

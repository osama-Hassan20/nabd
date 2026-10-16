import 'package:flutter/material.dart';
import '../services/navigation_mode_service.dart';

extension NavigationModeExtension on BuildContext {
  bool get is3ButtonNavigation => NavigationModeService.is3ButtonNavigation;
}

import 'package:flutter/animation.dart';

class AppAnimations {
  // ─── Standard Durations ──────────────────────────────────────────────────
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration extraSlow = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // ─── Stagger Delays ──────────────────────────────────────────────────────
  static const Duration staggerShort = Duration(milliseconds: 80);
  static const Duration staggerMedium = Duration(milliseconds: 160);
  static const Duration staggerLong = Duration(milliseconds: 240);
  static const Duration staggerExtraLong = Duration(milliseconds: 320);

  // ─── Standard Easing Curves ──────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve decelerate = Curves.fastOutSlowIn;

  // ─── Lottie Fallback Asset Paths ─────────────────────────────────────────
  static const String loading = 'assets/animations/loading.json';
  static const String success = 'assets/animations/success.json';
  static const String empty = 'assets/animations/empty_animation.json';
  static const String emptyOrders = 'assets/animations/empty_orders.json';
  static const String failedProcess = 'assets/animations/failed_animation.json';
  static const String noInternet = 'assets/animations/no_internet.json';
  static const String emptySearch = 'assets/animations/empty_search.json';
  static const String lockAcc = 'assets/animations/lock_acc.json';
  static const String notificationDisabled = 'assets/animations/disabled_notification.json';
}

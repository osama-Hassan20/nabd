import 'package:flutter/foundation.dart';

/// Global service to keep track of the selected clinic branch across the app.
class AppBranchService {
  AppBranchService._();
  static final AppBranchService instance = AppBranchService._();

  final ValueNotifier<String> selectedBranchNotifier =
      ValueNotifier<String>('branch_1');

  String get currentBranchId => selectedBranchNotifier.value;

  void selectBranch(String branchId) {
    if (selectedBranchNotifier.value != branchId) {
      selectedBranchNotifier.value = branchId;
    }
  }
}


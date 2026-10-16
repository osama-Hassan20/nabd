import 'package:flutter/material.dart';

/// A mixin that provides common pagination functionality for cubits
/// following the infinite scroll pattern used in the app.
mixin PaginationMixin {
  int currentPage = 1;
  int limit = 20;
  bool hasReachedMax = false;
  final ScrollController scrollController = ScrollController();

  /// Adds a scroll listener to trigger pagination when reaching the bottom
  ///
  /// `isLoading` is a closure evaluated at scroll time to ensure the latest
  /// loading state from the caller is used (not a single captured boolean).
  void addPaginationListener(
    VoidCallback onLoadMore, {
    required bool Function() isLoading,
  }) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 50) {
        if (!isLoading() && !hasReachedMax) {
          onLoadMore();
        }
      }
    });
  }

  /// Resets pagination state to initial values
  void resetPagination() {
    currentPage = 1;
    hasReachedMax = false;
  }

  /// Disposes the scroll controller
  void disposePagination() {
    scrollController.dispose();
  }
}

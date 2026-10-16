import 'dart:async';
import 'package:flutter/material.dart';

/// A mixin that provides common search functionality with debounce support
mixin SearchMixin {
  final Map<int, String> _lastQueries = {};
  final Map<int, Timer?> _debounces = {};
  final TextEditingController searchController = TextEditingController();

  /// Adds a listener to a search controller with a debounce.
  /// If [controller] is null, it uses the default [searchController].
  void addSearchListener(
    VoidCallback onSearch, {
    TextEditingController? controller,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    final effectiveController = controller ?? searchController;
    final id = effectiveController.hashCode;

    _lastQueries[id] = effectiveController.text;
    effectiveController.addListener(() {
      final query = effectiveController.text;

      if (query == _lastQueries[id]) return;

      if (_debounces[id]?.isActive ?? false) _debounces[id]?.cancel();

      _debounces[id] = Timer(duration, () {
        _lastQueries[id] = query;
        onSearch();
      });
    });
  }

  /// Disposes search resources.
  /// If [controller] is provided, it disposes only that specific search's resources.
  /// Otherwise, it clears all debounces and disposes the default [searchController].
  void disposeSearch([TextEditingController? controller]) {
    if (controller != null) {
      final id = controller.hashCode;
      _debounces[id]?.cancel();
      _debounces.remove(id);
      _lastQueries.remove(id);
      controller.dispose();
    } else {
      for (final timer in _debounces.values) {
        timer?.cancel();
      }
      _debounces.clear();
      _lastQueries.clear();
      searchController.dispose();
    }
  }

  /// Gets the current search query from the default [searchController]
  String get searchQuery => searchController.text;
}

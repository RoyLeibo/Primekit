import 'package:flutter/material.dart';

/// Manages per-tab scroll state for bottom-navigation-style layouts.
///
/// Each tab gets its own [ScrollController], and the last known scroll
/// position for that tab is preserved so it can be restored when the user
/// returns to the tab.
///
/// ```dart
/// final tabManager = TabStateManager(tabCount: 3);
///
/// // In your tab's body widget:
/// ListView(
///   controller: tabManager.getScrollController(tabIndex),
///   ...
/// )
///
/// // Optionally restore the position when switching tabs:
/// tabManager.getScrollController(newIndex)
///   ..jumpTo(tabManager.getScrollPosition(newIndex) ?? 0);
///
/// // Dispose when the parent widget is disposed:
/// tabManager.dispose();
/// ```
class TabStateManager {
  /// Creates a [TabStateManager] for [tabCount] tabs.
  ///
  /// Asserts that [tabCount] is at least 1.
  TabStateManager({required int tabCount})
    : assert(tabCount > 0, 'tabCount must be at least 1') {
    _controllers = List.generate(
      tabCount,
      (index) => ScrollController(debugLabel: 'tab_$index'),
      growable: false,
    );
    _positions = List.filled(tabCount, null);
  }

  late final List<ScrollController> _controllers;
  late final List<double?> _positions;

  /// Returns the [ScrollController] associated with [tabIndex].
  ///
  /// The same controller instance is returned on every call for a given index.
  ScrollController getScrollController(int tabIndex) {
    _assertValidIndex(tabIndex);
    return _controllers[tabIndex];
  }

  /// Records [position] as the last known scroll offset for [tabIndex].
  void saveScrollPosition(int tabIndex, double position) {
    _assertValidIndex(tabIndex);
    _positions[tabIndex] = position;
  }

  /// Returns the last saved scroll position for [tabIndex], or `null` if
  /// the position has never been saved or was reset.
  double? getScrollPosition(int tabIndex) {
    _assertValidIndex(tabIndex);
    return _positions[tabIndex];
  }

  /// Resets the scroll position for [tabIndex] and jumps the controller to
  /// the top (offset 0) if it has attached clients.
  void resetTab(int tabIndex) {
    _assertValidIndex(tabIndex);
    _positions[tabIndex] = null;

    final controller = _controllers[tabIndex];
    if (controller.hasClients) {
      controller.jumpTo(0);
    }
  }

  /// Resets scroll positions for every tab.
  void resetAll() {
    for (var i = 0; i < _controllers.length; i++) {
      resetTab(i);
    }
  }

  /// The total number of tabs managed by this instance.
  int get tabCount => _controllers.length;

  /// Disposes all [ScrollController]s. Call this in the parent widget's
  /// `dispose()` method.
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  void _assertValidIndex(int index) {
    if (index < 0 || index >= _controllers.length) {
      throw RangeError.index(index, _controllers, 'tabIndex');
    }
  }
}

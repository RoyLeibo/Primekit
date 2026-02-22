/// Pagination-aware state and notifier.
///
/// Provides a ready-made pattern for infinite-scroll lists, separating the
/// concerns of first-page loading, subsequent page loading, and errors.
library primekit_paginated_state;

import 'package:flutter/foundation.dart';

/// Immutable snapshot of a paginated list's state.
///
/// ```dart
/// final state = PaginatedState<Post>.initial();
///
/// // Load the first page:
/// final next = await repository.fetchPage(0, 20);
/// final updated = state.copyWithNextPage(next, hasMore: next.length == 20);
/// ```
final class PaginatedState<T> {
  /// Creates a [PaginatedState] with the given fields.
  ///
  /// Prefer the named constructors ([PaginatedState.initial]) and `copyWith`
  /// helpers over using this directly.
  const PaginatedState({
    required this.items,
    required this.isLoading,
    required this.isInitialLoad,
    required this.error,
    required this.hasMore,
    required this.page,
  });

  /// Returns the empty initial state, ready for the first page load.
  PaginatedState.initial()
      : items = <T>[],
        isLoading = false,
        isInitialLoad = true,
        error = null,
        hasMore = true,
        page = 0;

  /// All items accumulated across all loaded pages.
  final List<T> items;

  /// Whether a subsequent (non-first) page is currently loading.
  final bool isLoading;

  /// Whether the first page has never been loaded yet.
  final bool isInitialLoad;

  /// The error from the last failed page load, or `null` if none.
  final Object? error;

  /// Whether more pages are expected after the last loaded page.
  final bool hasMore;

  /// The index of the last successfully loaded page (0-based).
  final int page;

  // ---------------------------------------------------------------------------
  // copyWith helpers
  // ---------------------------------------------------------------------------

  /// Returns a new state that appends [newItems] from the next page.
  ///
  /// Increments [page] and clears any previous [error].
  PaginatedState<T> copyWithNextPage(
    List<T> newItems, {
    required bool hasMore,
  }) =>
      PaginatedState<T>(
        items: [...items, ...newItems],
        isLoading: false,
        isInitialLoad: false,
        error: null,
        hasMore: hasMore,
        page: page + 1,
      );

  /// Returns a new state that records [error] while keeping existing [items].
  PaginatedState<T> copyWithError(Object error) => PaginatedState<T>(
        items: items,
        isLoading: false,
        isInitialLoad: isInitialLoad,
        error: error,
        hasMore: hasMore,
        page: page,
      );

  /// Returns a new state with [isLoading] set to `true`, clearing any error.
  PaginatedState<T> copyWithLoading() => PaginatedState<T>(
        items: items,
        isLoading: true,
        isInitialLoad: isInitialLoad,
        error: null,
        hasMore: hasMore,
        page: page,
      );

  /// Returns the [PaginatedState.initial] state, clearing all items and
  /// pagination metadata.
  PaginatedState<T> reset() => PaginatedState.initial();

  @override
  String toString() => 'PaginatedState<$T>('
      'items: ${items.length}, '
      'page: $page, '
      'hasMore: $hasMore, '
      'isLoading: $isLoading, '
      'isInitialLoad: $isInitialLoad, '
      'error: $error)';
}

/// A [ChangeNotifier] that manages paginated loading for a list of [T].
///
/// Call [loadFirst] to start from page 0, then [loadNext] to append
/// subsequent pages, and [refresh] to restart from the beginning.
///
/// ```dart
/// final notifier = PaginatedNotifier<Post>();
/// await notifier.loadFirst(
///   (page, size) => postRepository.fetchPage(page, size),
/// );
///
/// // Append more:
/// if (notifier.state.hasMore) {
///   await notifier.loadNext();
/// }
/// ```
class PaginatedNotifier<T> extends ChangeNotifier {
  PaginatedNotifier() : _state = PaginatedState.initial();

  PaginatedState<T> _state;
  Future<List<T>> Function(int page, int pageSize)? _loader;
  int _pageSize = 20;

  /// The current pagination state.
  PaginatedState<T> get state => _state;

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  /// Resets state and loads the first page using [loader].
  ///
  /// `pageSize` controls how many items are requested per page. The notifier
  /// infers `hasMore` from whether the returned list length equals `pageSize`.
  Future<void> loadFirst(
    Future<List<T>> Function(int page, int pageSize) loader, {
    int pageSize = 20,
  }) async {
    _loader = loader;
    _pageSize = pageSize;
    _setState(PaginatedState.initial());
    await _loadPage(0);
  }

  /// Loads the next page, appending results to [PaginatedState.items].
  ///
  /// Does nothing when [PaginatedState.hasMore] is `false` or a load is
  /// already in flight.
  Future<void> loadNext() async {
    if (!_state.hasMore || _state.isLoading || _loader == null) return;
    await _loadPage(_state.page);
  }

  /// Resets to the initial state and re-runs the first page load.
  ///
  /// Has no effect if [loadFirst] has never been called.
  Future<void> refresh() async {
    if (_loader == null) return;
    _setState(PaginatedState.initial());
    await _loadPage(0);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadPage(int pageIndex) async {
    _setState(_state.copyWithLoading());
    try {
      final items = await _loader!(pageIndex, _pageSize);
      final hasMore = items.length == _pageSize;
      _setState(_state.copyWithNextPage(items, hasMore: hasMore));
    } on Exception catch (e) {
      _setState(_state.copyWithError(e));
    }
  }

  void _setState(PaginatedState<T> next) {
    _state = next;
    notifyListeners();
  }
}

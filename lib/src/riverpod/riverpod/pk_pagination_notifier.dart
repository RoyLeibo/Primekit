import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a paginated list with optional bidirectional support.
class PkPaginationState<T> {
  const PkPaginationState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isLoadingPrevious = false,
    this.hasMore = true,
    this.hasPrevious = false,
    this.error,
    this.page = 0,
    this.initialScrollIndex,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingPrevious;
  final bool hasMore;
  final bool hasPrevious;
  final Object? error;
  final int page;

  /// Index within [items] to scroll to on first load (e.g. first active item).
  /// Only meaningful after [loadFirst] or [loadAt]; consumers should read once
  /// and then ignore.
  final int? initialScrollIndex;

  bool get isEmpty => items.isEmpty && !isLoading;

  /// Whether a previous-page load is possible right now.
  bool get canLoadPrevious => hasPrevious && !isLoadingPrevious && !isLoading;

  /// Whether a next-page load is possible right now.
  bool get canLoadMore => hasMore && !isLoadingMore && !isLoading;

  PkPaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingPrevious,
    bool? hasMore,
    bool? hasPrevious,
    Object? error,
    int? page,
    int? Function()? initialScrollIndex,
  }) => PkPaginationState<T>(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isLoadingPrevious: isLoadingPrevious ?? this.isLoadingPrevious,
    hasMore: hasMore ?? this.hasMore,
    hasPrevious: hasPrevious ?? this.hasPrevious,
    error: error ?? this.error,
    page: page ?? this.page,
    initialScrollIndex: initialScrollIndex != null
        ? initialScrollIndex()
        : this.initialScrollIndex,
  );
}

/// Result returned by [PkPaginationNotifierMixin.fetchPage].
///
/// For simple append-only pagination, only [items] is required.
/// For bidirectional pagination, set [hasPrevious] and optionally
/// [initialScrollIndex] to enable [loadPrevious] and auto-scroll.
class PkPageResult<T> {
  const PkPageResult({
    required this.items,
    this.hasPrevious,
    this.initialScrollIndex,
  });

  final List<T> items;

  /// Whether pages before this one exist. When `null`, the mixin infers
  /// `hasPrevious` from `page > 0`.
  final bool? hasPrevious;

  /// Index of the item to scroll to within [items] (used only on initial load).
  final int? initialScrollIndex;
}

/// Pagination-aware mixin for Riverpod [Notifier]s.
///
/// Supports both append-only (forward) and bidirectional pagination.
///
/// **Append-only (default):**
/// ```dart
/// @override
/// Future<List<Product>> fetchPage(int page, int pageSize) =>
///     api.getProducts(page: page, pageSize: pageSize);
/// ```
///
/// **Bidirectional — override [fetchPageResult] instead:**
/// ```dart
/// @override
/// Future<PkPageResult<Match>> fetchPageResult(int page, int pageSize) async {
///   final resp = await api.getMatches(page: page, pageSize: pageSize);
///   return PkPageResult(
///     items: resp.items,
///     hasPrevious: resp.hasPreviousPage,
///     initialScrollIndex: resp.firstActiveIndex,
///   );
/// }
/// ```
mixin PkPaginationNotifierMixin<T> on Notifier<PkPaginationState<T>> {
  static const int defaultPageSize = 20;

  /// Override this for simple forward-only pagination.
  /// Returns a plain list of items for the given [page].
  Future<List<T>> fetchPage(int page, int pageSize) =>
      throw UnimplementedError(
        'Override fetchPage or fetchPageResult in your notifier.',
      );

  /// Override this instead of [fetchPage] when you need bidirectional
  /// pagination metadata (hasPrevious, initialScrollIndex).
  Future<PkPageResult<T>> fetchPageResult(int page, int pageSize) async {
    final items = await fetchPage(page, pageSize);
    return PkPageResult<T>(items: items);
  }

  /// Loads the first page (page 0), replacing all existing items.
  Future<void> loadFirst() async {
    state = const PkPaginationState(isLoading: true);
    try {
      final result = await fetchPageResult(0, defaultPageSize);
      state = PkPaginationState<T>(
        items: result.items,
        hasMore: result.items.length >= defaultPageSize,
        hasPrevious: result.hasPrevious ?? false,
        page: 0,
        initialScrollIndex: result.initialScrollIndex,
      );
    } catch (e) {
      state = PkPaginationState<T>(isLoading: false, error: e);
    }
  }

  /// Loads a specific page, replacing all existing items.
  ///
  /// Useful for "jump to active" scenarios where the initial page
  /// is not page 0.
  Future<void> loadAt(int page) async {
    state = const PkPaginationState(isLoading: true);
    try {
      final result = await fetchPageResult(page, defaultPageSize);
      state = PkPaginationState<T>(
        items: result.items,
        hasMore: result.items.length >= defaultPageSize,
        hasPrevious: result.hasPrevious ?? (page > 0),
        page: page,
        initialScrollIndex: result.initialScrollIndex,
      );
    } catch (e) {
      state = PkPaginationState<T>(isLoading: false, error: e);
    }
  }

  /// Appends the next page of items to the end of the list.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await fetchPageResult(nextPage, defaultPageSize);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.items.length >= defaultPageSize,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Prepends the previous page of items to the beginning of the list.
  ///
  /// No-op when [PkPaginationState.canLoadPrevious] is `false`.
  Future<void> loadPrevious() async {
    if (!state.canLoadPrevious || state.page <= 0) return;
    state = state.copyWith(isLoadingPrevious: true);
    try {
      final prevPage = state.page - 1;
      final result = await fetchPageResult(prevPage, defaultPageSize);
      state = state.copyWith(
        items: [...result.items, ...state.items],
        isLoadingPrevious: false,
        hasPrevious: result.hasPrevious ?? (prevPage > 0),
        page: prevPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPrevious: false, error: e);
    }
  }

  /// Resets pagination to its initial empty state.
  void reset() => state = const PkPaginationState();
}

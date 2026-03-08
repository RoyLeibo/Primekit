import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a paginated list.
class PkPaginationState<T> {
  const PkPaginationState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final int page;

  bool get isEmpty => items.isEmpty && !isLoading;

  PkPaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    int? page,
  }) => PkPaginationState<T>(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error ?? this.error,
    page: page ?? this.page,
  );
}

/// Base class for Riverpod notifiers that manage paginated lists.
///
/// ```dart
/// @riverpod
/// class ProductsNotifier extends _$ProductsNotifier
///     with PkPaginationNotifierMixin<Product> {
///   @override
///   PkPaginationState<Product> build() => const PkPaginationState();
///
///   @override
///   Future<List<Product>> fetchPage(int page, int pageSize) =>
///       api.getProducts(page: page, pageSize: pageSize);
/// }
/// ```
mixin PkPaginationNotifierMixin<T> on Notifier<PkPaginationState<T>> {
  static const int defaultPageSize = 20;

  Future<List<T>> fetchPage(int page, int pageSize);

  Future<void> loadFirst() async {
    state = const PkPaginationState(isLoading: true);
    try {
      final items = await fetchPage(0, defaultPageSize);
      state = PkPaginationState(
        items: items,
        hasMore: items.length >= defaultPageSize,
        page: 0,
      );
    } catch (e) {
      state = PkPaginationState(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final items = await fetchPage(nextPage, defaultPageSize);
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length >= defaultPageSize,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  void reset() => state = const PkPaginationState();
}

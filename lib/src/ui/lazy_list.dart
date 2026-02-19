import 'package:flutter/material.dart';

/// An infinite-scroll list that automatically loads pages as the user
/// approaches the bottom.
///
/// [onLoadPage] is called with the current zero-based page index and
/// [pageSize]. When it returns an empty list the list treats that as the last
/// page and stops requesting more data.
///
/// ```dart
/// LazyList<User>(
///   onLoadPage: (page, pageSize) => api.getUsers(page: page, limit: pageSize),
///   itemBuilder: (context, user, index) => UserTile(user: user),
/// )
/// ```
class LazyList<T> extends StatefulWidget {
  /// Creates an infinite-scroll list.
  const LazyList({
    super.key,
    required this.onLoadPage,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Async callback that fetches a single page of data.
  ///
  /// Receives the zero-based page number and the requested page size.
  /// Return an empty list to signal the end of data.
  final Future<List<T>> Function(int page, int pageSize) onLoadPage;

  /// Builds a single list item from [item] at position [index].
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Number of items per page. Defaults to 20.
  final int pageSize;

  /// Widget shown at the bottom while the next page is loading.
  final Widget? loadingWidget;

  /// Widget shown when no items exist.
  final Widget? emptyWidget;

  /// Widget shown when a page load fails.
  final Widget? errorWidget;

  /// Whether the list shrink-wraps its content.
  final bool shrinkWrap;

  /// Scroll physics passed to the underlying [ListView].
  final ScrollPhysics? physics;

  @override
  State<LazyList<T>> createState() => _LazyListState<T>();
}

class _LazyListState<T> extends State<LazyList<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasReachedEnd = false;

  static const double _triggerThreshold = 300;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _triggerThreshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _hasReachedEnd) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.onLoadPage(_currentPage, widget.pageSize);

      if (!mounted) return;

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _isLoading = false;
        if (newItems.length < widget.pageSize) {
          _hasReachedEnd = true;
        }
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _retry() => _loadNextPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Initial load states
    if (_items.isEmpty) {
      if (_isLoading) {
        return widget.loadingWidget ??
            const Center(child: CircularProgressIndicator());
      }
      if (_hasError) {
        return widget.errorWidget ??
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load data.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
      }
      return widget.emptyWidget ??
          const Center(child: Text('No items found.'));
    }

    // Item count includes a bottom sentinel slot for loading/end indicator.
    final itemCount = _items.length + (_hasReachedEnd ? 0 : 1);

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Render the real item.
        if (index < _items.length) {
          return widget.itemBuilder(context, _items[index], index);
        }

        // Bottom sentinel: loading spinner or error retry.
        if (_hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load more',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: widget.loadingWidget ??
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                ),
          ),
        );
      },
    );
  }
}

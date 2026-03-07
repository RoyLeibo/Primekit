import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit_riverpod/primekit_riverpod.dart';

// ---------------------------------------------------------------------------
// Concrete pagination notifier under test
// ---------------------------------------------------------------------------

class _StringPaginationNotifier extends Notifier<PkPaginationState<String>>
    with PkPaginationNotifierMixin<String> {
  // Control which page data to return and whether to throw.
  List<List<String>> pages = [];
  Exception? errorToThrow;

  @override
  PkPaginationState<String> build() => const PkPaginationState();

  @override
  Future<List<String>> fetchPage(int page, int pageSize) async {
    if (errorToThrow != null) throw errorToThrow!;
    if (page < pages.length) return pages[page];
    return [];
  }
}

final _paginationProvider =
    NotifierProvider<_StringPaginationNotifier, PkPaginationState<String>>(
      _StringPaginationNotifier.new,
    );

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PkPaginationNotifierMixin', () {
    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------

    group('initial state', () {
      test('items is empty', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final state = container.read(_paginationProvider);
        expect(state.items, isEmpty);
      });

      test('isLoading is false', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).isLoading, isFalse);
      });

      test('isLoadingMore is false', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).isLoadingMore, isFalse);
      });

      test('hasMore is true', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).hasMore, isTrue);
      });

      test('page is 0', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).page, equals(0));
      });

      test('error is null', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).error, isNull);
      });

      test('isEmpty returns true when items empty and not loading', () {
        final container = _makeContainer();
        addTearDown(container.dispose);

        expect(container.read(_paginationProvider).isEmpty, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // PkPaginationState.copyWith
    // -----------------------------------------------------------------------

    group('PkPaginationState.copyWith', () {
      test('returns new state with updated items', () {
        const original = PkPaginationState<String>();
        final updated = original.copyWith(items: ['a', 'b']);

        expect(updated.items, equals(['a', 'b']));
        expect(original.items, isEmpty);
      });

      test('preserves unchanged fields', () {
        const original = PkPaginationState<String>(
          items: ['x'],
          hasMore: false,
          page: 2,
        );
        final updated = original.copyWith(isLoadingMore: true);

        expect(updated.items, equals(['x']));
        expect(updated.hasMore, isFalse);
        expect(updated.page, equals(2));
        expect(updated.isLoadingMore, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // loadFirst
    // -----------------------------------------------------------------------

    group('loadFirst', () {
      test('populates items from first page', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container.read(_paginationProvider.notifier).pages = [
          ['alpha', 'beta', 'gamma'],
        ];

        await container.read(_paginationProvider.notifier).loadFirst();

        final state = container.read(_paginationProvider);
        expect(state.items, equals(['alpha', 'beta', 'gamma']));
      });

      test('sets isLoading to false after load', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container.read(_paginationProvider.notifier).pages = [[]];
        await container.read(_paginationProvider.notifier).loadFirst();

        expect(container.read(_paginationProvider).isLoading, isFalse);
      });

      test('sets page to 0', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container.read(_paginationProvider.notifier).pages = [
          ['a'],
        ];
        await container.read(_paginationProvider.notifier).loadFirst();

        expect(container.read(_paginationProvider).page, equals(0));
      });

      test(
        'hasMore is false when page returns fewer than pageSize items',
        () async {
          final container = _makeContainer();
          addTearDown(container.dispose);

          // Return only 3 items — less than defaultPageSize (20).
          container.read(_paginationProvider.notifier).pages = [
            ['a', 'b', 'c'],
          ];

          await container.read(_paginationProvider.notifier).loadFirst();

          expect(container.read(_paginationProvider).hasMore, isFalse);
        },
      );

      test(
        'hasMore is true when page returns exactly pageSize items',
        () async {
          final container = _makeContainer();
          addTearDown(container.dispose);

          final fullPage = List.generate(
            PkPaginationNotifierMixin.defaultPageSize,
            (i) => 'item-$i',
          );
          container.read(_paginationProvider.notifier).pages = [fullPage];

          await container.read(_paginationProvider.notifier).loadFirst();

          expect(container.read(_paginationProvider).hasMore, isTrue);
        },
      );

      test('sets error when provider throws', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container.read(_paginationProvider.notifier).errorToThrow = Exception(
          'fetch failed',
        );

        await container.read(_paginationProvider.notifier).loadFirst();

        final state = container.read(_paginationProvider);
        expect(state.error, isA<Exception>());
      });
    });

    // -----------------------------------------------------------------------
    // loadMore
    // -----------------------------------------------------------------------

    group('loadMore', () {
      test('appends items to existing list', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final fullPage = List.generate(
          PkPaginationNotifierMixin.defaultPageSize,
          (i) => 'item-$i',
        );
        container.read(_paginationProvider.notifier).pages = [
          fullPage,
          ['extra-1', 'extra-2'],
        ];

        await container.read(_paginationProvider.notifier).loadFirst();
        await container.read(_paginationProvider.notifier).loadMore();

        final state = container.read(_paginationProvider);
        expect(state.items.length, equals(fullPage.length + 2));
        expect(state.items.last, equals('extra-2'));
      });

      test('increments page after loadMore', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final fullPage = List.generate(
          PkPaginationNotifierMixin.defaultPageSize,
          (i) => 'item-$i',
        );
        container.read(_paginationProvider.notifier).pages = [
          fullPage,
          ['x'],
        ];

        await container.read(_paginationProvider.notifier).loadFirst();
        await container.read(_paginationProvider.notifier).loadMore();

        expect(container.read(_paginationProvider).page, equals(1));
      });

      test('does nothing when hasMore is false', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        // Load a partial page so hasMore becomes false.
        container.read(_paginationProvider.notifier).pages = [
          ['only'],
        ];
        await container.read(_paginationProvider.notifier).loadFirst();

        final stateBeforeLoadMore = container.read(_paginationProvider);
        expect(stateBeforeLoadMore.hasMore, isFalse);

        await container.read(_paginationProvider.notifier).loadMore();

        final stateAfterLoadMore = container.read(_paginationProvider);
        expect(stateAfterLoadMore.items.length, equals(1));
        expect(stateAfterLoadMore.page, equals(0));
      });

      test('sets error on loadMore failure without clearing items', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        final fullPage = List.generate(
          PkPaginationNotifierMixin.defaultPageSize,
          (i) => 'item-$i',
        );
        container.read(_paginationProvider.notifier).pages = [fullPage];
        await container.read(_paginationProvider.notifier).loadFirst();

        // Now make the next page throw.
        container.read(_paginationProvider.notifier).errorToThrow = Exception(
          'page 1 failed',
        );
        await container.read(_paginationProvider.notifier).loadMore();

        final state = container.read(_paginationProvider);
        expect(state.error, isA<Exception>());
        expect(state.items.length, equals(fullPage.length));
        expect(state.isLoadingMore, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // reset
    // -----------------------------------------------------------------------

    group('reset', () {
      test('returns state to initial defaults', () async {
        final container = _makeContainer();
        addTearDown(container.dispose);

        container.read(_paginationProvider.notifier).pages = [
          ['a', 'b', 'c'],
        ];
        await container.read(_paginationProvider.notifier).loadFirst();

        container.read(_paginationProvider.notifier).reset();

        final state = container.read(_paginationProvider);
        expect(state.items, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.hasMore, isTrue);
        expect(state.page, equals(0));
        expect(state.error, isNull);
      });
    });
  });
}

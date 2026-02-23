import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/async_state.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AsyncLoading
  // ---------------------------------------------------------------------------
  group('AsyncLoading', () {
    test('isLoading is true', () {
      const state = AsyncState<int>.loading();
      expect(state.isLoading, isTrue);
    });

    test('isData is false', () {
      const state = AsyncState<int>.loading();
      expect(state.isData, isFalse);
    });

    test('isError is false', () {
      const state = AsyncState<int>.loading();
      expect(state.isError, isFalse);
    });

    test('isRefreshing is false', () {
      const state = AsyncState<int>.loading();
      expect(state.isRefreshing, isFalse);
    });

    test('hasValue is false', () {
      const state = AsyncState<int>.loading();
      expect(state.hasValue, isFalse);
    });

    test('valueOrNull is null', () {
      const state = AsyncState<int>.loading();
      expect(state.valueOrNull, isNull);
    });

    test('errorOrNull is null', () {
      const state = AsyncState<int>.loading();
      expect(state.errorOrNull, isNull);
    });

    test('equality: two AsyncLoading<int> are equal', () {
      expect(
        const AsyncState<int>.loading(),
        equals(const AsyncState<int>.loading()),
      );
    });

    test('toString contains loading', () {
      expect(const AsyncState<int>.loading().toString(), contains('loading'));
    });
  });

  // ---------------------------------------------------------------------------
  // AsyncData
  // ---------------------------------------------------------------------------
  group('AsyncData', () {
    test('isData is true', () {
      const state = AsyncState<int>.data(42);
      expect(state.isData, isTrue);
    });

    test('isLoading is false', () {
      const state = AsyncState<int>.data(42);
      expect(state.isLoading, isFalse);
    });

    test('isError is false', () {
      const state = AsyncState<int>.data(42);
      expect(state.isError, isFalse);
    });

    test('isRefreshing is false', () {
      const state = AsyncState<int>.data(42);
      expect(state.isRefreshing, isFalse);
    });

    test('hasValue is true', () {
      const state = AsyncState<int>.data(42);
      expect(state.hasValue, isTrue);
    });

    test('valueOrNull returns value', () {
      const state = AsyncState<int>.data(42);
      expect(state.valueOrNull, equals(42));
    });

    test('errorOrNull is null', () {
      const state = AsyncState<int>.data(42);
      expect(state.errorOrNull, isNull);
    });

    test('equality: same value', () {
      expect(
        const AsyncState<int>.data(42),
        equals(const AsyncState<int>.data(42)),
      );
    });

    test('inequality: different value', () {
      expect(
        const AsyncState<int>.data(42),
        isNot(equals(const AsyncState<int>.data(99))),
      );
    });

    test('map transforms value', () {
      const state = AsyncState<int>.data(5);
      final mapped = state.map((v) => v * 2);
      expect(mapped, equals(const AsyncState<int>.data(10)));
    });
  });

  // ---------------------------------------------------------------------------
  // AsyncError
  // ---------------------------------------------------------------------------
  group('AsyncError', () {
    final error = Exception('boom');
    final stackTrace = StackTrace.current;

    test('isError is true', () {
      final state = AsyncState<int>.error(error);
      expect(state.isError, isTrue);
    });

    test('isLoading is false', () {
      final state = AsyncState<int>.error(error);
      expect(state.isLoading, isFalse);
    });

    test('isData is false', () {
      final state = AsyncState<int>.error(error);
      expect(state.isData, isFalse);
    });

    test('isRefreshing is false', () {
      final state = AsyncState<int>.error(error);
      expect(state.isRefreshing, isFalse);
    });

    test('hasValue is false', () {
      final state = AsyncState<int>.error(error);
      expect(state.hasValue, isFalse);
    });

    test('valueOrNull is null', () {
      final state = AsyncState<int>.error(error);
      expect(state.valueOrNull, isNull);
    });

    test('errorOrNull returns error', () {
      final state = AsyncState<int>.error(error);
      expect(state.errorOrNull, equals(error));
    });

    test('stackTrace is nullable — null when not provided', () {
      final state = AsyncState<int>.error(error);
      expect((state as AsyncError<int>).stackTrace, isNull);
    });

    test('stackTrace carries value when provided', () {
      final state = AsyncState<int>.error(error, stackTrace: stackTrace);
      expect((state as AsyncError<int>).stackTrace, equals(stackTrace));
    });

    test('map preserves error type parameter', () {
      final state = AsyncState<int>.error(error);
      final mapped = state.map<String>((v) => v.toString());
      expect(mapped.isError, isTrue);
      expect(mapped.errorOrNull, equals(error));
    });
  });

  // ---------------------------------------------------------------------------
  // AsyncRefreshing
  // ---------------------------------------------------------------------------
  group('AsyncRefreshing', () {
    test('isRefreshing is true', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.isRefreshing, isTrue);
    });

    test('isLoading is false', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.isLoading, isFalse);
    });

    test('isData is false', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.isData, isFalse);
    });

    test('isError is false', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.isError, isFalse);
    });

    test('hasValue is true', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.hasValue, isTrue);
    });

    test('valueOrNull returns previousValue', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.valueOrNull, equals(10));
    });

    test('errorOrNull is null', () {
      final state = AsyncState<int>.refreshing(10);
      expect(state.errorOrNull, isNull);
    });

    test('map transforms previousValue', () {
      final state = AsyncState<int>.refreshing(3);
      final mapped = state.map((v) => v * 3);
      expect(mapped, isA<AsyncRefreshing<int>>());
      expect(mapped.valueOrNull, equals(9));
    });
  });

  // ---------------------------------------------------------------------------
  // when()
  // ---------------------------------------------------------------------------
  group('when()', () {
    test('loading branch called for AsyncLoading', () {
      const state = AsyncState<int>.loading();
      final result = state.when(
        loading: () => 'loading',
        data: (_) => 'data',
        error: (_, __) => 'error',
      );
      expect(result, equals('loading'));
    });

    test('data branch called for AsyncData', () {
      const state = AsyncState<int>.data(7);
      final result = state.when(
        loading: () => 0,
        data: (v) => v,
        error: (_, __) => -1,
      );
      expect(result, equals(7));
    });

    test('error branch called for AsyncError', () {
      final err = Exception('x');
      final state = AsyncState<int>.error(err);
      final result = state.when(
        loading: () => 'loading',
        data: (_) => 'data',
        error: (e, _) => e.toString(),
      );
      expect(result, contains('x'));
    });

    test('refreshing branch called for AsyncRefreshing when provided', () {
      final state = AsyncState<int>.refreshing(5);
      final result = state.when(
        loading: () => 'loading',
        data: (_) => 'data',
        error: (_, __) => 'error',
        refreshing: (prev) => 'refreshing:$prev',
      );
      expect(result, equals('refreshing:5'));
    });

    test('loading branch used for AsyncRefreshing when refreshing omitted', () {
      final state = AsyncState<int>.refreshing(5);
      final result = state.when(
        loading: () => 'loading',
        data: (_) => 'data',
        error: (_, __) => 'error',
      );
      expect(result, equals('loading'));
    });
  });

  // ---------------------------------------------------------------------------
  // maybeWhen()
  // ---------------------------------------------------------------------------
  group('maybeWhen()', () {
    test('orElse called when no matching branch provided — loading state', () {
      const state = AsyncState<int>.loading();
      final result = state.maybeWhen(
        orElse: () => 'else',
        data: (v) => 'data:$v',
      );
      expect(result, equals('else'));
    });

    test('matching branch takes precedence over orElse — data state', () {
      const state = AsyncState<int>.data(3);
      final result = state.maybeWhen(
        orElse: () => 'else',
        data: (v) => 'data:$v',
      );
      expect(result, equals('data:3'));
    });

    test('orElse called for error when error branch not provided', () {
      final state = AsyncState<int>.error(Exception('!'));
      final result = state.maybeWhen(
        orElse: () => 'fallback',
        data: (v) => 'data:$v',
      );
      expect(result, equals('fallback'));
    });

    test('refreshing branch matched for AsyncRefreshing', () {
      final state = AsyncState<int>.refreshing(9);
      final result = state.maybeWhen(
        orElse: () => 'else',
        refreshing: (prev) => 'refresh:$prev',
      );
      expect(result, equals('refresh:9'));
    });

    test('orElse called for AsyncRefreshing when refreshing branch absent', () {
      final state = AsyncState<int>.refreshing(9);
      final result = state.maybeWhen(
        orElse: () => 'else',
        data: (v) => 'data:$v',
      );
      expect(result, equals('else'));
    });
  });

  // ---------------------------------------------------------------------------
  // map()
  // ---------------------------------------------------------------------------
  group('map()', () {
    test('transforms AsyncData value', () {
      const state = AsyncState<int>.data(4);
      final result = state.map((v) => 'val:$v');
      expect(result.valueOrNull, equals('val:4'));
    });

    test('preserves AsyncLoading with new type', () {
      const state = AsyncState<int>.loading();
      final result = state.map<String>((v) => v.toString());
      expect(result.isLoading, isTrue);
      expect(result, isA<AsyncLoading<String>>());
    });

    test('preserves AsyncError with new type', () {
      final err = Exception('fail');
      final state = AsyncState<int>.error(err);
      final result = state.map<String>((v) => v.toString());
      expect(result.isError, isTrue);
      expect(result.errorOrNull, equals(err));
    });

    test('transforms AsyncRefreshing previousValue', () {
      final state = AsyncState<int>.refreshing(6);
      final result = state.map((v) => v + 1);
      expect(result.isRefreshing, isTrue);
      expect(result.valueOrNull, equals(7));
    });
  });

  // ---------------------------------------------------------------------------
  // AsyncStateNotifier
  // ---------------------------------------------------------------------------
  group('AsyncStateNotifier', () {
    test('initial state is AsyncLoading', () {
      final notifier = AsyncStateNotifier<int>();
      expect(notifier.state.isLoading, isTrue);
      notifier.dispose();
    });

    test('run() transitions loading -> data on success', () async {
      final notifier = AsyncStateNotifier<int>();
      await notifier.run(() async => 42);
      expect(notifier.state.isData, isTrue);
      expect(notifier.state.valueOrNull, equals(42));
      notifier.dispose();
    });

    test('run() transitions loading -> error on failure', () async {
      final notifier = AsyncStateNotifier<int>();
      await notifier.run(() async => throw Exception('bad'));
      expect(notifier.state.isError, isTrue);
      expect(notifier.state.errorOrNull, isA<Exception>());
      notifier.dispose();
    });

    test('run() notifies listeners on state changes', () async {
      final notifier = AsyncStateNotifier<int>();
      final states = <AsyncState<int>>[];
      notifier.addListener(() => states.add(notifier.state));

      await notifier.run(() async => 1);

      // Expect: loading (initial run), then data
      expect(states, hasLength(2));
      expect(states[0].isLoading, isTrue);
      expect(states[1].isData, isTrue);
      notifier.dispose();
    });

    test('refresh() transitions to refreshing, then data', () async {
      final notifier = AsyncStateNotifier<int>();
      await notifier.run(() async => 10);

      final states = <AsyncState<int>>[];
      notifier.addListener(() => states.add(notifier.state));

      await notifier.refresh(() async => 20);

      expect(states.first.isRefreshing, isTrue);
      expect(states.first.valueOrNull, equals(10));
      expect(states.last.isData, isTrue);
      expect(states.last.valueOrNull, equals(20));
      notifier.dispose();
    });

    test('refresh() falls back to run() when no previous value', () async {
      final notifier = AsyncStateNotifier<int>();
      // State is still loading (no previous value)
      await notifier.refresh(() async => 5);
      expect(notifier.state.isData, isTrue);
      expect(notifier.state.valueOrNull, equals(5));
      notifier.dispose();
    });

    test('reset() returns state to AsyncLoading', () async {
      final notifier = AsyncStateNotifier<int>();
      await notifier.run(() async => 3);
      notifier.reset();
      expect(notifier.state.isLoading, isTrue);
      notifier.dispose();
    });

    test('setData() directly sets AsyncData state', () {
      final notifier = AsyncStateNotifier<int>();
      notifier.setData(99);
      expect(notifier.state.isData, isTrue);
      expect(notifier.state.valueOrNull, equals(99));
      notifier.dispose();
    });

    test('setError() directly sets AsyncError state', () {
      final notifier = AsyncStateNotifier<int>();
      final err = Exception('direct');
      notifier.setError(err);
      expect(notifier.state.isError, isTrue);
      expect(notifier.state.errorOrNull, equals(err));
      notifier.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // PaginatedState
  // ---------------------------------------------------------------------------
  group('PaginatedState', () {
    test('initial state has no items and no load in progress', () {
      final state = PaginatedState<String>.initial();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isInitialLoad, isTrue);
      expect(state.error, isNull);
      expect(state.hasMore, isTrue);
      expect(state.page, equals(0));
    });

    test('copyWithNextPage appends items and increments page', () {
      final state = PaginatedState<String>.initial().copyWithNextPage([
        'a',
        'b',
      ], hasMore: true);
      expect(state.items, equals(['a', 'b']));
      expect(state.page, equals(1));
      expect(state.hasMore, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isInitialLoad, isFalse);
    });

    test('copyWithError keeps existing items', () {
      final initial = PaginatedState<int>.initial().copyWithNextPage([
        1,
        2,
      ], hasMore: true);
      final err = Exception('fail');
      final errState = initial.copyWithError(err);
      expect(errState.items, equals([1, 2]));
      expect(errState.error, equals(err));
      expect(errState.isLoading, isFalse);
    });

    test('copyWithLoading sets isLoading true and clears error', () {
      final state = PaginatedState<int>.initial()
          .copyWithNextPage([1], hasMore: true)
          .copyWithError(Exception('x'))
          .copyWithLoading();
      expect(state.isLoading, isTrue);
      expect(state.error, isNull);
    });

    test('reset clears all state', () {
      final loaded = PaginatedState<int>.initial().copyWithNextPage([
        1,
        2,
        3,
      ], hasMore: false);
      final reset = loaded.reset();
      expect(reset.items, isEmpty);
      expect(reset.page, equals(0));
      expect(reset.hasMore, isTrue);
      expect(reset.isInitialLoad, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // PaginatedNotifier
  // ---------------------------------------------------------------------------
  group('PaginatedNotifier', () {
    test('loadFirst populates items and sets isInitialLoad to false', () async {
      final notifier = PaginatedNotifier<int>();
      await notifier.loadFirst(
        (page, size) async => List.generate(size, (i) => i),
        pageSize: 5,
      );
      expect(notifier.state.items, hasLength(5));
      expect(notifier.state.isInitialLoad, isFalse);
      expect(notifier.state.hasMore, isTrue);
      notifier.dispose();
    });

    test('loadNext appends items', () async {
      final notifier = PaginatedNotifier<int>();
      await notifier.loadFirst(
        (page, size) async => List.generate(size, (i) => page * size + i),
        pageSize: 3,
      );
      await notifier.loadNext();
      expect(notifier.state.items, hasLength(6));
      expect(notifier.state.page, equals(2));
      notifier.dispose();
    });

    test(
      'hasMore is false when loader returns fewer items than pageSize',
      () async {
        final notifier = PaginatedNotifier<int>();
        await notifier.loadFirst(
          (page, size) async => [1, 2], // fewer than pageSize
          pageSize: 5,
        );
        expect(notifier.state.hasMore, isFalse);
        notifier.dispose();
      },
    );

    test('loadNext does nothing when hasMore is false', () async {
      final notifier = PaginatedNotifier<int>();
      await notifier.loadFirst((_, __) async => [1, 2], pageSize: 5);
      final pageBeforeLoadNext = notifier.state.page;
      await notifier.loadNext();
      expect(notifier.state.page, equals(pageBeforeLoadNext));
      notifier.dispose();
    });

    test('refresh resets and reloads from page 0', () async {
      final notifier = PaginatedNotifier<int>();
      await notifier.loadFirst(
        (page, size) async => List.generate(size, (i) => i),
        pageSize: 3,
      );
      await notifier.loadNext();
      expect(notifier.state.items, hasLength(6));

      await notifier.refresh();
      expect(notifier.state.items, hasLength(3));
      expect(notifier.state.page, equals(1));
      notifier.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // AsyncBuilder widget
  // ---------------------------------------------------------------------------
  group('AsyncBuilder', () {
    testWidgets('renders CircularProgressIndicator for AsyncLoading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncBuilder<int>(
            state: const AsyncState.loading(),
            data: (v) => Text('$v'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders data widget for AsyncData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncBuilder<int>(
            state: const AsyncState.data(42),
            data: (v) => Text('value:$v'),
          ),
        ),
      );
      expect(find.text('value:42'), findsOneWidget);
    });

    testWidgets('renders error widget for AsyncError', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncBuilder<int>(
            state: const AsyncState.error('oops'),
            data: (v) => Text('$v'),
          ),
        ),
      );
      expect(find.textContaining('oops'), findsOneWidget);
    });

    testWidgets(
      'renders Stack with LinearProgressIndicator for AsyncRefreshing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AsyncBuilder<int>(
              state: AsyncState.refreshing(5),
              data: (v) => Text('val:$v'),
            ),
          ),
        );
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('val:5'), findsOneWidget);
      },
    );

    testWidgets('uses custom loading builder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncBuilder<int>(
            state: const AsyncState.loading(),
            data: (v) => Text('$v'),
            loading: () => const Text('custom-loading'),
          ),
        ),
      );
      expect(find.text('custom-loading'), findsOneWidget);
    });

    testWidgets('uses custom error builder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncBuilder<int>(
            state: const AsyncState.error('err'),
            data: (v) => Text('$v'),
            error: (e, _) => Text('custom-error:$e'),
          ),
        ),
      );
      expect(find.textContaining('custom-error'), findsOneWidget);
    });
  });
}

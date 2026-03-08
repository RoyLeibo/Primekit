import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/riverpod.dart';

// ---------------------------------------------------------------------------
// Concrete notifier under test
// ---------------------------------------------------------------------------

class _CounterNotifier extends AsyncNotifier<int>
    with PkAsyncNotifierMixin<int> {
  @override
  Future<int> build() async => 0;

  Future<void> fetch(
    Future<int> Function() fetcher, {
    bool preserveData = true,
  }) => guard(fetcher, preserveData: preserveData);
}

final _counterProvider = AsyncNotifierProvider<_CounterNotifier, int>(
  _CounterNotifier.new,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PkAsyncNotifierMixin', () {
    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------

    group('initial state', () {
      test('build returns initial value 0', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final value = await container.read(_counterProvider.future);
        expect(value, equals(0));
      });
    });

    // -----------------------------------------------------------------------
    // guard — success
    // -----------------------------------------------------------------------

    group('guard — success', () {
      test('state becomes AsyncData with the returned value', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);
        await container.read(_counterProvider.notifier).fetch(() async => 42);

        expect(container.read(_counterProvider).value, equals(42));
      });

      test('currentData equals the returned value', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);
        await container.read(_counterProvider.notifier).fetch(() async => 7);

        expect(
          container.read(_counterProvider.notifier).currentData,
          equals(7),
        );
      });

      test('isLoading is false after successful fetch', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);
        await container.read(_counterProvider.notifier).fetch(() async => 7);

        expect(container.read(_counterProvider.notifier).isLoading, isFalse);
      });

      test('currentError is null after successful fetch', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);
        await container.read(_counterProvider.notifier).fetch(() async => 1);

        expect(container.read(_counterProvider.notifier).currentError, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // guard — error
    // -----------------------------------------------------------------------

    group('guard — error', () {
      test('state becomes AsyncError when operation throws', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);

        await container.read(_counterProvider.notifier).fetch(() async {
          throw Exception('network failure');
        });

        final state = container.read(_counterProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<Exception>());
      });

      test('currentError is non-null after failure', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);

        await container.read(_counterProvider.notifier).fetch(() async {
          throw StateError('bad state');
        });

        expect(
          container.read(_counterProvider.notifier).currentError,
          isA<StateError>(),
        );
      });

      test('currentData is null after error', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);

        await container.read(_counterProvider.notifier).fetch(() async {
          throw Exception('oops');
        });

        expect(container.read(_counterProvider.notifier).currentData, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // guard — preserveData flag
    // -----------------------------------------------------------------------

    group('guard — preserveData', () {
      test(
        'preserveData:true keeps previous value visible during loading',
        () async {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          await container.read(_counterProvider.future);
          // Establish a known data value.
          await container.read(_counterProvider.notifier).fetch(() async => 99);

          // Start a long operation that won't complete yet.
          final completer = Completer<int>();
          unawaited(
            container
                .read(_counterProvider.notifier)
                .fetch(() => completer.future),
          );

          final loadingState = container.read(_counterProvider);
          expect(loadingState.isLoading, isTrue);
          // Previous value should still be accessible.
          expect(loadingState.valueOrNull, equals(99));

          completer.complete(100);
          await Future<void>.delayed(Duration.zero);
        },
      );

      test('preserveData:false clears previous value during loading', () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(_counterProvider.future);
        await container.read(_counterProvider.notifier).fetch(() async => 99);

        final completer = Completer<int>();
        unawaited(
          container
              .read(_counterProvider.notifier)
              .fetch(() => completer.future, preserveData: false),
        );

        final loadingState = container.read(_counterProvider);
        expect(loadingState.isLoading, isTrue);
        // No previous value when preserveData is false.
        expect(container.read(_counterProvider.notifier).currentData, isNull);

        completer.complete(200);
        await Future<void>.delayed(Duration.zero);
      });
    });
  });
}

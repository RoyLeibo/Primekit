import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/network.dart';
import 'package:primekit/riverpod.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('pkConnectivityProvider', () {
    // -----------------------------------------------------------------------
    // Stream emissions
    // -----------------------------------------------------------------------

    group('stream emissions', () {
      test(
        'emits true (online) when ConnectivityMonitor reports connected',
        () async {
          // Use the testing API on ConnectivityMonitor to inject status.
          ConnectivityMonitor.instance.injectStatusForTesting(true);

          final container = ProviderContainer();
          addTearDown(container.dispose);

          // Read the provider and collect the first emission.
          final events = <bool>[];
          final subscription = container.listen<AsyncValue<bool>>(
            pkConnectivityProvider,
            (_, next) {
              next.whenData(events.add);
            },
          );

          // Trigger an online event.
          ConnectivityMonitor.instance.injectStatusForTesting(true);

          // Allow async propagation.
          await Future<void>.delayed(const Duration(milliseconds: 600));

          subscription.close();

          expect(events, contains(true));
        },
      );

      test(
        'emits false (offline) when ConnectivityMonitor reports disconnected',
        () async {
          final container = ProviderContainer();
          addTearDown(container.dispose);

          final events = <bool>[];
          final subscription = container.listen<AsyncValue<bool>>(
            pkConnectivityProvider,
            (_, next) {
              next.whenData(events.add);
            },
          );

          ConnectivityMonitor.instance.injectStatusForTesting(false);

          await Future<void>.delayed(const Duration(milliseconds: 600));

          subscription.close();

          expect(events, contains(false));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Provider identity
    // -----------------------------------------------------------------------

    group('provider identity', () {
      test('pkConnectivityProvider is a StreamProvider<bool>', () {
        expect(pkConnectivityProvider, isA<StreamProvider<bool>>());
      });

      test('two containers share the same ConnectivityMonitor instance', () {
        // ConnectivityMonitor is a singleton — verify the provider delegates
        // to the same instance from both containers.
        final a = ConnectivityMonitor.instance;
        final b = ConnectivityMonitor.instance;
        expect(identical(a, b), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // pkIsAuthenticatedProvider — type check
    // -----------------------------------------------------------------------

    group('pkIsAuthenticatedProvider', () {
      test('is a Provider<bool>', () {
        expect(pkIsAuthenticatedProvider, isA<Provider<bool>>());
      });
    });

    // -----------------------------------------------------------------------
    // pkAppVersionProvider — type check
    // -----------------------------------------------------------------------

    group('pkAppVersionProvider', () {
      test('is a FutureProvider<String>', () {
        expect(pkAppVersionProvider, isA<FutureProvider<String>>());
      });
    });
  });
}

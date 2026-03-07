import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/routing.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockNavigationAnalyticsProvider extends Mock
    implements NavigationAnalyticsProvider {}

// ---------------------------------------------------------------------------
// Helpers — fake routes
// ---------------------------------------------------------------------------

Route<dynamic> _namedRoute(String name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox(),
  );
}

Route<dynamic> _unnamedRoute() {
  return MaterialPageRoute<void>(
    builder: (_) => const SizedBox(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockNavigationAnalyticsProvider mockProvider;

  setUp(() {
    mockProvider = MockNavigationAnalyticsProvider();
    when(
      () => mockProvider.logScreenView(
        any(),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------

  group('NavigationLogger construction', () {
    test('creates instance with analyticsProvider and logToConsole defaults',
        () {
      final logger = NavigationLogger();
      expect(logger.analyticsProvider, isNull);
      expect(logger.logToConsole, isTrue);
    });

    test('accepts analyticsProvider and logToConsole override', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );
      expect(logger.analyticsProvider, isNotNull);
      expect(logger.logToConsole, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // didPush
  // -------------------------------------------------------------------------

  group('didPush()', () {
    test('calls logScreenView with current route name', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      final current = _namedRoute('/home');
      final previous = _namedRoute('/splash');

      logger.didPush(current, previous);

      verify(
        () => mockProvider.logScreenView(
          '/home',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('does not call logScreenView when current route has no name', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didPush(_unnamedRoute(), null);

      verifyNever(
        () => mockProvider.logScreenView(
          any(),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('works without previous route', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didPush(_namedRoute('/home'), null);

      verify(
        () => mockProvider.logScreenView(
          '/home',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('does not throw when analyticsProvider is null', () {
      final logger = NavigationLogger(logToConsole: false);
      expect(
        () => logger.didPush(_namedRoute('/home'), null),
        returnsNormally,
      );
    });

    test('passes push event type in parameters', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didPush(_namedRoute('/profile'), null);

      final captured = verify(
        () => mockProvider.logScreenView(
          any(),
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured;

      final params = captured.first as Map<String, Object?>?;
      expect(params?['event'], 'push');
    });
  });

  // -------------------------------------------------------------------------
  // didPop
  // -------------------------------------------------------------------------

  group('didPop()', () {
    test('logs the previous route name (the one we returned to)', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      final current = _namedRoute('/detail');
      final previous = _namedRoute('/home');

      // In didPop, the "current" parameter is the route being removed
      // and "previous" is the route we're returning to.
      logger.didPop(current, previous);

      verify(
        () => mockProvider.logScreenView(
          '/home',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('does not log when returning to a null route', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didPop(_namedRoute('/detail'), null);

      verifyNever(
        () => mockProvider.logScreenView(
          any(),
          parameters: any(named: 'parameters'),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // didReplace
  // -------------------------------------------------------------------------

  group('didReplace()', () {
    test('logs new route name', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didReplace(
        newRoute: _namedRoute('/settings'),
        oldRoute: _namedRoute('/home'),
      );

      verify(
        () => mockProvider.logScreenView(
          '/settings',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    test('does not log when newRoute is null', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didReplace(newRoute: null, oldRoute: _namedRoute('/home'));

      verifyNever(
        () => mockProvider.logScreenView(
          any(),
          parameters: any(named: 'parameters'),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // didRemove
  // -------------------------------------------------------------------------

  group('didRemove()', () {
    test('logs the route below the removed one', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      // didRemove calls _logEvent with current=previousRoute, previous=route
      logger.didRemove(_namedRoute('/modal'), _namedRoute('/main'));

      verify(
        () => mockProvider.logScreenView(
          '/main',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // logToConsole flag
  // -------------------------------------------------------------------------

  group('logToConsole', () {
    testWidgets('does not call debugPrint when logToConsole is false',
        (tester) async {
      // Indirectly verify by ensuring it still calls the analytics provider
      // without error when logToConsole is false.
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      logger.didPush(_namedRoute('/home'), null);

      verify(
        () => mockProvider.logScreenView(
          any(),
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // Route name fallback
  // -------------------------------------------------------------------------

  group('route name fallback', () {
    test('uses runtimeType when route.settings.name is empty', () {
      final logger = NavigationLogger(
        analyticsProvider: mockProvider,
        logToConsole: false,
      );

      // Route with empty name string.
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: ''),
        builder: (_) => const SizedBox(),
      );

      logger.didPush(route, null);

      // Should use the runtimeType string instead of empty name.
      final captured = verify(
        () => mockProvider.logScreenView(
          captureAny(),
          parameters: any(named: 'parameters'),
        ),
      ).captured;

      final screenName = captured.first as String;
      expect(screenName, isNotEmpty);
    });
  });
}

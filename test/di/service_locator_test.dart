import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/di.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _Counter {
  int count = 0;
}

class _Disposable implements PkDisposable {
  bool disposed = false;

  @override
  Future<void> dispose() async => disposed = true;
}

class _Service {
  _Service(this.id);
  final int id;
}

class _AuthModule implements DiModule {
  @override
  void register(ServiceLocator locator) {
    locator.registerSingleton<_Service>(_Service(1));
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ServiceLocator locator;

  setUp(() => locator = ServiceLocator());
  tearDown(() => locator.reset());

  // ---------------------------------------------------------------------------
  // registerSingleton
  // ---------------------------------------------------------------------------
  group('registerSingleton', () {
    test('returns the same instance every time', () {
      final instance = _Counter();
      locator.registerSingleton<_Counter>(instance);

      final a = locator.get<_Counter>();
      final b = locator.get<_Counter>();
      expect(identical(a, b), isTrue);
    });

    test('returns the exact registered object', () {
      final instance = _Counter()..count = 7;
      locator.registerSingleton<_Counter>(instance);
      expect(locator.get<_Counter>().count, equals(7));
    });
  });

  // ---------------------------------------------------------------------------
  // registerLazySingleton
  // ---------------------------------------------------------------------------
  group('registerLazySingleton', () {
    test('creates instance only once', () {
      var callCount = 0;
      locator.registerLazySingleton<_Counter>((_) {
        callCount++;
        return _Counter();
      });

      locator.get<_Counter>();
      locator.get<_Counter>();
      expect(callCount, equals(1));
    });

    test('returns same instance on repeated calls', () {
      locator.registerLazySingleton<_Counter>((_) => _Counter());
      final a = locator.get<_Counter>();
      final b = locator.get<_Counter>();
      expect(identical(a, b), isTrue);
    });

    test('is not created until first get', () {
      var created = false;
      locator.registerLazySingleton<_Counter>((_) {
        created = true;
        return _Counter();
      });
      expect(created, isFalse);
      locator.get<_Counter>();
      expect(created, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // registerFactory
  // ---------------------------------------------------------------------------
  group('registerFactory', () {
    test('creates a new instance on every get', () {
      locator.registerFactory<_Counter>((_) => _Counter());
      final a = locator.get<_Counter>();
      final b = locator.get<_Counter>();
      expect(identical(a, b), isFalse);
    });

    test('factory receives the locator', () {
      locator.registerSingleton<_Counter>(_Counter()..count = 5);
      locator.registerFactory<_Service>(
        (loc) => _Service(loc.get<_Counter>().count),
      );
      expect(locator.get<_Service>().id, equals(5));
    });
  });

  // ---------------------------------------------------------------------------
  // tryGet
  // ---------------------------------------------------------------------------
  group('tryGet', () {
    test('returns null for unregistered type', () {
      expect(locator.tryGet<_Counter>(), isNull);
    });

    test('returns instance for registered type', () {
      locator.registerSingleton<_Counter>(_Counter());
      expect(locator.tryGet<_Counter>(), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // isRegistered
  // ---------------------------------------------------------------------------
  group('isRegistered', () {
    test('returns false for unregistered type', () {
      expect(locator.isRegistered<_Counter>(), isFalse);
    });

    test('returns true after registration', () {
      locator.registerSingleton<_Counter>(_Counter());
      expect(locator.isRegistered<_Counter>(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // get — error case
  // ---------------------------------------------------------------------------
  group('get errors', () {
    test('throws StateError for unregistered type', () {
      expect(() => locator.get<_Counter>(), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // reset
  // ---------------------------------------------------------------------------
  group('reset', () {
    test('clears all registrations', () {
      locator.registerSingleton<_Counter>(_Counter());
      locator.reset();
      expect(locator.isRegistered<_Counter>(), isFalse);
    });

    test('get throws after reset', () {
      locator.registerSingleton<_Counter>(_Counter());
      locator.reset();
      expect(() => locator.get<_Counter>(), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // disposeAll
  // ---------------------------------------------------------------------------
  group('disposeAll', () {
    test('calls dispose on PkDisposable singletons', () async {
      final d = _Disposable();
      locator.registerSingleton<_Disposable>(d);
      await locator.disposeAll();
      expect(d.disposed, isTrue);
    });

    test('does not throw for non-disposable singletons', () async {
      locator.registerSingleton<_Counter>(_Counter());
      await expectLater(locator.disposeAll(), completes);
    });

    test(
      'does not call dispose on lazy singletons that have not been created',
      () async {
        var created = false;
        locator.registerLazySingleton<_Disposable>((_) {
          created = true;
          return _Disposable();
        });
        // Never called get<>, so the instance was never created.
        await locator.disposeAll();
        expect(created, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // registerSingletonAsync / allReady
  // ---------------------------------------------------------------------------
  group('registerSingletonAsync / allReady', () {
    test('resolves async singleton after allReady', () async {
      locator.registerSingletonAsync<_Counter>(
        (_) async => _Counter()..count = 99,
      );
      await locator.allReady();
      expect(locator.get<_Counter>().count, equals(99));
    });

    test('same instance returned after resolution', () async {
      locator.registerSingletonAsync<_Counter>((_) async => _Counter());
      await locator.allReady();
      final a = locator.get<_Counter>();
      final b = locator.get<_Counter>();
      expect(identical(a, b), isTrue);
    });

    test('get before allReady throws StateError', () async {
      locator.registerSingletonAsync<_Counter>(
        (_) => Future.delayed(const Duration(milliseconds: 50), _Counter.new),
      );
      // Do NOT await allReady
      expect(() => locator.get<_Counter>(), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // ServiceScope
  // ---------------------------------------------------------------------------
  group('ServiceScope', () {
    test('inherits singleton registrations from parent', () {
      locator.registerSingleton<_Counter>(_Counter()..count = 3);
      final scope = ServiceScope.of(locator);
      expect(scope.get<_Counter>().count, equals(3));
    });

    test('scoped instances are independent between scopes', () {
      locator.registerScoped<_Counter>((_) => _Counter());
      final scopeA = ServiceScope.of(locator);
      final scopeB = ServiceScope.of(locator);
      final a = scopeA.get<_Counter>();
      final b = scopeB.get<_Counter>();
      expect(identical(a, b), isFalse);
    });

    test('scoped instance is shared within the same scope', () {
      locator.registerScoped<_Counter>((_) => _Counter());
      final scope = ServiceScope.of(locator);
      final a = scope.get<_Counter>();
      final b = scope.get<_Counter>();
      expect(identical(a, b), isTrue);
    });

    test('dispose calls PkDisposable.dispose on scoped instances', () async {
      locator.registerScoped<_Disposable>((_) => _Disposable());
      final scope = ServiceScope.of(locator);
      final d = scope.get<_Disposable>();

      await scope.dispose();
      expect(d.disposed, isTrue);
    });

    test('get throws after scope is disposed', () async {
      locator.registerScoped<_Counter>((_) => _Counter());
      final scope = ServiceScope.of(locator);
      await scope.dispose();
      expect(() => scope.get<_Counter>(), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // DiModule
  // ---------------------------------------------------------------------------
  group('DiModule', () {
    test('registerModule calls module.register with the locator', () {
      locator.registerModule(_AuthModule());
      expect(locator.isRegistered<_Service>(), isTrue);
    });

    test('services registered by module are resolvable', () {
      locator.registerModule(_AuthModule());
      expect(locator.get<_Service>().id, equals(1));
    });
  });
}

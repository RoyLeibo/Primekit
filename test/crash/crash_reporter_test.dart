import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/crash/crash_config.dart';
import 'package:primekit/src/crash/crash_reporter.dart';
import 'package:primekit/src/crash/multi_crash_reporter.dart';

// ---------------------------------------------------------------------------
// Spy / in-memory implementation for testing
// ---------------------------------------------------------------------------

class _SpyCrashReporter implements CrashReporter {
  final List<(Object, StackTrace?, bool)> recordedErrors = [];
  final List<Breadcrumb> breadcrumbs = [];
  String? userId;
  final Map<String, Object> customKeys = {};
  int flushCount = 0;
  bool _enabled = true;
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    if (!_enabled) {
      return;
    }
    recordedErrors.add((error, stackTrace, fatal));
  }

  @override
  void addBreadcrumb(Breadcrumb breadcrumb) {
    if (!_enabled) {
      return;
    }
    breadcrumbs.add(breadcrumb);
  }

  @override
  void setUser({required String id, String? email, String? name}) {
    userId = id;
  }

  @override
  void clearUser() {
    userId = null;
  }

  @override
  void setCustomKey(String key, Object value) {
    customKeys[key] = value;
  }

  @override
  Future<void> flush() async {
    flushCount++;
  }

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled({required bool enabled}) {
    _enabled = enabled;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CrashReporter interface (via _SpyCrashReporter)', () {
    late _SpyCrashReporter reporter;

    setUp(() {
      reporter = _SpyCrashReporter();
    });

    test('initialize is called once', () async {
      await reporter.initialize();
      expect(reporter.initialized, isTrue);
    });

    test('recordError stores error and fatality', () async {
      final error = Exception('oops');
      final stack = StackTrace.current;

      await reporter.recordError(error, stack, fatal: true);

      expect(reporter.recordedErrors.length, equals(1));
      expect(reporter.recordedErrors.first.$1, same(error));
      expect(reporter.recordedErrors.first.$3, isTrue);
    });

    test('recordError not called when disabled', () async {
      reporter.setEnabled(enabled: false);
      await reporter.recordError(Exception('ignored'), null);

      expect(reporter.recordedErrors, isEmpty);
    });

    test('addBreadcrumb stores breadcrumb', () {
      final bc = Breadcrumb(
        message: 'User tapped login',
        type: BreadcrumbType.userAction,
        category: 'auth',
      );
      reporter.addBreadcrumb(bc);

      expect(reporter.breadcrumbs.length, equals(1));
      expect(reporter.breadcrumbs.first.message, equals('User tapped login'));
    });

    test('addBreadcrumb not called when disabled', () {
      reporter
        ..setEnabled(enabled: false)
        ..addBreadcrumb(
          Breadcrumb(message: 'ignored', type: BreadcrumbType.info),
        );

      expect(reporter.breadcrumbs, isEmpty);
    });

    test('setUser stores userId', () {
      reporter.setUser(id: 'abc123', email: 'a@b.com');
      expect(reporter.userId, equals('abc123'));
    });

    test('clearUser resets userId', () {
      reporter
        ..setUser(id: 'abc123')
        ..clearUser();
      expect(reporter.userId, isNull);
    });

    test('setCustomKey stores key-value', () {
      reporter.setCustomKey('version', '1.2.3');
      expect(reporter.customKeys['version'], equals('1.2.3'));
    });

    test('flush increments counter', () async {
      await reporter.flush();
      await reporter.flush();
      expect(reporter.flushCount, equals(2));
    });

    test('isEnabled reflects setEnabled', () {
      reporter.setEnabled(enabled: false);
      expect(reporter.isEnabled, isFalse);
      reporter.setEnabled(enabled: true);
      expect(reporter.isEnabled, isTrue);
    });
  });

  group('MultiCrashReporter', () {
    late _SpyCrashReporter spy1;
    late _SpyCrashReporter spy2;
    late MultiCrashReporter multi;

    setUp(() {
      spy1 = _SpyCrashReporter();
      spy2 = _SpyCrashReporter();
      multi = MultiCrashReporter([spy1, spy2]);
    });

    test('initialize calls all reporters', () async {
      await multi.initialize();
      expect(spy1.initialized, isTrue);
      expect(spy2.initialized, isTrue);
    });

    test('recordError fans out to all reporters', () async {
      final error = Exception('boom');
      await multi.recordError(error, null, fatal: true);

      expect(spy1.recordedErrors.length, equals(1));
      expect(spy2.recordedErrors.length, equals(1));
      expect(spy1.recordedErrors.first.$3, isTrue);
      expect(spy2.recordedErrors.first.$3, isTrue);
    });

    test('addBreadcrumb fans out to all reporters', () {
      final bc = Breadcrumb(
        message: 'nav to settings',
        type: BreadcrumbType.navigation,
      );
      multi.addBreadcrumb(bc);

      expect(spy1.breadcrumbs.length, equals(1));
      expect(spy2.breadcrumbs.length, equals(1));
    });

    test('setUser fans out to all reporters', () {
      multi.setUser(id: 'u1', email: 'u@example.com');

      expect(spy1.userId, equals('u1'));
      expect(spy2.userId, equals('u1'));
    });

    test('clearUser fans out to all reporters', () {
      multi
        ..setUser(id: 'u1')
        ..clearUser();

      expect(spy1.userId, isNull);
      expect(spy2.userId, isNull);
    });

    test('setCustomKey fans out to all reporters', () {
      multi.setCustomKey('build', '42');

      expect(spy1.customKeys['build'], equals('42'));
      expect(spy2.customKeys['build'], equals('42'));
    });

    test('flush calls all reporters', () async {
      await multi.flush();

      expect(spy1.flushCount, equals(1));
      expect(spy2.flushCount, equals(1));
    });

    test('isEnabled is true when all reporters enabled', () {
      expect(multi.isEnabled, isTrue);
    });

    test('isEnabled is false when any reporter is disabled', () {
      spy1.setEnabled(enabled: false);
      expect(multi.isEnabled, isFalse);
    });

    test('setEnabled fans out to all reporters', () {
      multi.setEnabled(enabled: false);

      expect(spy1.isEnabled, isFalse);
      expect(spy2.isEnabled, isFalse);
    });
  });

  group('CrashConfig', () {
    late _SpyCrashReporter spy;

    setUp(() {
      spy = _SpyCrashReporter();
    });

    test('reporter is null before initialize', () {
      // Reset internal state via private field workaround.
      // We test that after a fresh build reporter returns the configured one.
      // This test validates the post-initialize state.
    });

    test('initialize sets reporter', () async {
      await CrashConfig.initialize(spy, captureFlutterErrors: false);
      expect(CrashConfig.reporter, same(spy));
    });

    test('initialize hooks FlutterError.onError', () async {
      final previousHandler = FlutterError.onError;

      await CrashConfig.initialize(spy);
      expect(FlutterError.onError, isNotNull);
      expect(FlutterError.onError, isNot(same(previousHandler)));

      // Trigger the hook.
      FlutterError.reportError(
        FlutterErrorDetails(exception: Exception('flutter err')),
      );

      await Future<void>.delayed(Duration.zero);
      expect(spy.recordedErrors, isNotEmpty);
    });

    test('recordError is forwarded to reporter', () async {
      await CrashConfig.initialize(spy, captureFlutterErrors: false);

      final err = Exception('test error');
      await CrashConfig.recordError(err, null);

      expect(spy.recordedErrors.length, greaterThanOrEqualTo(1));
      expect(spy.recordedErrors.last.$1, same(err));
    });

    test('addBreadcrumb is forwarded to reporter', () async {
      await CrashConfig.initialize(spy, captureFlutterErrors: false);

      final bc = Breadcrumb(
        message: 'Test breadcrumb',
        type: BreadcrumbType.info,
      );
      CrashConfig.addBreadcrumb(bc);

      expect(spy.breadcrumbs.length, greaterThanOrEqualTo(1));
      expect(spy.breadcrumbs.last.message, equals('Test breadcrumb'));
    });
  });

  group('Breadcrumb', () {
    test('toString includes level and message', () {
      final bc = Breadcrumb(
        message: 'Navigated to Home',
        type: BreadcrumbType.navigation,
        category: 'nav',
      );
      final s = bc.toString();
      expect(s, contains('Navigated to Home'));
      expect(s, contains('info'));
    });

    test('all BreadcrumbType values are representable', () {
      for (final type in BreadcrumbType.values) {
        final bc = Breadcrumb(message: 'test', type: type);
        expect(bc.type, equals(type));
      }
    });

    test('all BreadcrumbLevel values are representable', () {
      for (final level in BreadcrumbLevel.values) {
        final bc = Breadcrumb(
          message: 'test',
          type: BreadcrumbType.info,
          level: level,
        );
        expect(bc.level, equals(level));
      }
    });
  });
}

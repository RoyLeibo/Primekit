import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/crash/crash_reporter.dart';
import 'package:primekit/src/crash/error_boundary.dart';

// ---------------------------------------------------------------------------
// Spy reporter
// ---------------------------------------------------------------------------

class _SpyCrashReporter implements CrashReporter {
  final List<Object> errors = [];
  bool _enabled = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    errors.add(error);
  }

  @override
  void addBreadcrumb(Breadcrumb breadcrumb) {}

  @override
  void setUser({required String id, String? email, String? name}) {}

  @override
  void clearUser() {}

  @override
  void setCustomKey(String key, Object value) {}

  @override
  Future<void> flush() async {}

  @override
  bool get isEnabled => _enabled;

  @override
  void setEnabled({required bool enabled}) {
    _enabled = enabled;
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

/// Widget that throws unconditionally during build.
class _ThrowingWidget extends StatelessWidget {
  const _ThrowingWidget({this.error = 'Build error!'});

  final Object error;

  @override
  Widget build(BuildContext context) => throw Exception(error);
}

/// Widget that renders normally.
class _GoodWidget extends StatelessWidget {
  const _GoodWidget();

  @override
  Widget build(BuildContext context) =>
      const Text('All good', key: Key('good'));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: _GoodWidget())),
      );

      expect(find.text('All good'), findsOneWidget);
    });

    testWidgets('renders custom fallback when child throws', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            fallback: Text('Oops!'),
            child: _ThrowingWidget(),
          ),
        ),
      );
      // Clear the build exception recorded by the test framework.
      tester.takeException();
      // Let microtask + rebuild run.
      await tester.pumpAndSettle();

      expect(find.text('Oops!'), findsOneWidget);
    });

    testWidgets('renders default error widget when no fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: _ThrowingWidget())),
      );
      tester.takeException();
      await tester.pumpAndSettle();

      // Default fallback contains the error card text.
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('calls onError with error and stack', (tester) async {
      Object? capturedError;
      StackTrace? capturedStack;

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (e, st) {
              capturedError = e;
              capturedStack = st;
            },
            fallback: const Text('fallback'),
            child: const _ThrowingWidget(error: 'test error'),
          ),
        ),
      );
      tester.takeException();
      await tester.pumpAndSettle();

      expect(capturedError, isNotNull);
      expect(capturedStack, isNotNull);
      expect(capturedError.toString(), contains('test error'));
    });

    testWidgets('calls reporter.recordError when reporter provided', (
      tester,
    ) async {
      final spy = _SpyCrashReporter();

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            reporter: spy,
            fallback: const Text('fallback'),
            child: const _ThrowingWidget(error: 'reported error'),
          ),
        ),
      );
      tester.takeException();
      await tester.pumpAndSettle();

      expect(spy.errors, isNotEmpty);
    });

    testWidgets('good child renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: _GoodWidget())),
      );
      await tester.pump();

      expect(find.text('All good'), findsOneWidget);
    });
  });
}

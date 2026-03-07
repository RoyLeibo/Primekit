import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/routing.dart';

// ---------------------------------------------------------------------------
// Fakes & concrete guards for testing
// ---------------------------------------------------------------------------

class FakeGoRouterState extends Fake implements GoRouterState {}

/// A guard that always allows navigation (returns null).
class AllowGuard extends RouteGuard {
  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async =>
      null;
}

/// A guard that always redirects to the given path.
class RedirectGuard extends RouteGuard {
  RedirectGuard(this.path);
  final String path;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async =>
      path;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late GoRouterState fakeState;
  late BuildContext fakeContext;

  setUpAll(() {
    registerFallbackValue(FakeGoRouterState());
  });

  setUp(() {
    fakeState = FakeGoRouterState();
  });

  // We use a simple WidgetTester to obtain a real BuildContext.
  testWidgets('setup context', (tester) async {
    fakeContext = tester.element(find.byType(Container));
  });

  // Since we need a BuildContext, wrap all tests that call redirect in
  // testWidgets so Flutter provides one.

  // -------------------------------------------------------------------------
  // AllowGuard (baseline)
  // -------------------------------------------------------------------------

  group('AllowGuard', () {
    testWidgets('returns null (allows navigation)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final guard = AllowGuard();
      final result = await guard.redirect(ctx, fakeState);
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // RedirectGuard (baseline)
  // -------------------------------------------------------------------------

  group('RedirectGuard', () {
    testWidgets('returns the configured path', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final guard = RedirectGuard('/login');
      final result = await guard.redirect(ctx, fakeState);
      expect(result, '/login');
    });
  });

  // -------------------------------------------------------------------------
  // RouteGuard.all (CompositeRouteGuard)
  // -------------------------------------------------------------------------

  group('RouteGuard.all()', () {
    testWidgets('returns null when all guards allow', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.all([AllowGuard(), AllowGuard()]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, isNull);
    });

    testWidgets('returns first redirect when first guard blocks', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.all([
        RedirectGuard('/login'),
        RedirectGuard('/blocked'),
      ]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, '/login');
    });

    testWidgets('returns second redirect when first allows but second blocks', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.all([
        AllowGuard(),
        RedirectGuard('/paywall'),
      ]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, '/paywall');
    });

    testWidgets('returns null for empty guard list', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.all([]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, isNull);
    });

    testWidgets('evaluates guards in order', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final order = <String>[];
      final guards = [
        _OrderedAllowGuard('first', order),
        _OrderedAllowGuard('second', order),
        _OrderedAllowGuard('third', order),
      ];

      final composite = RouteGuard.all(guards);
      await composite.redirect(ctx, fakeState);

      expect(order, ['first', 'second', 'third']);
    });

    testWidgets('stops at first redirect without evaluating remaining guards', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final order = <String>[];
      final composite = RouteGuard.all([
        _OrderedAllowGuard('first', order),
        _OrderedRedirectGuard('second', '/login', order),
        _OrderedAllowGuard('third', order), // Should not be reached.
      ]);

      await composite.redirect(ctx, fakeState);
      expect(order, ['first', 'second']);
      expect(order, isNot(contains('third')));
    });
  });

  // -------------------------------------------------------------------------
  // RouteGuard.any
  // -------------------------------------------------------------------------

  group('RouteGuard.any()', () {
    testWidgets('returns null when any guard allows', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.any([
        RedirectGuard('/login'),
        AllowGuard(), // This one allows.
      ]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, isNull);
    });

    testWidgets('returns redirect when every guard blocks', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.any([
        RedirectGuard('/login'),
        RedirectGuard('/blocked'),
      ]);
      final result = await composite.redirect(ctx, fakeState);
      // All guards blocked; last redirect wins.
      expect(result, '/blocked');
    });

    testWidgets('returns null when first guard allows', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.any([AllowGuard(), RedirectGuard('/login')]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, isNull);
    });

    testWidgets('returns null for empty guard list (no redirects)', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = RouteGuard.any([]);
      final result = await composite.redirect(ctx, fakeState);
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // CompositeRouteGuard (direct instantiation)
  // -------------------------------------------------------------------------

  group('CompositeRouteGuard (direct)', () {
    testWidgets('same behaviour as RouteGuard.all', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final composite = CompositeRouteGuard(
        guards: [AllowGuard(), RedirectGuard('/settings')],
      );
      final result = await composite.redirect(ctx, fakeState);
      expect(result, '/settings');
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _OrderedAllowGuard extends RouteGuard {
  _OrderedAllowGuard(this.id, this.order);
  final String id;
  final List<String> order;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    order.add(id);
    return null;
  }
}

class _OrderedRedirectGuard extends RouteGuard {
  _OrderedRedirectGuard(this.id, this.path, this.order);
  final String id;
  final String path;
  final List<String> order;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    order.add(id);
    return path;
  }
}

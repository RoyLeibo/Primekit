import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/routing.dart';

void main() {
  // -------------------------------------------------------------------------
  // Construction
  // -------------------------------------------------------------------------

  group('TabStateManager construction', () {
    test('creates manager with tabCount tabs', () {
      final manager = TabStateManager(tabCount: 3);
      expect(manager.tabCount, 3);
      manager.dispose();
    });

    test('creates manager with 1 tab', () {
      final manager = TabStateManager(tabCount: 1);
      expect(manager.tabCount, 1);
      manager.dispose();
    });

    test('each tab gets a distinct ScrollController', () {
      final manager = TabStateManager(tabCount: 3);
      final c0 = manager.getScrollController(0);
      final c1 = manager.getScrollController(1);
      final c2 = manager.getScrollController(2);

      expect(identical(c0, c1), isFalse);
      expect(identical(c1, c2), isFalse);
      manager.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // getScrollController
  // -------------------------------------------------------------------------

  group('getScrollController()', () {
    late TabStateManager manager;

    setUp(() => manager = TabStateManager(tabCount: 3));
    tearDown(() => manager.dispose());

    test('returns the same instance on repeated calls', () {
      expect(
        identical(
          manager.getScrollController(0),
          manager.getScrollController(0),
        ),
        isTrue,
      );
    });

    test('throws RangeError for negative index', () {
      expect(() => manager.getScrollController(-1), throwsRangeError);
    });

    test('throws RangeError for index equal to tabCount', () {
      expect(() => manager.getScrollController(3), throwsRangeError);
    });

    test('throws RangeError for index beyond tabCount', () {
      expect(() => manager.getScrollController(100), throwsRangeError);
    });

    test('returns valid controller for last valid index', () {
      expect(() => manager.getScrollController(2), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // saveScrollPosition / getScrollPosition
  // -------------------------------------------------------------------------

  group('saveScrollPosition() / getScrollPosition()', () {
    late TabStateManager manager;

    setUp(() => manager = TabStateManager(tabCount: 3));
    tearDown(() => manager.dispose());

    test('getScrollPosition returns null before any save', () {
      expect(manager.getScrollPosition(0), isNull);
    });

    test('returns saved position', () {
      manager.saveScrollPosition(0, 123.45);
      expect(manager.getScrollPosition(0), 123.45);
    });

    test('each tab has an independent position', () {
      manager.saveScrollPosition(0, 100.0);
      manager.saveScrollPosition(1, 200.0);
      manager.saveScrollPosition(2, 300.0);

      expect(manager.getScrollPosition(0), 100.0);
      expect(manager.getScrollPosition(1), 200.0);
      expect(manager.getScrollPosition(2), 300.0);
    });

    test('overwriting a position stores the latest value', () {
      manager.saveScrollPosition(0, 100.0);
      manager.saveScrollPosition(0, 500.0);
      expect(manager.getScrollPosition(0), 500.0);
    });

    test('saving position 0.0 is a valid stored value', () {
      manager.saveScrollPosition(0, 0.0);
      expect(manager.getScrollPosition(0), 0.0);
    });

    test('saveScrollPosition throws RangeError for invalid index', () {
      expect(() => manager.saveScrollPosition(-1, 10.0), throwsRangeError);
    });

    test('getScrollPosition throws RangeError for invalid index', () {
      expect(() => manager.getScrollPosition(99), throwsRangeError);
    });
  });

  // -------------------------------------------------------------------------
  // resetTab
  // -------------------------------------------------------------------------

  group('resetTab()', () {
    late TabStateManager manager;

    setUp(() => manager = TabStateManager(tabCount: 3));
    tearDown(() => manager.dispose());

    test('clears the saved position for the given tab', () {
      manager.saveScrollPosition(1, 200.0);
      manager.resetTab(1);
      expect(manager.getScrollPosition(1), isNull);
    });

    test('does not affect other tabs', () {
      manager.saveScrollPosition(0, 100.0);
      manager.saveScrollPosition(1, 200.0);
      manager.resetTab(0);

      expect(manager.getScrollPosition(0), isNull);
      expect(manager.getScrollPosition(1), 200.0);
    });

    test('throws RangeError for invalid index', () {
      expect(() => manager.resetTab(5), throwsRangeError);
    });

    test('is a no-op when position was never saved', () {
      expect(() => manager.resetTab(2), returnsNormally);
      expect(manager.getScrollPosition(2), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // resetAll
  // -------------------------------------------------------------------------

  group('resetAll()', () {
    late TabStateManager manager;

    setUp(() => manager = TabStateManager(tabCount: 3));
    tearDown(() => manager.dispose());

    test('clears saved positions for all tabs', () {
      manager.saveScrollPosition(0, 100.0);
      manager.saveScrollPosition(1, 200.0);
      manager.saveScrollPosition(2, 300.0);

      manager.resetAll();

      expect(manager.getScrollPosition(0), isNull);
      expect(manager.getScrollPosition(1), isNull);
      expect(manager.getScrollPosition(2), isNull);
    });

    test('is a no-op when no positions have been saved', () {
      expect(() => manager.resetAll(), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // tabCount
  // -------------------------------------------------------------------------

  group('tabCount', () {
    test('returns the number of tabs specified at construction', () {
      final manager = TabStateManager(tabCount: 5);
      expect(manager.tabCount, 5);
      manager.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose()', () {
    testWidgets('disposes all ScrollControllers', (tester) async {
      // We need a Flutter binding for ScrollController.dispose.
      final manager = TabStateManager(tabCount: 2);
      final c0 = manager.getScrollController(0);
      final c1 = manager.getScrollController(1);

      manager.dispose();

      // After dispose, controllers should no longer be usable;
      // accessing .hasClients should throw an assertion error.
      expect(() => c0.hasClients, throwsFlutterError);
      expect(() => c1.hasClients, throwsFlutterError);
    });
  });

  // -------------------------------------------------------------------------
  // Integration: save → reset → verify
  // -------------------------------------------------------------------------

  group('integration', () {
    test('full save-reset-verify cycle', () {
      final manager = TabStateManager(tabCount: 4);

      // Save positions for all tabs.
      for (var i = 0; i < 4; i++) {
        manager.saveScrollPosition(i, i * 50.0);
      }

      // Verify all saved.
      for (var i = 0; i < 4; i++) {
        expect(manager.getScrollPosition(i), i * 50.0);
      }

      // Reset tab 2 only.
      manager.resetTab(2);
      expect(manager.getScrollPosition(2), isNull);
      expect(manager.getScrollPosition(0), 0.0);
      expect(manager.getScrollPosition(1), 50.0);
      expect(manager.getScrollPosition(3), 150.0);

      manager.dispose();
    });
  });
}

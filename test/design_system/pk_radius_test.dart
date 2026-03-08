import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/design_system.dart';

void main() {
  group('PkRadius', () {
    // -------------------------------------------------------------------------
    // Non-negative constants
    // -------------------------------------------------------------------------

    group('all scalar constants are non-negative', () {
      test('xs >= 0', () => expect(PkRadius.xs, greaterThanOrEqualTo(0)));
      test('sm >= 0', () => expect(PkRadius.sm, greaterThanOrEqualTo(0)));
      test('md >= 0', () => expect(PkRadius.md, greaterThanOrEqualTo(0)));
      test('lg >= 0', () => expect(PkRadius.lg, greaterThanOrEqualTo(0)));
      test('xl >= 0', () => expect(PkRadius.xl, greaterThanOrEqualTo(0)));
      test('full >= 0', () => expect(PkRadius.full, greaterThanOrEqualTo(0)));
    });

    // -------------------------------------------------------------------------
    // Exact values
    // -------------------------------------------------------------------------

    group('exact scalar values', () {
      test('xs == 4.0', () => expect(PkRadius.xs, equals(4.0)));
      test('sm == 8.0', () => expect(PkRadius.sm, equals(8.0)));
      test('md == 12.0', () => expect(PkRadius.md, equals(12.0)));
      test('lg == 16.0', () => expect(PkRadius.lg, equals(16.0)));
      test('xl == 24.0', () => expect(PkRadius.xl, equals(24.0)));
      test('full == 999.0', () => expect(PkRadius.full, equals(999.0)));
    });

    // -------------------------------------------------------------------------
    // Ascending order
    // -------------------------------------------------------------------------

    group('ascending order', () {
      test('xs < sm', () => expect(PkRadius.xs, lessThan(PkRadius.sm)));
      test('sm < md', () => expect(PkRadius.sm, lessThan(PkRadius.md)));
      test('md < lg', () => expect(PkRadius.md, lessThan(PkRadius.lg)));
      test('lg < xl', () => expect(PkRadius.lg, lessThan(PkRadius.xl)));
      test('xl < full', () => expect(PkRadius.xl, lessThan(PkRadius.full)));
    });

    // -------------------------------------------------------------------------
    // BorderRadius factories
    // -------------------------------------------------------------------------

    group('BorderRadius factories', () {
      test('circle uses full radius', () {
        final expected = BorderRadius.circular(PkRadius.full);
        expect(PkRadius.circle, equals(expected));
      });

      test('card uses md radius', () {
        final expected = BorderRadius.circular(PkRadius.md);
        expect(PkRadius.card, equals(expected));
      });

      test('button uses sm radius', () {
        final expected = BorderRadius.circular(PkRadius.sm);
        expect(PkRadius.button, equals(expected));
      });

      test('chip uses lg radius', () {
        final expected = BorderRadius.circular(PkRadius.lg);
        expect(PkRadius.chip, equals(expected));
      });

      test('factories return BorderRadius instances', () {
        expect(PkRadius.circle, isA<BorderRadius>());
        expect(PkRadius.card, isA<BorderRadius>());
        expect(PkRadius.button, isA<BorderRadius>());
        expect(PkRadius.chip, isA<BorderRadius>());
      });
    });
  });
}

import 'package:test/test.dart';
import 'package:primekit/design_system.dart';

void main() {
  group('PkSpacing', () {
    // -------------------------------------------------------------------------
    // Positivity
    // -------------------------------------------------------------------------

    group('all constants are positive', () {
      test('xs is positive', () => expect(PkSpacing.xs, greaterThan(0)));
      test('sm is positive', () => expect(PkSpacing.sm, greaterThan(0)));
      test('md is positive', () => expect(PkSpacing.md, greaterThan(0)));
      test('lg is positive', () => expect(PkSpacing.lg, greaterThan(0)));
      test('xl is positive', () => expect(PkSpacing.xl, greaterThan(0)));
      test('xxl is positive', () => expect(PkSpacing.xxl, greaterThan(0)));
      test('xxxl is positive', () => expect(PkSpacing.xxxl, greaterThan(0)));
    });

    // -------------------------------------------------------------------------
    // Exact values
    // -------------------------------------------------------------------------

    group('exact values', () {
      test('xs == 4.0', () => expect(PkSpacing.xs, equals(4.0)));
      test('sm == 8.0', () => expect(PkSpacing.sm, equals(8.0)));
      test('md == 12.0', () => expect(PkSpacing.md, equals(12.0)));
      test('lg == 16.0', () => expect(PkSpacing.lg, equals(16.0)));
      test('xl == 24.0', () => expect(PkSpacing.xl, equals(24.0)));
      test('xxl == 32.0', () => expect(PkSpacing.xxl, equals(32.0)));
      test('xxxl == 48.0', () => expect(PkSpacing.xxxl, equals(48.0)));
    });

    // -------------------------------------------------------------------------
    // Ordering
    // -------------------------------------------------------------------------

    group('ascending order', () {
      test('xs < sm', () => expect(PkSpacing.xs, lessThan(PkSpacing.sm)));
      test('sm < md', () => expect(PkSpacing.sm, lessThan(PkSpacing.md)));
      test('md < lg', () => expect(PkSpacing.md, lessThan(PkSpacing.lg)));
      test('lg < xl', () => expect(PkSpacing.lg, lessThan(PkSpacing.xl)));
      test('xl < xxl', () => expect(PkSpacing.xl, lessThan(PkSpacing.xxl)));
      test('xxl < xxxl', () => expect(PkSpacing.xxl, lessThan(PkSpacing.xxxl)));
    });
  });
}

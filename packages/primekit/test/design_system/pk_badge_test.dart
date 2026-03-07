import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/design_system.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PkBadge', () {
    // -------------------------------------------------------------------------
    // PkBadge.count
    // -------------------------------------------------------------------------

    group('PkBadge.count', () {
      testWidgets('renders the count as text', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(7)));
        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('renders 0 as text', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(0)));
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('caps count at 99+', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(100)));
        expect(find.text('99+'), findsOneWidget);
      });

      testWidgets('renders 99 as-is (not capped)', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(99)));
        expect(find.text('99'), findsOneWidget);
      });

      testWidgets('uses default red color', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(3)));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFE53935)));
      });

      testWidgets('accepts custom color', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.count(3, color: Colors.green)));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.green));
      });
    });

    // -------------------------------------------------------------------------
    // PkBadge.dot
    // -------------------------------------------------------------------------

    group('PkBadge.dot', () {
      testWidgets('renders a circular Container with no text', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.dot()));

        // No text inside a dot badge
        expect(find.byType(Text), findsNothing);

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
      });

      testWidgets('default dot size is 8', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.dot()));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxWidth, equals(8));
        expect(container.constraints?.maxHeight, equals(8));
      });

      testWidgets('accepts custom size', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.dot(size: 12)));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxWidth, equals(12));
        expect(container.constraints?.maxHeight, equals(12));
      });

      testWidgets('uses default red color', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.dot()));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFE53935)));
      });

      testWidgets('accepts custom color', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.dot(color: Colors.orange)));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.orange));
      });
    });

    // -------------------------------------------------------------------------
    // PkBadge.label
    // -------------------------------------------------------------------------

    group('PkBadge.label', () {
      testWidgets('renders the label text', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.label('NEW')));
        expect(find.text('NEW'), findsOneWidget);
      });

      testWidgets('uses default blue color', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.label('SALE')));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF1565C0)));
      });

      testWidgets('accepts custom color', (tester) async {
        await tester.pumpWidget(
          _wrap(PkBadge.label('HOT', color: Colors.deepOrange)),
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.deepOrange));
      });

      testWidgets('has rounded decoration (not circle shape)', (tester) async {
        await tester.pumpWidget(_wrap(PkBadge.label('TAG')));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;
        // label variant uses borderRadius, not BoxShape.circle
        expect(decoration.borderRadius, isNotNull);
      });
    });
  });
}

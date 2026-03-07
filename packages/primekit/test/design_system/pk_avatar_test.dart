import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/design_system.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// Reproduces the same hash-based color selection as PkAvatar._colorFor()
Color _expectedColor(String seed) {
  const palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF29B6F6),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];
  final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PkAvatar', () {
    // -------------------------------------------------------------------------
    // Initials rendering
    // -------------------------------------------------------------------------

    group('initials variant', () {
      testWidgets('renders single initial for single-word name', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(const PkAvatar(displayName: 'Alice')));

        expect(find.text('A'), findsOneWidget);
      });

      testWidgets('renders first+last initials for two-word name', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(const PkAvatar(displayName: 'Jane Doe')));

        expect(find.text('JD'), findsOneWidget);
      });

      testWidgets('renders first+last initials for multi-word name', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(const PkAvatar(displayName: 'Mary Anne Smith')),
        );

        expect(find.text('MS'), findsOneWidget);
      });

      testWidgets('initials are upper-cased', (tester) async {
        await tester.pumpWidget(
          _wrap(const PkAvatar(displayName: 'alice bob')),
        );

        expect(find.text('AB'), findsOneWidget);
      });

      testWidgets('falls back to first char of userId when no displayName', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(const PkAvatar(userId: 'user-123')));

        expect(find.text('U'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Deterministic color from userId
    // -------------------------------------------------------------------------

    group('deterministic color', () {
      testWidgets(
        'same userId always produces same CircleAvatar background color',
        (tester) async {
          const userId = 'user-abc';
          final expectedBg = _expectedColor(userId);

          await tester.pumpWidget(_wrap(const PkAvatar(userId: userId)));

          final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
          expect(avatar.backgroundColor, equals(expectedBg));
        },
      );

      testWidgets('different userIds can produce different colors', (
        tester,
      ) async {
        final color1 = _expectedColor('user-001');
        final color2 = _expectedColor('user-999');
        // Not strictly guaranteed to differ, but these specific IDs do differ.
        expect(color1 == color2, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Image variant
    // -------------------------------------------------------------------------

    group('image variant', () {
      testWidgets(
        'shows CircleAvatar with NetworkImage when imageUrl provided',
        (tester) async {
          await tester.pumpWidget(
            _wrap(const PkAvatar(imageUrl: 'https://example.com/photo.jpg')),
          );

          final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
          expect(avatar.backgroundImage, isA<NetworkImage>());
          final image = avatar.backgroundImage as NetworkImage;
          expect(image.url, equals('https://example.com/photo.jpg'));

          // Discard the HttpClient 400 error from TestWidgetsFlutterBinding.
          tester.takeException();
        },
      );

      testWidgets('does not render initials Text when imageUrl provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            const PkAvatar(
              imageUrl: 'https://example.com/photo.jpg',
              displayName: 'Jane Doe',
            ),
          ),
        );

        expect(find.byType(Text), findsNothing);

        // Discard the HttpClient 400 error from TestWidgetsFlutterBinding.
        tester.takeException();
      });
    });

    // -------------------------------------------------------------------------
    // Size
    // -------------------------------------------------------------------------

    group('size', () {
      testWidgets('SizedBox has correct dimensions', (tester) async {
        await tester.pumpWidget(
          _wrap(const PkAvatar(displayName: 'Test User', size: 60)),
        );

        final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(box.width, equals(60));
        expect(box.height, equals(60));
      });
    });

    // -------------------------------------------------------------------------
    // Border
    // -------------------------------------------------------------------------

    group('border', () {
      testWidgets(
        'wraps in DecoratedBox with border when borderWidth > 0 and borderColor set',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              const PkAvatar(
                displayName: 'Roy',
                borderWidth: 2.0,
                borderColor: Colors.blue,
              ),
            ),
          );

          final boxes = tester.widgetList<DecoratedBox>(
            find.byType(DecoratedBox),
          );
          final bordered = boxes.firstWhere((b) {
            final decoration = b.decoration as BoxDecoration?;
            return decoration?.border != null;
          }, orElse: () => throw TestFailure('No bordered DecoratedBox found'));
          final decoration = bordered.decoration as BoxDecoration;
          expect(decoration.shape, equals(BoxShape.circle));
        },
      );

      testWidgets('no extra Container when borderWidth is 0', (tester) async {
        await tester.pumpWidget(_wrap(const PkAvatar(displayName: 'Roy')));

        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasBordered = containers.any((c) {
          final decoration = c.decoration as BoxDecoration?;
          return decoration?.border != null;
        });
        expect(hasBordered, isFalse);
      });
    });
  });
}

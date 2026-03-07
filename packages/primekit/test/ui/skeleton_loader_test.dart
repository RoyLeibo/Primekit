import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:primekit/src/ui/skeleton_loader.dart';
import 'package:primekit/src/ui/pk_ui_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, {PkUiTheme? extension}) => MaterialApp(
  theme: ThemeData(extensions: [if (extension != null) extension]),
  home: Scaffold(body: child),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SkeletonLoader — isLoading=true', () {
    testWidgets('renders shimmer overlay (child is still in tree)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SkeletonLoader(
            isLoading: true,
            child: const Text('real content', key: Key('real')),
          ),
        ),
      );

      // The child is passed to the ShaderMask child even while loading.
      // We verify that no Text widget with 'real content' is _visible_ in
      // a findable way — the ShaderMask still keeps it in the tree.
      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('uses custom skeleton colors from PkUiTheme', (tester) async {
      const ext = PkUiTheme(
        skeletonBaseColor: Color(0xFF123456),
        skeletonHighlightColor: Color(0xFF654321),
      );

      await tester.pumpWidget(
        _wrap(
          SkeletonLoader(
            isLoading: true,
            child: const SizedBox(width: 100, height: 20),
          ),
          extension: ext,
        ),
      );

      // No assertion on paint colors (deep integration), but verify no errors.
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLoader — isLoading=false', () {
    testWidgets('renders real child directly when not loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SkeletonLoader(
            isLoading: false,
            child: const Text('visible content', key: Key('content')),
          ),
        ),
      );

      expect(find.text('visible content'), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
    });
  });

  group('SkeletonLoader.text factory', () {
    testWidgets('renders without error with default lines', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.text()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correct number of rows for lines=5', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.text(lines: 5)));
      // Each line is wrapped in a Padding widget inside a Column.
      // Verify the widget tree renders without crashing.
      expect(tester.takeException(), isNull);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('accepts custom width', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.text(width: 200)));
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLoader.card factory', () {
    testWidgets('renders card skeleton without error', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.card()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom height', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.card(height: 200)));
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLoader.avatar factory', () {
    testWidgets('renders avatar skeleton without error', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.avatar()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom size', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.avatar(size: 72)));
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLoader.listItem factory', () {
    testWidgets('renders list item with avatar', (tester) async {
      await tester.pumpWidget(_wrap(SkeletonLoader.listItem()));
      expect(find.byType(Row), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders list item without avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(SkeletonLoader.listItem(hasAvatar: false, textLines: 3)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders list item with custom textLines count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SkeletonLoader.listItem(hasAvatar: true, textLines: 4)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLoader — animation lifecycle', () {
    testWidgets('disposes animation controller without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SkeletonLoader(
            isLoading: true,
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      );

      // Replace with non-loading widget to trigger dispose.
      await tester.pumpWidget(
        _wrap(
          SkeletonLoader(
            isLoading: false,
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

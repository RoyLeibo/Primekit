import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:primekit/src/ui/empty_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: child),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EmptyState — basic rendering', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(message: 'Nothing to see here.')),
      );
      expect(find.text('Nothing to see here.'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyState(message: 'msg', title: 'My Title'),
        ),
      );
      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('does not render title when omitted', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(message: 'msg only')),
      );
      // Only one text widget — the message.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders icon in a circular container when provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyState(
            message: 'msg',
            icon: Icons.inbox_outlined,
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders custom illustration instead of icon when both given',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyState(
            message: 'msg',
            icon: Icons.inbox_outlined,
            illustration: Text('custom illustration', key: Key('illus')),
          ),
        ),
      );
      expect(find.byKey(const Key('illus')), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('renders action button when actionLabel and onAction provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            message: 'msg',
            actionLabel: 'Retry',
            onAction: () {},
          ),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('does not render button when actionLabel is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(message: 'msg')),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('does not render button when onAction is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyState(message: 'msg', actionLabel: 'Action')),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('onAction callback is invoked when button tapped',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          EmptyState(
            message: 'msg',
            actionLabel: 'Do it',
            onAction: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      expect(tapped, isTrue);
    });
  });

  group('EmptyState.noResults', () {
    testWidgets('renders correct title and message', (tester) async {
      await tester.pumpWidget(_wrap(EmptyState.noResults()));
      expect(find.text('No results found'), findsOneWidget);
      expect(find.textContaining('search'), findsOneWidget);
    });

    testWidgets('renders Clear filters button when onClear provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.noResults(onClear: () {})),
      );
      expect(find.text('Clear filters'), findsOneWidget);
    });

    testWidgets('onClear callback fires when button tapped', (tester) async {
      var cleared = false;
      await tester.pumpWidget(
        _wrap(EmptyState.noResults(onClear: () => cleared = true)),
      );
      await tester.tap(find.text('Clear filters'));
      expect(cleared, isTrue);
    });

    testWidgets('no button when onClear is null', (tester) async {
      await tester.pumpWidget(_wrap(EmptyState.noResults()));
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('EmptyState.noConnection', () {
    testWidgets('renders correct title and icon', (tester) async {
      await tester.pumpWidget(_wrap(EmptyState.noConnection()));
      expect(find.text('No connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('renders Retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.noConnection(onRetry: () {})),
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('onRetry fires when button tapped', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(EmptyState.noConnection(onRetry: () => retried = true)),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  group('EmptyState.error', () {
    testWidgets('renders default error title and message', (tester) async {
      await tester.pumpWidget(_wrap(EmptyState.error()));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.textContaining('unexpected error'), findsOneWidget);
    });

    testWidgets('renders custom message when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.error(message: 'Custom error message')),
      );
      expect(find.text('Custom error message'), findsOneWidget);
    });

    testWidgets('renders Retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.error(onRetry: () {})),
      );
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('EmptyState.noData', () {
    testWidgets('renders default title and message', (tester) async {
      await tester.pumpWidget(_wrap(EmptyState.noData()));
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.textContaining('first item'), findsOneWidget);
    });

    testWidgets('renders Create button when onCreate provided', (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.noData(onCreate: () {})),
      );
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('onCreate fires when Create tapped', (tester) async {
      var created = false;
      await tester.pumpWidget(
        _wrap(EmptyState.noData(onCreate: () => created = true)),
      );
      await tester.tap(find.text('Create'));
      expect(created, isTrue);
    });

    testWidgets('renders custom message when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(EmptyState.noData(message: 'Tap + to add your first note.')),
      );
      expect(find.text('Tap + to add your first note.'), findsOneWidget);
    });
  });
}

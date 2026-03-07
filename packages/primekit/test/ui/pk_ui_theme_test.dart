import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:primekit/src/ui/pk_ui_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _app({PkUiTheme? extension, required Widget child}) => MaterialApp(
  theme: ThemeData(
    extensions: [if (extension != null) extension],
  ),
  home: Scaffold(body: child),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PkUiTheme — effective defaults (no override)', () {
    const theme = PkUiTheme();

    test('effectiveSuccessColor defaults to 0xFF2E7D32', () {
      expect(theme.effectiveSuccessColor, const Color(0xFF2E7D32));
    });

    test('effectiveErrorColor defaults to 0xFFC62828', () {
      expect(theme.effectiveErrorColor, const Color(0xFFC62828));
    });

    test('effectiveWarningColor defaults to 0xFFE65100', () {
      expect(theme.effectiveWarningColor, const Color(0xFFE65100));
    });

    test('effectiveInfoColor defaults to 0xFF01579B', () {
      expect(theme.effectiveInfoColor, const Color(0xFF01579B));
    });

    test('effectiveToastTextColor defaults to Colors.white', () {
      expect(theme.effectiveToastTextColor, Colors.white);
    });

    test('effectiveLoadingBarrierColor defaults to Colors.black54', () {
      expect(theme.effectiveLoadingBarrierColor, Colors.black54);
    });

    test('effectiveSkeletonBaseColor defaults to 0xFFE0E0E0', () {
      expect(theme.effectiveSkeletonBaseColor, const Color(0xFFE0E0E0));
    });

    test('effectiveSkeletonHighlightColor defaults to 0xFFF5F5F5', () {
      expect(theme.effectiveSkeletonHighlightColor, const Color(0xFFF5F5F5));
    });
  });

  group('PkUiTheme — custom overrides', () {
    const customTheme = PkUiTheme(
      successColor: Color(0xFF00FF00),
      errorColor: Color(0xFFFF0000),
      warningColor: Color(0xFFFFFF00),
      infoColor: Color(0xFF0000FF),
      toastTextColor: Color(0xFF111111),
      loadingBarrierColor: Color(0x80000000),
      skeletonBaseColor: Color(0xFFAAAAAA),
      skeletonHighlightColor: Color(0xFFCCCCCC),
    );

    test('effectiveSuccessColor returns overridden value', () {
      expect(customTheme.effectiveSuccessColor, const Color(0xFF00FF00));
    });

    test('effectiveErrorColor returns overridden value', () {
      expect(customTheme.effectiveErrorColor, const Color(0xFFFF0000));
    });

    test('effectiveWarningColor returns overridden value', () {
      expect(customTheme.effectiveWarningColor, const Color(0xFFFFFF00));
    });

    test('effectiveInfoColor returns overridden value', () {
      expect(customTheme.effectiveInfoColor, const Color(0xFF0000FF));
    });

    test('effectiveToastTextColor returns overridden value', () {
      expect(customTheme.effectiveToastTextColor, const Color(0xFF111111));
    });

    test('effectiveSkeletonBaseColor returns overridden value', () {
      expect(customTheme.effectiveSkeletonBaseColor, const Color(0xFFAAAAAA));
    });

    test('effectiveSkeletonHighlightColor returns overridden value', () {
      expect(
        customTheme.effectiveSkeletonHighlightColor,
        const Color(0xFFCCCCCC),
      );
    });
  });

  group('PkUiTheme.copyWith', () {
    const base = PkUiTheme(successColor: Color(0xFF111111));

    test('copyWith overrides only specified fields', () {
      final copy = base.copyWith(errorColor: const Color(0xFF222222));
      expect(copy.successColor, const Color(0xFF111111));
      expect(copy.errorColor, const Color(0xFF222222));
    });

    test('copyWith with no args returns equivalent theme', () {
      final copy = base.copyWith();
      expect(copy.successColor, base.successColor);
    });
  });

  group('PkUiTheme.lerp', () {
    const a = PkUiTheme(
      successColor: Color(0xFF000000),
      errorColor: Color(0xFF000000),
    );
    const b = PkUiTheme(
      successColor: Color(0xFFFFFFFF),
      errorColor: Color(0xFFFFFFFF),
    );

    test('lerp at t=0 returns values close to a', () {
      final result = a.lerp(b, 0);
      expect(result.successColor, const Color(0xFF000000));
    });

    test('lerp at t=1 returns values close to b', () {
      final result = a.lerp(b, 1);
      expect(result.successColor, const Color(0xFFFFFFFF));
    });

    test('lerp with null other returns this', () {
      final result = a.lerp(null, 0.5);
      expect(result.successColor, a.successColor);
    });
  });

  group('PkUiTheme.of', () {
    testWidgets('returns null when no PkUiTheme extension registered',
        (tester) async {
      PkUiTheme? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = PkUiTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isNull);
    });

    testWidgets('returns PkUiTheme when registered as extension',
        (tester) async {
      PkUiTheme? captured;
      const ext = PkUiTheme(successColor: Color(0xFFAABBCC));

      await tester.pumpWidget(
        _app(
          extension: ext,
          child: Builder(
            builder: (context) {
              captured = PkUiTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.successColor, const Color(0xFFAABBCC));
    });
  });
}

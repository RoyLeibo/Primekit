import 'package:flutter/material.dart';

/// ThemeExtension for PrimeKit UI components.
/// Add to your ThemeData to customize PrimeKit colors:
///
/// ```dart
/// theme: ThemeData(
///   extensions: [
///     PkUiTheme(
///       successColor: Color(0xFF2E7D32),
///       errorColor: Color(0xFFC62828),
///     ),
///   ],
/// )
/// ```
class PkUiTheme extends ThemeExtension<PkUiTheme> {
  const PkUiTheme({
    this.successColor,
    this.errorColor,
    this.warningColor,
    this.infoColor,
    this.toastTextColor,
    this.loadingBarrierColor,
    this.skeletonBaseColor,
    this.skeletonHighlightColor,
  });

  final Color? successColor;
  final Color? errorColor;
  final Color? warningColor;
  final Color? infoColor;
  final Color? toastTextColor;
  final Color? loadingBarrierColor;
  final Color? skeletonBaseColor;
  final Color? skeletonHighlightColor;

  static PkUiTheme? of(BuildContext context) =>
      Theme.of(context).extension<PkUiTheme>();

  Color get effectiveSuccessColor => successColor ?? const Color(0xFF2E7D32);
  Color get effectiveErrorColor => errorColor ?? const Color(0xFFC62828);
  Color get effectiveWarningColor => warningColor ?? const Color(0xFFE65100);
  Color get effectiveInfoColor => infoColor ?? const Color(0xFF01579B);
  Color get effectiveToastTextColor => toastTextColor ?? Colors.white;
  Color get effectiveLoadingBarrierColor =>
      loadingBarrierColor ?? Colors.black54;
  Color get effectiveSkeletonBaseColor =>
      skeletonBaseColor ?? const Color(0xFFE0E0E0);
  Color get effectiveSkeletonHighlightColor =>
      skeletonHighlightColor ?? const Color(0xFFF5F5F5);

  @override
  PkUiTheme copyWith({
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? infoColor,
    Color? toastTextColor,
    Color? loadingBarrierColor,
    Color? skeletonBaseColor,
    Color? skeletonHighlightColor,
  }) => PkUiTheme(
    successColor: successColor ?? this.successColor,
    errorColor: errorColor ?? this.errorColor,
    warningColor: warningColor ?? this.warningColor,
    infoColor: infoColor ?? this.infoColor,
    toastTextColor: toastTextColor ?? this.toastTextColor,
    loadingBarrierColor: loadingBarrierColor ?? this.loadingBarrierColor,
    skeletonBaseColor: skeletonBaseColor ?? this.skeletonBaseColor,
    skeletonHighlightColor:
        skeletonHighlightColor ?? this.skeletonHighlightColor,
  );

  @override
  PkUiTheme lerp(PkUiTheme? other, double t) {
    if (other == null) return this;
    return PkUiTheme(
      successColor: Color.lerp(successColor, other.successColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
      warningColor: Color.lerp(warningColor, other.warningColor, t),
      infoColor: Color.lerp(infoColor, other.infoColor, t),
      toastTextColor: Color.lerp(toastTextColor, other.toastTextColor, t),
      loadingBarrierColor: Color.lerp(
        loadingBarrierColor,
        other.loadingBarrierColor,
        t,
      ),
      skeletonBaseColor: Color.lerp(
        skeletonBaseColor,
        other.skeletonBaseColor,
        t,
      ),
      skeletonHighlightColor: Color.lerp(
        skeletonHighlightColor,
        other.skeletonHighlightColor,
        t,
      ),
    );
  }
}

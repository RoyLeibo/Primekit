import 'package:flutter/material.dart';

/// Branded gradient definitions for a [PkAppTheme].
///
/// Each theme provides light and dark gradient variants.
/// Access the current theme's gradients via `PkAppTheme` or directly
/// from the theme instance.
///
/// ```dart
/// final theme = PkAppTheme.freshMint();
/// Container(
///   decoration: BoxDecoration(gradient: theme.gradients(context).hero),
/// );
/// ```
@immutable
class PkGradients {
  const PkGradients({
    required this.hero,
    required this.positive,
    required this.negative,
    required this.accent,
    required this.celebration,
  });

  /// Primary brand gradient — hero banners, CTA buttons.
  final LinearGradient hero;

  /// Success / positive outcome gradient.
  final LinearGradient positive;

  /// Error / negative outcome gradient.
  final LinearGradient negative;

  /// Accent / info gradient.
  final LinearGradient accent;

  /// Celebration / multi-color gradient.
  final LinearGradient celebration;

  /// Empty / transparent gradients (fallback).
  static const PkGradients none = PkGradients(
    hero: LinearGradient(colors: [Colors.transparent, Colors.transparent]),
    positive: LinearGradient(colors: [Colors.transparent, Colors.transparent]),
    negative: LinearGradient(colors: [Colors.transparent, Colors.transparent]),
    accent: LinearGradient(colors: [Colors.transparent, Colors.transparent]),
    celebration:
        LinearGradient(colors: [Colors.transparent, Colors.transparent]),
  );
}

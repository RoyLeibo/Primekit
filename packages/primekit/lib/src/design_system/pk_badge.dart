import 'package:flutter/material.dart';

/// A compact status badge for counts, labels, or dot indicators.
///
/// ```dart
/// PkBadge.count(3)
/// PkBadge.dot(color: Colors.red)
/// PkBadge.label('NEW', color: Colors.green)
/// ```
class PkBadge extends StatelessWidget {
  const PkBadge._({
    super.key,
    required this.child,
    required this.color,
    this.textColor = Colors.white,
    this.size,
  });

  factory PkBadge.count(
    int count, {
    Key? key,
    Color color = const Color(0xFFE53935),
    Color textColor = Colors.white,
  }) {
    return PkBadge._(
      key: key,
      color: color,
      textColor: textColor,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  factory PkBadge.dot({
    Key? key,
    Color color = const Color(0xFFE53935),
    double size = 8,
  }) {
    return PkBadge._(
      key: key,
      color: color,
      size: size,
      child: const SizedBox.shrink(),
    );
  }

  factory PkBadge.label(
    String text, {
    Key? key,
    Color color = const Color(0xFF1565C0),
    Color textColor = Colors.white,
  }) {
    return PkBadge._(
      key: key,
      color: color,
      textColor: textColor,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  final Widget child;
  final Color color;
  final Color textColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

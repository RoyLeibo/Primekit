import 'package:flutter/material.dart';

/// A deterministic avatar widget that assigns consistent colors from a
/// palette based on the provided [userId] or [displayName].
///
/// ```dart
/// PkAvatar(userId: 'user-123', displayName: 'Jane Doe', size: 40)
/// PkAvatar.image(imageUrl: 'https://...', size: 40)
/// ```
class PkAvatar extends StatelessWidget {
  const PkAvatar({
    super.key,
    this.userId,
    this.displayName,
    this.imageUrl,
    this.size = 40.0,
    this.fontSize,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  final String? userId;
  final String? displayName;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final Color? borderColor;
  final double borderWidth;

  static const List<Color> _palette = [
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

  Color _colorFor(String seed) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey[200],
      );
    } else {
      final seed = userId ?? displayName ?? '?';
      final color = _colorFor(seed);
      final initials =
          displayName != null
              ? _initialsFor(displayName!)
              : seed[0].toUpperCase();

      child = CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize ?? size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (borderWidth > 0 && borderColor != null) {
      child = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: child,
      );
    }

    return SizedBox(width: size, height: size, child: child);
  }
}

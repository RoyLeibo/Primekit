import 'package:flutter/material.dart';

/// An animated shimmer skeleton loader that wraps any child widget.
///
/// While [isLoading] is `true` the widget renders a shimmer animation over
/// grey placeholder rectangles. When [isLoading] becomes `false` the real
/// [child] is revealed.
///
/// Use the static factory methods for common skeleton shapes:
///
/// ```dart
/// // Wrap any widget
/// SkeletonLoader(
///   isLoading: _isLoading,
///   child: MyRealWidget(),
/// )
///
/// // Pre-built variants
/// SkeletonLoader.text(lines: 3)
/// SkeletonLoader.card(height: 140)
/// SkeletonLoader.avatar(size: 56)
/// SkeletonLoader.listItem(hasAvatar: true, textLines: 2)
/// ```
class SkeletonLoader extends StatefulWidget {
  /// Creates a skeleton loader that wraps [child].
  ///
  /// When [isLoading] is `true` the shimmer placeholder is shown; otherwise
  /// [child] is rendered normally.
  const SkeletonLoader({required this.child, this.isLoading = true, super.key});

  // ---------------------------------------------------------------------------
  // Pre-built factory methods
  // ---------------------------------------------------------------------------

  /// A multi-line text skeleton.
  ///
  /// [lines] controls how many text rows are shown.
  /// [width] pins all lines to a fixed width.
  static Widget text({Key? key, int lines = 3, double? width}) =>
      _SkeletonTextWidget(key: key, lines: lines, fixedWidth: width);

  /// A rectangular card skeleton.
  static Widget card({Key? key, double height = 120}) =>
      _SkeletonCardWidget(key: key, height: height);

  /// A circular avatar skeleton.
  static Widget avatar({Key? key, double size = 48}) =>
      _SkeletonAvatarWidget(key: key, size: size);

  /// A list-item skeleton with an optional leading avatar and text lines.
  static Widget listItem({
    Key? key,
    bool hasAvatar = true,
    int textLines = 2,
  }) => _SkeletonListItemWidget(
    key: key,
    hasAvatar: hasAvatar,
    textLines: textLines,
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Whether the skeleton placeholder is currently shown.
  final bool isLoading;

  /// The real content revealed once [isLoading] is `false`.
  final Widget child;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerPosition = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _shimmerPosition,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: [
            (_shimmerPosition.value - 1).clamp(0.0, 1.0),
            (_shimmerPosition.value.clamp(0.0, 1.0)) * 0.5 + 0.5,
            (_shimmerPosition.value + 1).clamp(0.0, 1.0),
          ],
          transform: _SlidingGradientTransform(_shimmerPosition.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A gradient transform that slides horizontally to create the shimmer motion.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
}

// ---------------------------------------------------------------------------
// Shared shimmer primitive
// ---------------------------------------------------------------------------

/// The core shimmer animation used by all pre-built skeletons.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, this.height = 16, this.borderRadius = 8});

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (context, _) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFBDBDBD),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Pre-built skeleton widgets
// ---------------------------------------------------------------------------

class _SkeletonTextWidget extends StatelessWidget {
  const _SkeletonTextWidget({required this.lines, this.fixedWidth, super.key});

  final int lines;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: List.generate(lines, (index) {
      final isLast = index == lines - 1;
      return Padding(
        padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
        child: _ShimmerBox(
          // Last line intentionally shorter to mimic real text wrapping.
          width: isLast ? (fixedWidth ?? 160) : fixedWidth,
          height: 14,
        ),
      );
    }),
  );
}

class _SkeletonCardWidget extends StatelessWidget {
  const _SkeletonCardWidget({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context) =>
      _ShimmerBox(height: height, borderRadius: 12);
}

class _SkeletonAvatarWidget extends StatelessWidget {
  const _SkeletonAvatarWidget({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      _ShimmerBox(width: size, height: size, borderRadius: size / 2);
}

class _SkeletonListItemWidget extends StatelessWidget {
  const _SkeletonListItemWidget({
    required this.hasAvatar,
    required this.textLines,
    super.key,
  });

  final bool hasAvatar;
  final int textLines;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (hasAvatar) ...[
        const _ShimmerBox(width: 48, height: 48, borderRadius: 24),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < textLines; i++) ...[
              _ShimmerBox(width: i == textLines - 1 ? 120 : null, height: 14),
              if (i < textLines - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ],
  );
}

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Whether the current platform supports mouse hover.
bool get _supportsHover =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// A glassmorphism card with frosted backdrop blur.
///
/// Supports optional animated gradient border, hover lift effect on desktop,
/// and tap handling. Works with any theme — pass your own colors or rely on
/// the ambient [Theme].
///
/// ```dart
/// PkGlassCard(
///   blur: 20,
///   opacity: 0.12,
///   borderRadius: 16,
///   child: Text('Hello'),
/// )
/// ```
class PkGlassCard extends StatefulWidget {
  /// The widget to display inside the card.
  final Widget child;

  /// Padding inside the glass surface.
  final EdgeInsetsGeometry? padding;

  /// Corner radius of the card.
  final double borderRadius;

  /// Backdrop blur sigma (both X and Y).
  final double blur;

  /// Opacity of the glass background fill (0.0 – 1.0).
  final double opacity;

  /// Background color of the glass surface. Defaults to the theme surface.
  final Color? backgroundColor;

  /// Border color when no gradient border is used.
  final Color? borderColor;

  /// Width of the border.
  final double borderWidth;

  /// Optional gradient overlay on the card content area.
  final Gradient? gradientOverlay;

  /// When non-null, shows a continuously animating gradient border.
  /// Supply the gradient colors (at least 2). Animation cycles over
  /// [gradientBorderDuration].
  final List<Color>? gradientBorderColors;

  /// Duration of one full gradient-border animation cycle.
  final Duration gradientBorderDuration;

  /// Fixed width constraint.
  final double? width;

  /// Fixed height constraint.
  final double? height;

  /// Tap callback. When non-null the card becomes tappable.
  final VoidCallback? onTap;

  /// Whether to show a hover-lift effect on desktop platforms.
  final bool enableHover;

  const PkGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.blur = 20,
    this.opacity = 0.12,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.gradientOverlay,
    this.gradientBorderColors,
    this.gradientBorderDuration = const Duration(seconds: 6),
    this.width,
    this.height,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<PkGlassCard> createState() => _PkGlassCardState();
}

class _PkGlassCardState extends State<PkGlassCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _isHovered = false;

  bool get _hasAnimatedBorder =>
      widget.gradientBorderColors != null &&
      widget.gradientBorderColors!.length >= 2;

  @override
  void initState() {
    super.initState();
    if (_hasAnimatedBorder) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.gradientBorderDuration,
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(PkGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final needsController =
        widget.gradientBorderColors != null &&
        widget.gradientBorderColors!.length >= 2;

    if (needsController && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.gradientBorderDuration,
      )..repeat();
    } else if (!needsController && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCard(BuildContext context, double shift) {
    final theme = Theme.of(context);
    final bgColor = (widget.backgroundColor ?? theme.colorScheme.surface)
        .withValues(alpha: widget.opacity);
    final border = widget.borderColor ??
        theme.colorScheme.outline.withValues(alpha: 0.2);
    final br = BorderRadius.circular(widget.borderRadius);
    final innerRadius = widget.borderRadius - widget.borderWidth;

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: _hasAnimatedBorder
            ? LinearGradient(
                begin: const Alignment(-1, -1),
                end: const Alignment(1, 1),
                colors: widget.gradientBorderColors!,
                tileMode: TileMode.mirror,
                transform: _GradientShift(shift),
              )
            : null,
        border: !_hasAnimatedBorder
            ? Border.all(color: border, width: widget.borderWidth)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(_hasAnimatedBorder ? widget.borderWidth : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            _hasAnimatedBorder ? innerRadius : widget.borderRadius,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blur,
              sigmaY: widget.blur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                gradient: widget.gradientOverlay,
                borderRadius: BorderRadius.circular(
                  _hasAnimatedBorder ? innerRadius : widget.borderRadius,
                ),
              ),
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      card = GestureDetector(onTap: widget.onTap, child: card);
    }
    return card;
  }

  Widget _withHover(Widget card) {
    if (!widget.enableHover || !_supportsHover) return card;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, t, child) => Transform(
          transform: Matrix4.identity()
            ..translate(0.0, t * -2.0, 0.0)
            ..scale(1.0 + t * 0.01),
          alignment: Alignment.center,
          child: child,
        ),
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return _withHover(_buildCard(context, 0.0));
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) =>
          _withHover(_buildCard(context, _controller!.value)),
    );
  }
}

/// Slides a gradient horizontally by [shift] * width.
class _GradientShift implements GradientTransform {
  final double shift;
  const _GradientShift(this.shift);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(-shift * bounds.width, 0.0, 0.0);
  }
}

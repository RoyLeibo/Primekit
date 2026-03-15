import 'package:flutter/material.dart';

import '../design_system/pk_radius.dart';
import '../design_system/pk_spacing.dart';

/// A generic animated progress bar.
///
/// Takes a [value] between 0.0 and 1.0. Optionally displays a [label] above
/// and a percentage below. Supports custom colors, height, and animation.
///
/// ```dart
/// PkProgressBar(
///   value: 0.65,
///   activeColor: Colors.blue,
///   label: 'Upload progress',
/// )
/// ```
class PkProgressBar extends StatefulWidget {
  /// Progress value between 0.0 and 1.0.
  final double value;

  /// Color of the filled portion. Defaults to theme primary.
  final Color? activeColor;

  /// Gradient for the filled portion. Overrides [activeColor] when set.
  final Gradient? activeGradient;

  /// Color of the track (unfilled portion).
  final Color? trackColor;

  /// Height of the bar in logical pixels.
  final double height;

  /// Border radius of the bar. Defaults to half of [height].
  final double? borderRadius;

  /// Optional label displayed above the bar (left-aligned).
  final String? label;

  /// Optional right-aligned text above the bar (e.g. "3 / 10 tasks").
  final String? trailingLabel;

  /// Whether to show "XX% complete" text below the bar.
  final bool showPercentage;

  /// Duration of the progress fill animation.
  final Duration animationDuration;

  /// Animation curve.
  final Curve animationCurve;

  /// Whether to show a glowing dot at the leading edge.
  final bool showLeadingDot;

  /// Color of the leading dot glow. Defaults to [activeColor].
  final Color? leadingDotGlowColor;

  /// Text style for the labels. Falls back to theme caption style.
  final TextStyle? labelStyle;

  const PkProgressBar({
    super.key,
    required this.value,
    this.activeColor,
    this.activeGradient,
    this.trackColor,
    this.height = 7,
    this.borderRadius,
    this.label,
    this.trailingLabel,
    this.showPercentage = false,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeInOut,
    this.showLeadingDot = false,
    this.leadingDotGlowColor,
    this.labelStyle,
  });

  @override
  State<PkProgressBar> createState() => _PkProgressBarState();
}

class _PkProgressBarState extends State<PkProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(PkProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = widget.borderRadius ?? (widget.height / 2);
    final br = BorderRadius.circular(effectiveRadius);
    final trackColor =
        widget.trackColor ?? theme.colorScheme.surfaceContainerHighest;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final captionStyle = widget.labelStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.trailingLabel != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(widget.label!, style: captionStyle),
              if (widget.trailingLabel != null)
                Text(widget.trailingLabel!, style: captionStyle),
            ],
          ),
          const SizedBox(height: PkSpacing.sm),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final progress = _animation.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Track
                Container(
                  height: widget.height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: br,
                  ),
                ),
                // Fill
                if (progress > 0)
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.activeGradient == null
                            ? activeColor
                            : null,
                        gradient: widget.activeGradient,
                        borderRadius: br,
                      ),
                    ),
                  ),
                // Leading dot
                if (widget.showLeadingDot &&
                    progress > 0 &&
                    progress < 1.0)
                  Positioned(
                    top: -(widget.height * 0.4),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          width: widget.height * 1.8,
                          height: widget.height * 1.8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.leadingDotGlowColor ??
                                        activeColor)
                                    .withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.showPercentage) ...[
          const SizedBox(height: PkSpacing.xs),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final pct = (_animation.value * 100).round();
              return Text('$pct% complete', style: captionStyle);
            },
          ),
        ],
      ],
    );
  }
}

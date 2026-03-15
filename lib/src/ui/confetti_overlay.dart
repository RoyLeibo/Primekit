import 'dart:math';

import 'package:flutter/material.dart';

/// Default celebration colors used when none are provided.
const List<Color> kPkConfettiColors = [
  Color(0xFF9B85E8), // purple
  Color(0xFF5EB3F6), // blue
  Color(0xFF3ABFCC), // teal
  Color(0xFF4CC5A0), // green
  Color(0xFFE8B544), // amber
  Color(0xFFFF8AC0), // pink
];

/// Controls when confetti fires and which mode to use.
///
/// ```dart
/// final controller = PkConfettiController();
/// controller.burst(position); // point-burst
/// controller.rain();          // full-screen rain
/// ```
class PkConfettiController extends ChangeNotifier {
  _ConfettiRequest? _pending;

  /// Current pending request (consumed by the overlay).
  _ConfettiRequest? get pending => _pending;

  /// Fire a burst of confetti from a specific [position] (global coordinates).
  void burst(Offset position) {
    _pending = _ConfettiRequest(mode: PkConfettiMode.burst, origin: position);
    notifyListeners();
  }

  /// Start a full-screen confetti rain from the top.
  void rain() {
    _pending = _ConfettiRequest(mode: PkConfettiMode.rain, origin: null);
    notifyListeners();
  }

  /// Clear any pending request (called internally after consumption).
  void consume() {
    _pending = null;
  }
}

/// The two confetti presentation modes.
enum PkConfettiMode {
  /// Particles explode outward from a single point.
  burst,

  /// Particles fall from the top of the screen.
  rain,
}

class _ConfettiRequest {
  final PkConfettiMode mode;
  final Offset? origin;
  const _ConfettiRequest({required this.mode, required this.origin});
}

/// Overlay widget that renders confetti particles on top of its [child].
///
/// Supports two modes:
/// - **burst** — particles radiate from a point (like best_todo_list).
/// - **rain** — particles fall from the top (like Bullseye celebration).
///
/// Control playback via [controller] or the simpler [showConfetti] flag
/// (which triggers rain mode).
///
/// ```dart
/// PkConfettiOverlay(
///   controller: _confettiController,
///   particleCount: 60,
///   colors: [Colors.red, Colors.blue],
///   child: MyContent(),
/// )
/// ```
class PkConfettiOverlay extends StatefulWidget {
  /// Child widget rendered beneath the confetti layer.
  final Widget child;

  /// Optional controller for imperative triggering.
  final PkConfettiController? controller;

  /// Simple boolean trigger — starts rain mode when flipped to true.
  final bool showConfetti;

  /// Number of particles to generate.
  final int particleCount;

  /// Duration of the full animation.
  final Duration duration;

  /// Particle colors. Defaults to [kPkConfettiColors].
  final List<Color> colors;

  /// Called when the animation completes.
  final VoidCallback? onComplete;

  const PkConfettiOverlay({
    super.key,
    required this.child,
    this.controller,
    this.showConfetti = false,
    this.particleCount = 60,
    this.duration = const Duration(milliseconds: 2000),
    this.colors = kPkConfettiColors,
    this.onComplete,
  });

  @override
  State<PkConfettiOverlay> createState() => _PkConfettiOverlayState();
}

class _PkConfettiOverlayState extends State<PkConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  List<_Particle> _particles = const [];
  PkConfettiMode _mode = PkConfettiMode.rain;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    widget.controller?.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(PkConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _startRain();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _anim.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    final req = widget.controller?.pending;
    if (req == null) return;
    widget.controller!.consume();

    switch (req.mode) {
      case PkConfettiMode.burst:
        _startBurst(req.origin ?? Offset.zero);
      case PkConfettiMode.rain:
        _startRain();
    }
  }

  void _startBurst(Offset origin) {
    _mode = PkConfettiMode.burst;
    _particles = _Particle.generateBurst(
      widget.particleCount,
      origin,
      widget.colors,
    );
    _anim
      ..duration = widget.duration
      ..reset()
      ..forward();
    setState(() {});
  }

  void _startRain() {
    _mode = PkConfettiMode.rain;
    _particles = _Particle.generateRain(
      widget.particleCount,
      widget.colors,
    );
    _anim
      ..duration = widget.duration
      ..reset()
      ..forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _anim.value,
                    mode: _mode,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows a one-shot confetti burst overlay at [position].
///
/// Convenience function that inserts into the nearest [Overlay].
void showPkConfettiBurst(
  BuildContext context,
  Offset position, {
  int particleCount = 30,
  List<Color> colors = kPkConfettiColors,
  Duration duration = const Duration(milliseconds: 1400),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _StandaloneBurst(
      position: position,
      particleCount: particleCount,
      colors: colors,
      duration: duration,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _StandaloneBurst extends StatefulWidget {
  final Offset position;
  final int particleCount;
  final List<Color> colors;
  final Duration duration;
  final VoidCallback onDone;

  const _StandaloneBurst({
    required this.position,
    required this.particleCount,
    required this.colors,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_StandaloneBurst> createState() => _StandaloneBurstState();
}

class _StandaloneBurstState extends State<_StandaloneBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _Particle.generateBurst(
      widget.particleCount,
      widget.position,
      widget.colors,
    );
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
            mode: PkConfettiMode.burst,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle model
// ---------------------------------------------------------------------------

class _Particle {
  final Offset origin;
  final double speed;
  final double angle;
  final Color color;
  final double size;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swaySpeed;
  final int shapeIndex;

  const _Particle({
    required this.origin,
    required this.speed,
    required this.angle,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swaySpeed,
    required this.shapeIndex,
  });

  /// Generate particles for burst mode (radiate outward from [origin]).
  static List<_Particle> generateBurst(
    int count,
    Offset origin,
    List<Color> colors,
  ) {
    final rng = Random();
    return List.generate(count, (i) {
      final angle = (-pi / 2) + (rng.nextDouble() - 0.5) * (2 * pi / 3);
      return _Particle(
        origin: origin,
        speed: 80 + rng.nextDouble() * 220,
        angle: angle,
        color: colors[rng.nextInt(colors.length)],
        size: 4 + rng.nextDouble() * 5,
        rotationSpeed: rng.nextDouble() * 8,
        swayAmplitude: 0,
        swaySpeed: 0,
        shapeIndex: i % 3,
      );
    });
  }

  /// Generate particles for rain mode (fall from top).
  static List<_Particle> generateRain(int count, List<Color> colors) {
    final rng = Random();
    return List.generate(count, (i) {
      return _Particle(
        origin: Offset(rng.nextDouble(), -rng.nextDouble() * 0.3),
        speed: rng.nextDouble() * 3 + 2,
        angle: 0,
        color: colors[rng.nextInt(colors.length)],
        size: rng.nextDouble() * 8 + 4,
        rotationSpeed: (rng.nextDouble() - 0.5) * 10,
        swayAmplitude: rng.nextDouble() * 50 + 20,
        swaySpeed: rng.nextDouble() * 2 + 1,
        shapeIndex: i % 3,
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final PkConfettiMode mode;

  const _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case PkConfettiMode.burst:
        _paintBurst(canvas, size);
      case PkConfettiMode.rain:
        _paintRain(canvas, size);
    }
  }

  void _paintBurst(Canvas canvas, Size size) {
    final fadeStart = 0.7;
    final opacity =
        progress < fadeStart
            ? 1.0
            : (1.0 - (progress - fadeStart) / (1.0 - fadeStart)).clamp(0.0, 1.0);
    const gravity = 400.0;

    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * progress;
      final dy =
          sin(p.angle) * p.speed * progress + 0.5 * gravity * progress * progress;
      final pos = p.origin + Offset(dx, dy);
      _drawParticle(canvas, pos, p, opacity);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final opacity = 1.0 - progress * 0.5;

    for (final p in particles) {
      final x = p.origin.dx * size.width +
          sin(progress * p.swaySpeed * pi * 2) * p.swayAmplitude;
      final y = p.origin.dy * size.height +
          progress * size.height * p.speed;
      if (y > size.height) continue;
      _drawParticle(canvas, Offset(x, y), p, opacity);
    }
  }

  void _drawParticle(
    Canvas canvas,
    Offset pos,
    _Particle p,
    double opacity,
  ) {
    final rotation = p.rotationSpeed * progress;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    switch (p.shapeIndex) {
      case 0:
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      case 1:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      default:
        final path = Path()
          ..moveTo(0, -p.size / 2)
          ..lineTo(p.size / 2, p.size / 2)
          ..lineTo(-p.size / 2, p.size / 2)
          ..close();
        canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

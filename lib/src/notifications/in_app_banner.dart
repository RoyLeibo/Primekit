import 'dart:async';

import 'package:flutter/material.dart';

import '../core/logger.dart';

// ---------------------------------------------------------------------------
// Configuration types
// ---------------------------------------------------------------------------

/// Controls where the [InAppBanner] slides in from.
enum InAppBannerPosition {
  /// Banner slides down from the top of the screen.
  top,

  /// Banner slides up from the bottom of the screen.
  bottom,
}

/// Configuration object passed to [InAppBannerService.show].
final class InAppBannerConfig {
  const InAppBannerConfig({
    required this.message,
    this.title,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.displayDuration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
    this.position = InAppBannerPosition.top,
  });

  /// The main notification message (required).
  final String message;

  /// Optional title shown above the message in bold.
  final String? title;

  /// Optional leading icon.
  final IconData? icon;

  /// Background colour of the banner. Defaults to a dark surface colour.
  final Color? backgroundColor;

  /// Text and icon colour. Defaults to white.
  final Color? foregroundColor;

  /// How long the banner stays visible before auto-dismissing.
  final Duration displayDuration;

  /// Called when the user taps the banner.
  final VoidCallback? onTap;

  /// Called when the banner is dismissed (by auto-timeout or swipe).
  final VoidCallback? onDismiss;

  /// Whether the banner slides in from the top or bottom.
  final InAppBannerPosition position;
}

// ---------------------------------------------------------------------------
// InAppBannerService
// ---------------------------------------------------------------------------

/// A service for imperatively showing and hiding [InAppBanner]s.
///
/// ```dart
/// // Show a banner from anywhere with a BuildContext:
/// InAppBannerService.show(
///   context,
///   InAppBannerConfig(
///     title: 'New message',
///     message: 'Alice sent you a message.',
///     icon: Icons.chat_bubble_outline,
///     onTap: () => router.push('/chat'),
///   ),
/// );
///
/// // Dismiss programmatically:
/// InAppBannerService.hide();
/// ```
class InAppBannerService {
  InAppBannerService._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static const String _tag = 'InAppBannerService';

  /// Shows an in-app banner overlay.
  ///
  /// Dismisses any currently visible banner before showing the new one.
  static void show(BuildContext context, InAppBannerConfig config) {
    hide(); // Dismiss existing banner first.

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _InAppBannerOverlay(
        config: config,
        onDismiss: () {
          _removeCurrent();
          config.onDismiss?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(config.displayDuration, () {
      _removeCurrent();
      config.onDismiss?.call();
    });

    PrimekitLogger.debug(
      'InAppBannerService: showed banner "${config.message}"',
      tag: _tag,
    );
  }

  /// Hides the currently visible banner immediately.
  static void hide() {
    _removeCurrent();
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ---------------------------------------------------------------------------
// InAppBanner widget
// ---------------------------------------------------------------------------

/// A non-intrusive in-app notification banner that slides in from the top or
/// bottom and auto-dismisses after [displayDuration].
///
/// Supports tap, swipe-to-dismiss, and programmatic dismissal via
/// [InAppBannerService.hide].
///
/// Typically you use [InAppBannerService.show] rather than placing this
/// widget directly in the tree.
class InAppBanner extends StatefulWidget {
  /// Creates an in-app notification banner.
  const InAppBanner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.displayDuration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
    this.position = InAppBannerPosition.top,
  });

  /// The primary notification message.
  final String message;

  /// Optional title displayed in bold above the message.
  final String? title;

  /// Optional leading icon.
  final IconData? icon;

  /// Background colour (default: dark charcoal).
  final Color? backgroundColor;

  /// Text and icon colour (default: white).
  final Color? foregroundColor;

  /// How long the banner remains visible.
  final Duration displayDuration;

  /// Called when the user taps the banner.
  final VoidCallback? onTap;

  /// Called when the banner is dismissed.
  final VoidCallback? onDismiss;

  /// Banner entry position.
  final InAppBannerPosition position;

  @override
  State<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<InAppBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final beginOffset = widget.position == InAppBannerPosition.top
        ? const Offset(0.0, -1.0)
        : const Offset(0.0, 1.0);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? const Color(0xFF1F2937);
    final fg = widget.foregroundColor ?? Colors.white;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: const ValueKey('in_app_banner'),
          direction: widget.position == InAppBannerPosition.top
              ? DismissDirection.up
              : DismissDirection.down,
          onDismissed: (_) => widget.onDismiss?.call(),
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 22),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null)
                            Text(
                              widget.title!,
                              style: TextStyle(
                                color: fg,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          if (widget.title != null) const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close_rounded,
                        color: fg.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal overlay wrapper
// ---------------------------------------------------------------------------

class _InAppBannerOverlay extends StatelessWidget {
  const _InAppBannerOverlay({required this.config, required this.onDismiss});

  final InAppBannerConfig config;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      top: config.position == InAppBannerPosition.top ? topPadding + 4 : null,
      bottom: config.position == InAppBannerPosition.bottom
          ? bottomPadding + 4
          : null,
      left: 0,
      right: 0,
      child: InAppBanner(
        message: config.message,
        title: config.title,
        icon: config.icon,
        backgroundColor: config.backgroundColor,
        foregroundColor: config.foregroundColor,
        displayDuration: config.displayDuration,
        position: config.position,
        onTap: config.onTap,
        onDismiss: onDismiss,
      ),
    );
  }
}

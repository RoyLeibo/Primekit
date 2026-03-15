import 'package:flutter/material.dart';

import '../design_system/pk_radius.dart';
import '../design_system/pk_spacing.dart';

/// Data for a single onboarding page.
@immutable
class PkOnboardingPage {
  /// The widget content for this page (full page area).
  final Widget content;

  /// Optional builder — if provided, takes precedence over [content].
  /// Receives the [BuildContext] for theme access.
  final Widget Function(BuildContext context)? builder;

  const PkOnboardingPage({required this.content, this.builder});

  /// Convenience constructor with icon + title + subtitle layout.
  const PkOnboardingPage.simple({
    required IconData icon,
    required String title,
    required String subtitle,
    double iconSize = 36,
    double iconContainerSize = 80,
    Color? iconColor,
    Color? iconBackgroundColor,
  }) : content = _PkOnboardingSimplePage(
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconSize: iconSize,
          iconContainerSize: iconContainerSize,
          iconColor: iconColor,
          iconBackgroundColor: iconBackgroundColor,
        ),
       builder = null;
}

/// A generic swipeable onboarding flow with progress dots and navigation.
///
/// ```dart
/// PkOnboardingFlow(
///   pages: [
///     PkOnboardingPage.simple(
///       icon: Icons.star,
///       title: 'Welcome',
///       subtitle: 'Get started with our app',
///     ),
///     PkOnboardingPage(content: MyCustomPage()),
///   ],
///   onComplete: () => Navigator.of(context).pushReplacement(...),
///   showSkip: true,
/// )
/// ```
class PkOnboardingFlow extends StatefulWidget {
  /// The pages to display.
  final List<PkOnboardingPage> pages;

  /// Called when the user finishes the last page or taps skip.
  final VoidCallback onComplete;

  /// Whether to show a skip button.
  final bool showSkip;

  /// Label for the skip button.
  final String skipLabel;

  /// Label for the next button.
  final String nextLabel;

  /// Label for the final page's CTA button.
  final String doneLabel;

  /// Duration of the page transition animation.
  final Duration animationDuration;

  /// Active dot color. Defaults to theme primary.
  final Color? activeDotColor;

  /// Inactive dot color. Defaults to theme outline variant.
  final Color? inactiveDotColor;

  /// Builder for the primary action button. When null, uses a default
  /// filled button.
  final Widget Function(String label, VoidCallback onPressed)?
      actionButtonBuilder;

  const PkOnboardingFlow({
    super.key,
    required this.pages,
    required this.onComplete,
    this.showSkip = true,
    this.skipLabel = 'Skip',
    this.nextLabel = 'Next',
    this.doneLabel = 'Get Started',
    this.animationDuration = const Duration(milliseconds: 300),
    this.activeDotColor,
    this.inactiveDotColor,
    this.actionButtonBuilder,
  });

  @override
  State<PkOnboardingFlow> createState() => _PkOnboardingFlowState();
}

class _PkOnboardingFlowState extends State<PkOnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == widget.pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) {
      widget.onComplete();
    } else {
      _pageController.nextPage(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // Skip button
          if (widget.showSkip)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PkSpacing.lg,
                vertical: PkSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      widget.skipLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = widget.pages[index];
                return page.builder?.call(context) ?? page.content;
              },
            ),
          ),
          // Bottom: dots + CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PkSpacing.xl,
              PkSpacing.xl,
              PkSpacing.xl,
              PkSpacing.xxxl,
            ),
            child: Column(
              children: [
                _PageDots(
                  count: widget.pages.length,
                  current: _currentPage,
                  activeColor:
                      widget.activeDotColor ?? theme.colorScheme.primary,
                  inactiveColor: widget.inactiveDotColor ??
                      theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: PkSpacing.xxl),
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final label = _isLastPage ? widget.doneLabel : widget.nextLabel;

    if (widget.actionButtonBuilder != null) {
      return widget.actionButtonBuilder!(label, _next);
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _next,
        child: Text(label),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page dots
// ---------------------------------------------------------------------------

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  const _PageDots({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: PkSpacing.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(PkRadius.full),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple page layout
// ---------------------------------------------------------------------------

class _PkOnboardingSimplePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final double iconContainerSize;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const _PkOnboardingSimplePage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconSize = 36,
    this.iconContainerSize = 80,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBgColor = iconBackgroundColor ??
        theme.colorScheme.primaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PkSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: iconSize),
          ),
          const SizedBox(height: PkSpacing.xxl),
          Text(
            title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PkSpacing.md),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

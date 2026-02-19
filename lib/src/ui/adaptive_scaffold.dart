import 'package:flutter/material.dart';

/// A single destination entry used by [AdaptiveScaffold].
///
/// Maps to a [NavigationDestination] on mobile, a [NavigationRailDestination]
/// on tablet, and a drawer item on desktop.
class AdaptiveDestination {
  /// Creates an adaptive navigation destination.
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    Widget? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;
  // Note: selectedIcon is intentionally optional (defaults to icon).

  /// Icon shown when the destination is not selected.
  final Widget icon;

  /// Icon shown when the destination is selected.
  final Widget selectedIcon;

  /// The human-readable label for the destination.
  final String label;
}

/// A responsive scaffold that automatically adapts its navigation chrome:
///
/// | Screen width | Navigation type               |
/// |-------------|-------------------------------|
/// | < 600 px    | Bottom navigation bar         |
/// | 600–1199 px | Navigation rail (side)        |
/// | ≥ 1200 px   | Persistent navigation drawer  |
///
/// ```dart
/// AdaptiveScaffold(
///   destinations: [
///     AdaptiveDestination(label: 'Home', icon: Icon(Icons.home)),
///     AdaptiveDestination(label: 'Search', icon: Icon(Icons.search)),
///   ],
///   selectedIndex: _selectedIndex,
///   onDestinationSelected: (i) => setState(() => _selectedIndex = i),
///   body: (index) => _pages[index],
/// )
/// ```
class AdaptiveScaffold extends StatelessWidget {
  /// Creates an adaptive scaffold.
  const AdaptiveScaffold({
    required this.destinations,
    required this.body,
    this.floatingActionButton,
    this.appBar,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    super.key,
  }) : assert(destinations.length >= 2, 'At least 2 destinations required');

  /// The list of top-level navigation destinations.
  final List<AdaptiveDestination> destinations;

  /// Builder that returns the body widget for the currently selected index.
  final Widget Function(int index) body;

  /// Optional floating action button forwarded to the [Scaffold].
  final Widget? floatingActionButton;

  /// Optional app bar forwarded to the [Scaffold].
  final PreferredSizeWidget? appBar;

  /// The index of the currently selected destination.
  final int selectedIndex;

  /// Called when the user taps a destination.
  final void Function(int)? onDestinationSelected;

  // Breakpoints follow Material 3 adaptive layout guidelines.
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1200;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < _mobileBreakpoint) {
            return _MobileScaffold(scaffold: this);
          } else if (width < _tabletBreakpoint) {
            return _TabletScaffold(scaffold: this);
          } else {
            return _DesktopScaffold(scaffold: this);
          }
        },
      );
}

// ---------------------------------------------------------------------------
// Mobile — BottomNavigationBar
// ---------------------------------------------------------------------------

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({required this.scaffold});

  final AdaptiveScaffold scaffold;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: scaffold.appBar,
        floatingActionButton: scaffold.floatingActionButton,
        body: scaffold.body(scaffold.selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: scaffold.selectedIndex,
          onDestinationSelected: scaffold.onDestinationSelected,
          destinations: scaffold.destinations
              .map(
                (d) => NavigationDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: d.label,
                ),
              )
              .toList(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Tablet — NavigationRail
// ---------------------------------------------------------------------------

class _TabletScaffold extends StatelessWidget {
  const _TabletScaffold({required this.scaffold});

  final AdaptiveScaffold scaffold;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: scaffold.appBar,
        floatingActionButton: scaffold.floatingActionButton,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: scaffold.selectedIndex,
              onDestinationSelected:
                  scaffold.onDestinationSelected ?? (_) {},
              labelType: NavigationRailLabelType.selected,
              destinations: scaffold.destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: scaffold.body(scaffold.selectedIndex)),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Desktop — Persistent NavigationDrawer
// ---------------------------------------------------------------------------

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({required this.scaffold});

  final AdaptiveScaffold scaffold;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: scaffold.appBar,
      floatingActionButton: scaffold.floatingActionButton,
      body: Row(
        children: [
          // Persistent drawer panel
          SizedBox(
            width: 256,
            child: ColoredBox(
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  for (int i = 0; i < scaffold.destinations.length; i++)
                    _DrawerItem(
                      destination: scaffold.destinations[i],
                      isSelected: i == scaffold.selectedIndex,
                      onTap: () =>
                          scaffold.onDestinationSelected?.call(i),
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: scaffold.body(scaffold.selectedIndex)),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.textTheme,
    required this.colorScheme,
  });

  final AdaptiveDestination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: isSelected
              ? colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    child: isSelected
                        ? destination.selectedIcon
                        : destination.icon,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

import 'package:flutter/widgets.dart';

import 'membership_service.dart';
import 'membership_tier.dart';

/// An [InheritedWidget] that makes a [MembershipService] available to the
/// widget sub-tree.
///
/// Wrap your app (or a sub-tree) with [MembershipScope] to enable [TierGate]
/// and other membership-aware widgets:
///
/// ```dart
/// MembershipScope(
///   service: membershipService,
///   child: MyApp(),
/// )
/// ```
class MembershipScope extends InheritedNotifier<MembershipService> {
  /// Creates a [MembershipScope] that provides [service] to [child].
  const MembershipScope({
    required MembershipService service,
    required super.child,
    super.key,
  }) : super(notifier: service);

  /// Retrieves the nearest [MembershipService] from the widget tree.
  ///
  /// Throws a [FlutterError] if no [MembershipScope] ancestor is found.
  static MembershipService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MembershipScope>();
    if (scope == null) {
      throw FlutterError(
        'MembershipScope.of() called with a context that does not contain a '
        'MembershipScope.\n'
        'Ensure a MembershipScope widget wraps the part of the widget tree '
        'where tier-gated widgets are used.',
      );
    }
    return scope.notifier!;
  }

  /// Returns the nearest [MembershipService], or `null` if none exists.
  static MembershipService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MembershipScope>()?.notifier;
}

/// A widget that renders [child] only when the current user's tier meets or
/// exceeds [requires].
///
/// When the user's tier is insufficient, [fallback] is shown instead (or
/// nothing if [fallback] is `null`).
///
/// Requires a [MembershipScope] ancestor in the widget tree.
///
/// ```dart
/// TierGate(
///   requires: MembershipTier.pro,
///   fallback: UpgradePrompt(targetTier: MembershipTier.pro),
///   child: ExportButton(),
/// )
/// ```
class TierGate extends StatelessWidget {
  /// Creates a [TierGate].
  ///
  /// [child] is displayed when the user's tier satisfies [requires].
  /// [fallback] is displayed otherwise; passing `null` renders nothing.
  /// [customCheck] overrides the tier comparison with an arbitrary predicate
  /// when provided.
  const TierGate({
    required this.child,
    required this.requires,
    super.key,
    this.fallback,
    this.customCheck,
  });

  /// The widget to show when the user has sufficient access.
  final Widget child;

  /// The minimum tier required to show [child].
  final MembershipTier requires;

  /// Widget shown when the user's tier is below [requires].
  ///
  /// Renders [SizedBox.shrink] when `null`.
  final Widget? fallback;

  /// If supplied, replaces the default tier comparison.
  ///
  /// Returning `true` shows [child]; returning `false` shows [fallback].
  final bool Function()? customCheck;

  @override
  Widget build(BuildContext context) {
    final service = MembershipScope.of(context);
    final hasAccess = customCheck != null
        ? customCheck!()
        : service.currentTier.isAtLeast(requires);

    if (hasAccess) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

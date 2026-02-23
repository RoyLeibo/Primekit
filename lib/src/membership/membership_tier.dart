import 'package:flutter/painting.dart';

/// A membership tier that defines a user's privilege level in the application.
///
/// Tiers are ordered by [level]; a higher level means more access. Use
/// [isAtLeast] to compare tiers in access-control logic.
///
/// Three standard tiers are provided as constants:
/// - [MembershipTier.free]  — level 0, no subscription required.
/// - [MembershipTier.pro]   — level 10, paid subscription.
/// - [MembershipTier.enterprise] — level 20, team / business plan.
///
/// Register custom tiers as `const` values and pass them to `AccessPolicy`:
///
/// ```dart
/// const starter = MembershipTier(
///   id: 'starter',
///   name: 'Starter',
///   level: 5,
///   perks: ['10 exports/month', 'Email support'],
///   badgeLabel: 'Starter',
///   badgeColor: Color(0xFF42A5F5),
/// );
/// ```
class MembershipTier {
  /// Creates a [MembershipTier].
  ///
  /// [id] must be unique across all tiers in the app. [level] must be
  /// non-negative; higher values indicate greater privilege.
  const MembershipTier({
    required this.id,
    required this.name,
    required this.level,
    this.perks = const [],
    this.badgeLabel,
    this.badgeColor,
  }) : assert(level >= 0, 'MembershipTier.level must be non-negative');

  /// Unique stable identifier for this tier (e.g. `'pro'`, `'enterprise'`).
  final String id;

  /// Display name shown to the user (e.g. `'Pro'`, `'Enterprise'`).
  final String name;

  /// Privilege level — 0 is the base free tier; higher means more access.
  final int level;

  /// Human-readable list of benefits included in this tier.
  final List<String> perks;

  /// Short label shown on the member badge (e.g. `'PRO'`). `null` hides the badge.
  final String? badgeLabel;

  /// Background color of the member badge. Defaults to a neutral grey when `null`.
  final Color? badgeColor;

  // ---------------------------------------------------------------------------
  // Standard tiers
  // ---------------------------------------------------------------------------

  /// The default free tier — level 0, no subscription required.
  static const MembershipTier free = MembershipTier(
    id: 'free',
    name: 'Free',
    level: 0,
    perks: ['Basic features', 'Community support'],
  );

  /// The standard paid pro tier — level 10.
  static const MembershipTier pro = MembershipTier(
    id: 'pro',
    name: 'Pro',
    level: 10,
    perks: [
      'All free features',
      'Unlimited exports',
      'Priority support',
      'No ads',
    ],
    badgeLabel: 'PRO',
    badgeColor: Color(0xFF6366F1), // Indigo
  );

  /// The enterprise / team tier — level 20.
  static const MembershipTier enterprise = MembershipTier(
    id: 'enterprise',
    name: 'Enterprise',
    level: 20,
    perks: [
      'All Pro features',
      'Team management',
      'SSO integration',
      'Dedicated account manager',
      'SLA guarantee',
    ],
    badgeLabel: 'ENTERPRISE',
    badgeColor: Color(0xFFF59E0B), // Amber
  );

  // ---------------------------------------------------------------------------
  // Comparison
  // ---------------------------------------------------------------------------

  /// Returns `true` if this tier's [level] is at least as high as [other].
  ///
  /// Use this in access-control checks:
  /// ```dart
  /// if (userTier.isAtLeast(MembershipTier.pro)) {
  ///   grantProAccess();
  /// }
  /// ```
  bool isAtLeast(MembershipTier other) => level >= other.level;

  /// Returns `true` if this tier's [level] is strictly higher than [other].
  bool isAbove(MembershipTier other) => level > other.level;

  /// Returns `true` if this tier's [level] is strictly lower than [other].
  bool isBelow(MembershipTier other) => level < other.level;

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  MembershipTier copyWith({
    String? id,
    String? name,
    int? level,
    List<String>? perks,
    String? badgeLabel,
    Color? badgeColor,
  }) => MembershipTier(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    perks: perks ?? List.unmodifiable(this.perks),
    badgeLabel: badgeLabel ?? this.badgeLabel,
    badgeColor: badgeColor ?? this.badgeColor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipTier &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          level == other.level;

  @override
  int get hashCode => Object.hash(id, level);

  @override
  String toString() => 'MembershipTier(id: $id, name: $name, level: $level)';
}

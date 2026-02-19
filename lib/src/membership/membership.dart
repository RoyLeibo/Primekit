/// Membership — Tier-based access control, upgrade prompts, trial management,
/// and membership-aware UI widgets for Primekit applications.
///
/// ## Quick start
///
/// ```dart
/// import 'package:primekit/membership.dart';
///
/// // 1. Define your access policy.
/// final policy = AccessPolicy();
/// policy.define('export_pdf',  MembershipTier.pro);
/// policy.define('sso_login',   MembershipTier.enterprise);
///
/// // 2. Set up the membership service with your tier resolver.
/// final service = MembershipService();
/// service.configure(resolver: () async {
///   final activeSub = await billingManager.getActiveSubscription();
///   return activeSub != null ? MembershipTier.pro : MembershipTier.free;
/// });
/// await service.refresh();
///
/// // 3. Provide the service to the widget tree.
/// MembershipScope(
///   service: service,
///   child: MyApp(),
/// );
///
/// // 4. Gate features in the UI.
/// TierGate(
///   requires: MembershipTier.pro,
///   fallback: UpgradePrompt(
///     targetTier: MembershipTier.pro,
///     featureName: 'PDF Export',
///     onUpgradeTap: () => showPaywall(),
///   ),
///   child: ExportButton(),
/// );
/// ```
library primekit_membership;

export 'access_policy.dart';
export 'member_badge.dart';
export 'membership_service.dart';
export 'membership_tier.dart';
export 'tier_gate.dart';
export 'trial_manager.dart';
export 'upgrade_prompt.dart';

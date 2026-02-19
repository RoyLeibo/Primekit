import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../core/logger.dart';
import 'membership_tier.dart';

/// A function that asynchronously resolves the current user's [MembershipTier].
///
/// Implement this to integrate your backend, billing SDK, or RevenueCat:
/// ```dart
/// Future<MembershipTier> myResolver() async {
///   final sub = await revenueCat.getActiveSubscription();
///   if (sub?.productId == 'enterprise') return MembershipTier.enterprise;
///   if (sub?.productId.startsWith('pro') == true) return MembershipTier.pro;
///   return MembershipTier.free;
/// }
/// ```
typedef MembershipTierResolver = Future<MembershipTier> Function();

/// Manages the current user's [MembershipTier] and broadcasts changes.
///
/// Configure the service with a [MembershipTierResolver] that integrates your
/// billing backend, then use [currentTier] and [tierUpdates] throughout the app:
///
/// ```dart
/// final service = MembershipService();
/// service.configure(resolver: myResolver);
/// await service.refresh();
///
/// // Reactive UI:
/// service.tierUpdates.listen((tier) {
///   print('Tier changed to ${tier.name}');
/// });
/// ```
class MembershipService extends ChangeNotifier {
  /// Creates a [MembershipService]. Call [configure] before [refresh].
  MembershipService()
      : _currentTier = MembershipTier.free,
        _tierController = BehaviorSubject<MembershipTier>.seeded(
          MembershipTier.free,
        );

  MembershipTier _currentTier;
  MembershipTierResolver? _resolver;

  final BehaviorSubject<MembershipTier> _tierController;

  static const String _tag = 'MembershipService';

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the resolver used to fetch the user's current tier.
  ///
  /// [resolver] is called on every [refresh]. This method is idempotent —
  /// calling it again replaces the previous resolver.
  void configure({required MembershipTierResolver resolver}) {
    _resolver = resolver;
    PrimekitLogger.info('MembershipService configured', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The most recently fetched membership tier.
  ///
  /// Defaults to [MembershipTier.free] until [refresh] succeeds.
  MembershipTier get currentTier => _currentTier;

  /// Broadcast stream that replays the latest [MembershipTier] to new
  /// subscribers and emits whenever [refresh] yields a new tier.
  Stream<MembershipTier> get tierUpdates => _tierController.stream;

  /// Fetches the user's current tier from the configured resolver and updates
  /// [currentTier] and [tierUpdates].
  ///
  /// Throws [StateError] if [configure] has not been called.
  Future<void> refresh() async {
    final resolver = _resolver;
    if (resolver == null) {
      throw StateError(
        'MembershipService.refresh() called before configure(). '
        'Call configure(resolver: …) first.',
      );
    }

    try {
      final tier = await resolver();

      if (tier == _currentTier) {
        PrimekitLogger.verbose(
          'MembershipService.refresh: tier unchanged (${tier.name})',
          tag: _tag,
        );
        return;
      }

      _currentTier = tier;
      _tierController.add(tier);
      notifyListeners();

      PrimekitLogger.info(
        'Membership tier updated → ${tier.name} (level ${tier.level})',
        tag: _tag,
      );
    } catch (error, stack) {
      PrimekitLogger.error(
        'MembershipService.refresh failed',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Resets the tier to [MembershipTier.free] (e.g. on sign-out).
  void reset() {
    _currentTier = MembershipTier.free;
    _tierController.add(MembershipTier.free);
    notifyListeners();
    PrimekitLogger.info('MembershipService reset to free tier', tag: _tag);
  }

  /// Whether the current user has at least [tier] access.
  bool hasAtLeast(MembershipTier tier) => _currentTier.isAtLeast(tier);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _tierController.close();
    super.dispose();
  }
}

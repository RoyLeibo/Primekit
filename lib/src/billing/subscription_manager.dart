import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../core/logger.dart';

/// The current lifecycle state of a subscription.
enum SubscriptionStatus {
  /// The subscription is active and the entitlement is granted.
  active,

  /// The subscription has passed its expiry date without renewal.
  expired,

  /// The user has cancelled; may still be active until [SubscriptionInfo.expiresAt].
  cancelled,

  /// The subscription is within a free-trial period.
  trialing,

  /// The subscription has been paused (e.g. billing hold on Android).
  paused,

  /// The status could not be determined (e.g. before the first refresh).
  unknown,
}

/// A snapshot of a user's subscription state for a single product.
///
/// All fields are immutable. Use [SubscriptionManager.getSubscription] or
/// [SubscriptionManager.subscriptionUpdates] to receive updated snapshots.
///
/// ```dart
/// final info = await manager.getSubscription('primekit_pro_monthly');
/// if (info?.isActive ?? false) {
///   // Grant access
/// }
/// ```
final class SubscriptionInfo {
  /// Creates a subscription snapshot.
  const SubscriptionInfo({
    required this.productId,
    required this.status,
    this.expiresAt,
    this.startedAt,
    this.isInTrial = false,
    this.willRenew = false,
  });

  /// The Primekit product ID this info belongs to.
  final String productId;

  /// Current lifecycle status of the subscription.
  final SubscriptionStatus status;

  /// UTC timestamp when the current billing period expires.
  ///
  /// `null` when the subscription has no known expiry (e.g. [SubscriptionStatus.unknown]).
  final DateTime? expiresAt;

  /// UTC timestamp when the subscription was originally started.
  ///
  /// `null` if unavailable from the billing backend.
  final DateTime? startedAt;

  /// Whether the subscription is currently in a free-trial period.
  final bool isInTrial;

  /// Whether the subscription is set to auto-renew after the current period.
  final bool willRenew;

  /// `true` if the user's entitlement should be granted right now.
  ///
  /// Covers both [SubscriptionStatus.active] and [SubscriptionStatus.trialing],
  /// and also [SubscriptionStatus.cancelled] when the billing period has not yet
  /// elapsed.
  bool get isActive {
    switch (status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.trialing:
        return true;
      case SubscriptionStatus.cancelled:
        // Cancelled but still within the paid period.
        final expiry = expiresAt;
        return expiry != null && expiry.isAfter(DateTime.now().toUtc());
      case SubscriptionStatus.expired:
      case SubscriptionStatus.paused:
      case SubscriptionStatus.unknown:
        return false;
    }
  }

  /// Time remaining until the subscription expires, or `null` if [expiresAt]
  /// is not set or the subscription has already expired.
  Duration? get daysUntilExpiry {
    final expiry = expiresAt;
    if (expiry == null) return null;
    final remaining = expiry.difference(DateTime.now().toUtc());
    return remaining.isNegative ? null : remaining;
  }

  /// Returns a copy with the given fields replaced.
  SubscriptionInfo copyWith({
    String? productId,
    SubscriptionStatus? status,
    DateTime? expiresAt,
    DateTime? startedAt,
    bool? isInTrial,
    bool? willRenew,
  }) =>
      SubscriptionInfo(
        productId: productId ?? this.productId,
        status: status ?? this.status,
        expiresAt: expiresAt ?? this.expiresAt,
        startedAt: startedAt ?? this.startedAt,
        isInTrial: isInTrial ?? this.isInTrial,
        willRenew: willRenew ?? this.willRenew,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionInfo &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          status == other.status &&
          expiresAt == other.expiresAt &&
          startedAt == other.startedAt &&
          isInTrial == other.isInTrial &&
          willRenew == other.willRenew;

  @override
  int get hashCode =>
      Object.hash(productId, status, expiresAt, startedAt, isInTrial, willRenew);

  @override
  String toString() =>
      'SubscriptionInfo(productId: $productId, status: $status, '
      'isActive: $isActive, expiresAt: $expiresAt)';
}

/// Contract that a platform billing integration must implement to supply
/// [SubscriptionManager] with real subscription data.
///
/// Implement this for RevenueCat, in-house backend, App Store Server API, etc.
abstract interface class SubscriptionDataSource {
  /// Returns the current [SubscriptionInfo] for the given [productId],
  /// or `null` if the user has never purchased it.
  Future<SubscriptionInfo?> fetchSubscription(String productId);

  /// Returns all subscriptions ever purchased by the user, regardless of status.
  Future<List<SubscriptionInfo>> fetchAllSubscriptions();

  /// Forces the data source to re-validate purchases with the billing backend.
  Future<void> refresh();

  /// Triggers the platform restore-purchases flow and returns the restored infos.
  Future<List<SubscriptionInfo>> restore();
}

/// Manages access to the user's subscription state across all products.
///
/// Depends on a [SubscriptionDataSource] (injected at construction) to
/// abstract away the platform billing SDK (RevenueCat, native IAP, etc.).
///
/// ```dart
/// final manager = SubscriptionManager(dataSource: RevenueCatDataSource());
/// await manager.refresh();
///
/// final sub = await manager.getSubscription('primekit_pro_monthly');
/// if (sub?.isActive == true) { /* … */ }
///
/// manager.subscriptionUpdates.listen((subs) {
///   final hasPro = subs.any((s) => s.isActive);
/// });
/// ```
class SubscriptionManager extends ChangeNotifier {
  /// Creates a [SubscriptionManager] backed by [dataSource].
  SubscriptionManager({required SubscriptionDataSource dataSource})
      : _dataSource = dataSource;

  final SubscriptionDataSource _dataSource;

  // Cached subscription state.  Key = productId.
  final Map<String, SubscriptionInfo> _cache = {};

  final BehaviorSubject<List<SubscriptionInfo>> _updatesController =
      BehaviorSubject<List<SubscriptionInfo>>.seeded(const []);

  static const String _tag = 'SubscriptionManager';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Retrieves the current [SubscriptionInfo] for [productId].
  ///
  /// Returns a cached value if available, otherwise fetches from the data
  /// source. Returns `null` if the user has no purchase record for [productId].
  Future<SubscriptionInfo?> getSubscription(String productId) async {
    if (_cache.containsKey(productId)) return _cache[productId];

    try {
      final info = await _dataSource.fetchSubscription(productId);
      if (info != null) {
        _cache[productId] = info;
        _publishUpdate();
      }
      return info;
    } catch (error, stack) {
      PrimekitLogger.error(
        'Failed to fetch subscription for $productId',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Returns all subscriptions currently known to be active (not expired,
  /// not paused, not unknown).
  Future<List<SubscriptionInfo>> getActiveSubscriptions() async {
    await refresh();
    return _cache.values.where((s) => s.isActive).toList(growable: false);
  }

  /// Broadcast stream that emits the full list of known subscriptions whenever
  /// the state changes (e.g. after [refresh] or [restore]).
  ///
  /// The stream replays the latest value to new listeners immediately.
  Stream<List<SubscriptionInfo>> get subscriptionUpdates =>
      _updatesController.stream;

  /// Forces a re-fetch of all subscription data from the billing backend and
  /// updates the cache and [subscriptionUpdates] stream.
  Future<void> refresh() async {
    try {
      await _dataSource.refresh();
      final infos = await _dataSource.fetchAllSubscriptions();
      _cache
        ..clear()
        ..addEntries(infos.map((i) => MapEntry(i.productId, i)));
      _publishUpdate();
      notifyListeners();
      PrimekitLogger.debug('Subscription cache refreshed (${infos.length} items)', tag: _tag);
    } catch (error, stack) {
      PrimekitLogger.error(
        'Subscription refresh failed',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Triggers the platform restore-purchases flow and updates the cache with
  /// the restored subscriptions.
  Future<void> restore() async {
    try {
      final restored = await _dataSource.restore();
      for (final info in restored) {
        _cache[info.productId] = info;
      }
      _publishUpdate();
      notifyListeners();
      PrimekitLogger.info(
        'Restored ${restored.length} subscription(s)',
        tag: _tag,
      );
    } catch (error, stack) {
      PrimekitLogger.error(
        'Subscription restore failed',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// `true` if the user has at least one active, non-expired subscription.
  bool get hasPremium => _cache.values.any((s) => s.isActive);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _publishUpdate() {
    _updatesController.add(
      List.unmodifiable(_cache.values.toList(growable: false)),
    );
  }

  @override
  void dispose() {
    _updatesController.close();
    super.dispose();
  }
}

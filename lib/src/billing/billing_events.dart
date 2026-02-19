/// All billing-related events emitted by the Primekit billing system.
///
/// Use the factory constructors to create events, and pattern-match with
/// `switch` to handle them:
///
/// ```dart
/// billingEventBus.stream.listen((event) {
///   switch (event) {
///     case PurchaseCompleted(:final productId, :final amount, :final currency):
///       analytics.track('purchase', {'product': productId, 'amount': amount});
///     case PurchaseFailed(:final productId, :final reason):
///       showErrorSnackbar('Purchase failed: $reason');
///     case TrialStarted(:final productId, :final trialEnds):
///       scheduleTrialEndingNotification(productId, trialEnds);
///     default:
///       break;
///   }
/// });
/// ```
sealed class BillingEvent {
  const BillingEvent();

  /// The user has initiated a purchase flow for [productId].
  factory BillingEvent.purchaseStarted(String productId) =>
      PurchaseStarted(productId);

  /// A purchase completed successfully.
  factory BillingEvent.purchaseCompleted({
    required String productId,
    required double amount,
    required String currency,
  }) =>
      PurchaseCompleted(
        productId: productId,
        amount: amount,
        currency: currency,
      );

  /// A purchase attempt failed with the given [reason].
  factory BillingEvent.purchaseFailed({
    required String productId,
    required String reason,
  }) =>
      PurchaseFailed(productId: productId, reason: reason);

  /// The user explicitly cancelled the purchase flow for [productId].
  factory BillingEvent.purchaseCancelled(String productId) =>
      PurchaseCancelled(productId);

  /// A subscription was successfully renewed; the next renewal is [nextRenewal].
  factory BillingEvent.subscriptionRenewed({
    required String productId,
    required DateTime nextRenewal,
  }) =>
      SubscriptionRenewed(productId: productId, nextRenewal: nextRenewal);

  /// The user has cancelled an ongoing subscription for [productId].
  factory BillingEvent.subscriptionCancelled(String productId) =>
      SubscriptionCancelled(productId);

  /// A free trial has started for [productId]; it ends at [trialEnds].
  factory BillingEvent.trialStarted({
    required String productId,
    required DateTime trialEnds,
  }) =>
      TrialStarted(productId: productId, trialEnds: trialEnds);

  /// One or more purchases were restored via the platform restore flow.
  factory BillingEvent.restored(List<String> restoredProductIds) =>
      PurchasesRestored(restoredProductIds);
}

// ---------------------------------------------------------------------------
// Concrete event types
// ---------------------------------------------------------------------------

/// The user has initiated a purchase for [productId].
final class PurchaseStarted extends BillingEvent {
  const PurchaseStarted(this.productId);

  /// The Primekit product ID being purchased.
  final String productId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseStarted && productId == other.productId;

  @override
  int get hashCode => Object.hash(runtimeType, productId);

  @override
  String toString() => 'PurchaseStarted(productId: $productId)';
}

/// A purchase completed successfully.
final class PurchaseCompleted extends BillingEvent {
  const PurchaseCompleted({
    required this.productId,
    required this.amount,
    required this.currency,
  }) : assert(amount >= 0, 'PurchaseCompleted.amount must be non-negative');

  /// The Primekit product ID that was purchased.
  final String productId;

  /// The amount charged in [currency] units.
  final double amount;

  /// ISO 4217 currency code (e.g. `'USD'`).
  final String currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseCompleted &&
          productId == other.productId &&
          amount == other.amount &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(runtimeType, productId, amount, currency);

  @override
  String toString() =>
      'PurchaseCompleted(productId: $productId, amount: $amount $currency)';
}

/// A purchase attempt failed.
final class PurchaseFailed extends BillingEvent {
  const PurchaseFailed({required this.productId, required this.reason});

  /// The Primekit product ID for which the purchase was attempted.
  final String productId;

  /// A developer-readable reason string describing the failure.
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseFailed &&
          productId == other.productId &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(runtimeType, productId, reason);

  @override
  String toString() =>
      'PurchaseFailed(productId: $productId, reason: $reason)';
}

/// The user cancelled the purchase flow.
final class PurchaseCancelled extends BillingEvent {
  const PurchaseCancelled(this.productId);

  /// The Primekit product ID whose purchase was cancelled.
  final String productId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseCancelled && productId == other.productId;

  @override
  int get hashCode => Object.hash(runtimeType, productId);

  @override
  String toString() => 'PurchaseCancelled(productId: $productId)';
}

/// A subscription renewed successfully.
final class SubscriptionRenewed extends BillingEvent {
  const SubscriptionRenewed({
    required this.productId,
    required this.nextRenewal,
  });

  /// The Primekit product ID that renewed.
  final String productId;

  /// UTC timestamp of the next scheduled renewal.
  final DateTime nextRenewal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionRenewed &&
          productId == other.productId &&
          nextRenewal == other.nextRenewal;

  @override
  int get hashCode => Object.hash(runtimeType, productId, nextRenewal);

  @override
  String toString() =>
      'SubscriptionRenewed(productId: $productId, nextRenewal: $nextRenewal)';
}

/// The user cancelled an active subscription.
final class SubscriptionCancelled extends BillingEvent {
  const SubscriptionCancelled(this.productId);

  /// The Primekit product ID whose subscription was cancelled.
  final String productId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionCancelled && productId == other.productId;

  @override
  int get hashCode => Object.hash(runtimeType, productId);

  @override
  String toString() => 'SubscriptionCancelled(productId: $productId)';
}

/// A free trial has started for a product.
final class TrialStarted extends BillingEvent {
  const TrialStarted({required this.productId, required this.trialEnds});

  /// The Primekit product ID for which the trial started.
  final String productId;

  /// UTC timestamp when the trial period ends and billing begins.
  final DateTime trialEnds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrialStarted &&
          productId == other.productId &&
          trialEnds == other.trialEnds;

  @override
  int get hashCode => Object.hash(runtimeType, productId, trialEnds);

  @override
  String toString() =>
      'TrialStarted(productId: $productId, trialEnds: $trialEnds)';
}

/// One or more purchases were restored via the platform restore flow.
final class PurchasesRestored extends BillingEvent {
  PurchasesRestored(List<String> restoredProductIds)
      : restoredProductIds = List.unmodifiable(restoredProductIds);

  /// The Primekit product IDs that were successfully restored.
  final List<String> restoredProductIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchasesRestored &&
          _listEquals(restoredProductIds, other.restoredProductIds);

  @override
  int get hashCode => Object.hashAll(restoredProductIds);

  @override
  String toString() =>
      'PurchasesRestored(restoredProductIds: $restoredProductIds)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

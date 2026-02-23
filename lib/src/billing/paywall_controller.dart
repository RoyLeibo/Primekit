import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

// ---------------------------------------------------------------------------
// PaywallEvent
// ---------------------------------------------------------------------------

/// Events emitted by [PaywallController] for analytics and side-effect handling.
sealed class PaywallEvent {
  const PaywallEvent();
}

/// The paywall became visible to the user.
final class PaywallShown extends PaywallEvent {
  const PaywallShown({required this.featureName, this.customMessage});

  /// The feature that triggered the paywall display.
  final String featureName;

  /// Optional custom message shown on the paywall.
  final String? customMessage;

  @override
  String toString() =>
      'PaywallShown(featureName: $featureName, customMessage: $customMessage)';
}

/// The paywall was dismissed without a purchase.
final class PaywallDismissed extends PaywallEvent {
  const PaywallDismissed({required this.featureName});

  /// The feature that had triggered the paywall.
  final String featureName;

  @override
  String toString() => 'PaywallDismissed(featureName: $featureName)';
}

/// An impression was recorded (paywall was visible to the user).
final class PaywallImpression extends PaywallEvent {
  const PaywallImpression({
    required this.featureName,
    required this.impressionCount,
  });

  /// The feature linked to this impression.
  final String featureName;

  /// The cumulative number of impressions including this one.
  final int impressionCount;

  @override
  String toString() =>
      'PaywallImpression(featureName: $featureName, '
      'impressionCount: $impressionCount)';
}

/// The user completed a purchase from the paywall.
final class PaywallConversion extends PaywallEvent {
  const PaywallConversion({required this.featureName, required this.productId});

  /// The feature that had triggered the paywall.
  final String featureName;

  /// The product the user purchased.
  final String productId;

  @override
  String toString() =>
      'PaywallConversion(featureName: $featureName, productId: $productId)';
}

// ---------------------------------------------------------------------------
// PaywallController
// ---------------------------------------------------------------------------

/// Manages paywall visibility, impression tracking, and conversion analytics.
///
/// Impression counts are persisted across app restarts using
/// [SharedPreferences]. Wire this to your paywall widget via [ChangeNotifier]:
///
/// ```dart
/// // Show the paywall when the user taps a locked feature:
/// controller.show(featureName: 'export_pdf');
///
/// // In your paywall widget:
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) {
///     if (!controller.isVisible) return const SizedBox.shrink();
///     return PaywallWidget(
///       feature: controller.triggerFeature!,
///       onDismiss: controller.dismiss,
///     );
///   },
/// );
///
/// // Track an impression when the paywall appears on screen:
/// controller.trackImpression();
///
/// // After a successful purchase:
/// controller.trackConversion(productId);
/// ```
class PaywallController extends ChangeNotifier {
  /// Creates a [PaywallController].
  ///
  /// Provide a [SharedPreferences] instance for impression persistence.
  /// In tests, you can supply a mock. In production, obtain this via
  /// `SharedPreferences.getInstance()`.
  PaywallController({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;

  static const String _tag = 'PaywallController';
  static const String _impressionKeyPrefix = 'pk_paywall_impressions_';

  bool _isVisible = false;
  String? _triggerFeature;
  String? _customMessage;

  final StreamController<PaywallEvent> _eventsController =
      StreamController<PaywallEvent>.broadcast();

  // ---------------------------------------------------------------------------
  // Public API — visibility
  // ---------------------------------------------------------------------------

  /// Whether the paywall is currently visible.
  bool get isVisible => _isVisible;

  /// The feature name that triggered the paywall, or `null` if not visible.
  String? get triggerFeature => _triggerFeature;

  /// The optional custom message supplied to [show], or `null`.
  String? get customMessage => _customMessage;

  /// Makes the paywall visible for [featureName].
  ///
  /// [customMessage] overrides the default paywall copy.
  /// Calling [show] while the paywall is already visible replaces the current
  /// trigger feature.
  void show({required String featureName, String? customMessage}) {
    _isVisible = true;
    _triggerFeature = featureName;
    _customMessage = customMessage;

    _eventsController.add(
      PaywallShown(featureName: featureName, customMessage: customMessage),
    );

    PrimekitLogger.debug('Paywall shown for feature "$featureName"', tag: _tag);

    notifyListeners();
  }

  /// Hides the paywall and emits a [PaywallDismissed] event.
  void dismiss() {
    if (!_isVisible) return;

    final feature = _triggerFeature ?? 'unknown';

    _isVisible = false;
    _triggerFeature = null;
    _customMessage = null;

    _eventsController.add(PaywallDismissed(featureName: feature));

    PrimekitLogger.debug('Paywall dismissed for feature "$feature"', tag: _tag);

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public API — impression tracking
  // ---------------------------------------------------------------------------

  /// The total number of times the paywall has been seen (persisted).
  ///
  /// Counts are scoped to [triggerFeature]. Returns 0 if no feature is active.
  int get impressionCount {
    final feature = _triggerFeature;
    if (feature == null) return 0;
    return _preferences.getInt('$_impressionKeyPrefix$feature') ?? 0;
  }

  /// Increments the impression counter for the current [triggerFeature] and
  /// persists the new count.
  ///
  /// Emits a [PaywallImpression] event. No-op if no paywall is currently shown.
  void trackImpression() {
    final feature = _triggerFeature;
    if (feature == null) {
      PrimekitLogger.warning(
        'trackImpression() called with no active paywall',
        tag: _tag,
      );
      return;
    }

    final key = '$_impressionKeyPrefix$feature';
    final newCount = (_preferences.getInt(key) ?? 0) + 1;
    _preferences.setInt(key, newCount);

    _eventsController.add(
      PaywallImpression(featureName: feature, impressionCount: newCount),
    );

    PrimekitLogger.verbose(
      'Paywall impression #$newCount for "$feature"',
      tag: _tag,
    );
  }

  /// Returns the stored impression count for a specific [featureName] without
  /// requiring the paywall to be currently visible.
  int impressionCountForFeature(String featureName) =>
      _preferences.getInt('$_impressionKeyPrefix$featureName') ?? 0;

  // ---------------------------------------------------------------------------
  // Public API — conversion tracking
  // ---------------------------------------------------------------------------

  /// Records a conversion (successful purchase) from the paywall.
  ///
  /// Emits a [PaywallConversion] event, then dismisses the paywall.
  /// [productId] is the Primekit product ID that was purchased.
  void trackConversion(String productId) {
    final feature = _triggerFeature ?? 'unknown';

    _eventsController.add(
      PaywallConversion(featureName: feature, productId: productId),
    );

    PrimekitLogger.info(
      'Paywall conversion: "$feature" → $productId',
      tag: _tag,
    );

    dismiss();
  }

  // ---------------------------------------------------------------------------
  // Public API — event stream
  // ---------------------------------------------------------------------------

  /// Broadcast stream of all [PaywallEvent]s emitted by this controller.
  ///
  /// Use this stream to drive analytics tracking or side-effects.
  Stream<PaywallEvent> get events => _eventsController.stream;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _eventsController.close();
    super.dispose();
  }
}

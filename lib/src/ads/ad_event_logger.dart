import '../analytics/analytics_event.dart';
import '../analytics/event_tracker.dart';
import '../core/logger.dart';

// ---------------------------------------------------------------------------
// AdEvent sealed union
// ---------------------------------------------------------------------------

/// A discriminated union of ad lifecycle events.
///
/// Use [AdEventLogger] to record these events and fan them out to analytics:
///
/// ```dart
/// AdEventLogger.instance.log(
///   AdEvent.shown('interstitial', screenName: 'HomeScreen'),
/// );
/// ```
sealed class AdEvent {
  const AdEvent();

  /// Emitted when an ad finishes loading.
  factory AdEvent.loaded(String adType) = AdLoaded;

  /// Emitted when an ad is displayed to the user.
  factory AdEvent.shown(String adType, {String? screenName}) = AdShown;

  /// Emitted when the user taps an ad.
  factory AdEvent.clicked(String adType) = AdClicked;

  /// Emitted when the user closes an ad.
  factory AdEvent.closed(String adType) = AdClosed;

  /// Emitted when an ad fails to load or display.
  factory AdEvent.failed(String adType, {required String error}) = AdFailed;

  /// Emitted when a rewarded ad grants the user a reward.
  factory AdEvent.rewarded({required String rewardType, required int amount}) =
      AdRewarded;

  /// The ad type tag (e.g. `'banner'`, `'interstitial'`, `'rewarded'`).
  String get adType;
}

/// Ad finished loading.
final class AdLoaded extends AdEvent {
  const AdLoaded(this.adType);

  @override
  final String adType;

  @override
  String toString() => 'AdEvent.loaded($adType)';
}

/// Ad was shown on screen.
final class AdShown extends AdEvent {
  const AdShown(this.adType, {this.screenName});

  @override
  final String adType;

  /// The screen on which the ad was displayed (optional).
  final String? screenName;

  @override
  String toString() => 'AdEvent.shown($adType, screenName: $screenName)';
}

/// User tapped the ad.
final class AdClicked extends AdEvent {
  const AdClicked(this.adType);

  @override
  final String adType;

  @override
  String toString() => 'AdEvent.clicked($adType)';
}

/// User closed the ad.
final class AdClosed extends AdEvent {
  const AdClosed(this.adType);

  @override
  final String adType;

  @override
  String toString() => 'AdEvent.closed($adType)';
}

/// Ad failed to load or display.
final class AdFailed extends AdEvent {
  const AdFailed(this.adType, {required this.error});

  @override
  final String adType;

  /// The error message from the SDK.
  final String error;

  @override
  String toString() => 'AdEvent.failed($adType, error: $error)';
}

/// Rewarded ad granted a reward.
final class AdRewarded extends AdEvent {
  const AdRewarded({required this.rewardType, required this.amount});

  @override
  String get adType => 'rewarded';

  /// The reward type string returned by the SDK (e.g. `'coins'`).
  final String rewardType;

  /// The amount of the reward.
  final int amount;

  @override
  String toString() =>
      'AdEvent.rewarded(rewardType: $rewardType, amount: $amount)';
}

// ---------------------------------------------------------------------------
// AdEventLogger
// ---------------------------------------------------------------------------

/// Records [AdEvent]s and forwards them to [EventTracker] for analytics.
///
/// Also maintains in-memory impression and click counters for quick access.
///
/// ```dart
/// AdEventLogger.instance.log(AdEvent.shown('banner'));
/// print(AdEventLogger.instance.impressionsByType); // {banner: 1}
/// print(AdEventLogger.instance.clickThroughRate);  // 0.0
/// ```
class AdEventLogger {
  AdEventLogger._();

  static final AdEventLogger _instance = AdEventLogger._();

  /// The shared singleton instance.
  static AdEventLogger get instance => _instance;

  static const String _tag = 'AdEventLogger';

  // Mutable counters — only mutated through [log] to keep mutation
  // in one place and ensure consistency.
  final Map<String, int> _impressions = {};
  final Map<String, int> _clicks = {};

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  /// Records [event] and forwards it to [EventTracker] (non-blocking).
  void log(AdEvent event) {
    _updateCounters(event);
    _forwardToAnalytics(event);
    PrimekitLogger.debug(event.toString(), tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Counters
  // ---------------------------------------------------------------------------

  /// Total impressions (shown events) per ad type.
  Map<String, int> get impressionsByType => Map.unmodifiable(_impressions);

  /// Total click events per ad type.
  Map<String, int> get clicksByType => Map.unmodifiable(_clicks);

  /// Overall click-through rate across all ad types.
  ///
  /// Returns `0.0` when no impressions have been recorded.
  double get clickThroughRate {
    final totalImpressions = _impressions.values.fold(0, (sum, v) => sum + v);
    if (totalImpressions == 0) return 0.0;
    final totalClicks = _clicks.values.fold(0, (sum, v) => sum + v);
    return totalClicks / totalImpressions;
  }

  /// Resets all in-memory counters.
  void resetCounters() {
    _impressions.clear();
    _clicks.clear();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _updateCounters(AdEvent event) {
    switch (event) {
      case AdShown(:final adType):
        _impressions[adType] = (_impressions[adType] ?? 0) + 1;
      case AdClicked(:final adType):
        _clicks[adType] = (_clicks[adType] ?? 0) + 1;
      default:
        break;
    }
  }

  void _forwardToAnalytics(AdEvent event) {
    final analyticsEvent = switch (event) {
      AdLoaded(:final adType) => AnalyticsEvent(
        name: 'ad_loaded',
        parameters: {'ad_type': adType},
      ),
      AdShown(:final adType, :final screenName) => AnalyticsEvent(
        name: 'ad_impression',
        parameters: {'ad_type': adType, 'screen_name': ?screenName},
      ),
      AdClicked(:final adType) => AnalyticsEvent(
        name: 'ad_click',
        parameters: {'ad_type': adType},
      ),
      AdClosed(:final adType) => AnalyticsEvent(
        name: 'ad_closed',
        parameters: {'ad_type': adType},
      ),
      AdFailed(:final adType, :final error) => AnalyticsEvent(
        name: 'ad_failed',
        parameters: {'ad_type': adType, 'error': error},
      ),
      AdRewarded(:final rewardType, :final amount) => AnalyticsEvent(
        name: 'ad_reward_earned',
        parameters: {'reward_type': rewardType, 'amount': amount},
      ),
    };

    // Fire-and-forget; EventTracker handles its own error isolation.
    EventTracker.instance.logEvent(analyticsEvent);
  }
}

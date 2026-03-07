import 'analytics_event.dart';

/// Contract that every analytics back-end must implement.
///
/// Implement this interface to integrate a third-party analytics service
/// (Firebase, Amplitude, Mixpanel, etc.) and register it with `EventTracker`:
///
/// ```dart
/// class FirebaseAnalyticsProvider implements AnalyticsProvider {
///   @override
///   String get name => 'firebase_analytics';
///
///   @override
///   Future<void> initialize() async {
///     // One-time SDK setup
///   }
///
///   @override
///   Future<void> logEvent(AnalyticsEvent event) async {
///     await FirebaseAnalytics.instance.logEvent(
///       name: event.name,
///       parameters: event.parameters.cast<String, Object>(),
///     );
///   }
///
///   // …implement remaining methods
/// }
/// ```
abstract interface class AnalyticsProvider {
  /// A stable, machine-readable identifier for this provider.
  ///
  /// Used in log messages and for de-duplication when multiple providers
  /// of the same type are registered. Must be non-empty.
  String get name;

  /// Performs one-time initialisation of the analytics SDK.
  ///
  /// Called by `EventTracker.configure` before any events are dispatched.
  /// Implementations should be idempotent — calling this multiple times
  /// must not cause errors.
  Future<void> initialize();

  /// Records [event] in the analytics back-end.
  ///
  /// Implementations should be resilient; they must not throw unless the
  /// failure is unrecoverable. Prefer swallowing non-fatal errors and logging
  /// them internally.
  Future<void> logEvent(AnalyticsEvent event);

  /// Attaches a persistent user property to all subsequent events.
  ///
  /// [key] is the property name; [value] is its string representation.
  Future<void> setUserProperty(String key, String value);

  /// Associates all subsequent events with the given [userId].
  ///
  /// Pass `null` to clear the current user identity (e.g. on sign-out).
  Future<void> setUserId(String? userId);

  /// Clears all user identity data from the analytics back-end.
  ///
  /// Typically called on sign-out alongside [setUserId(null)].
  Future<void> reset();
}

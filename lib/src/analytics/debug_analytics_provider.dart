import 'package:flutter/foundation.dart';

import 'analytics_event.dart';
import 'analytics_provider.dart';

/// A development-only analytics provider that prints events to the debug
/// console via [debugPrint].
///
/// Use this in development / staging builds to verify instrumentation without
/// sending data to a real analytics back-end. Replace with a production
/// provider (Firebase Analytics, Amplitude, etc.) before shipping.
///
/// ```dart
/// EventTracker.instance.configure([
///   if (kDebugMode) DebugAnalyticsProvider() else FirebaseAnalyticsProvider(),
/// ]);
/// ```
final class DebugAnalyticsProvider implements AnalyticsProvider {
  @override
  String get name => 'debug';

  @override
  Future<void> initialize() async {
    debugPrint('[Analytics:debug] initialized');
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    final params = event.parameters.isEmpty
        ? ''
        : ' ${event.parameters}';
    debugPrint('[Analytics] ${event.name}$params');
  }

  @override
  Future<void> setUserProperty(String key, String value) async {
    debugPrint('[Analytics] setUserProperty $key=$value');
  }

  @override
  Future<void> setUserId(String? userId) async {
    debugPrint('[Analytics] setUserId $userId');
  }

  @override
  Future<void> reset() async {
    debugPrint('[Analytics] reset');
  }
}

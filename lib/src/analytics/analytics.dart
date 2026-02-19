/// Analytics — event tracking, funnel analysis, session management, and
/// persistent event counting for Flutter apps.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Configure providers once at app startup:
/// await EventTracker.instance.configure([
///   FirebaseAnalyticsProvider(),
/// ]);
///
/// // 2. Track events anywhere:
/// await EventTracker.instance.logEvent(
///   AnalyticsEvent.screenView(screenName: 'HomeScreen'),
/// );
///
/// // 3. Track funnels:
/// FunnelTracker.instance.registerFunnel(const FunnelDefinition(
///   name: 'onboarding',
///   steps: ['welcome', 'profile', 'done'],
/// ));
/// FunnelTracker.instance.startFunnel('onboarding', userId: user.id);
///
/// // 4. Track sessions:
/// await SessionTracker.instance.startSession();
///
/// // 5. Count events:
/// await EventCounter.instance.increment('export_tapped');
/// ```
library primekit_analytics;

export 'analytics_event.dart';
export 'analytics_provider.dart';
export 'event_counter.dart';
export 'event_tracker.dart';
export 'funnel_tracker.dart';
export 'session_tracker.dart';

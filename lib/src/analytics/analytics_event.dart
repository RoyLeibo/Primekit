/// Represents a single analytics event with a name, optional parameters,
/// and a timestamp.
///
/// Use the named factory constructors for well-known event types, or supply
/// a custom [name] directly:
///
/// ```dart
/// // Predefined factory
/// final event = AnalyticsEvent.screenView(screenName: 'HomeScreen');
///
/// // Custom event
/// final event = AnalyticsEvent(
///   name: 'level_complete',
///   parameters: {'level': 3, 'score': 9500},
/// );
/// ```
final class AnalyticsEvent {
  /// Creates a custom analytics event.
  ///
  /// [name] must be a non-empty string. [parameters] defaults to an empty map.
  /// [timestamp] defaults to the current UTC time when omitted.
  AnalyticsEvent({
    required this.name,
    this.parameters = const {},
    DateTime? timestamp,
  })  : assert(name.isNotEmpty, 'AnalyticsEvent.name must not be empty'),
        timestamp = timestamp ?? DateTime.now().toUtc();

  /// Records a screen-view event.
  ///
  /// [screenName] is required; [screenClass] is the optional class/widget name.
  factory AnalyticsEvent.screenView({
    required String screenName,
    String? screenClass,
  }) =>
      AnalyticsEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
        },
      );

  /// Records a button-tap interaction.
  ///
  /// [buttonName] identifies the tapped button; [screen] is the host screen.
  factory AnalyticsEvent.buttonTap({
    required String buttonName,
    String? screen,
  }) =>
      AnalyticsEvent(
        name: 'button_tap',
        parameters: {
          'button_name': buttonName,
          if (screen != null) 'screen': screen,
        },
      );

  /// Records a purchase event.
  ///
  /// [amount] is the transaction value, [currency] is the ISO 4217 code
  /// (e.g. `'USD'`), and [productId] identifies the purchased product.
  factory AnalyticsEvent.purchase({
    required double amount,
    required String currency,
    required String productId,
  }) =>
      AnalyticsEvent(
        name: 'purchase',
        parameters: {
          'amount': amount,
          'currency': currency,
          'product_id': productId,
        },
      );

  /// Records a sign-in event.
  ///
  /// [method] is the authentication method used (e.g. `'google'`, `'email'`).
  factory AnalyticsEvent.signIn({required String method}) => AnalyticsEvent(
        name: 'sign_in',
        parameters: {'method': method},
      );

  /// Records a sign-up / account-creation event.
  ///
  /// [method] is the registration method used (e.g. `'google'`, `'email'`).
  factory AnalyticsEvent.signUp({required String method}) => AnalyticsEvent(
        name: 'sign_up',
        parameters: {'method': method},
      );

  /// Records a search query event.
  factory AnalyticsEvent.search({required String query}) => AnalyticsEvent(
        name: 'search',
        parameters: {'search_term': query},
      );

  /// Records an application error event.
  ///
  /// [errorName] is a machine-readable error identifier;
  /// [errorMessage] is an optional human-readable description.
  factory AnalyticsEvent.error({
    required String errorName,
    String? errorMessage,
  }) =>
      AnalyticsEvent(
        name: 'app_error',
        parameters: {
          'error_name': errorName,
          if (errorMessage != null) 'error_message': errorMessage,
        },
      );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// The event name as it will appear in your analytics dashboard.
  final String name;

  /// Arbitrary key–value parameters attached to this event.
  ///
  /// Values must be JSON-serialisable primitives (String, num, bool, or null).
  final Map<String, Object?> parameters;

  /// The UTC time at which this event was recorded.
  final DateTime timestamp;

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Returns a copy of this event with the given fields replaced.
  AnalyticsEvent copyWith({
    String? name,
    Map<String, Object?>? parameters,
    DateTime? timestamp,
  }) =>
      AnalyticsEvent(
        name: name ?? this.name,
        parameters: parameters ??
            Map<String, Object?>.unmodifiable(this.parameters),
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() =>
      'AnalyticsEvent(name: $name, parameters: $parameters, '
      'timestamp: ${timestamp.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEvent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(name, timestamp);
}

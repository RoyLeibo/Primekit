import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

// ---------------------------------------------------------------------------
// TrialEvent
// ---------------------------------------------------------------------------

/// Events emitted by [TrialManager] when a trial's lifecycle changes.
sealed class TrialEvent {
  const TrialEvent();
}

/// A trial has just been started for [productId].
final class TrialEventStarted extends TrialEvent {
  const TrialEventStarted({required this.productId, required this.trialEnds});

  /// The Primekit product ID for which the trial started.
  final String productId;

  /// UTC timestamp when the trial period ends.
  final DateTime trialEnds;

  @override
  String toString() =>
      'TrialEventStarted(productId: $productId, trialEnds: $trialEnds)';
}

/// A trial is ending soon; [hoursLeft] indicates the time remaining.
final class TrialEventEndingSoon extends TrialEvent {
  const TrialEventEndingSoon({
    required this.productId,
    required this.hoursLeft,
  });

  /// The Primekit product ID whose trial is ending.
  final String productId;

  /// Approximate hours remaining in the trial.
  final int hoursLeft;

  @override
  String toString() =>
      'TrialEventEndingSoon(productId: $productId, hoursLeft: $hoursLeft)';
}

/// A trial has ended for [productId].
final class TrialEventEnded extends TrialEvent {
  const TrialEventEnded({required this.productId});

  /// The Primekit product ID whose trial ended.
  final String productId;

  @override
  String toString() => 'TrialEventEnded(productId: $productId)';
}

// ---------------------------------------------------------------------------
// TrialManager
// ---------------------------------------------------------------------------

/// Manages free-trial periods for products locally on-device.
///
/// Trial state is persisted via [SharedPreferences] so it survives app
/// restarts. A background [Timer] fires every hour to detect trials that
/// are ending soon or have expired.
///
/// ```dart
/// final manager = TrialManager(preferences: await SharedPreferences.getInstance());
///
/// await manager.startTrial('primekit_pro_monthly', duration: const Duration(days: 7));
///
/// if (await manager.isInTrial('primekit_pro_monthly')) {
///   final remaining = await manager.getRemainingTime('primekit_pro_monthly');
///   print('Trial ends in ${remaining?.inDays} days');
/// }
///
/// manager.events.listen((event) {
///   if (event is TrialEventEndingSoon) {
///     showTrialEndingBanner(event.hoursLeft);
///   }
/// });
/// ```
class TrialManager {
  /// Creates a [TrialManager] backed by [preferences].
  TrialManager({required SharedPreferences preferences})
    : _preferences = preferences {
    _startPeriodicCheck();
  }

  final SharedPreferences _preferences;

  static const String _tag = 'TrialManager';
  static const String _endDateKeyPrefix = 'pk_trial_end_';
  static const String _startedKeyPrefix = 'pk_trial_started_';

  /// How far in advance to emit [TrialEventEndingSoon] (24 hours).
  static const Duration _endingSoonThreshold = Duration(hours: 24);

  final StreamController<TrialEvent> _eventsController =
      StreamController<TrialEvent>.broadcast();

  Timer? _checkTimer;

  // Tracks which products have already had their "ending soon" event fired
  // within the current app session to avoid duplicate notifications.
  final Set<String> _endingSoonFired = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Starts a trial for [productId] lasting [duration].
  ///
  /// If a trial for [productId] is already active, this replaces it.
  Future<void> startTrial(
    String productId, {
    required Duration duration,
  }) async {
    assert(duration > Duration.zero, 'Trial duration must be positive');

    final endDate = DateTime.now().toUtc().add(duration);

    await _preferences.setString(
      '$_endDateKeyPrefix$productId',
      endDate.toIso8601String(),
    );
    await _preferences.setString(
      '$_startedKeyPrefix$productId',
      DateTime.now().toUtc().toIso8601String(),
    );

    _endingSoonFired.remove(productId);

    _eventsController.add(
      TrialEventStarted(productId: productId, trialEnds: endDate),
    );

    PrimekitLogger.info(
      'Trial started for "$productId" — ends at $endDate',
      tag: _tag,
    );
  }

  /// Returns `true` if [productId] has an active, non-expired trial.
  Future<bool> isInTrial(String productId) async {
    final endDate = _getEndDate(productId);
    if (endDate == null) return false;
    return endDate.isAfter(DateTime.now().toUtc());
  }

  /// Returns the remaining trial duration for [productId], or `null` if no
  /// active trial exists.
  Future<Duration?> getRemainingTime(String productId) async {
    final endDate = _getEndDate(productId);
    if (endDate == null) return null;

    final remaining = endDate.difference(DateTime.now().toUtc());
    return remaining.isNegative ? null : remaining;
  }

  /// Returns the UTC timestamp when the trial for [productId] ends, or `null`
  /// if no trial has been started.
  Future<DateTime?> getTrialEndDate(String productId) async =>
      _getEndDate(productId);

  /// Ends the trial for [productId] immediately by clearing stored dates and
  /// emitting [TrialEventEnded].
  Future<void> endTrial(String productId) async {
    final hadTrial = _preferences.containsKey('$_endDateKeyPrefix$productId');

    await _preferences.remove('$_endDateKeyPrefix$productId');
    await _preferences.remove('$_startedKeyPrefix$productId');
    _endingSoonFired.remove(productId);

    if (hadTrial) {
      _eventsController.add(TrialEventEnded(productId: productId));
      PrimekitLogger.info('Trial ended for "$productId"', tag: _tag);
    }
  }

  /// Broadcast stream of [TrialEvent]s for all managed trials.
  Stream<TrialEvent> get events => _eventsController.stream;

  /// Returns a [Stream] scoped to events for a single [productId].
  Stream<TrialEvent> eventsFor(String productId) =>
      _eventsController.stream.where((event) {
        final id = switch (event) {
          TrialEventStarted(:final productId) => productId,
          TrialEventEndingSoon(:final productId) => productId,
          TrialEventEnded(:final productId) => productId,
        };
        return id == productId;
      });

  // ---------------------------------------------------------------------------
  // Periodic check
  // ---------------------------------------------------------------------------

  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _runExpiryCheck(),
    );
  }

  void _runExpiryCheck() {
    final now = DateTime.now().toUtc();
    final keys = _preferences
        .getKeys()
        .where((k) => k.startsWith(_endDateKeyPrefix))
        .toList(growable: false);

    for (final key in keys) {
      final productId = key.substring(_endDateKeyPrefix.length);
      final endDateStr = _preferences.getString(key);
      if (endDateStr == null) continue;

      final DateTime endDate;
      try {
        endDate = DateTime.parse(endDateStr).toUtc();
      } on FormatException {
        continue;
      }

      if (endDate.isBefore(now)) {
        // Trial has expired.
        _preferences
          ..remove(key)
          ..remove('$_startedKeyPrefix$productId');
        _endingSoonFired.remove(productId);
        _eventsController.add(TrialEventEnded(productId: productId));
        PrimekitLogger.info(
          'Trial expired for "$productId" (detected in periodic check)',
          tag: _tag,
        );
        continue;
      }

      final remaining = endDate.difference(now);
      if (remaining <= _endingSoonThreshold &&
          !_endingSoonFired.contains(productId)) {
        _endingSoonFired.add(productId);
        _eventsController.add(
          TrialEventEndingSoon(
            productId: productId,
            hoursLeft: remaining.inHours,
          ),
        );
        PrimekitLogger.info(
          'Trial ending soon for "$productId" (${remaining.inHours}h left)',
          tag: _tag,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  DateTime? _getEndDate(String productId) {
    final raw = _preferences.getString('$_endDateKeyPrefix$productId');
    if (raw == null) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancels the periodic expiry check and closes the event stream.
  ///
  /// Call this when the [TrialManager] is no longer needed.
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _eventsController.close();
  }
}

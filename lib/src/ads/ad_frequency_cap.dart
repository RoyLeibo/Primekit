import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// Enforces per-session and per-day frequency caps on ad impressions.
///
/// Prevents over-saturating users with ads in a single session or day.
///
/// ```dart
/// final cap = AdFrequencyCap(maxPerSession: 5, maxPerDay: 20);
/// await cap.load();
///
/// if (cap.canShow) {
///   await AdManager.instance.showInterstitial();
///   cap.recordImpression();
/// }
/// ```
class AdFrequencyCap {
  /// Creates a frequency cap.
  ///
  /// [maxPerSession] is the maximum number of ads shown per app session.
  /// [maxPerDay] is the maximum number of ads shown in a calendar day.
  AdFrequencyCap({
    int maxPerSession = 5,
    int maxPerDay = 20,
  })  : _maxPerSession = maxPerSession.clamp(1, 1000),
        _maxPerDay = maxPerDay.clamp(1, 10000);

  final int _maxPerSession;
  final int _maxPerDay;

  int _sessionImpressions = 0;
  int _todayImpressions = 0;
  DateTime _dayStartedAt = _startOfToday();

  static const String _prefsKeyToday = 'primekit_ad_freq_today';
  static const String _prefsKeyDate = 'primekit_ad_freq_date';
  static const String _tag = 'AdFrequencyCap';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether another ad can be shown given current caps.
  bool get canShow {
    _rolloverDayIfNeeded();
    return _sessionImpressions < _maxPerSession &&
        _todayImpressions < _maxPerDay;
  }

  /// Records one ad impression, incrementing both session and day counters.
  ///
  /// Call this immediately after successfully showing an ad.
  Future<void> recordImpression() async {
    _rolloverDayIfNeeded();
    _sessionImpressions += 1;
    _todayImpressions += 1;

    PrimekitLogger.debug(
      'AdFrequencyCap: session=$_sessionImpressions/$_maxPerSession '
      'day=$_todayImpressions/$_maxPerDay',
      tag: _tag,
    );

    await _persistDay();
  }

  /// Number of ads shown in the current session.
  int get sessionImpressions => _sessionImpressions;

  /// Number of ads shown today (calendar day).
  int get todayImpressions => _todayImpressions;

  /// Resets only the session counter (e.g. when the app moves to background
  /// and returns after a significant gap).
  void resetSession() {
    _sessionImpressions = 0;
    PrimekitLogger.debug(
      'AdFrequencyCap: session counter reset.',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Loads today's impression count from [SharedPreferences].
  ///
  /// Call this during [AdManager.initialize].
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_prefsKeyDate);
      final storedDate =
          dateStr != null ? DateTime.parse(dateStr) : _startOfToday();

      if (_isSameDay(storedDate, _startOfToday())) {
        _todayImpressions = prefs.getInt(_prefsKeyToday) ?? 0;
      } else {
        // New day — clear the stale count.
        _todayImpressions = 0;
        await _persistDay();
      }

      PrimekitLogger.debug(
        'AdFrequencyCap: loaded todayImpressions=$_todayImpressions',
        tag: _tag,
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'AdFrequencyCap: failed to load persisted state.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _persistDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyToday, _todayImpressions);
      await prefs.setString(
        _prefsKeyDate,
        _startOfToday().toIso8601String(),
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'AdFrequencyCap: failed to persist impression count.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _rolloverDayIfNeeded() {
    final today = _startOfToday();
    if (!_isSameDay(_dayStartedAt, today)) {
      _dayStartedAt = today;
      _todayImpressions = 0;
      PrimekitLogger.debug(
        'AdFrequencyCap: rolled over to new day.',
        tag: _tag,
      );
    }
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets all counters and persisted state.
  ///
  /// For use in tests only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    _sessionImpressions = 0;
    _todayImpressions = 0;
    _dayStartedAt = _startOfToday();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyToday);
    await prefs.remove(_prefsKeyDate);
  }
}

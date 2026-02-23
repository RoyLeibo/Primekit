import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';

/// Enforces a minimum delay between consecutive interstitial ad displays.
///
/// Persists the last-shown timestamp across app restarts using
/// [SharedPreferences].
///
/// ```dart
/// final cooldown = AdCooldownTimer(cooldown: Duration(minutes: 3));
///
/// if (cooldown.canShowAd) {
///   await AdManager.instance.showInterstitial();
///   cooldown.recordAdShown();
/// }
/// ```
class AdCooldownTimer {
  /// Creates a cooldown timer with the specified [cooldown] duration.
  ///
  /// The default cooldown is 3 minutes — a reasonable value that balances
  /// revenue and user experience for most apps.
  AdCooldownTimer({Duration cooldown = const Duration(minutes: 3)})
    : _cooldown = cooldown;

  final Duration _cooldown;
  DateTime? _lastShownAt;
  bool _loaded = false;

  static const String _prefsKey = 'primekit_ad_last_shown';
  static const String _tag = 'AdCooldownTimer';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` if enough time has elapsed since the last ad was shown.
  ///
  /// Always returns `true` if no ad has been shown yet in this install.
  bool get canShowAd {
    if (!_loaded) {
      // Synchronous check while loading hasn't completed — be permissive.
      return true;
    }
    if (_lastShownAt == null) return true;
    return DateTime.now().toUtc().difference(_lastShownAt!) >= _cooldown;
  }

  /// The time remaining before another ad can be shown.
  ///
  /// Returns `null` if [canShowAd] is `true` (no wait needed).
  Duration? get timeUntilNextAd {
    if (canShowAd) return null;
    final elapsed = DateTime.now().toUtc().difference(_lastShownAt!);
    final remaining = _cooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Records that an ad was shown right now and persists the timestamp.
  ///
  /// Call this immediately after an ad is successfully displayed.
  Future<void> recordAdShown() async {
    final now = DateTime.now().toUtc();
    _lastShownAt = now;
    _loaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, now.toIso8601String());
      PrimekitLogger.debug(
        'AdCooldownTimer: last-shown recorded at ${now.toIso8601String()}',
        tag: _tag,
      );
    } catch (e, stack) {
      PrimekitLogger.error(
        'AdCooldownTimer: failed to persist last-shown time.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Loads the persisted last-shown time from [SharedPreferences].
  ///
  /// Called automatically by [AdManager.initialize]. You can call this
  /// manually if you use [AdCooldownTimer] independently.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        _lastShownAt = DateTime.parse(raw);
        PrimekitLogger.debug(
          'AdCooldownTimer: loaded lastShownAt=$raw',
          tag: _tag,
        );
      }
    } catch (e, stack) {
      PrimekitLogger.error(
        'AdCooldownTimer: failed to load persisted state.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    } finally {
      _loaded = true;
    }
  }

  /// Clears the persisted state (for testing).
  @visibleForTesting
  Future<void> resetForTesting() async {
    _lastShownAt = null;
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

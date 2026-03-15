import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core.dart';

/// Immutable snapshot of a user's AI quota state at a point in time.
class AiQuotaSnapshot {
  const AiQuotaSnapshot({
    required this.used,
    required this.limit,
    required this.date,
  });

  /// Number of requests used today.
  final int used;

  /// Maximum requests allowed per day.
  final int limit;

  /// The date (YYYY-MM-DD) this snapshot is for.
  final String date;

  /// Remaining requests for today.
  int get remaining => (limit - used).clamp(0, limit);

  /// Usage as a percentage (0–100).
  int get percentageUsed => (used / limit * 100).round();

  /// Whether the quota has been exhausted.
  bool get isExhausted => used >= limit;
}

/// Configuration for [AiQuotaService].
///
/// Pass this at construction time to customise limits without hardcoded values.
class AiQuotaConfig {
  const AiQuotaConfig({
    this.dailyLimit = 50,
    this.warningThreshold = 40,
    this.collection = 'ai_quota',
  });

  /// Maximum AI requests allowed per day.
  final int dailyLimit;

  /// Usage count at which a warning should be shown (e.g. 80% of limit).
  final int warningThreshold;

  /// Firestore collection where quota documents are stored.
  final String collection;
}

/// Generic, Firestore-backed AI usage quota service.
///
/// Each user gets a document at `{collection}/{userId}` containing:
/// ```json
/// { "count": 3, "date": "2026-03-15" }
/// ```
///
/// The counter resets automatically when a new day is detected.
///
/// Usage:
/// ```dart
/// final quota = AiQuotaService(
///   firestore: FirebaseFirestore.instance,
///   config: const AiQuotaConfig(dailyLimit: 100),
/// );
///
/// if (await quota.canMakeRequest(userId: uid)) {
///   await quota.recordUsage(userId: uid);
///   // ... call AI provider
/// }
/// ```
class AiQuotaService {
  AiQuotaService({
    required FirebaseFirestore firestore,
    AiQuotaConfig config = const AiQuotaConfig(),
  })  : _firestore = firestore,
        _config = config;

  final FirebaseFirestore _firestore;
  final AiQuotaConfig _config;

  static const String _tag = 'AiQuota';

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /// Returns `true` when the user still has quota remaining today.
  Future<bool> canMakeRequest({required String userId}) async {
    try {
      final snapshot = await getQuotaSnapshot(userId: userId);
      return !snapshot.isExhausted;
    } on PrimekitException {
      rethrow;
    } catch (error, stackTrace) {
      PrimekitLogger.error(
        'Failed to check quota for user $userId',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      throw AiQuotaException(
        message: 'Failed to check AI quota',
        cause: error,
      );
    }
  }

  /// Increments the usage counter for today.
  ///
  /// Throws [AiQuotaExceededException] if the daily limit has already been
  /// reached. Callers should check [canMakeRequest] first to avoid this.
  Future<AiQuotaSnapshot> recordUsage({required String userId}) async {
    try {
      final snapshot = await _resetIfNewDay(userId: userId);

      if (snapshot.isExhausted) {
        throw AiQuotaExceededException(dailyLimit: _config.dailyLimit);
      }

      final newCount = snapshot.used + 1;
      await _docRef(userId).set({
        'count': newCount,
        'date': snapshot.date,
      });

      PrimekitLogger.debug(
        'Recorded usage for $userId: $newCount/${_config.dailyLimit}',
        tag: _tag,
      );

      return AiQuotaSnapshot(
        used: newCount,
        limit: _config.dailyLimit,
        date: snapshot.date,
      );
    } on PrimekitException {
      rethrow;
    } catch (error, stackTrace) {
      PrimekitLogger.error(
        'Failed to record usage for user $userId',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      throw AiQuotaException(
        message: 'Failed to record AI usage',
        cause: error,
      );
    }
  }

  /// Returns the number of remaining requests for today.
  Future<int> remainingQuota({required String userId}) async {
    final snapshot = await getQuotaSnapshot(userId: userId);
    return snapshot.remaining;
  }

  /// Returns `true` when the user's usage has reached the warning threshold.
  Future<bool> isApproachingLimit({required String userId}) async {
    final snapshot = await getQuotaSnapshot(userId: userId);
    return snapshot.used >= _config.warningThreshold;
  }

  /// Returns a full [AiQuotaSnapshot] for the user, resetting if a new day.
  Future<AiQuotaSnapshot> getQuotaSnapshot({required String userId}) async {
    try {
      return await _resetIfNewDay(userId: userId);
    } on PrimekitException {
      rethrow;
    } catch (error, stackTrace) {
      PrimekitLogger.error(
        'Failed to fetch quota snapshot for user $userId',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      throw AiQuotaException(
        message: 'Failed to fetch AI quota',
        cause: error,
      );
    }
  }

  /// Resets the quota counter to zero (for admin / testing purposes).
  Future<AiQuotaSnapshot> resetQuota({required String userId}) async {
    try {
      final today = _todayDateString();
      await _docRef(userId).set({'count': 0, 'date': today});

      PrimekitLogger.info('Quota reset for user $userId', tag: _tag);

      return AiQuotaSnapshot(
        used: 0,
        limit: _config.dailyLimit,
        date: today,
      );
    } on PrimekitException {
      rethrow;
    } catch (error, stackTrace) {
      PrimekitLogger.error(
        'Failed to reset quota for user $userId',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      throw AiQuotaException(
        message: 'Failed to reset AI quota',
        cause: error,
      );
    }
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _docRef(String userId) {
    return _firestore.collection(_config.collection).doc(userId);
  }

  /// Reads the current document and resets the counter when a new day is
  /// detected. Returns the (possibly reset) snapshot.
  Future<AiQuotaSnapshot> _resetIfNewDay({required String userId}) async {
    final today = _todayDateString();
    final doc = await _docRef(userId).get();

    final data = doc.data();
    final storedDate = data?['date'] as String?;
    final storedCount = data?['count'] as int? ?? 0;

    if (storedDate == today) {
      return AiQuotaSnapshot(
        used: storedCount,
        limit: _config.dailyLimit,
        date: today,
      );
    }

    // New day — reset counter in Firestore.
    await _docRef(userId).set({'count': 0, 'date': today});

    PrimekitLogger.debug(
      'New day detected for $userId — quota reset',
      tag: _tag,
    );

    return AiQuotaSnapshot(
      used: 0,
      limit: _config.dailyLimit,
      date: today,
    );
  }

  String _todayDateString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

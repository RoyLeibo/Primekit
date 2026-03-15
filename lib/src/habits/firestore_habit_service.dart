import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core.dart';
import 'habit.dart';
import 'habit_service.dart';
import 'streak_calculator.dart';

/// Firestore-backed implementation of [PkHabitService].
///
/// All queries are scoped to the current user via [setCurrentUserId].
/// Follows PrimeKit conventions: immutable operations, structured logging,
/// typed exceptions.
class FirestoreHabitService implements PkHabitService {
  FirestoreHabitService({
    FirebaseFirestore? firestore,
    String collectionPath = 'habits',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  final FirebaseFirestore _firestore;
  final String _collectionPath;
  String? _currentUserId;

  CollectionReference get _collection =>
      _firestore.collection(_collectionPath);

  @override
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  @override
  Stream<List<PkHabit>> getHabits({bool includeArchived = false}) {
    if (_currentUserId == null) return Stream.value([]);

    Query query = _collection.where('userId', isEqualTo: _currentUserId);
    if (!includeArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      final habits = snapshot.docs
          .map((doc) => _fromFirestore(doc))
          .toList();
      habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return habits;
    });
  }

  @override
  Future<String> createHabit(PkHabit habit) async {
    _requireAuth();
    try {
      final withUser = habit.copyWith(userId: _currentUserId);
      final docRef = await _collection.add(_toFirestore(withUser));
      PrimekitLogger.debug(
        'Habit created: ${docRef.id}',
        tag: 'PkHabitService',
      );
      return docRef.id;
    } catch (e) {
      PrimekitLogger.error(
        'Failed to create habit',
        tag: 'PkHabitService',
        error: e,
      );
      throw HabitException(message: 'Failed to create habit: $e', cause: e);
    }
  }

  @override
  Future<void> updateHabit(PkHabit habit) async {
    _requireHabitId(habit);
    try {
      await _collection.doc(habit.id).update(_toFirestore(habit));
    } catch (e) {
      PrimekitLogger.error(
        'Failed to update habit: ${habit.id}',
        tag: 'PkHabitService',
        error: e,
      );
      throw HabitException(message: 'Failed to update habit: $e', cause: e);
    }
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    try {
      await _collection.doc(habitId).delete();
    } catch (e) {
      PrimekitLogger.error(
        'Failed to delete habit: $habitId',
        tag: 'PkHabitService',
        error: e,
      );
      throw HabitException(message: 'Failed to delete habit: $e', cause: e);
    }
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    try {
      await _collection.doc(habitId).update({
        'isArchived': true,
        'archivedAt': Timestamp.now(),
      });
    } catch (e) {
      throw HabitException(message: 'Failed to archive habit: $e', cause: e);
    }
  }

  @override
  Future<void> unarchiveHabit(String habitId) async {
    try {
      await _collection.doc(habitId).update({
        'isArchived': false,
        'archivedAt': null,
      });
    } catch (e) {
      throw HabitException(
        message: 'Failed to unarchive habit: $e',
        cause: e,
      );
    }
  }

  @override
  Future<void> markCompleted(PkHabit habit) async {
    _requireHabitId(habit);
    try {
      final today = DateTime.now();
      final alreadyDone = habit.completionDates.any((c) =>
          c.year == today.year &&
          c.month == today.month &&
          c.day == today.day);
      if (alreadyDone) return;

      final updated = [...habit.completionDates, today];
      await _collection.doc(habit.id).update({
        'completionDates': updated
            .map((d) => Timestamp.fromDate(d))
            .toList(),
      });
    } catch (e) {
      throw HabitException(
        message: 'Failed to mark habit completed: $e',
        cause: e,
      );
    }
  }

  @override
  Future<void> removeCompletion(PkHabit habit, DateTime date) async {
    _requireHabitId(habit);
    try {
      final updated = habit.completionDates.where((d) =>
          !(d.year == date.year &&
              d.month == date.month &&
              d.day == date.day)).toList();

      await _collection.doc(habit.id).update({
        'completionDates': updated
            .map((d) => Timestamp.fromDate(d))
            .toList(),
      });
    } catch (e) {
      throw HabitException(
        message: 'Failed to remove completion: $e',
        cause: e,
      );
    }
  }

  @override
  Future<void> incrementCount(PkHabit habit) async {
    _requireHabitId(habit);
    if (habit.targetCount == null) {
      await markCompleted(habit);
      return;
    }

    final key = _dateKey(DateTime.now());
    final currentCount = habit.dailyCounts[key] ?? 0;
    final newCount = currentCount + 1;
    final updatedCounts = {...habit.dailyCounts, key: newCount};
    final updates = <String, dynamic>{'dailyCounts': updatedCounts};

    if (newCount == habit.targetCount) {
      final today = DateTime.now();
      final alreadyDone = habit.completionDates.any((c) =>
          c.year == today.year &&
          c.month == today.month &&
          c.day == today.day);
      if (!alreadyDone) {
        final updatedDates = [...habit.completionDates, today];
        updates['completionDates'] = updatedDates
            .map((d) => Timestamp.fromDate(d))
            .toList();
      }
    }

    await _collection.doc(habit.id).update(updates);
  }

  @override
  Future<void> decrementCount(PkHabit habit) async {
    _requireHabitId(habit);
    if (habit.targetCount == null) {
      await removeCompletion(habit, DateTime.now());
      return;
    }

    final key = _dateKey(DateTime.now());
    final currentCount = habit.dailyCounts[key] ?? 0;
    if (currentCount == 0) return;

    final newCount = currentCount - 1;
    final updatedCounts = {...habit.dailyCounts, key: newCount};
    final updates = <String, dynamic>{'dailyCounts': updatedCounts};

    final wasCompleted = currentCount >= habit.targetCount!;
    final nowComplete = newCount >= habit.targetCount!;
    if (wasCompleted && !nowComplete) {
      final today = DateTime.now();
      final updatedDates = habit.completionDates.where((c) =>
          !(c.year == today.year &&
              c.month == today.month &&
              c.day == today.day)).toList();
      updates['completionDates'] = updatedDates
          .map((d) => Timestamp.fromDate(d))
          .toList();
    }

    await _collection.doc(habit.id).update(updates);
  }

  @override
  Future<PkHabitStatistics> getHabitStatistics() async {
    if (_currentUserId == null) return const PkHabitStatistics.empty();

    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: _currentUserId)
          .where('isArchived', isEqualTo: false)
          .get();

      final habits = snapshot.docs.map(_fromFirestore).toList();
      if (habits.isEmpty) return const PkHabitStatistics.empty();

      var completedToday = 0;
      var totalCompletions = 0;
      var totalCurrentStreak = 0;
      var longestOverall = 0;

      for (final habit in habits) {
        if (_isCompletedInCurrentPeriod(habit)) completedToday++;
        totalCompletions += habit.completionDates.length;
        totalCurrentStreak += StreakCalculator.currentStreak(
          habit.completionDates,
          frequency: habit.frequency,
        );
        final longest = StreakCalculator.longestStreak(
          habit.completionDates,
          frequency: habit.frequency,
        );
        if (longest > longestOverall) longestOverall = longest;
      }

      return PkHabitStatistics(
        totalHabits: habits.length,
        completedToday: completedToday,
        totalCompletions: totalCompletions,
        averageCurrentStreak: totalCurrentStreak / habits.length,
        longestStreakOverall: longestOverall,
      );
    } catch (e) {
      PrimekitLogger.error(
        'Failed to get habit statistics',
        tag: 'PkHabitService',
        error: e,
      );
      return const PkHabitStatistics.empty();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _isCompletedInCurrentPeriod(PkHabit habit) {
    return switch (habit.frequency) {
      PkHabitFrequency.daily => habit.isCompletedToday,
      PkHabitFrequency.weekly => habit.isCompletedThisWeek,
      PkHabitFrequency.monthly => habit.isCompletedThisMonth,
      PkHabitFrequency.custom => habit.isCompletedToday,
    };
  }

  void _requireAuth() {
    if (_currentUserId == null) {
      throw const AuthException(message: 'User not authenticated');
    }
  }

  void _requireHabitId(PkHabit habit) {
    if (habit.id == null) {
      throw const HabitException(
        message: 'Habit ID cannot be null',
        code: 'NULL_HABIT_ID',
      );
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  PkHabit _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final rawCounts = data['dailyCounts'] as Map<String, dynamic>?;
    final counts =
        rawCounts?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {};

    return PkHabit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['createdDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      frequency: PkHabitFrequency.fromString(
        data['frequency'] as String? ?? 'daily',
      ),
      completionDates: (data['completionDates'] as List<dynamic>?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ??
          (data['completions'] as List<dynamic>?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ??
          [],
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      isArchived: data['isArchived'] as bool? ?? false,
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      targetCount: data['targetCount'] as int? ?? data['completionTarget'] as int?,
      dailyCounts: counts,
    );
  }

  Map<String, dynamic> _toFirestore(PkHabit habit) {
    return {
      'name': habit.name,
      'description': habit.description,
      'userId': habit.userId,
      'createdAt': Timestamp.fromDate(habit.createdAt),
      'frequency': habit.frequency.value,
      'completionDates': habit.completionDates
          .map((d) => Timestamp.fromDate(d))
          .toList(),
      'icon': habit.icon,
      'color': habit.color,
      'isArchived': habit.isArchived,
      'archivedAt':
          habit.archivedAt != null ? Timestamp.fromDate(habit.archivedAt!) : null,
      'targetCount': habit.targetCount,
      'dailyCounts': habit.dailyCounts,
    };
  }
}

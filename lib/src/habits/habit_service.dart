import 'habit.dart';

/// Aggregate statistics for a user's habits.
class PkHabitStatistics {
  final int totalHabits;
  final int completedToday;
  final int totalCompletions;
  final double averageCurrentStreak;
  final int longestStreakOverall;

  const PkHabitStatistics({
    required this.totalHabits,
    required this.completedToday,
    required this.totalCompletions,
    required this.averageCurrentStreak,
    required this.longestStreakOverall,
  });

  /// Empty statistics (no habits).
  const PkHabitStatistics.empty()
      : totalHabits = 0,
        completedToday = 0,
        totalCompletions = 0,
        averageCurrentStreak = 0.0,
        longestStreakOverall = 0;
}

/// Abstract habit tracking service.
///
/// Implementations handle persistence (Firestore, local DB, etc.).
/// All methods that modify state return new objects rather than mutating.
abstract class PkHabitService {
  /// Set the active user for scoped queries.
  void setCurrentUserId(String? userId);

  /// Stream of all habits for the current user.
  ///
  /// When [includeArchived] is true, archived habits are included.
  Stream<List<PkHabit>> getHabits({bool includeArchived = false});

  /// Create a new habit and return its generated ID.
  Future<String> createHabit(PkHabit habit);

  /// Update an existing habit.
  Future<void> updateHabit(PkHabit habit);

  /// Permanently delete a habit.
  Future<void> deleteHabit(String habitId);

  /// Archive a habit (soft delete).
  Future<void> archiveHabit(String habitId);

  /// Unarchive a previously archived habit.
  Future<void> unarchiveHabit(String habitId);

  /// Mark the habit as completed for the current period.
  Future<void> markCompleted(PkHabit habit);

  /// Remove a completion for a specific date.
  Future<void> removeCompletion(PkHabit habit, DateTime date);

  /// Increment the daily count for an incremental habit.
  Future<void> incrementCount(PkHabit habit);

  /// Decrement the daily count for an incremental habit.
  Future<void> decrementCount(PkHabit habit);

  /// Compute aggregate statistics across all active habits.
  Future<PkHabitStatistics> getHabitStatistics();
}

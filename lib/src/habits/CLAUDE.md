# habits -- Habit Tracking

**Purpose:** Generic habit model, streak calculator, heatmap widget, and Firestore service. Domain-agnostic.

**Key exports:**
- `PkHabit` -- immutable habit model with frequency, completionDates, dailyCounts, targetCount
- `PkHabitFrequency` -- enum: daily, weekly, monthly, custom
- `PkHabitService` -- abstract interface for CRUD + completion tracking
- `PkHabitStatistics` -- aggregate stats: totalHabits, completedToday, streaks
- `StreakCalculator` -- static pure functions: currentStreak, longestStreak, completionRate, heatmapData
- `PkHabitHeatmap` -- GitHub-style 52x7 completion heatmap widget

**Firebase adapter:** `FirestoreHabitService` in `firestore_habit_service.dart` (NOT auto-exported from barrel).

**Dependencies:** `core` (exceptions, logger), `cloud_firestore` (Firestore impl only), `flutter` (heatmap widget).

**Consumers:** best_todo_list.

**Maintenance:** Update when PkHabit fields change, new frequency types added, or service API changes.

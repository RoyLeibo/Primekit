/// PrimeKit Scheduling — generic recurrence and schedule computation.
///
/// ```dart
/// import 'package:primekit/scheduling.dart';
///
/// final rule = RecurrenceRule.dailyAt([
///   ScheduleTimeOfDay(hour: 8),
///   ScheduleTimeOfDay(hour: 20),
/// ]);
/// final slots = ScheduleCalculator.generateSlots(
///   rule: rule,
///   courseStart: DateTime(2026, 3, 10),
///   from: DateTime(2026, 3, 14),
///   to: DateTime(2026, 3, 14, 23, 59),
/// );
/// ```
library primekit_scheduling;

export 'src/scheduling/scheduling.dart';

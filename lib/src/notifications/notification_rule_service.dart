import 'package:primekit/core.dart';

import 'notification_rule.dart';

/// The result of computing the next notification time from a set of rules.
final class NextNotificationResult {
  const NextNotificationResult({
    required this.notificationTime,
    required this.ruleId,
  });

  /// When the next notification should fire.
  final DateTime notificationTime;

  /// The ID of the rule that should fire next.
  final String ruleId;

  @override
  String toString() =>
      'NextNotificationResult(time: $notificationTime, ruleId: $ruleId)';
}

/// Service for notification rule scheduling calculations.
///
/// All methods are pure (no side-effects) and return new objects.
/// Integrates with [LocalNotifier] for actual notification delivery —
/// this service only handles the **rule engine** logic.
///
/// ```dart
/// final next = NotificationRuleService.calculateNextNotificationTime(
///   rules,
///   targetDateTime,
/// );
/// if (next != null) {
///   await LocalNotifier.instance.schedule(
///     id: next.ruleId.hashCode,
///     title: 'Reminder',
///     body: entityName,
///     scheduledAt: next.notificationTime,
///   );
/// }
/// ```
abstract final class NotificationRuleService {
  /// Round [dateTime] down to the nearest minute (strips seconds/millis).
  static DateTime roundToMinute(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
  }

  /// Find the next notification time from [rules] given [targetDateTime].
  ///
  /// Only considers rules that are enabled and have not yet fired.
  /// Skips notification times that are in the past.
  /// Returns `null` when no rules are eligible to fire in the future.
  static NextNotificationResult? calculateNextNotificationTime(
    List<NotificationRule> rules,
    DateTime targetDateTime,
  ) {
    final now = roundToMinute(DateTime.now());
    DateTime? earliestTime;
    String? earliestRuleId;

    for (final rule in rules) {
      if (!rule.isEnabled || rule.hasFired) continue;

      final notificationTime =
          roundToMinute(targetDateTime.subtract(rule.duration));

      if (notificationTime.isBefore(now)) continue;

      if (earliestTime == null || notificationTime.isBefore(earliestTime)) {
        earliestTime = notificationTime;
        earliestRuleId = rule.id;
      }
    }

    if (earliestTime == null || earliestRuleId == null) return null;

    return NextNotificationResult(
      notificationTime: earliestTime,
      ruleId: earliestRuleId,
    );
  }

  /// Reset [hasFired] on every rule in [rules].
  ///
  /// Returns a new list — the original is not modified.
  /// Useful after a recurring entity advances to its next occurrence.
  static List<NotificationRule> resetFiredStatus(
    List<NotificationRule> rules,
  ) {
    return rules
        .map((rule) => rule.copyWith(hasFired: false))
        .toList(growable: false);
  }

  /// Mark the rule with [ruleId] as fired, returning a new list.
  ///
  /// Rules whose ID does not match are returned unchanged.
  static List<NotificationRule> markRuleFired(
    List<NotificationRule> rules,
    String ruleId,
  ) {
    return rules.map((rule) {
      if (rule.id == ruleId) {
        return rule.copyWith(hasFired: true);
      }
      return rule;
    }).toList(growable: false);
  }

  /// Whether any rules are enabled and have not yet fired.
  static bool hasPendingRules(List<NotificationRule> rules) {
    return rules.any((rule) => rule.isEnabled && !rule.hasFired);
  }

  /// Validate a [NotificationRule], throwing [ValidationException]
  /// if the rule is invalid.
  static void validate(NotificationRule rule) {
    final errors = <String, String>{};

    if (rule.id.isEmpty) {
      errors['id'] = 'Rule ID must not be empty';
    }
    if (rule.value < 0) {
      errors['value'] = 'Rule value must be non-negative';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        message: 'Invalid notification rule: ${rule.id}',
        errors: errors,
      );
    }
  }
}

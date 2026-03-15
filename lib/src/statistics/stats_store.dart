import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core.dart';
import 'completion_event.dart';

/// Abstract storage for completion and creation events.
///
/// Implementations decide persistence strategy (SharedPreferences, Firestore,
/// SQLite, etc.). All methods return new collections — never mutate.
abstract class PkStatsStore {
  /// Record a completion event.
  Future<void> trackCompletion(PkCompletionEvent event);

  /// Record a creation event.
  Future<void> trackCreation(PkCreationEvent event);

  /// Retrieve all stored completion events.
  Future<List<PkCompletionEvent>> getEvents();

  /// Retrieve completion events within a date range.
  Future<List<PkCompletionEvent>> getEventsInRange(
    DateTime start,
    DateTime end,
  );

  /// Retrieve all stored creation events.
  Future<List<PkCreationEvent>> getCreationEvents();

  /// Clear all stored events.
  Future<void> clearAll();
}

/// SharedPreferences-backed implementation of [PkStatsStore].
///
/// Stores events as JSON string lists. Privacy-first: all data stays on-device.
/// Caps storage at [maxEvents] to prevent unbounded growth.
class SharedPrefsStatsStore implements PkStatsStore {
  SharedPrefsStatsStore({
    this.completionKey = 'pk_stats_completion_events',
    this.creationKey = 'pk_stats_creation_events',
    this.maxEvents = 5000,
  });

  final String completionKey;
  final String creationKey;
  final int maxEvents;

  @override
  Future<void> trackCompletion(PkCompletionEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(completionKey) ?? [];
      final events = [
        ...existing.map((s) => PkCompletionEvent.fromJson(jsonDecode(s))),
        event,
      ];

      final trimmed =
          events.length > maxEvents ? events.sublist(events.length - maxEvents) : events;

      await prefs.setStringList(
        completionKey,
        trimmed.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (e) {
      PrimekitLogger.error(
        'Failed to track completion',
        tag: 'PkStatsStore',
        error: e,
      );
      throw StatisticsException(
        message: 'Failed to track completion: $e',
        cause: e,
      );
    }
  }

  @override
  Future<void> trackCreation(PkCreationEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(creationKey) ?? [];
      final events = [
        ...existing.map((s) => PkCreationEvent.fromJson(jsonDecode(s))),
        event,
      ];

      final trimmed =
          events.length > maxEvents ? events.sublist(events.length - maxEvents) : events;

      await prefs.setStringList(
        creationKey,
        trimmed.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (e) {
      PrimekitLogger.error(
        'Failed to track creation',
        tag: 'PkStatsStore',
        error: e,
      );
      throw StatisticsException(
        message: 'Failed to track creation: $e',
        cause: e,
      );
    }
  }

  @override
  Future<List<PkCompletionEvent>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(completionKey) ?? [];
      return raw
          .map((s) => PkCompletionEvent.fromJson(jsonDecode(s)))
          .toList();
    } catch (e) {
      PrimekitLogger.error(
        'Failed to read completion events',
        tag: 'PkStatsStore',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<List<PkCompletionEvent>> getEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getEvents();
    return all
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  @override
  Future<List<PkCreationEvent>> getCreationEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(creationKey) ?? [];
      return raw
          .map((s) => PkCreationEvent.fromJson(jsonDecode(s)))
          .toList();
    } catch (e) {
      PrimekitLogger.error(
        'Failed to read creation events',
        tag: 'PkStatsStore',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(completionKey);
    await prefs.remove(creationKey);
  }
}

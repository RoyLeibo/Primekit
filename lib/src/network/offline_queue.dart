import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'connectivity_monitor.dart';

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

/// Represents an HTTP request that has been enqueued for later execution.
final class QueuedRequest {
  /// Creates an immutable queued request.
  const QueuedRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.enqueuedAt,
    this.body,
    this.headers = const {},
    this.maxRetries = 3,
    this.retryCount = 0,
  });

  /// Deserialises from a JSON map.
  factory QueuedRequest.fromJson(Map<String, Object?> json) => QueuedRequest(
    id: (json['id'] ?? '') as String,
    method: (json['method'] ?? 'GET') as String,
    url: (json['url'] ?? '') as String,
    enqueuedAt: DateTime.parse(
      (json['enqueuedAt'] ?? DateTime.now().toIso8601String()) as String,
    ).toUtc(),
    body: json['body'],
    headers: (json['headers'] as Map?)?.cast<String, String>() ?? const {},
    maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
    retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Unique request identifier.
  final String id;

  /// HTTP method (GET, POST, PUT, DELETE, PATCH).
  final String method;

  /// Fully qualified URL.
  final String url;

  /// UTC timestamp when this request was originally enqueued.
  final DateTime enqueuedAt;

  /// Optional request body. Must be JSON-encodable.
  final Object? body;

  /// HTTP headers to include in the request.
  final Map<String, String> headers;

  /// Maximum number of retry attempts before the request is dropped.
  final int maxRetries;

  /// Number of times this request has already been attempted.
  final int retryCount;

  // ---------------------------------------------------------------------------
  // Methods
  // ---------------------------------------------------------------------------

  /// Returns a copy with [retryCount] incremented by one.
  QueuedRequest withIncrementedRetry() => QueuedRequest(
    id: id,
    method: method,
    url: url,
    enqueuedAt: enqueuedAt,
    body: body,
    headers: Map<String, String>.unmodifiable(headers),
    maxRetries: maxRetries,
    retryCount: retryCount + 1,
  );

  /// Serialises to a JSON-encodable map.
  Map<String, Object?> toJson() => {
    'id': id,
    'method': method,
    'url': url,
    'body': body,
    'headers': headers,
    'maxRetries': maxRetries,
    'enqueuedAt': enqueuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  @override
  String toString() =>
      'QueuedRequest(id: $id, method: $method, url: $url, '
      'retryCount: $retryCount/$maxRetries)';
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Discriminated union of events emitted by [OfflineQueue].
sealed class OfflineQueueEvent {
  const OfflineQueueEvent();
}

/// Emitted when a request is added to the queue.
final class RequestEnqueuedEvent extends OfflineQueueEvent {
  const RequestEnqueuedEvent(this.request);
  final QueuedRequest request;
}

/// Emitted when a queued request executes successfully.
final class RequestFlushedEvent extends OfflineQueueEvent {
  const RequestFlushedEvent(this.request);
  final QueuedRequest request;
}

/// Emitted when a request fails after exhausting its retry budget.
final class RequestDroppedEvent extends OfflineQueueEvent {
  const RequestDroppedEvent(this.request, this.error);
  final QueuedRequest request;
  final PrimekitException error;
}

/// Emitted when a flush cycle starts.
final class FlushStartedEvent extends OfflineQueueEvent {
  const FlushStartedEvent(this.pendingCount);
  final int pendingCount;
}

/// Emitted when a flush cycle completes.
final class FlushCompletedEvent extends OfflineQueueEvent {
  const FlushCompletedEvent({required this.succeeded, required this.dropped});
  final int succeeded;
  final int dropped;
}

// ---------------------------------------------------------------------------
// OfflineQueue
// ---------------------------------------------------------------------------

/// Buffers HTTP requests while the device is offline and replays them in
/// order when connectivity is restored.
///
/// [OfflineQueue] persists enqueued requests to [SharedPreferences] so they
/// survive app restarts. A [ConnectivityMonitor] subscription triggers
/// automatic flushing when the device comes back online.
///
/// Callers are responsible for providing a [RequestExecutor] — a function
/// that actually performs the HTTP call:
///
/// ```dart
/// await OfflineQueue.instance.initialize(
///   executor: (request) async {
///     final response = await http.post(Uri.parse(request.url),
///       headers: request.headers,
///       body: jsonEncode(request.body),
///     );
///     if (response.statusCode >= 400) {
///       throw NetworkException(
///         message: 'HTTP ${response.statusCode}',
///         statusCode: response.statusCode,
///       );
///     }
///   },
/// );
/// ```
///
/// Then enqueue requests anywhere:
///
/// ```dart
/// await OfflineQueue.instance.enqueue(QueuedRequest(
///   id: const Uuid().v4(),
///   method: 'POST',
///   url: 'https://api.example.com/events',
///   body: {'event': 'purchase'},
///   enqueuedAt: DateTime.now().toUtc(),
/// ));
/// ```
typedef RequestExecutor = Future<void> Function(QueuedRequest request);

final class OfflineQueue {
  OfflineQueue._();

  static final OfflineQueue _instance = OfflineQueue._();

  /// The shared singleton instance.
  static OfflineQueue get instance => _instance;

  static const String _tag = 'OfflineQueue';
  static const String _prefKey = 'primekit_offline_queue';

  final StreamController<OfflineQueueEvent> _eventController =
      StreamController<OfflineQueueEvent>.broadcast();

  /// Mutable queue — all modifications go through the private helpers to keep
  /// a consistent snapshot pattern (copy-on-write semantics).
  final List<QueuedRequest> _queue = [];

  StreamSubscription<bool>? _connectivitySub;
  RequestExecutor? _executor;
  bool _flushing = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialises the queue with the provided [executor] function.
  ///
  /// Loads any persisted requests from [SharedPreferences] and begins
  /// monitoring [ConnectivityMonitor] for automatic flush triggers.
  ///
  /// Must be called once before [enqueue] or [flush].
  Future<void> initialize({required RequestExecutor executor}) async {
    _executor = executor;
    await _loadPersistedQueue();

    _connectivitySub = ConnectivityMonitor.instance.isConnected.listen((
      connected,
    ) {
      if (connected && _queue.isNotEmpty) {
        PrimekitLogger.info(
          'Connectivity restored — flushing ${_queue.length} queued '
          'request(s).',
          tag: _tag,
        );
        flush();
      }
    });

    PrimekitLogger.info(
      'OfflineQueue initialised with ${_queue.length} persisted request(s).',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Broadcast stream of [OfflineQueueEvent]s.
  Stream<OfflineQueueEvent> get events => _eventController.stream;

  /// The number of requests currently waiting to be flushed.
  int get pendingCount => _queue.length;

  /// Adds [request] to the tail of the queue and persists it immediately.
  ///
  /// If the device is currently online, [flush] is triggered automatically
  /// so the request is dispatched without delay.
  Future<void> enqueue(QueuedRequest request) async {
    // Copy-on-write: append to a new list rather than mutating in place.
    _queue.add(request);
    await _persistQueue();

    _eventController.add(RequestEnqueuedEvent(request));

    PrimekitLogger.debug(
      'Enqueued request: ${request.method} ${request.url} '
      '(queue depth: ${_queue.length}).',
      tag: _tag,
    );

    if (ConnectivityMonitor.instance.currentStatus) {
      await flush();
    }
  }

  /// Attempts to execute all queued requests in FIFO order.
  ///
  /// Requests that succeed are removed from the queue. Requests that fail are
  /// retried on the next flush until [QueuedRequest.maxRetries] is exhausted,
  /// at which point they are dropped and a [RequestDroppedEvent] is emitted.
  ///
  /// Concurrent calls to [flush] are coalesced — only one flush cycle runs
  /// at a time.
  Future<void> flush() async {
    if (_flushing || _queue.isEmpty) return;

    final executor = _executor;
    if (executor == null) {
      PrimekitLogger.warning(
        'flush() called before initialize(). Skipping.',
        tag: _tag,
      );
      return;
    }

    _flushing = true;

    final snapshot = List<QueuedRequest>.unmodifiable(_queue);
    _eventController.add(FlushStartedEvent(snapshot.length));

    PrimekitLogger.info(
      'Flush started: ${snapshot.length} request(s).',
      tag: _tag,
    );

    var succeeded = 0;
    var dropped = 0;

    for (final request in snapshot) {
      if (!ConnectivityMonitor.instance.currentStatus) {
        PrimekitLogger.warning(
          'Connectivity lost mid-flush. Stopping.',
          tag: _tag,
        );
        break;
      }

      try {
        await executor(request);
        _queue.remove(request);
        succeeded++;
        _eventController.add(RequestFlushedEvent(request));
        PrimekitLogger.debug(
          'Flushed: ${request.method} ${request.url}.',
          tag: _tag,
        );
      } on Exception catch (error) {
        final updated = request.withIncrementedRetry();

        if (updated.retryCount > updated.maxRetries) {
          _queue.remove(request);
          dropped++;

          final pkError = error is PrimekitException
              ? error
              : NetworkException(message: error.toString(), cause: error);
          _eventController.add(RequestDroppedEvent(request, pkError));

          PrimekitLogger.warning(
            'Request dropped after ${request.maxRetries} retries: '
            '${request.method} ${request.url}.',
            tag: _tag,
            error: error,
          );
        } else {
          final idx = _queue.indexOf(request);
          if (idx != -1) {
            _queue[idx] = updated;
          }

          PrimekitLogger.warning(
            'Request failed (attempt ${updated.retryCount}/${updated.maxRetries}): '
            '${request.method} ${request.url}.',
            tag: _tag,
            error: error,
          );
        }
      }
    }

    await _persistQueue();
    _flushing = false;

    _eventController.add(
      FlushCompletedEvent(succeeded: succeeded, dropped: dropped),
    );

    PrimekitLogger.info(
      'Flush complete: $succeeded succeeded, $dropped dropped, '
      '${_queue.length} remaining.',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_queue.map((r) => r.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to persist offline queue.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _loadPersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return;

      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list
          .cast<Map<String, dynamic>>()
          .map((json) => QueuedRequest.fromJson(json.cast<String, Object?>()))
          .toList();

      _queue
        ..clear()
        ..addAll(loaded);
    } on Exception catch (error, stack) {
      PrimekitLogger.error(
        'Failed to load persisted offline queue.',
        tag: _tag,
        error: error,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the queue to its uninitialised state. For use in tests only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _queue.clear();
    _executor = null;
    _flushing = false;
  }
}

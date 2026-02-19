import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import 'email_message.dart';
import 'email_service.dart';

// ---------------------------------------------------------------------------
// Queue item models
// ---------------------------------------------------------------------------

/// The lifecycle status of a queued email.
enum QueuedEmailStatus {
  /// Waiting to be sent.
  pending,

  /// Currently being sent.
  sending,

  /// Sent successfully.
  sent,

  /// All retry attempts exhausted.
  failed,
}

/// A persisted record of an email waiting in the queue.
final class QueuedEmail {
  const QueuedEmail({
    required this.id,
    required this.message,
    required this.enqueuedAt,
    this.attempts = 0,
    this.lastAttemptAt,
    this.status = QueuedEmailStatus.pending,
    this.lastError,
  });

  /// Unique identifier for this queue item.
  final String id;

  /// The email message to send.
  final EmailMessage message;

  /// When this email was enqueued.
  final DateTime enqueuedAt;

  /// Number of send attempts so far.
  final int attempts;

  /// When the last attempt was made, or null if never attempted.
  final DateTime? lastAttemptAt;

  /// Current status of this queue item.
  final QueuedEmailStatus status;

  /// The last error message, if the most recent attempt failed.
  final String? lastError;

  /// Returns a copy with the given fields replaced.
  QueuedEmail copyWith({
    String? id,
    EmailMessage? message,
    DateTime? enqueuedAt,
    int? attempts,
    DateTime? lastAttemptAt,
    QueuedEmailStatus? status,
    String? lastError,
  }) =>
      QueuedEmail(
        id: id ?? this.id,
        message: message ?? this.message,
        enqueuedAt: enqueuedAt ?? this.enqueuedAt,
        attempts: attempts ?? this.attempts,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        status: status ?? this.status,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'enqueuedAt': enqueuedAt.toIso8601String(),
        'attempts': attempts,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'status': status.name,
        'lastError': lastError,
        'message': {
          'to': message.to,
          'toName': message.toName,
          'subject': message.subject,
          'textBody': message.textBody,
          'htmlBody': message.htmlBody,
          'replyTo': message.replyTo,
          'headers': message.headers,
          // Attachments are intentionally omitted from persistence
          // to avoid storing large binary data in SharedPreferences.
          // Re-attach before enqueueing if persistence is critical.
        },
      };

  factory QueuedEmail.fromJson(Map<String, dynamic> json) {
    final msgJson = json['message'] as Map<String, dynamic>? ?? {};
    return QueuedEmail(
      id: json['id'] as String,
      enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
      attempts: json['attempts'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      status: QueuedEmailStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueuedEmailStatus.pending,
      ),
      lastError: json['lastError'] as String?,
      message: EmailMessage(
        to: msgJson['to'] as String? ?? '',
        subject: msgJson['subject'] as String? ?? '',
        toName: msgJson['toName'] as String?,
        textBody: msgJson['textBody'] as String?,
        htmlBody: msgJson['htmlBody'] as String?,
        replyTo: msgJson['replyTo'] as String?,
        headers: Map<String, String>.from(
          (msgJson['headers'] as Map?)?.cast<String, String>() ?? {},
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// An event emitted by [EmailQueue] describing queue activity.
sealed class EmailQueueEvent {
  const EmailQueueEvent();
}

/// Emitted when an email is added to the queue.
final class EmailEnqueued extends EmailQueueEvent {
  const EmailEnqueued(this.email);
  final QueuedEmail email;
}

/// Emitted when a queue flush begins.
final class EmailFlushStarted extends EmailQueueEvent {
  const EmailFlushStarted({required this.count});
  final int count;
}

/// Emitted when an email is sent successfully during a flush.
final class EmailSentFromQueue extends EmailQueueEvent {
  const EmailSentFromQueue(this.email);
  final QueuedEmail email;
}

/// Emitted when an email fails to send during a flush.
final class EmailSendFailed extends EmailQueueEvent {
  const EmailSendFailed(this.email, {required this.reason});
  final QueuedEmail email;
  final String reason;
}

/// Emitted when a queue flush completes.
final class EmailFlushCompleted extends EmailQueueEvent {
  const EmailFlushCompleted({required this.sent, required this.failed});
  final int sent;
  final int failed;
}

// ---------------------------------------------------------------------------
// Queue
// ---------------------------------------------------------------------------

/// An offline-resilient local queue for email messages.
///
/// Messages are persisted to [SharedPreferences] so they survive app restarts.
/// When connectivity is restored, the queue auto-flushes via
/// [connectivity_plus].
///
/// ```dart
/// final queue = EmailQueue.instance;
///
/// // Queue a message — safe to call offline:
/// await queue.enqueue(message);
///
/// // Manually flush (e.g. after user returns online):
/// await queue.flush();
///
/// // Listen to events:
/// queue.events.listen((event) {
///   if (event is EmailSentFromQueue) print('Sent ${event.email.id}');
/// });
/// ```
class EmailQueue {
  EmailQueue._();

  static final EmailQueue _instance = EmailQueue._();

  /// The shared singleton instance.
  static EmailQueue get instance => _instance;

  static const String _prefsKey = 'primekit_email_queue';
  static const int _maxAttempts = 5;
  static const String _tag = 'EmailQueue';

  List<QueuedEmail> _queue = [];
  bool _initialized = false;
  bool _isFlushing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final StreamController<EmailQueueEvent> _eventController =
      StreamController<EmailQueueEvent>.broadcast();

  /// Stream of queue lifecycle events.
  Stream<EmailQueueEvent> get events => _eventController.stream;

  /// Number of emails currently pending in the queue.
  int get pendingCount => _queue
      .where((e) => e.status == QueuedEmailStatus.pending)
      .length;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the queue, loading persisted items and starting connectivity
  /// monitoring.
  ///
  /// Called automatically on first [enqueue] or [flush]; you may call it
  /// explicitly at app startup to start the connectivity listener sooner.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFromPrefs();
    _startConnectivityMonitor();

    PrimekitLogger.info(
      'EmailQueue initialized. ${_queue.length} items loaded from storage.',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Enqueue
  // ---------------------------------------------------------------------------

  /// Adds [message] to the queue.
  ///
  /// The email is persisted immediately so it survives process termination.
  Future<void> enqueue(EmailMessage message) async {
    await initialize();

    final item = QueuedEmail(
      id: _generateId(),
      message: message,
      enqueuedAt: DateTime.now().toUtc(),
    );

    _queue = [..._queue, item];
    await _saveToPrefs();

    _eventController.add(EmailEnqueued(item));
    PrimekitLogger.debug(
      'Enqueued email id=${item.id} to=${message.to}',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Flush
  // ---------------------------------------------------------------------------

  /// Attempts to send all pending queue items.
  ///
  /// Items that succeed are removed from the queue. Items that fail are
  /// retried up to [_maxAttempts] times before being marked [QueuedEmailStatus.failed].
  Future<void> flush() async {
    await initialize();

    if (_isFlushing) {
      PrimekitLogger.debug('Flush already in progress; skipping.', tag: _tag);
      return;
    }

    final pending = _queue
        .where((e) => e.status == QueuedEmailStatus.pending)
        .toList();

    if (pending.isEmpty) {
      PrimekitLogger.debug('Queue is empty; nothing to flush.', tag: _tag);
      return;
    }

    _isFlushing = true;
    _eventController.add(EmailFlushStarted(count: pending.length));

    PrimekitLogger.info(
      'Flushing ${pending.length} pending email(s).',
      tag: _tag,
    );

    var sent = 0;
    var failed = 0;

    for (final item in pending) {
      final updatedItem = item.copyWith(
        status: QueuedEmailStatus.sending,
        attempts: item.attempts + 1,
        lastAttemptAt: DateTime.now().toUtc(),
      );

      _updateItem(updatedItem);

      final result = await EmailService.instance.send(item.message);

      if (result.isSuccess) {
        _removeItem(updatedItem.id);
        final sentItem = updatedItem.copyWith(status: QueuedEmailStatus.sent);
        _eventController.add(EmailSentFromQueue(sentItem));
        sent++;
        PrimekitLogger.debug(
          'Queue item ${item.id} sent successfully.',
          tag: _tag,
        );
      } else {
        final failure = result as EmailFailure;
        final tooManyAttempts = updatedItem.attempts >= _maxAttempts;
        final finalStatus = tooManyAttempts
            ? QueuedEmailStatus.failed
            : QueuedEmailStatus.pending;

        final failedItem = updatedItem.copyWith(
          status: finalStatus,
          lastError: failure.reason,
        );

        _updateItem(failedItem);
        _eventController.add(
          EmailSendFailed(failedItem, reason: failure.reason),
        );
        failed++;

        PrimekitLogger.warning(
          'Queue item ${item.id} failed (attempt ${updatedItem.attempts}/'
          '$_maxAttempts): ${failure.reason}',
          tag: _tag,
        );
      }
    }

    await _saveToPrefs();
    _isFlushing = false;

    _eventController.add(EmailFlushCompleted(sent: sent, failed: failed));
    PrimekitLogger.info(
      'Flush complete. sent=$sent failed=$failed',
      tag: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Maintenance
  // ---------------------------------------------------------------------------

  /// Removes all items with [QueuedEmailStatus.failed] from the queue.
  Future<void> clearFailed() async {
    await initialize();
    _queue = _queue
        .where((e) => e.status != QueuedEmailStatus.failed)
        .toList();
    await _saveToPrefs();
    PrimekitLogger.info('Cleared failed queue items.', tag: _tag);
  }

  /// Returns a snapshot of all current queue items.
  List<QueuedEmail> get items => List.unmodifiable(_queue);

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      final list = (jsonDecode(raw) as List?)?.cast<Map<String, dynamic>>();
      if (list == null) return;

      _queue = list.map(QueuedEmail.fromJson).toList();
    } catch (e, stack) {
      PrimekitLogger.error(
        'Failed to load email queue from storage.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      _queue = [];
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_queue.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, json);
    } catch (e, stack) {
      PrimekitLogger.error(
        'Failed to persist email queue.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Connectivity monitoring
  // ---------------------------------------------------------------------------

  void _startConnectivityMonitor() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (r) => r != ConnectivityResult.none,
    );

    if (isConnected && pendingCount > 0) {
      PrimekitLogger.info(
        'Connectivity restored; auto-flushing ${pendingCount} pending emails.',
        tag: _tag,
      );
      flush();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _updateItem(QueuedEmail updated) {
    _queue = _queue.map((e) => e.id == updated.id ? updated : e).toList();
  }

  void _removeItem(String id) {
    _queue = _queue.where((e) => e.id != id).toList();
  }

  static String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_'
      '${_randomHex(8)}';

  static String _randomHex(int length) {
    const chars = '0123456789abcdef';
    final buffer = StringBuffer();
    final now = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < length; i++) {
      buffer.write(chars[(now + i * 13) % chars.length]);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Testing support
  // ---------------------------------------------------------------------------

  /// Resets the queue to its initial state.
  ///
  /// For use in tests only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _queue = [];
    _initialized = false;
    _isFlushing = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

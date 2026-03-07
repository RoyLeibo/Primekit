import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'message_buffer.dart';
import 'realtime_channel.dart';

/// WebSocket-based implementation of [RealtimeChannel].
///
/// Features:
/// - Automatic reconnection with exponential backoff
///   (up to `maxReconnectAttempts` attempts)
/// - Ping/pong keepalive via `pingInterval`
/// - Outgoing message queue that buffers messages while disconnected
///   and replays them on reconnect (backed by `MessageBuffer`)
///
/// ```dart
/// final channel = PkWebSocketChannel(
///   uri: Uri.parse('wss://example.com/socket'),
///   channelId: 'room1',
/// );
/// await channel.connect();
/// channel.messages.listen((msg) => print(msg.payload));
/// await channel.send({'text': 'hello'}, type: 'chat');
/// ```
class PkWebSocketChannel implements RealtimeChannel {
  /// Creates a [PkWebSocketChannel].
  PkWebSocketChannel({
    required Uri uri,
    required this.channelId,
    Map<String, String>? headers,
    Duration reconnectDelay = const Duration(seconds: 2),
    int maxReconnectAttempts = 10,
    Duration pingInterval = const Duration(seconds: 30),
    Duration connectTimeout = const Duration(seconds: 10),
    MessageBuffer? messageBuffer,
  }) : _uri = uri,
       _headers = headers ?? {},
       _baseReconnectDelay = reconnectDelay,
       _maxReconnectAttempts = maxReconnectAttempts,
       _pingInterval = pingInterval,
       _connectTimeout = connectTimeout,
       _buffer = messageBuffer ?? MessageBuffer(channelId: channelId);

  @override
  final String channelId;

  final Uri _uri;
  // Headers are kept for future use (e.g. subprotocol negotiation).
  // ignore: unused_field
  final Map<String, String> _headers;
  final Duration _baseReconnectDelay;
  final int _maxReconnectAttempts;
  final Duration _pingInterval;
  final Duration _connectTimeout;
  final MessageBuffer _buffer;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  final _messageController = StreamController<RealtimeMessage>.broadcast();
  final _statusController = StreamController<ChannelStatus>.broadcast();

  ChannelStatus _currentStatus = ChannelStatus.disconnected;

  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // RealtimeChannel interface
  // ---------------------------------------------------------------------------

  @override
  Stream<RealtimeMessage> get messages => _messageController.stream;

  @override
  Stream<ChannelStatus> get status => _statusController.stream;

  @override
  bool get isConnected => _currentStatus == ChannelStatus.connected;

  @override
  Future<void> connect() async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _setStatus(ChannelStatus.disconnecting);
    await _closeSocket();
    _setStatus(ChannelStatus.disconnected);
  }

  @override
  Future<void> send(Map<String, dynamic> payload, {String? type}) async {
    if (!isConnected) {
      await _buffer.enqueue(payload, type: type);
      return;
    }
    _sendRaw(payload, type: type);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _doConnect() async {
    _setStatus(ChannelStatus.connecting);
    try {
      _ws = WebSocketChannel.connect(_uri);
      await _ws!.ready.timeout(_connectTimeout);
      _setStatus(ChannelStatus.connected);
      _reconnectAttempts = 0;

      _wsSub = _ws!.stream.listen(
        _handleRaw,
        onError: _handleError,
        onDone: _handleDone,
      );

      _startPing();
      await _drainBuffer();
    } on Object catch (e) {
      // Abandon the failed socket without blocking — sink.close() on a socket
      // that never connected can hang indefinitely.
      final staleWs = _ws;
      _ws = null;
      staleWs?.sink.close().ignore();
      _handleError(e);
    }
  }

  void _handleRaw(dynamic raw) {
    if (raw is! String) {
      return;
    }
    final decoded = _tryDecode(raw);
    if (decoded == null) {
      return;
    }
    final message = RealtimeMessage(
      id: decoded['id'] as String? ?? _uuid.v4(),
      type: decoded['type'] as String?,
      payload: (decoded['payload'] as Map<String, dynamic>?) ?? decoded,
      receivedAt: DateTime.now(),
      senderId: decoded['senderId'] as String?,
    );
    _messageController.add(message);
  }

  void _handleError(Object error) {
    if (_intentionalDisconnect) {
      return;
    }
    _setStatus(ChannelStatus.error);
    _scheduleReconnect();
  }

  void _handleDone() {
    if (_intentionalDisconnect) {
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _stopPing();
    _wsSub?.cancel();
    _wsSub = null;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setStatus(ChannelStatus.disconnected);
      return;
    }

    _setStatus(ChannelStatus.reconnecting);
    final delay = _backoffDelay(_reconnectAttempts);
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () async {
      if (!_intentionalDisconnect) {
        await _doConnect();
      }
    });
  }

  Duration _backoffDelay(int attempt) {
    final ms = _baseReconnectDelay.inMilliseconds * (1 << attempt.clamp(0, 10));
    return Duration(milliseconds: ms);
  }

  Future<void> _drainBuffer() async {
    final pending = await _buffer.dequeueAll();
    for (final msg in pending) {
      if (!isConnected) {
        // Re-enqueue: we lost the connection while draining.
        await _buffer.enqueue(msg.payload, type: msg.type);
        break;
      }
      _sendRaw(msg.payload, type: msg.type);
    }
  }

  void _sendRaw(Map<String, dynamic> payload, {String? type}) {
    final envelope = <String, dynamic>{
      'id': _uuid.v4(),
      'type': ?type,
      'payload': payload,
      'sentAt': DateTime.now().toIso8601String(),
    };
    _ws?.sink.add(jsonEncode(envelope));
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) {
        _ws?.sink.add('ping');
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _closeSocket() async {
    _stopPing();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _wsSub?.cancel();
    _wsSub = null;
    final ws = _ws;
    _ws = null;
    if (ws != null) {
      // Don't await — sink.close() can block indefinitely on unestablished
      // sockets (e.g. when called mid-connect on a refused port).
      unawaited(
        ws.sink
            .close()
            .timeout(_connectTimeout, onTimeout: () {})
            // ignore: avoid_catches_without_on_clauses
            .catchError((_) {}),
      );
    }
  }

  void _setStatus(ChannelStatus s) {
    _currentStatus = s;
    _statusController.add(s);
  }

  Map<String, dynamic>? _tryDecode(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Releases all resources.  Call when the channel is no longer needed.
  Future<void> dispose() async {
    _intentionalDisconnect = true;
    await _closeSocket();
    await _messageController.close();
    await _statusController.close();
  }
}

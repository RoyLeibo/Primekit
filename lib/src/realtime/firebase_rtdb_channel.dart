import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import 'realtime_channel.dart';

/// Firebase Realtime Database implementation of [RealtimeChannel].
///
/// Incoming messages are received via [DatabaseReference.onChildAdded],
/// outgoing messages are written via [DatabaseReference.push].
/// Connection status is derived from the Firebase `.info/connected` special
/// path, so it reflects true connectivity (including offline persistence).
///
/// ```dart
/// final channel = FirebaseRtdbChannel(
///   channelId: 'room1',
///   path: 'channels/room1/messages',
/// );
/// await channel.connect();
/// channel.messages.listen((msg) => print(msg.payload));
/// await channel.send({'text': 'hello'}, type: 'chat');
/// ```
class FirebaseRtdbChannel implements RealtimeChannel {
  /// Creates a [FirebaseRtdbChannel].
  ///
  /// [path] is the RTDB path where messages are stored, e.g.
  /// `'channels/room1/messages'`.
  /// [maxMessages] limits the number of historic messages loaded on connect.
  FirebaseRtdbChannel({
    required this.channelId,
    required String path,
    FirebaseDatabase? database,
    int maxMessages = 100,
  }) : _path = path,
       _db = database ?? FirebaseDatabase.instance,
       _maxMessages = maxMessages;

  @override
  final String channelId;

  final String _path;
  final FirebaseDatabase _db;
  final int _maxMessages;

  StreamSubscription<DatabaseEvent>? _childSub;
  StreamSubscription<DatabaseEvent>? _connectedSub;

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
    _setStatus(ChannelStatus.connecting);

    // Monitor Firebase's own connectivity indicator.
    final connectedRef = _db.ref('.info/connected');
    _connectedSub = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        _setStatus(ChannelStatus.connected);
      } else if (_currentStatus != ChannelStatus.disconnecting &&
          _currentStatus != ChannelStatus.disconnected) {
        _setStatus(ChannelStatus.reconnecting);
      }
    });

    // Subscribe to new messages.
    final messagesRef = _db.ref(_path).limitToLast(_maxMessages);
    _childSub = messagesRef.onChildAdded.listen(
      _handleChildAdded,
      onError: _handleError,
    );
  }

  @override
  Future<void> disconnect() async {
    _setStatus(ChannelStatus.disconnecting);
    await _connectedSub?.cancel();
    await _childSub?.cancel();
    _connectedSub = null;
    _childSub = null;
    _setStatus(ChannelStatus.disconnected);
  }

  @override
  Future<void> send(Map<String, dynamic> payload, {String? type}) async {
    final ref = _db.ref(_path);
    final envelope = <String, dynamic>{
      'id': _uuid.v4(),
      if (type != null) 'type': type,
      'payload': payload,
      'sentAt': DateTime.now().toIso8601String(),
    };
    // push() creates a new child with a Firebase-generated key.
    await ref.push().set(envelope);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _handleChildAdded(DatabaseEvent event) {
    final raw = event.snapshot.value;
    if (raw is! Map) {
      return;
    }
    final data = Map<String, dynamic>.from(raw as Map<Object?, Object?>);
    final message = RealtimeMessage(
      id: data['id'] as String? ?? event.snapshot.key ?? _uuid.v4(),
      type: data['type'] as String?,
      payload: data['payload'] is Map
          ? Map<String, dynamic>.from(data['payload'] as Map<Object?, Object?>)
          : data,
      receivedAt: DateTime.now(),
      senderId: data['senderId'] as String?,
    );
    _messageController.add(message);
  }

  void _handleError(Object error) {
    _setStatus(ChannelStatus.error);
  }

  void _setStatus(ChannelStatus s) {
    _currentStatus = s;
    _statusController.add(s);
  }

  /// Releases all resources.
  Future<void> dispose() async {
    await _connectedSub?.cancel();
    await _childSub?.cancel();
    await _messageController.close();
    await _statusController.close();
  }
}

/// Primekit Realtime module.
///
/// WebSocket abstraction with auto-reconnect, presence detection, message
/// buffering, and Firebase RTDB backend support.
///
/// ## Quick-start
///
/// ```dart
/// import 'package:primekit/realtime.dart';
///
/// // 1. Open a WebSocket channel
/// final channel = PkWebSocketChannel(
///   uri: Uri.parse('wss://example.com/socket'),
///   channelId: 'room1',
/// );
/// await channel.connect();
///
/// // 2. Receive messages
/// channel.messages.listen((msg) => print('${msg.type}: ${msg.payload}'));
///
/// // 3. Send messages (buffered automatically while offline)
/// await channel.send({'text': 'hello'}, type: 'chat');
///
/// // 4. Track presence
/// RealtimeManager.instance.configurePresence(FirebasePresenceService());
/// await RealtimeManager.instance.presenceService!.connect(
///   userId: 'user123',
///   channelId: 'room1',
/// );
/// ```
library primekit_realtime;

export 'firebase_rtdb_channel.dart';
export 'message_buffer.dart';
export 'presence_service.dart';
export 'realtime_channel.dart';
export 'realtime_manager.dart';
export 'websocket_channel.dart';

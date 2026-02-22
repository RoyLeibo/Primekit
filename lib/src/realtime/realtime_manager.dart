import 'presence_service.dart';
import 'realtime_channel.dart';

/// Factory function that creates a [RealtimeChannel] for the given [channelId].
typedef RealtimeChannelFactory = RealtimeChannel Function(String channelId);

/// Central coordinator that owns all active `RealtimeChannel` instances.
///
/// Use [getChannel] to lazily create or retrieve an existing channel.
/// Channels are keyed by their `channelId`.
///
/// ```dart
/// // Configure presence once
/// RealtimeManager.instance.presenceService =
///     FirebasePresenceService();
///
/// // Open a channel (factory is only called on first access)
/// final channel = RealtimeManager.instance.getChannel(
///   'room1',
///   factory: (id) => PkWebSocketChannel(
///     uri: Uri.parse('wss://example.com/socket'),
///     channelId: id,
///   ),
/// );
/// await channel.connect();
/// ```
class RealtimeManager {
  RealtimeManager._();

  static final RealtimeManager _instance = RealtimeManager._();

  /// The singleton [RealtimeManager] instance.
  static RealtimeManager get instance => _instance;

  final Map<String, RealtimeChannel> _channels = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the channel with [channelId], creating it if necessary.
  ///
  /// [factory] is only invoked when no channel with [channelId] exists yet.
  RealtimeChannel getChannel(
    String channelId, {
    required RealtimeChannelFactory factory,
  }) {
    if (_channels.containsKey(channelId)) {
      return _channels[channelId]!;
    }
    final channel = factory(channelId);
    _channels[channelId] = channel;
    return channel;
  }

  /// Disconnects and removes the channel with [channelId].
  Future<void> closeChannel(String channelId) async {
    final channel = _channels.remove(channelId);
    await channel?.disconnect();
  }

  /// Disconnects and removes all open channels.
  Future<void> closeAll() async {
    final channels = List<RealtimeChannel>.from(_channels.values);
    _channels.clear();
    for (final channel in channels) {
      await channel.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Presence
  // ---------------------------------------------------------------------------

  /// The configured [PresenceService], if any.
  PresenceService? presenceService;
}

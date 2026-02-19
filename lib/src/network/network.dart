/// Network — HTTP client, offline request queue, connectivity monitoring,
/// and automatic retry support for Flutter apps.
///
/// ## Quick-start
///
/// ```dart
/// // 1. Create a client
/// final client = PrimekitNetworkClient(
///   baseUrl: 'https://api.example.com',
///   onAuthToken: () async => await storage.read('access_token'),
/// );
///
/// // 2. Make type-safe calls
/// final response = await client.get<List<Post>>(
///   '/posts',
///   parser: (json) => (json as List)
///       .map((e) => Post.fromJson(e as Map<String, dynamic>))
///       .toList(),
/// );
///
/// response.when(
///   loading: () {},
///   success: (posts) => setState(() => _posts = posts),
///   failure: (err)  => showError(err.userMessage),
/// );
///
/// // 3. Monitor connectivity
/// ConnectivityMonitor.instance.isConnected.listen((online) {
///   if (!online) showOfflineBanner();
/// });
///
/// // 4. Queue requests while offline
/// await OfflineQueue.instance.initialize(executor: client.rawExecutor);
/// ```
library primekit_network;

export 'api_response.dart';
export 'connectivity_monitor.dart';
export 'network_client.dart';
export 'offline_queue.dart';
export 'retry_interceptor.dart';

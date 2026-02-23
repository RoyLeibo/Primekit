import 'dart:async';

import 'package:dio/dio.dart';

import '../sync_data_source.dart';

/// A [SyncDataSource] backed by the MongoDB Atlas Data API (REST).
///
/// No additional SDK is required — all communication happens over HTTPS using
/// [Dio]. The Atlas Data API must be enabled on your cluster.
///
/// **Setup**
///
/// 1. Enable the Atlas Data API in your MongoDB Atlas project.
/// 2. Create an API key (or use Email/Password / App Services auth).
/// 3. Note your App ID, cluster name, and database name.
/// 4. Pass a [MongoSyncSource] to [SyncRepository].
///
/// ```dart
/// final repo = SyncRepository<Todo>(
///   collection: 'todos',
///   remoteSource: MongoSyncSource(
///     baseUrl: 'https://data.mongodb-api.com/app/<appId>/endpoint/data/v1',
///     apiKey: 'YOUR_API_KEY',
///     dataSource: 'Cluster0',
///     database: 'mydb',
///   ),
///   fromJson: Todo.fromJson,
/// );
/// ```
///
/// **Real-time watch**
///
/// MongoDB Atlas Data API does not provide native WebSocket streams.
/// [watchCollection] falls back to periodic polling at [watchPollInterval].
/// For true real-time sync, use the Realm/Atlas Device Sync SDK instead and
/// document that limitation clearly in your project.
final class MongoSyncSource implements SyncDataSource {
  /// Creates a [MongoSyncSource].
  ///
  /// [dio] may be supplied for testing; a default instance is created if
  /// omitted.
  ///
  /// [watchPollInterval] controls how frequently [watchCollection] polls
  /// when no native stream is available (default: 30 seconds).
  MongoSyncSource({
    required String baseUrl,
    required String apiKey,
    required String dataSource,
    required String database,
    Dio? dio,
    this.watchPollInterval = const Duration(seconds: 30),
    this.timestampField = 'updatedAt',
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _apiKey = apiKey,
       _dataSource = dataSource,
       _database = database,
       _dio = dio ?? Dio();

  final String _baseUrl;
  final String _apiKey;
  final String _dataSource;
  final String _database;
  final Dio _dio;

  /// Interval between poll cycles in [watchCollection].
  final Duration watchPollInterval;

  /// MongoDB document field used for incremental change queries.
  final String timestampField;

  @override
  String get providerId => 'mongodb';

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> fetchChanges({
    required String collection,
    DateTime? since,
    String? userId,
  }) async {
    final filter = <String, dynamic>{};

    if (since != null) {
      filter[timestampField] = {
        r'$gt': {r'$date': since.toUtc().toIso8601String()},
      };
    }

    if (userId != null && userId.isNotEmpty) {
      filter['userId'] = userId;
    }

    final body = {
      'dataSource': _dataSource,
      'database': _database,
      'collection': collection,
      'filter': filter,
    };

    final response = await _post('/action/find', body);
    final documents = (response['documents'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return documents.map(_normaliseId).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String collection,
    String? userId,
  }) {
    // NOTE: The Atlas Data API does not support native change streams over
    // REST. This implementation falls back to periodic polling.
    // For production real-time needs, integrate the Realm SDK or Atlas Device
    // Sync which provides native change stream support.
    return Stream<void>.periodic(watchPollInterval).asyncMap((_) async {
      return fetchChanges(collection: collection, userId: userId);
    });
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<void> pushChange({
    required String collection,
    required Map<String, dynamic> document,
    required SyncOperation operation,
  }) async {
    final id = document['id'] as String?;
    if (id == null) {
      throw ArgumentError(
        'MongoSyncSource.pushChange: document must contain an "id" field.',
      );
    }

    switch (operation) {
      case SyncOperation.create:
        await _post('/action/insertOne', {
          'dataSource': _dataSource,
          'database': _database,
          'collection': collection,
          'document': _prepareDocument(document),
        });
      case SyncOperation.update:
        await _post('/action/updateOne', {
          'dataSource': _dataSource,
          'database': _database,
          'collection': collection,
          'filter': {'id': id},
          'update': {r'$set': _prepareDocument(document)},
          'upsert': true,
        });
      case SyncOperation.delete:
        final isDeleted = document['isDeleted'] as bool? ?? false;
        if (isDeleted) {
          // Soft delete: update the isDeleted flag so other clients can sync
          await _post('/action/updateOne', {
            'dataSource': _dataSource,
            'database': _database,
            'collection': collection,
            'filter': {'id': id},
            'update': {
              r'$set': {
                'isDeleted': true,
                timestampField: {
                  r'$date': DateTime.now().toUtc().toIso8601String(),
                },
              },
            },
            'upsert': true,
          });
        } else {
          await _post('/action/deleteOne', {
            'dataSource': _dataSource,
            'database': _database,
            'collection': collection,
            'filter': {'id': id},
          });
        }
    }
  }

  @override
  Future<void> pushBatch({
    required String collection,
    required List<SyncChange> changes,
  }) async {
    // Atlas Data API does not have a batch endpoint; push sequentially.
    // Group by operation type to minimise round-trips where possible.
    final creates = changes
        .where((c) => c.operation == SyncOperation.create)
        .toList();
    final updates = changes
        .where((c) => c.operation == SyncOperation.update)
        .toList();
    final deletes = changes
        .where((c) => c.operation == SyncOperation.delete)
        .toList();

    // Bulk insert for creates
    if (creates.isNotEmpty) {
      await _post('/action/insertMany', {
        'dataSource': _dataSource,
        'database': _database,
        'collection': collection,
        'documents': creates.map((c) => _prepareDocument(c.document)).toList(),
      });
    }

    // Updates and deletes must be done individually
    await Future.wait([
      ...updates.map(
        (c) => pushChange(
          collection: collection,
          document: c.document,
          operation: c.operation,
        ),
      ),
      ...deletes.map(
        (c) => pushChange(
          collection: collection,
          document: c.document,
          operation: c.operation,
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // HTTP helper
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl$endpoint',
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
      ),
    );

    if (response.statusCode == null || response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'MongoSyncSource: HTTP ${response.statusCode} from $endpoint',
      );
    }

    return response.data ?? {};
  }

  // ---------------------------------------------------------------------------
  // Document normalisation
  // ---------------------------------------------------------------------------

  /// Renames MongoDB's `_id` field to `id` for portability.
  Map<String, dynamic> _normaliseId(Map<String, dynamic> doc) {
    final id = doc['_id']?['\$oid'] as String? ?? doc['id'] as String?;
    return {...doc, if (id != null) 'id': id}..remove('_id');
  }

  /// Converts the app-level `updatedAt` ISO-8601 string to a MongoDB Extended
  /// JSON `$date` object so Atlas stores it as a proper BSON Date.
  Map<String, dynamic> _prepareDocument(Map<String, dynamic> document) {
    final prepared = Map<String, dynamic>.from(document);
    final ts = prepared[timestampField];
    if (ts is String) {
      prepared[timestampField] = {r'$date': ts};
    }
    return prepared;
  }
}
